import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:just_audio/just_audio.dart';
import '../../../core/config/reminder_audio_config.dart';
import '../../../core/services/alarm_audio_service.dart';
import '../../../core/services/native_alarm_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../quiet_hours/presentation/providers/quiet_hours_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../domain/reminder_model.dart';
import 'widgets/alarm_customization_modal.dart';
import 'widgets/ambient_wave_background.dart';
import 'providers/reminder_provider.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  final String? reminderId;
  final String? prayerName;
  final String? title;
  final String? soundType;
  final int? notifId;
  final String? initialBgType;
  final String? initialBgValue;
  final bool? initialShowWaves;

  final bool isPreview;

  const AlarmScreen({
    super.key,
    this.reminderId,
    this.prayerName,
    this.title,
    this.soundType,
    this.notifId,
    this.initialBgType,
    this.initialBgValue,
    this.initialShowWaves,
    this.isPreview = false,
  });

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late AnimationController _rotateController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoDismissTimer;
  Timer? _vibrationTimer;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  String _activeSoundName = 'Default Ringtone';
  bool _isDismissed = false;
  StreamSubscription<String>? _dismissSubscription;
  StreamSubscription<int>? _snoozeSubscription;

  bool get _isEffectivePreview =>
      widget.isPreview || widget.soundType == 'preview_silent';

  @override
  void initState() {
    super.initState();

    // Listen to physical volume / power buttons to dismiss/silence alarm
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    if (!_isEffectivePreview) {
      // Informs native Android coordinator that alarm is active (activates MediaSession & ScreenOff receiver)
      NativeAlarmService.instance.notifyAlarmStarted(
        reminderId: widget.reminderId,
        title: widget.title,
        prayerName: widget.prayerName,
        soundType: widget.soundType,
        notifId: widget.notifId,
      );

      // Listen to native dismiss events (Volume button, Screen-off, or Notification Action)
      _dismissSubscription = NativeAlarmService.onDismissAlarm.listen((reason) {
        if (mounted && !_isDismissed) {
          _dismissAlarm(reason: reason);
        }
      });

      // Listen to native snooze events
      _snoozeSubscription = NativeAlarmService.onSnoozeAlarm.listen((minutes) {
        if (mounted && !_isDismissed) {
          _snoozeAlarm(minutes, reason: 'NativeSnooze');
        }
      });
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Live clock ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    _initAudioAndVibration();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final storage = ref.read(storageServiceProvider);

      if (key == LogicalKeyboardKey.audioVolumeDown ||
          key == LogicalKeyboardKey.audioVolumeUp ||
          key == LogicalKeyboardKey.audioVolumeMute) {
        final volumeAction = VolumeButtonAction.fromValue(
          storage.getVolumeButtonAction(),
        );
        switch (volumeAction) {
          case VolumeButtonAction.stopAlarm:
            _dismissAlarm(reason: 'VolumeButton');
            return true;
          case VolumeButtonAction.snoozeAlarm:
            _snoozeAlarm(10, reason: 'VolumeButton');
            return true;
          case VolumeButtonAction.doNothing:
            return false;
        }
      } else if (key == LogicalKeyboardKey.power) {
        final screenOffAction = ScreenOffAction.fromValue(
          storage.getScreenOffAction(),
        );
        if (screenOffAction == ScreenOffAction.stopAlarm) {
          _dismissAlarm(reason: 'ScreenOff');
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _initAudioAndVibration() async {
    if (_isDismissed) return;

    final reminders = ref.read(remindersProvider);
    final customReminder = widget.reminderId != null
        ? reminders.where((r) => r.id == widget.reminderId).firstOrNull
        : null;

    final effectiveSoundType =
        widget.soundType ??
        customReminder?.soundType ??
        (widget.prayerName != null
            ? ReminderAudioConfig.defaultSound
            : ReminderAudioConfig.defaultRingtone);

    if (mounted) {
      setState(() {
        _activeSoundName = effectiveSoundType;
      });
    }

    final quietHours = ref.read(quietHoursProvider);
    final quietHoursService = ref.read(quietHoursServiceProvider);
    final isQuietActive = await quietHoursService.isQuietHoursCurrentlyActive(
      quietHours,
    );

    if (_isDismissed) return;
    if (_isEffectivePreview) return;

    final soundEnabled =
        !isQuietActive && (customReminder?.soundEnabled ?? true);
    final vibrationEnabled =
        !isQuietActive && (customReminder?.vibrationEnabled ?? true);
    final durationSeconds = customReminder?.duration.inSeconds ?? 30;

    // Auto-dismiss timer based on user specified reminder duration
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted && !_isDismissed) _dismissAlarm();
    });

    if (soundEnabled && !_isDismissed) {
      final assetPath = ReminderAudioConfig.getAssetPath(effectiveSoundType);
      try {
        final mediaItem = MediaItem(
          id: 'alarm_${widget.reminderId ?? "prayer"}_${effectiveSoundType.replaceAll(" ", "_")}',
          title: widget.title ?? widget.prayerName ?? effectiveSoundType,
          album: 'Adhkar Alarm',
        );
        await _audioPlayer.setAudioSource(
          AudioSource.asset(assetPath, tag: mediaItem),
        );
        if (_isDismissed) {
          await _audioPlayer.stop();
          return;
        }
        await _audioPlayer.setLoopMode(LoopMode.one);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('[AlarmScreen] Audio playback fallback: $e');
      }
    }

    if (vibrationEnabled && !_isDismissed) {
      // Continuous rhythmic haptic vibration
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
        if (_isDismissed) {
          _vibrationTimer?.cancel();
          return;
        }
        HapticFeedback.heavyImpact();
      });
    }
  }

  @override
  void dispose() {
    _isDismissed = true;
    _dismissSubscription?.cancel();
    _snoozeSubscription?.cancel();
    if (!_isEffectivePreview) {
      NativeAlarmService.instance.notifyAlarmStopped();
      NativeAlarmService.instance.cancelNotification(
        reminderId: widget.reminderId,
        prayerName: widget.prayerName,
        notifId: widget.notifId,
      );
    }
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _pulseController.dispose();
    _rotateController.dispose();
    _autoDismissTimer?.cancel();
    _vibrationTimer?.cancel();
    _clockTimer?.cancel();
    try {
      _audioPlayer.stop();
      _audioPlayer.dispose();
    } catch (_) {}
    try {
      AlarmAudioService().stopAlarm();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _dismissAlarm({String reason = 'UserStop'}) async {
    if (_isDismissed) return;
    _isDismissed = true;

    // 1. Immediate tactile and audio silence
    HapticFeedback.mediumImpact();
    _vibrationTimer?.cancel();
    _autoDismissTimer?.cancel();
    _clockTimer?.cancel();
    try {
      _audioPlayer.stop();
    } catch (_) {}
    try {
      AlarmAudioService().stopAlarm();
    } catch (_) {}

    final reminders = ref.read(remindersProvider);
    final customReminder = widget.reminderId != null
        ? reminders.where((r) => r.id == widget.reminderId).firstOrNull
        : null;

    final notifTitle = widget.prayerName != null
        ? '${widget.prayerName} Prayer'
        : (widget.title ?? customReminder?.title ?? 'Adhkar Reminder');

    // Only apply alarm deactivation, native cancellation, and toasts for real alarms (not preview)
    if (!_isEffectivePreview) {
      // 2. If one-time reminder, deactivate it
      if (customReminder != null &&
          customReminder.frequency == ReminderFrequency.once) {
        ref.read(remindersProvider.notifier).toggleEnable(customReminder.id);
      }

      // 3. Cancel active notification and native alarm for reminder or prayer via centralized stop
      try {
        await NativeAlarmService.instance.stopActiveAlarm(reason: reason);
        await NativeAlarmService.instance.cancelNotification(
          reminderId: widget.reminderId,
          prayerName: widget.prayerName,
          notifId: widget.notifId,
        );
        if (widget.reminderId != null) {
          final notifId = widget.reminderId.hashCode.abs() % 100000000;
          await NotificationService().cancel(notifId);
          await NativeAlarmService.instance.cancelAlarm(widget.reminderId!);
          await NativeAlarmService.instance.cancelAlarm(
            '${widget.reminderId!}_snooze',
          );
        }
        if (widget.prayerName != null) {
          final prayerId = widget.prayerName.hashCode.abs() % 100000000;
          await NotificationService().cancel(prayerId);
        }
      } catch (_) {}

      if (mounted) {
        AppFloatingToast.showAdded(
          context,
          message: 'Alarm turned off: $notifTitle',
        );
      }
    }

    if (mounted) {
      final isLocked = await NativeAlarmService.instance.isDeviceLocked();
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (isLocked && !context.canPop()) {
          SystemNavigator.pop();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    }
  }

  Future<void> _snoozeAlarm(int minutes, {String reason = 'UserSnooze'}) async {
    _vibrationTimer?.cancel();
    _autoDismissTimer?.cancel();
    await _audioPlayer.stop();

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final alarmTitle = widget.title ?? widget.prayerName ?? 'Alarm';

    if (!_isEffectivePreview) {
      // Cancel current notification
      try {
        await NativeAlarmService.instance.cancelNotification(
          reminderId: widget.reminderId,
          prayerName: widget.prayerName,
          notifId: widget.notifId,
        );
        if (widget.reminderId != null) {
          final notifId = widget.reminderId.hashCode.abs() % 100000000;
          await NotificationService().cancel(notifId);
        }
        if (widget.prayerName != null) {
          final prayerId = widget.prayerName.hashCode.abs() % 100000000;
          await NotificationService().cancel(prayerId);
        }
      } catch (_) {}

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Schedule snooze natively via AlarmStateManager & AlarmScheduler
        await NativeAlarmService.instance.snoozeActiveAlarm(
          reason: reason,
          minutes: minutes,
        );
        await NativeAlarmService.instance.scheduleAlarm(
          id: '${widget.reminderId ?? "alarm"}_snooze',
          title: 'Snoozed: $alarmTitle',
          body: 'Snoozed alert ringing now',
          scheduledTime: snoozeTime,
          sound: true,
          vibration: true,
          soundType: _activeSoundName,
          prayerName: widget.prayerName,
        );
      } else {
        final snoozeId =
            (DateTime.now().millisecondsSinceEpoch % 900000) + 100000;
        await NotificationService().scheduleCustomReminderNotification(
          id: snoozeId,
          title: 'Snoozed: $alarmTitle',
          body: 'Snoozed alert ringing now',
          scheduledTime: snoozeTime,
          reminderId: widget.reminderId ?? 'snooze_alarm',
          sound: true,
          vibration: true,
          soundType: _activeSoundName,
        );
      }

      if (mounted) {
        AppFloatingToast.showAdded(
          context,
          message: 'Snoozed for $minutes minutes',
        );
      }
      final isLocked = await NativeAlarmService.instance.isDeviceLocked();
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (isLocked && !context.canPop()) {
          SystemNavigator.pop();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    }
  }

  void _showSnoozeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2D24) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Snooze Alarm',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ...[5, 10, 15, 30].map((mins) {
                return ListTile(
                  title: Text(
                    '$mins minutes',
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.snooze_rounded,
                    color: Color(0xFF2A531D),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _snoozeAlarm(mins);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showDuaAfterAzaan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF17261D) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dua After Azaan',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A531D),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF203328)
                      : const Color(0xFFF1F8F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلاَةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ',
                      textDirection: TextDirection.rtl,
                      style: AppTypography.arabicBody(
                        fontSize: 20,
                        height: 2.0,
                        color: isDark ? Colors.white : const Color(0xFF1B3D26),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '"O Allah, Lord of this perfect call and established prayer, grant Muhammad the intercession and favor, and raise him to the praised station which You have promised him."',
                      style: GoogleFonts.lexend(
                        fontSize: 12.5,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF475569),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A531D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForReminder(String title, bool isPrayer) {
    if (isPrayer) return Icons.mosque_rounded;
    final lower = title.toLowerCase();
    if (lower.contains('quran') || lower.contains('surah')) {
      return Icons.menu_book_rounded;
    }
    if (lower.contains('adhkar') ||
        lower.contains('tasbeeh') ||
        lower.contains('dhikr')) {
      return FlutterIslamicIcons.tasbih;
    }
    if (lower.contains('medicine') || lower.contains('pill')) {
      return Icons.medication_rounded;
    }
    if (lower.contains('water') || lower.contains('drink')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('namaz') ||
        lower.contains('salah') ||
        lower.contains('prayer')) {
      return Icons.mosque_rounded;
    }
    return Icons.alarm_on_rounded;
  }

  Widget _buildBackground(
    StorageService storage,
    CustomReminder? customReminder,
  ) {
    final bgType =
        widget.initialBgType ??
        customReminder?.alarmBgType ??
        storage.getAlarmBgType();
    final bgValue =
        widget.initialBgValue ??
        customReminder?.alarmBgValue ??
        storage.getAlarmBgValue();
    final showWaves =
        widget.initialShowWaves ??
        customReminder?.alarmShowWaves ??
        storage.getAlarmShowWaves();

    Widget base;
    if (bgType == 'image') {
      base = Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            bgValue,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0C171F), Color(0xFF192A38)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Subtle scrim overlay to ensure 100% legibility
          Container(color: Colors.black.withValues(alpha: 0.22)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ],
      );
    } else {
      final colors = AlarmBackgroundConfig.getGradientColors(bgValue);
      base = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }

    if (showWaves) {
      return Stack(
        fit: StackFit.expand,
        children: [base, const AmbientWaveBackground()],
      );
    }

    return base;
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final customReminder = widget.reminderId != null
        ? reminders.where((r) => r.id == widget.reminderId).firstOrNull
        : null;

    final storage = ref.watch(storageServiceProvider);
    final isPrayer = widget.prayerName != null;
    final alarmTitle = isPrayer
        ? 'TIME FOR ${widget.prayerName!.toUpperCase()} PRAYER'
        : widget.title ?? customReminder?.title ?? "It's time !";

    final alarmSubtitle = isPrayer
        ? (widget.prayerName!.toLowerCase() == 'fajr'
              ? 'الصلاة خير من النوم • Prayer is better than sleep'
              : 'حي على الصلاة • Come to Success')
        : (customReminder?.description ?? 'Time for your scheduled reminder.');

    final dateStr = DateFormat('EEEE, MMMM d').format(_currentTime);
    final timeStr = DateFormat('h:mm').format(_currentTime);
    final amPmStr = DateFormat('a').format(_currentTime);
    final iconData = _getIconForReminder(alarmTitle, isPrayer);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _dismissAlarm();
        }
      },
      child: Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Configured Background (Wallpapers from alarm-bgs / Gradients / Ambient Waves)
              _buildBackground(storage, customReminder),

              // 2. Alarm UI Content (matching reference image structure)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      // Top header: In preview -> only back button; In real alarm -> Adhkar with logo
                      Align(
                        alignment: Alignment.topLeft,
                        child: _isEffectivePreview
                            ? Material(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    _dismissAlarm(reason: 'PreviewBack');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/logo.png',
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        cacheWidth: 84,
                                        cacheHeight: 84,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(
                                              FlutterIslamicIcons.solidMosque,
                                              color: Color(0xFF2A531D),
                                              size: 16,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Adhkar',
                                    style: GoogleFonts.lexend(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const Spacer(flex: 2),
                      

                      // Date Header: "Saturday, January 21"
                      Text(
                        dateStr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.95),
                          letterSpacing: 0.2,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Large Digital Clock Display: "2:43"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.outfit(
                              fontSize: 76,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 16,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            amPmStr,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Animated Reminder Icon with pulsing glow rings
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.25),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: 0.45 * _glowAnimation.value,
                                ), 
                                width: 1.5, 
                              ),
                            ),
                            child: Center(
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Icon(
                                  iconData,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const Spacer(flex: 6),

                      
                      // Title: "It's time !"
                      Text(
                        alarmTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Description: "Don't forget your pills."
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          alarmSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lexend(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.35,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // STOP Pill Button (Dark capsule button)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _dismissAlarm,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 160,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF222226,
                              ).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'STOP',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Snooze Pill Button (White capsule button)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showSnoozeOptions,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 105,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Snooze',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lexend(
                                color: const Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Optional Dua After Azaan button for prayer alarms
                      if (isPrayer) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _showDuaAfterAzaan,
                          icon: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          label: Text(
                            'Read Dua After Azaan',
                            style: GoogleFonts.lexend(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
