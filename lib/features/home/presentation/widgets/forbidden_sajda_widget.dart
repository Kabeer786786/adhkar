import 'package:adhkar/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/prayer_calculation_service.dart';
import '../../../../core/services/storage_service.dart';

/// The 3 specific Makrooh / Tahrim times when Sajda is forbidden:
/// 1. Sunrise (Tulu): Exactly at sunrise and for 20 minutes after (Red).
/// 2. Zawal (Zenith): 15 minutes before Dhuhr starts (Yellow).
/// 3. Ghurub (Sunset): 10 minutes before Maghrib starts (Yellow), with exception for unperformed Asr.
enum ForbiddenSajdaType { sunrise, zawal, ghurub }

/// Data model holding timing, messaging, and visual styling for the forbidden Sajda period.
class ForbiddenSajdaInfo {
  final ForbiddenSajdaType type;
  final String title;
  final String arabicTitle;
  final String pillText;
  final String shortReason;
  final String fullMessage;
  final String hadithReference;
  final DateTime startTime;
  final DateTime endTime;
  final Color primaryColor;
  final Color lightBgColor;
  final Color darkBgColor;
  final Color lightBorderColor;
  final Color darkBorderColor;
  final Color lightTextColor;
  final Color darkTextColor;
  final Color toastBgColor;
  final Color toastBorderColor;
  final bool isAsrExceptionApplicable;
  final bool hasPrayedAsr;

  const ForbiddenSajdaInfo({
    required this.type,
    required this.title,
    required this.arabicTitle,
    required this.pillText,
    required this.shortReason,
    required this.fullMessage,
    required this.hadithReference,
    required this.startTime,
    required this.endTime,
    required this.primaryColor,
    required this.lightBgColor,
    required this.darkBgColor,
    required this.lightBorderColor,
    required this.darkBorderColor,
    required this.lightTextColor,
    required this.darkTextColor,
    required this.toastBgColor,
    required this.toastBorderColor,
    this.isAsrExceptionApplicable = false,
    this.hasPrayedAsr = false,
  });

  int get windowDurationMinutes => endTime.difference(startTime).inMinutes;

  String get shortName {
    switch (type) {
      case ForbiddenSajdaType.sunrise:
        return 'Tulu';
      case ForbiddenSajdaType.zawal:
        return 'Zawal';
      case ForbiddenSajdaType.ghurub:
        return 'Ghurub';
    }
  }

  String get conciseSubtitle {
    switch (type) {
      case ForbiddenSajdaType.sunrise:
        return 'During Sunrise ($windowDurationMinutes mins)';
      case ForbiddenSajdaType.zawal:
        return 'Midday Zenith ($windowDurationMinutes mins)';
      case ForbiddenSajdaType.ghurub:
        return 'During Sunset ($windowDurationMinutes mins)';
    }
  }

  String get formattedTimeRange {
    final startStr = DateFormat('hh:mm a').format(startTime);
    final endStr = DateFormat('hh:mm a').format(endTime);
    return '$startStr – $endStr';
  }
}

/// Service that computes whether the current time falls inside one of the three forbidden Sajda windows.
class ForbiddenSajdaService {
  /// When enabled, cycles through all 3 forbidden toasts for 20 seconds each for testing/demo.
  static bool isTestMode = false;

  static ForbiddenSajdaInfo buildSunriseInfo(DateTime start, DateTime end) {
    return ForbiddenSajdaInfo(
      type: ForbiddenSajdaType.sunrise,
      title: 'Sunrise Prohibited Window (Tulu)',
      arabicTitle: 'طُلُوعُ الشَّمْسِ',
      pillText: 'Sajda Prohibited',
      shortReason: 'Prohibited for 20 minutes after sunrise',
      fullMessage:
          'Prostration and prayer are strictly prohibited from sunrise for 20 minutes until the sun has risen high above the horizon.',
      hadithReference:
          'The Prophet ﷺ said: "When the edge of the sun has risen, delay prayer until it has risen high..." (Sahih al-Bukhari 582, Sahih Muslim 831).',
      startTime: start,
      endTime: end,
      primaryColor: const Color(0xFFDC2626),
      lightBgColor: const Color(0xFFFEF2F2),
      darkBgColor: const Color(0xFF2A1414),
      lightBorderColor: const Color(0xFFFCA5A5),
      darkBorderColor: const Color(0xFF7F1D1D),
      lightTextColor: const Color(0xFFB91C1C),
      darkTextColor: const Color(0xFFFCA5A5),
      toastBgColor: const Color(0xFF991B1B),
      toastBorderColor: const Color(0xFF7F1D1D),
    );
  }

