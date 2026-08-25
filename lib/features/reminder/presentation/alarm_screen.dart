import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/config/reminder_audio_config.dart';
import '../../../core/services/notification_service.dart';
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
  late AnimationController _rotateController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoDismissTimer;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _initAudioAndVibration();

    // Auto dismiss after 5 minutes max to save battery
    _autoDismissTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) _dismissAlarm();
    });
  }

  Future<void> _initAudioAndVibration() async {
    final effectiveSoundType = widget.soundType ?? ReminderAudioConfig.defaultSound;
    final assetPath = ReminderAudioConfig.getAssetPath(effectiveSoundType);

    try {
      if (assetPath != null) {
        await _audioPlayer.setAsset(assetPath);
      } else {
        final fallbackUrl = PrayerNotificationConfig.soundAudioUrls[effectiveSoundType];
        if (fallbackUrl != null) {
          await _audioPlayer.setUrl(fallbackUrl);
        } else {
          await _audioPlayer.setAsset('assets/audios/madina_azaan.mp3');
        }
      }
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(1.0); 
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing alarm audio: $e');
    }

    // Trigger haptic vibration every 2 seconds
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      HapticFeedback.vibrate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _autoDismissTimer?.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _dismissAlarm() {
    _vibrationTimer?.cancel();
    _audioPlayer.stop();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _snoozeAlarm(int minutes) async {
    _vibrationTimer?.cancel();
    await _audioPlayer.stop();

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozeId = (DateTime.now().millisecondsSinceEpoch % 900000) + 100000;

    final alarmTitle = widget.title ?? widget.prayerName ?? 'Alarm';

    await NotificationService().scheduleCustomReminderNotification(
      id: snoozeId,
      title: 'Snoozed: $alarmTitle',
      body: 'Snoozed alert ringing now',
      scheduledTime: snoozeTime,
      reminderId: widget.reminderId ?? 'snooze_alarm',
      sound: true,
      vibration: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Snoozed for $minutes minutes',
            style: GoogleFonts.lexend(),
          ),
          backgroundColor: const Color(0xFF2A531D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _dismissAlarm();
    }
  }

  void _showSnoozeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
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
              Text(
                'Snooze Alarm',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                  color: isDark ? const Color(0xFF203328) : const Color(0xFFF1F8F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A531D).withValues(alpha: 0.2)),
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
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
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

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final customReminder = widget.reminderId != null
        ? reminders.firstWhere(
            (r) => r.id == widget.reminderId,
            orElse: () => CustomReminder(
              id: 'default',
              title: widget.title ?? 'Adhkar Alarm',
              description: 'Time for your scheduled Islamic prayer & adhkar.',
              hour: DateTime.now().hour,
              minute: DateTime.now().minute,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              timezone: DateTime.now().timeZoneName,
            ),
          )
        : null;

    final alarmTitle = widget.prayerName != null
        ? 'TIME FOR ${widget.prayerName!.toUpperCase()} PRAYER'
        : widget.title ?? customReminder?.title ?? 'PRAYER ALARM';

    final alarmSubtitle = widget.prayerName?.toLowerCase() == 'fajr'
        ? 'الصلاة خير من النوم'
        : 'حي على الصلاة';

    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF081910),
                Color(0xFF102A1C),
                Color(0xFF1E4627),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Top Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PRAYER ALARM ACTIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4ADE80),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Animated Dome & Pulsing Bell Icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: RotationTransition(
                      turns: Tween(begin: -0.01, end: 0.01).animate(_pulseController),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2A531D).withValues(alpha: 0.35),
                          border: Border.all(
                            color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.mosque_rounded,
                            size: 68,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Digital Clock Display
                  Text(
                    timeStr,
                    style: GoogleFonts.oxanium(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Arabic Calligraphy Subtitle
                  Text(
                    alarmSubtitle,
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF86EFAC),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Alarm Title
                  Text(
                    alarmTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Time to perform Salah and connect with Allah SWT.',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Dua After Azaan Quick Button
                  TextButton.icon(
                    onPressed: _showDuaAfterAzaan,
                    icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF86EFAC), size: 18),
                    label: Text(
                      'Read Dua After Azaan',
                      style: GoogleFonts.lexend(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF86EFAC),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons: Snooze & Dismiss
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showSnoozeOptions,
                          icon: const Icon(Icons.snooze_rounded, size: 20),
                          label: const Text('Snooze'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54, width: 1.5),
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
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _dismissAlarm,
                          icon: const Icon(Icons.notifications_off_rounded, size: 20),
                          label: const Text('Dismiss Alarm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF102A1C),
                            elevation: 6,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
