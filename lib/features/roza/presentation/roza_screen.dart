import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_calculation_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/fasting_helper.dart';
import '../../../core/utils/hijri_date_helper.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../widgets/app_header_bar.dart';

import '../../../shared/widgets/feature_intro_modal.dart';

class RozaScreen extends ConsumerStatefulWidget {
  const RozaScreen({super.key});

  @override
  ConsumerState<RozaScreen> createState() => _RozaScreenState();
}

class _RozaScreenState extends ConsumerState<RozaScreen> {
  Timer? _timer;
  bool _isSehriExpanded = false;
  bool _isIftarExpanded = false;
  int? _expandedOccasionIndex;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureIntroModal.show(context, FeatureIntroType.roza);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getRemainingTimeText(PrayerTimeResult? prayerTimes) {
    if (prayerTimes == null) return '--:--';

    final now = DateTime.now();
    final fajr = prayerTimes.fajr;
    final maghrib = prayerTimes.maghrib;

    if (now.isBefore(fajr)) {
      final diff = fajr.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      return 'Sehri Ends in ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else if (now.isBefore(maghrib)) {
      final diff = maghrib.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      return 'Iftar in ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      final tomorrowFajr = fajr.add(const Duration(days: 1));
      final diff = tomorrowFajr.difference(now);
      if (diff.isNegative) {
        return 'Fasting Completed for Today';
      }
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      return 'Next Sehri in ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
  }

  void _openDayDetailModal(
    BuildContext context, {
    required DateTime date,
    required HijriDate hijriDate,
    required String hijriStr,
    required String sehriTime,
    required String iftarTime,
    required String durationStr,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = context.isDarkMode;
        final fastingInfo = FastingHelper.getFastingInfo(date, hijriDate);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF192520) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF2A531D),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
                      Text(
                        hijriStr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3FAF2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF2A531D,
                          ).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                CupertinoIcons.sunrise_fill,
                                size: 18,
                                color: Color(0xFFD97724),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Sehri Ends',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8C6D53),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sehriTime,
                            style: GoogleFonts.oxanium(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2A531D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3FAF2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF2A531D,
                          ).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                CupertinoIcons.sunset_fill,
                                size: 18,
                                color: Color(0xFFEA580C),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Iftar Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8C6D53),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            iftarTime,
                            style: GoogleFonts.oxanium(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2A531D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Color(0xFFB45309),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Total Fasting Duration:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      durationStr,
                      style: GoogleFonts.oxanium(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),

              // Fasting Significance Box for Special Days (Ramadan, Zul Hijjah 10 Days, Ashura, Ayyam al-Beed, etc.)
              if (fastingInfo != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? fastingInfo.primaryColor.withValues(alpha: 0.15)
                        : fastingInfo.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: fastingInfo.primaryColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            fastingInfo.icon,
                            color: fastingInfo.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fastingInfo.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: fastingInfo.primaryColor,
                                  ),
                                ),
                                Text(
                                  fastingInfo.subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: fastingInfo.primaryColor.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (fastingInfo.arabicHadith != null) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            fastingInfo.arabicHadith!,
                            textDirection: TextDirection.rtl,
                            style: AppTypography.arabicBody(
                              fontSize: 18,
                              height: 2,
                              color: fastingInfo.primaryColor,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        fastingInfo.description,
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fastingInfo.hadith,
                        style: GoogleFonts.lexend(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? const Color(0xFFFDE68A)
                              : fastingInfo.primaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openCalendarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RozaCalendarModalContent(
          onDateSelected: (date, hijri) {
            final location =
                ref.read(currentLocationProvider).value ??
                LocationService.defaultLocation;
            final method = ref.read(calculationMethodProvider);
            final juristic = ref.read(asrJuristicProvider);

            final calcResult = PrayerCalculationService.calculate(
              date: date,
              latitude: location.latitude,
              longitude: location.longitude,
              methodName: method,
              juristicAsr: juristic,
            );
            final sehri = DateFormat('hh:mm a').format(calcResult.fajr);
            final iftar = DateFormat('hh:mm a').format(calcResult.maghrib);
            final diff = calcResult.maghrib.difference(calcResult.fajr);
            final durStr = '${diff.inHours}h ${diff.inMinutes % 60}m';
            final hijriFormatted = '${hijri.day} ${hijri.monthName}';
            _openDayDetailModal(
              context,
              date: date,
              hijriDate: hijri,
              hijriStr: hijriFormatted,
              sehriTime: sehri,
              iftarTime: iftar,
              durationStr: durStr,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimes = ref.watch(prayerTimesProvider);
    final storage = ref.watch(storageServiceProvider);
    final now = DateTime.now();

    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final rawHijri =
        storage.getCachedHijriDate(todayKey) ??
        HijriDateHelper.formatHijri(now);
    final hijriStr = rawHijri
        .replaceAll(RegExp(r'\s*AH$', caseSensitive: false), '')
        .trim();
    final todayHijri = HijriDateHelper.convertToHijri(now);
    final todayFastingInfo = FastingHelper.getFastingInfo(now, todayHijri);

    final sehriTimeStr = prayerTimes != null
        ? DateFormat('hh:mm a').format(prayerTimes.fajr)
        : '--:--';
    final iftarTimeStr = prayerTimes != null
        ? DateFormat('hh:mm a').format(prayerTimes.maghrib)
        : '--:--';

    // Calculate Fasting Progress
    double progress = 0.0;
    if (prayerTimes != null) {
      final fajr = prayerTimes.fajr;
      final maghrib = prayerTimes.maghrib;
      if (now.isAfter(fajr) && now.isBefore(maghrib)) {
        final totalMs =
            maghrib.millisecondsSinceEpoch - fajr.millisecondsSinceEpoch;
        final elapsedMs =
            now.millisecondsSinceEpoch - fajr.millisecondsSinceEpoch;
        progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
      } else if (now.isAfter(maghrib)) {
        progress = 1.0;
      }
    }

    final clockDigits = DateFormat('hh:mm').format(now);
    final clockAmPm = DateFormat('a').format(now);
    final remainingTimeStr = _getRemainingTimeText(prayerTimes);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF173a24), // Deep forest green
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'Roza (Fasting)',
            titleWidget: const Text(
              'Roza (Fasting)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            showBackButton: true,
            iconColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Roza Calendar',
                onPressed: () => _openCalendarModal(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Upper Half Container (Forest Green Progress Gauge & Timings)
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 5,
                ),
                child: Column(
                  children: [
                    // Semi-Arc Circular Gauge
                    SizedBox(
                      width: double.infinity,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Arc Painter (concentric, 20px gap above dome)
                          CustomPaint(
                            size: const Size(320, 160),
                            painter: _RozaArcPainter(progress: progress),
                          ),

                          // Center Dome Container
                          Positioned(
                            top: 20,
                            child: Container(
                              width: 250,
                              height: 135,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5E9C75,
                                ).withValues(alpha: 0.99),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(300),
                                  bottom: Radius.circular(30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 28),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        clockDigits,
                                        style: GoogleFonts.oxanium(
                                          fontSize: 45,
                                          height: 1,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        clockAmPm,
                                        style: GoogleFonts.oxanium(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFACC15),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Date & Hijri Pill inside center dome
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        hijriStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // Remaining Time in place of Location
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 13,
                                          color: Color(0xFFFACC15),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          remainingTimeStr,
                                          style: GoogleFonts.oxanium(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color.fromARGB(
                                              255,
                                              255,
                                              243,
                                              204,
                                            ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Bottom Timings Row (Sehri Ends Fajr & Iftar Maghrib)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sehri Ends Item
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.sunrise_fill,
                                size: 22,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sehri Ends',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  sehriTimeStr,
                                  style: GoogleFonts.oxanium(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Iftar Time Item
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Iftar Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  iftarTimeStr,
                                  style: GoogleFonts.oxanium(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.sunset_fill,
                                size: 22,
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Lower Half Sheet Container (White / Light sheet containing Duas & Fasting Highlights)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Featured Today's Fasting Banner (if today is a significant fasting day)
                      if (todayFastingInfo != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                todayFastingInfo.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                todayFastingInfo.primaryColor.withValues(
                                  alpha: 0.04,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: todayFastingInfo.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    todayFastingInfo.icon,
                                    color: todayFastingInfo.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Today\'s Fasting Significance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: todayFastingInfo.primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                todayFastingInfo.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: todayFastingInfo.primaryColor,
                                ),
                              ),
                              Text(
                                todayFastingInfo.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: todayFastingInfo.primaryColor
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                todayFastingInfo.description,
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: const Color(0xFF374151),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Box 1: Sehri Dua (Dua for Suhoor / Intention to Fast)
                      _buildDuaCard(
                        context,
                        title: 'Sehri Dua (Intention for Fasting)',
                        arabic:
                            'وَبِصَوۡمِ غَدٍ نَّوَيۡتُ مِنۡ شَهۡرِ رَمَضَانَ',
                        transliteration:
                            'Wa bi-sawmi ghadin nawaitu min shahri ramadan.',
                        translation:
                            '"I intend to keep the fast tomorrow for the month of Ramadan."',
                        badgeColor: const Color(0xFFD97724),
                        isExpanded: _isSehriExpanded,
                        onTap: () => setState(
                          () => _isSehriExpanded = !_isSehriExpanded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Box 2: Iftar Dua (Dua for Breaking Fast)
                      _buildDuaCard(
                        context,
                        title: 'Iftar Dua (Dua for Breaking Fast)',
                        arabic:
                            'اللَّهُمَّ إِنِّي لَكُ صُمۡتُ وَبِكُ آمَنۡتُ وَعَلَى رِزۡقِكَ أَفۡطَرۡتُ',
                        transliteration:
                            'Allahumma inni laka sumtu wa bika aamantu wa \'ala rizqika aftartu.',
                        translation:
                            '"O Allah, I fasted for You and I believe in You and I break my fast with Your provision."',
                        badgeColor: const Color(0xFF16A34A),
                        isExpanded: _isIftarExpanded,
                        onTap: () => setState(
                          () => _isIftarExpanded = !_isIftarExpanded,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Box 3: Significant Fasting Days in Islam Section
                      _buildSignificantFastingDaysSection(context),

                      const SizedBox(height: 24),
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

  Widget _buildDuaCard(
    BuildContext context, {
    required String title,
    required String arabic,
    required String transliteration,
    required String translation,
    required Color badgeColor,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? badgeColor.withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: badgeColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Arabic Text
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                arabic,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabicBody(
                  fontSize: 24,
                  height: 1.6,
                  color: const Color(0xFF1E3816),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Transliteration
            Text(
              transliteration,
              style: GoogleFonts.lexend(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A531D),
              ),
            ),

            // Translation (shown only when expanded)
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  translation,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignificantFastingDaysSection(BuildContext context) {
    final occasions = FastingHelper.getSignificantOccasionsList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2A531D),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Significant Fasting Days in Islam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A531D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap on any occasion to explore its virtues and Hadiths',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: occasions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final occ = occasions[index];
            final isExpanded = _expandedOccasionIndex == index;

            return InkWell(
              onTap: () {
                setState(() {
                  _expandedOccasionIndex = isExpanded ? null : index;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: occ.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: occ.primaryColor.withValues(
                      alpha: isExpanded ? 0.4 : 0.15,
                    ),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: occ.primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            occ.icon,
                            color: occ.primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                occ.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: occ.primaryColor,
                                ),
                              ),
                              Text(
                                occ.subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: occ.primaryColor,
                          size: 20,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      if (occ.arabicHadith != null) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            occ.arabicHadith!,
                            textDirection: TextDirection.rtl,
                            style: AppTypography.arabicBody(
                              fontSize: 17,
                              height: 2.2,
                              color: occ.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        occ.description,
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: const Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        occ.hadith,
                        style: GoogleFonts.lexend(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: occ.primaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RozaArcPainter extends CustomPainter {
  final double progress;

  _RozaArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Dome top is at y=20, dome radius is 125, so center is at (width/2, 145)
    final center = Offset(size.width / 2, size.height - 15);
    final radius = 145.0; // 125 (dome radius) + 20px gap

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    final startAngle = math.pi; // 180 deg (left)
    final sweepAngle = math.pi; // 180 deg (to right)

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RozaArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RozaCalendarModalContent extends ConsumerStatefulWidget {
  final Function(DateTime date, HijriDate hijri) onDateSelected;

  const _RozaCalendarModalContent({required this.onDateSelected});

  @override
  ConsumerState<_RozaCalendarModalContent> createState() =>
      _RozaCalendarModalContentState();
}

class _RozaCalendarModalContentState
    extends ConsumerState<_RozaCalendarModalContent> {
  static const int _initialPage = 1200;
  late PageController _pageController;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMonthForPage(int pageIndex) {
    final now = DateTime.now();
    final monthOffset = pageIndex - _initialPage;
    return DateTime(now.year, now.month + monthOffset, 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final now = DateTime.now();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Month Header Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF2A531D),
                  size: 28,
                ),
                tooltip: 'Previous Month',
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),

              // Month & Hijri Header
              Builder(
                builder: (context) {
                  final midDate = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    15,
                  );
                  final hijriMid = HijriDateHelper.convertToHijri(midDate);
                  final gregorianMonthStr = DateFormat(
                    'MMMM yyyy',
                  ).format(_currentMonth);
                  return Column(
                    children: [
                      Text(
                        gregorianMonthStr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hijriMid.monthName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97724),
                        ),
                      ),
                    ],
                  );
                },
              ),

              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2A531D),
                  size: 28,
                ),
                tooltip: 'Next Month',
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Weekday Labels Row (Mon to Sun)
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((
              day,
            ) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8C6D53),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // PageView for Sliding Calendar Grid
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (pageIndex) {
                setState(() {
                  _currentMonth = _getMonthForPage(pageIndex);
                });
              },
              itemBuilder: (context, pageIndex) {
                final monthDate = _getMonthForPage(pageIndex);
                final daysInMonth = DateTime(
                  monthDate.year,
                  monthDate.month + 1,
                  0,
                ).day;
                final firstWeekday = DateTime(
                  monthDate.year,
                  monthDate.month,
                  1,
                ).weekday; // 1 = Mon, 7 = Sun
                final leadingBlankCount = firstWeekday - 1;
                final totalItems = leadingBlankCount + daysInMonth;

                return GridView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    if (index < leadingBlankCount) {
                      return const SizedBox.shrink();
                    }

                    final dayNum = index - leadingBlankCount + 1;
                    final date = DateTime(
                      monthDate.year,
                      monthDate.month,
                      dayNum,
                    );
                    final hijri = HijriDateHelper.convertToHijri(date);
                    final isToday =
                        date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                    final fastingInfo = FastingHelper.getFastingInfo(
                      date,
                      hijri,
                    );
                    final isSpecialFastingDay =
                        fastingInfo != null &&
                        fastingInfo.type != FastingType.prohibited;
                    final isProhibitedDay =
                        fastingInfo?.type == FastingType.prohibited;

                    Color bg;
                    Color borderColor;
                    double borderWidth = 1.0;

                    if (isToday) {
                      bg = const Color(0xFF2A531D);
                      borderColor = const Color(0xFF15803D);
                      borderWidth = 2.0;
                    } else if (isProhibitedDay) {
                      bg = isDark
                          ? const Color(0xFF3B1818)
                          : const Color(0xFFFEF2F2);
                      borderColor = const Color(0xFFEF4444);
                      borderWidth = 1.5;
                    } else if (isSpecialFastingDay) {
                      bg = isDark
                          ? fastingInfo.primaryColor.withValues(alpha: 0.2)
                          : fastingInfo.primaryColor.withValues(alpha: 0.08);
                      borderColor = fastingInfo.primaryColor.withValues(
                        alpha: 0.6,
                      );
                      borderWidth = 1.5;
                    } else {
                      bg = isDark
                          ? const Color(0xFF23322B)
                          : const Color(0xFFF3FAF2);
                      borderColor = const Color(
                        0xFF2A531D,
                      ).withValues(alpha: 0.15);
                    }

                    return InkWell(
                      onTap: () => widget.onDateSelected(date, hijri),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Top-Right Corner: English Date Number (Big Bold)
                            Positioned(
                              top: 4,
                              right: 6,
                              child: Text(
                                '$dayNum',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? Colors.white
                                      : (isSpecialFastingDay
                                            ? fastingInfo.primaryColor
                                            : (isProhibitedDay
                                                  ? const Color(0xFFDC2626)
                                                  : (isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF2A531D,
                                                          )))),
                                ),
                              ),
                            ),

                            // Bottom-Left Corner: Hijri Date Number
                            Positioned(
                              bottom: 4,
                              left: 6,
                              child: Text(
                                '${hijri.day}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isToday
                                      ? const Color(0xFFFACC15)
                                      : (isSpecialFastingDay
                                            ? fastingInfo.primaryColor
                                            : (isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF8C6D53))),
                                ),
                              ),
                            ),

                            // Top-Left Corner Badge for Special Fasting Days
                            if (fastingInfo != null && !isToday)
                              Positioned(
                                top: 4,
                                left: 5,
                                child: Icon(
                                  fastingInfo.icon,
                                  size: 10,
                                  color: fastingInfo.primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