  static ForbiddenSajdaInfo buildZawalInfo(DateTime start, DateTime end) {
    return ForbiddenSajdaInfo(
      type: ForbiddenSajdaType.zawal,
      title: 'Zawal Prohibited Window (Zenith)',
      arabicTitle: 'اسْتِوَاءُ الشَّمْسِ (الزَّوَال)',
      pillText: 'Sajda Prohibited',
      shortReason: 'Prohibited for 15 minutes before Dhuhr',
      fullMessage:
          'Prostration and prayer are prohibited for 15 minutes before Dhuhr while the sun is at its midday zenith.',
      hadithReference:
          'The Messenger of Allah ﷺ forbade prayer "when the sun is at its height at midday until it has crossed the meridian." (Sahih Muslim 831).',
      startTime: start,
      endTime: end,
      primaryColor: const Color(0xFFD97706),
      lightBgColor: const Color(0xFFFFFBEB),
      darkBgColor: const Color(0xFF2B1D0E),
      lightBorderColor: const Color(0xFFFCD34D),
      darkBorderColor: const Color(0xFF78350F),
      lightTextColor: const Color(0xFF92400E),
      darkTextColor: const Color(0xFFFDE68A),
      toastBgColor: const Color(0xFFB45309),
      toastBorderColor: const Color(0xFF78350F),
    );
  }

  static ForbiddenSajdaInfo buildGhurubInfo(
    DateTime start,
    DateTime end, {
    required bool hasPrayedAsr,
  }) {
    return ForbiddenSajdaInfo(
      type: ForbiddenSajdaType.ghurub,
      title: 'Pre-Maghrib Prohibited Window (Ghurub)',
      arabicTitle: 'غُرُوبُ الشَّمْسِ',
      pillText: 'Sajda Prohibited (Asr Exception)',
      shortReason: 'Prohibited 10 minutes before Maghrib',
      fullMessage:
          'Prostration and voluntary prayers are prohibited during the 10 minutes before Maghrib as the sun sets.',
      hadithReference:
          'The Messenger of Allah ﷺ said: "Whoever catches one rak\'ah of the Asr prayer before the sun sets has caught Asr." (Sahih al-Bukhari 579, Sahih Muslim 608).',
      startTime: start,
      endTime: end,
      primaryColor: const Color(0xFFD97706),
      lightBgColor: const Color(0xFFFFFBEB),
      darkBgColor: const Color(0xFF2B1D0E),
      lightBorderColor: const Color(0xFFFCD34D),
      darkBorderColor: const Color(0xFF78350F),
      lightTextColor: const Color(0xFF92400E),
      darkTextColor: const Color(0xFFFDE68A),
      toastBgColor: const Color(0xFFB45309),
      toastBorderColor: const Color(0xFF78350F),
      isAsrExceptionApplicable: true,
      hasPrayedAsr: hasPrayedAsr,
    );
  }

  static ForbiddenSajdaInfo getSunriseInfo(PrayerTimeResult prayerTimes) {
    final start = prayerTimes.sunrise;
    final end = start.add(const Duration(minutes: 20));
    return buildSunriseInfo(start, end);
  }

  static ForbiddenSajdaInfo getZawalInfo(PrayerTimeResult prayerTimes) {
    final end = prayerTimes.dhuhr;
    final start = end.subtract(const Duration(minutes: 15));
    return buildZawalInfo(start, end);
  }

