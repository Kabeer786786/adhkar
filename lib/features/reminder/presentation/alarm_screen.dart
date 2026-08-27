import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../core/config/reminder_audio_config.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../prayer/domain/prayer_models.dart';
import '../domain/reminder_model.dart';
import 'providers/reminder_provider.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  final String? reminderId;
  final String? prayerName;
  final String? title;
  final String? soundType;

  const AlarmScreen({
    super.key,
    this.reminderId,
    this.prayerName,
    this.title,
    this.soundType,
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

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Live clock ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    _initAudioAndVibration();
  } 

  Future<void> _initAudioAndVibration() async {
    final reminders = ref.read(remindersProvider);
    final customReminder = widget.reminderId != null
        ? reminders.where((r) => r.id == widget.reminderId).firstOrNull
        : null;

    final effectiveSoundType = widget.soundType ??
        customReminder?.soundType ??
        (widget.prayerName != null
            ? ReminderAudioConfig.defaultSound
            : ReminderAudioConfig.defaultRingtone);

    setState(() {
      _activeSoundName = effectiveSoundType;
    });

    final soundEnabled = customReminder?.soundEnabled ?? true;
    final vibrationEnabled = customReminder?.vibrationEnabled ?? true;
    final durationSeconds = customReminder?.duration.inSeconds ?? 30;

    // Iteratively loop audio for user specified period of time, then auto-dismiss
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted) _dismissAlarm();
    });

    if (soundEnabled) {
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
        await _audioPlayer.setLoopMode(LoopMode.one);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('[AlarmScreen] Asset error: $e. Trying fallback URL...');
        try {
          final fallbackUrl =
              PrayerNotificationConfig.soundAudioUrls[effectiveSoundType];
          if (fallbackUrl != null) {
            final mediaItem = MediaItem(
              id: 'alarm_fallback_${widget.reminderId ?? "prayer"}',
              title: widget.title ?? widget.prayerName ?? effectiveSoundType,
              album: 'Adhkar Alarm',
            );
            await _audioPlayer.setAudioSource(
              AudioSource.uri(Uri.parse(fallbackUrl), tag: mediaItem),
            );
            await _audioPlayer.setLoopMode(LoopMode.one);
            await _audioPlayer.play();
          }
        } catch (err) {
          debugPrint('[AlarmScreen] Fallback audio failed: $err');
        }
      }
    }

    if (vibrationEnabled) {
      // Continuous rhythmic haptic vibration
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
        HapticFeedback.heavyImpact();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _autoDismissTimer?.cancel();
    _vibrationTimer?.cancel();
    _clockTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _dismissAlarm() async {
    _vibrationTimer?.cancel();
    _autoDismissTimer?.cancel();
    _clockTimer?.cancel();
    await _audioPlayer.stop();

    final reminders = ref.read(remindersProvider);
    final customReminder = widget.reminderId != null
        ? reminders.where((r) => r.id == widget.reminderId).firstOrNull
        : null;

    final notifTitle = widget.prayerName != null
        ? '${widget.prayerName} Prayer'
        : (widget.title ?? customReminder?.title ?? 'Adhkar Reminder');

    // 1. If one-time reminder, deactivate it
    if (customReminder != null &&
        customReminder.frequency == ReminderFrequency.once) {
      ref.read(remindersProvider.notifier).toggleEnable(customReminder.id);
    }

    // 2. Cancel active notification and post dismissed notification
    if (widget.reminderId != null) {
      final notifId = widget.reminderId.hashCode.abs() % 100000000;
      await NotificationService().cancel(notifId);
      await NotificationService().showDismissedNotification(
        id: notifId,
        title: '$notifTitle - Alarm Turned Off',
        body: 'Your scheduled reminder has been turned off and dismissed.',
      );
    }

    if (mounted) {
      AppFloatingToast.showAdded(
        context,
        message: 'Alarm turned off: $notifTitle',
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _snoozeAlarm(int minutes) async {
    _vibrationTimer?.cancel();
    _autoDismissTimer?.cancel();
    await _audioPlayer.stop();

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozeId =
        (DateTime.now().millisecondsSinceEpoch % 900000) + 100000;

    final alarmTitle = widget.title ?? widget.prayerName ?? 'Alarm';

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

    if (mounted) {
      AppFloatingToast.showAdded(
        context,
        message: 'Snoozed for $minutes minutes',
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
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
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                        color:
                            isDark ? Colors.white70 : const Color(0xFF475569),
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
    if (lower.contains('namaz') || lower.contains('salah')) {
      return Icons.mosque_rounded;
    }
    return Icons.alarm_on_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final customReminder = widget.reminderId != null
        ? reminders.where((r) => r.id == widget.reminderId).firstOrNull
        : null;

    final isPrayer = widget.prayerName != null;
    final alarmTitle = isPrayer
        ? 'TIME FOR ${widget.prayerName!.toUpperCase()} PRAYER'
        : widget.title ?? customReminder?.title ?? 'SCHEDULED REMINDER';

    final alarmSubtitle = isPrayer
        ? (widget.prayerName!.toLowerCase() == 'fajr'
            ? 'الصلاة خير من النوم'
            : 'حي على الصلاة • Come to Success')
        : (customReminder?.description ??
            'Time for your scheduled reminder & adhkar.');

    final timeStr = DateFormat('hh:mm a').format(_currentTime);
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_currentTime);
    final iconData = _getIconForReminder(alarmTitle, isPrayer);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF06140D),
                Color(0xFF0C2417),
                Color(0xFF163E26),
                Color(0xFF1F5234),
              ],
              stops: [0.0, 0.35, 0.75, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Spacer(flex: 1),

                  // Animated Concentric Pulsing Center Avatar
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E492B).withValues(alpha: 0.4),
                            border: Border.all(
                              color: const Color(0xFF4ADE80)
                                  .withValues(alpha: _glowAnimation.value),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.35 * _glowAnimation.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Digital Clock Display
                  Text(
                    timeStr,
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Date String
                  Text(
                    dateStr,
                    style: GoogleFonts.lexend(
                      fontSize: 13.5,
                      color: const Color(0xFF86EFAC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Title Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          alarmTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alarmSubtitle,
                          style: GoogleFonts.lexend(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Dua After Azaan Quick Button (For Prayer)
                  if (isPrayer) ...[
                    TextButton.icon(
                      onPressed: _showDuaAfterAzaan,
                      icon: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF86EFAC),
                        size: 18,
                      ),
                      label: Text(
                        'Read Dua After Azaan',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF86EFAC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Action Buttons: Snooze & Dismiss
                  Row(
                    children: [
                      // Snooze Button
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: _showSnoozeOptions,
                          icon: const Icon(Icons.snooze_rounded, size: 20),
                          label: const Text('Snooze'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: GoogleFonts.lexend(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Dismiss Alarm Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _dismissAlarm,
                          icon: const Icon(
                            Icons.alarm_off_rounded,
                            size: 22,
                            color: Color(0xFF0C2417),
                          ),
                          label: const Text('Turn Off & Dismiss'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0C2417),
                            elevation: 8,
                            shadowColor: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: GoogleFonts.lexend(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