  static ForbiddenSajdaInfo getGhurubInfo(
    PrayerTimeResult prayerTimes,
    StorageService storage, {
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(d);
    final asrRecords = storage.getSubPrayerRecords(dateKey, 'Asr');
    final hasPrayedAsr = asrRecords.contains('asr_farz');
    final end = prayerTimes.maghrib;
    final start = end.subtract(const Duration(minutes: 10));
    return buildGhurubInfo(start, end, hasPrayedAsr: hasPrayedAsr);
  }

  static ForbiddenSajdaInfo? getNextForbiddenWindow({
    required PrayerTimeResult prayerTimes,
    required DateTime now,
    required StorageService storage,
  }) {
    final sunrise = getSunriseInfo(prayerTimes);
    if (now.isBefore(sunrise.startTime)) return sunrise;

    final zawal = getZawalInfo(prayerTimes);
    if (now.isBefore(zawal.startTime)) return zawal;

    final ghurub = getGhurubInfo(prayerTimes, storage, date: now);
    if (now.isBefore(ghurub.startTime)) return ghurub;

    return null;
  }

  static ForbiddenSajdaInfo? getForbiddenSajdaInfo({
    required PrayerTimeResult? prayerTimes,
    required DateTime now,
    required StorageService storage,
    bool? overrideTestMode,
  }) {
    final useTestMode = overrideTestMode ?? isTestMode;
    if (useTestMode) {
      final cycle = (now.second ~/ 20) % 3;
      if (cycle == 0) {
        final start =
            prayerTimes?.sunrise ?? now.subtract(const Duration(minutes: 5));
        final end = start.add(const Duration(minutes: 20));
        return buildSunriseInfo(start, end);
      } else if (cycle == 1) {
        final end = prayerTimes?.dhuhr ?? now.add(const Duration(minutes: 10));
        final start = end.subtract(const Duration(minutes: 15));
        return buildZawalInfo(start, end);
      } else {
        final dateKey = DateFormat('yyyy-MM-dd').format(now);
        final asrRecords = storage.getSubPrayerRecords(dateKey, 'Asr');
        final hasPrayedAsr = asrRecords.contains('asr_farz');
        final end = prayerTimes?.maghrib ?? now.add(const Duration(minutes: 7));
        final start = end.subtract(const Duration(minutes: 10));
        return buildGhurubInfo(start, end, hasPrayedAsr: hasPrayedAsr);
      }
    }

    if (prayerTimes == null) return null;

    bool isInWindow(DateTime start, DateTime end) {
      return !now.isBefore(start) && now.isBefore(end);
    }

    // 1. After sunrise 20 mins
    final sunriseStart = prayerTimes.sunrise;
    final sunriseEnd = sunriseStart.add(const Duration(minutes: 20));
    if (isInWindow(sunriseStart, sunriseEnd)) {
      return buildSunriseInfo(sunriseStart, sunriseEnd);
    }

    // 2. Before Dhuhr 15 mins
    final zawalStart = prayerTimes.dhuhr.subtract(const Duration(minutes: 15));
    final zawalEnd = prayerTimes.dhuhr;
    if (isInWindow(zawalStart, zawalEnd)) {
      return buildZawalInfo(zawalStart, zawalEnd);
    }

    // 3. Before Maghrib 10 mins
    final ghurubStart = prayerTimes.maghrib.subtract(
      const Duration(minutes: 10),
    );
    final ghurubEnd = prayerTimes.maghrib;
    if (isInWindow(ghurubStart, ghurubEnd)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(now);
      final asrRecords = storage.getSubPrayerRecords(dateKey, 'Asr');
      final hasPrayedAsr = asrRecords.contains('asr_farz');
      return buildGhurubInfo(
        ghurubStart,
        ghurubEnd,
        hasPrayedAsr: hasPrayedAsr,
      );
    }

    return null;
  }
}

/// Sajda icon using `FlutterIslamicIcons.solidPrayingPerson` with a clean
/// strike-off line overlaid across it.
class ForbiddenSajdaIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ForbiddenSajdaIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Islamic Sujood Icon
          Icon(FlutterIslamicIcons.solidKowtow, size: size, color: color),
          // Precision strike-off line across the figure
          CustomPaint(
            size: Size(size, size),
            painter: _SajdaStrikePainter(
              color: color,
              strokeWidth: (size * 0.07).clamp(1.6, 2.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SajdaStrikePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _SajdaStrikePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Diagonal strike-off across the prostrating figure
    canvas.drawLine(
      Offset(size.width * 0.84, size.height * 0.16),
      Offset(size.width * 0.16, size.height * 0.84),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SajdaStrikePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Swipable bottom toast positioned at the bottom of the screen touching the tab bar,
/// top-rounded, no box-shadow, with concise text "Sajda Forbidden".
class ForbiddenSajdaBottomToast extends StatelessWidget {
  final ForbiddenSajdaInfo info;
  final VoidCallback onTap;

  const ForbiddenSajdaBottomToast({
    super.key,
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dark red for red period (Sunrise) and dark yellow/amber for yellow periods (Zawal, Ghurub)
    // in both light & dark themes for strong highlighting
    final bgColor = info.toastBgColor;
    final borderColor = info.toastBorderColor;
    const textColor = Colors.white;
    final subTextColor = Colors.white.withValues(alpha: 0.90);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -80) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: borderColor, width: 1.2),
                left: BorderSide(color: borderColor, width: 1.2),
                right: BorderSide(color: borderColor, width: 1.2),
              ),
              // NO box shadow as requested
              boxShadow: null,
            ),
            child: Row(
              children: [
                // Struck-off Islamic Sajda Icon in pure white
                const ForbiddenSajdaIcon(size: 28, color: Colors.white),
                const SizedBox(width: 12),

                // Concise Name & Start/End Times
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${info.shortName} - ${info.conciseSubtitle}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Start: ${DateFormat('hh:mm a').format(info.startTime)}  •  End: ${DateFormat('hh:mm a').format(info.endTime)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: subTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Drag / Open indicator in pure white
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detailed bottom sheet modal attached flush to the bottom (matching registration modal),
/// with top rounded corners, no box shadow, no emojis, concise content, and no overflow.
class ForbiddenSajdaDetailModal extends StatelessWidget {
  final ForbiddenSajdaInfo info;

  const ForbiddenSajdaDetailModal({super.key, required this.info});

  static Future<void> show({
    required BuildContext context,
    required ForbiddenSajdaInfo info,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ForbiddenSajdaDetailModal(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final surfaceBg = isDark
        ? const Color(0xFF142018)
        : info.lightBgColor.withValues(alpha: 0.5);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return Container(
      // Attached directly to bottom matching registration modal
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),

        // NO box shadow
        boxShadow: null,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Icon + Title Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: info.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: info.primaryColor.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: ForbiddenSajdaIcon(
                        size: 28,
                        color: info.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.arabicTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: info.primaryColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Time Window Card (Responsive with zero overflow)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: surfaceBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: info.primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: info.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info.formattedTimeRange,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: info.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${info.windowDurationMinutes} min',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: info.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Concise Explanation Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131D16)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF27382B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  info.fullMessage,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // 5. Pre-Maghrib Asr Exception Card (Small, clean text without button)
              if (info.isAsrExceptionApplicable) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (info.hasPrayedAsr
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706))
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          (info.hasPrayedAsr
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706))
                              .withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        info.hasPrayedAsr
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: info.hasPrayedAsr
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info.hasPrayedAsr
                              ? "Today's Asr is completed. Prostration is forbidden until Maghrib."
                              : "Exception: If you haven't prayed today's Asr yet, you may pray it before Maghrib.",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: info.hasPrayedAsr
                                ? (isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF15803D))
                                : (isDark
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFFB45309)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // 6. Hadith Citation
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: info.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      info.hadithReference,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: subTextColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 7. Close Button
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: info.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

/// A clean box placed between prayers in the prayer timetable
/// showing the prohibited window with its theme color (Red for Sunrise, Yellow/Amber for Zawal & Ghurub)
/// and tapping opens [ForbiddenSajdaDetailModal].
class ForbiddenTimeCard extends StatelessWidget {
  final ForbiddenSajdaInfo info;
  final bool isCurrent;
  final VoidCallback? onTap;

  const ForbiddenTimeCard({
    super.key,
    required this.info,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? info.darkBgColor : info.lightBgColor;
    final borderColor = isCurrent
        ? info.primaryColor
        : (isDark ? info.darkBorderColor : info.lightBorderColor);
    final textColor = isDark ? info.darkTextColor : info.lightTextColor;

    final startTimeStr = DateFormat('hh:mm a').format(info.startTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (onTap != null) {
              onTap!();
            } else {
              ForbiddenSajdaDetailModal.show(context: context, info: info);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 24,
              top: 14,
              bottom: 14,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: isCurrent
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: info.primaryColor.withValues(alpha: 0.1), 
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                // Icon
                ForbiddenSajdaIcon(size: 26, color: info.primaryColor),
                const SizedBox(width: 16),

                // 2-Line Content: Line 1 = Name (Duration), Line 2 = Concise Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        info.shortName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        info.conciseSubtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Right Side Start Time (same as other prayer timings)
                Text(
                  startTimeStr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prominent, elegant box displayed on the Home Screen below the time digits
/// when a prohibited prayer window is currently active.
/// Displays name, start time, end time, and live remaining countdown.
/// On click, it opens the [ForbiddenSajdaDetailModal] showing why.
class ForbiddenHomeBanner extends StatelessWidget {
  final ForbiddenSajdaInfo info;
  final DateTime now;
  final VoidCallback? onTap;

  const ForbiddenHomeBanner({
    super.key,
    required this.info,
    required this.now,
    this.onTap,
  });

  String _formatDuration(Duration d) {
    if (d.isNegative) return '0:00:00';
    final hours = d.inHours.toString();
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('hh:mm a').format(info.startTime);
    final endStr = DateFormat('hh:mm a').format(info.endTime);
    final remainingDiff = info.endTime.difference(now);
    final remainingStr = _formatDuration(remainingDiff);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            ForbiddenSajdaDetailModal.show(context: context, info: info);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: info.lightBgColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: info.lightBorderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: info.primaryColor.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Icon + Name + Prohibited Tag
              Row(
                children: [
                  ForbiddenSajdaIcon(size: 22, color: info.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: info.lightTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: info.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PROHIBITED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Start and End Timings Row
              Row(
                children: [
                  // Start Time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Start: $startStr',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // End Time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: info.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'End: $endStr',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: info.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Remaining Time and Click Action Row
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: info.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Remaining: $remainingStr',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: info.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to see why ➔',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: info.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
