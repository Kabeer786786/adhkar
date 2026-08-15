import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/hijri_service.dart';
import '../../../core/services/prayer_calculation_service.dart';
import '../../../core/services/showcase_service.dart';
import '../../../core/utils/hijri_date_helper.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_showcase.dart';
import '../../../widgets/app_header_bar.dart';
import '../../prayer/presentation/providers/aladhan_providers.dart';

import '../../../shared/providers/user_profile_provider.dart';
import '../../../shared/widgets/complete_profile_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  Timer? _secondsTimer;
  bool _showSeconds = false;
  late ScrollController _scrollController;
  final ValueNotifier<double> _appBarOpacity = ValueNotifier<double>(0.0);
  static bool _hasPromptedProfileInSession = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkAndPromptCompleteProfile();
      final hasSeen = await ShowcaseService.hasSeenHomeShowcase();
      if (!hasSeen && mounted) {
        ShowcaseService.startHomeShowcase(context);
      }
    });
  }

  void _checkAndPromptCompleteProfile() async {
    if (_hasPromptedProfileInSession || !mounted) return;

    final hasSeenShowcase = await ShowcaseService.hasSeenHomeShowcase();
    final justSkipped = await UserProfileNotifier.wasJustSkippedInThisSession();

    if (!mounted) return;
    // Do not show popup if showcase tour is running / hasn't been completed yet, or if user just skipped registration in this session
    if (!hasSeenShowcase || justSkipped) return;

    final userProfile = ref.read(userProfileProvider);
    if (!userProfile.registrationCompleted) {
      _hasPromptedProfileInSession = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          CompleteProfileModal.show(context);
        }
      });
    }
  }




  void _toggleShowSeconds() {
    _secondsTimer?.cancel();
    setState(() {
      _showSeconds = !_showSeconds;
    });
    if (_showSeconds) {
      _secondsTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _showSeconds = false;
          });
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final opacity = (offset / 100.0).clamp(0.0, 1.0);
    if ((opacity - _appBarOpacity.value).abs() > 0.01) {
      _appBarOpacity.value = opacity;
    }
  }

  Future<void> _onRefresh() async {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    try {
      await ref.read(userLocationProvider.notifier).refreshFromGps();
    } catch (_) {}
    ref.invalidate(aladhanPrayerTimesProvider(dateOnly));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appBarOpacity.dispose();
    _timer?.cancel();
    _secondsTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '0:00:00';
    final hours = d.inHours.toString();
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  _CurrentNamazInfo? _getCurrentNamazInfo(PrayerTimeResult? result) {
    if (result == null) return null;
    final now = DateTime.now();

    if (now.isAfter(result.fajr) && now.isBefore(result.sunrise)) {
      return _CurrentNamazInfo(
        'Fajr',
        result.fajr,
        result.sunrise,
        CupertinoIcons.cloud_sun_fill,
      );
    } else if (now.isAfter(result.sunrise) && now.isBefore(result.dhuhr)) {
      return _CurrentNamazInfo(
        'Sunrise',
        result.sunrise,
        result.dhuhr,
        CupertinoIcons.sunrise_fill,
      );
    } else if (now.isAfter(result.dhuhr) && now.isBefore(result.asr)) {
      return _CurrentNamazInfo(
        'Dhuhr',
        result.dhuhr,
        result.asr,
        CupertinoIcons.sun_max_fill,
      );
    } else if (now.isAfter(result.asr) && now.isBefore(result.maghrib)) {
      return _CurrentNamazInfo(
        'Asr',
        result.asr,
        result.maghrib,
        CupertinoIcons.cloud_sun_fill,
      );
    } else if (now.isAfter(result.maghrib) && now.isBefore(result.isha)) {
      return _CurrentNamazInfo(
        'Maghrib',
        result.maghrib,
        result.isha,
        CupertinoIcons.sunset_fill,
      );
    } else {
      final nextFajr = result.fajr.add(const Duration(days: 1));
      return _CurrentNamazInfo(
        'Isha',
        result.isha,
        nextFajr,
        CupertinoIcons.moon_stars_fill,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = ref.watch(nextPrayerProvider);
    final prayerTimes = ref.watch(prayerTimesProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final now = DateTime.now();
    final todayHijriAsync = ref.watch(todayHijriProvider);
    final hijriStr = todayHijriAsync.value?.formatted ?? HijriDateHelper.formatHijri(now);

    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    final namazInfo = _getCurrentNamazInfo(prayerTimes);
    final currentNamazName = namazInfo?.name ?? '---';
    final startTimeStr = namazInfo != null
        ? DateFormat('hh:mm a').format(namazInfo.start)
        : '--:--';
    final endTimeStr = namazInfo != null
        ? DateFormat('hh:mm a').format(namazInfo.end)
        : '--:--';
    final timeDigits = DateFormat('hh:mm').format(now);
    final timeAmPm = DateFormat('a').format(now);
    final timeSeconds = DateFormat('ss').format(now);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder<double>(
          valueListenable: _appBarOpacity,
          builder: (context, opacity, child) {
            return AppHeaderBar(
              title: '',
              titleWidget: Text(
                'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A531D),
                  shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
                ),
              ),
              backgroundColor: Colors.white.withValues(alpha: opacity),
              elevation: opacity * 4.0,
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF2A531D),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Banner Section with Overlapping Grid Cards
              SizedBox(
                width: double.infinity,
                height: screenWidth + 70,
                child: Stack(
                  children: [
                    // Square background image starting from top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: screenWidth,
                      child: Image.asset(
                        'assets/home.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF3FAF2),
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    // Bottom gradient fade into white (Pure white alpha interpolation: NO black line)
                    Positioned(
                      top: screenWidth - 120,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00FFFFFF), // 0% opacity white
                              Color(0x33FFFFFF), // 20% opacity white
                              Color(0x99FFFFFF), // 60% opacity white
                              Color(0xFFFFFFFF), // 100% solid white
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Left-aligned Overlay Content (Time, Namaz Name + Icon, Start & End Times)
                    Positioned(
                      top: topPadding,
                      left: 20,
                      right: 20,
                      child: AppShowcase(
                        globalKey: ShowcaseService.keyNamazStartEnd,
                        title: 'Namaz Start & End Times',
                        description:
                            'View current prayer times along with exact start and end times dynamically updated for your location.',
                        stepIndex: 1,
                        totalSteps: 15,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Large Time Digits with Tappable Interactive AM/PM & Seconds (Smooth slide & 10s auto-hide)
                            GestureDetector(
                              onTap: _toggleShowSeconds,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    timeDigits,
                                    style: GoogleFonts.oxanium(
                                      fontSize: 60,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2A531D),
                                      letterSpacing: -2.5,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.white70,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          timeAmPm,
                                          style: GoogleFonts.oxanium(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF4F2D12),
                                            height: 1.1,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.white70,
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_showSeconds)
                                          AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            opacity: _showSeconds ? 1.0 : 0.0,
                                            child: Text(
                                              timeSeconds,
                                              style: GoogleFonts.oxanium(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF2A531D),
                                                height: 1.1,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.white70,
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Namaz Name with Icon on Left
                            Row(
                              children: [
                                Icon(
                                  namazInfo?.icon ?? CupertinoIcons.sun_max_fill,
                                  size: 24,
                                  color: const Color(0xFFD97724),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentNamazName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A531D),
                                    shadows: [
                                      Shadow(
                                        color: Colors.white70,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Start Time in Green
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Start: $startTimeStr',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                    shadows: [
                                      Shadow(
                                        color: Colors.white70,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // End Time in Red
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'End: $endTimeStr',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                    shadows: [
                                      Shadow(
                                        color: Colors.white70,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Two Grid Boxes Overlapping Banner Image by 50px
                    Positioned(
                      top: screenWidth - 44,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          // Box 1: Remaining Time
                          Expanded(
                            child: AppShowcase(
                              globalKey: ShowcaseService.keyRemainingTime,
                              title: 'Prayer Countdown',
                              description:
                                  'Stay mindful with a live countdown timer showing remaining time for the next upcoming prayer.',
                              stepIndex: 2,
                              totalSteps: 15,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3FAF2),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'REMAINING TIME',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        color: Color(0xFF8C6D53),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (locationAsync.isLoading ||
                                              locationAsync.isRefreshing ||
                                              nextPrayer == null)
                                          ? '---'
                                          : nextPrayer.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A531D),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (locationAsync.isLoading ||
                                              locationAsync.isRefreshing ||
                                              nextPrayer == null)
                                          ? '--:--:--'
                                          : _formatDuration(
                                              nextPrayer.currentRemaining,
                                            ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFD97724),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Box 2: Hijri Date & Location
                          Expanded(
                            child: AppShowcase(
                              globalKey: ShowcaseService.keyHijriLocation,
                              title: 'Hijri Date & Location',
                              description:
                                  'Current Hijri Islamic date paired with auto-detected GPS location for accurate local prayer calculations.',
                              stepIndex: 3,
                              totalSteps: 15,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3FAF2),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'HIJRI & LOCATION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        color: Color(0xFF8C6D53),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      hijriStr,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A531D),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (locationAsync.isLoading ||
                                              locationAsync.isRefreshing ||
                                              locationAsync.value == null ||
                                              locationAsync.value!.city.isEmpty)
                                          ? '---'
                                          : (locationAsync
                                                    .value!
                                                    .country
                                                    .isNotEmpty
                                                ? '${locationAsync.value!.city}, ${locationAsync.value!.country}'
                                                : locationAsync.value!.city),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B533E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Quick Action Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FAF2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: GridView.count(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 0,
                  children: [
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileNamaz,
                      title: 'Namaz Timings',
                      description:
                          'View complete 5 daily prayer times, Fajr to Isha, with countdowns and notification settings.',
                      stepIndex: 4,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Namaz',
                        assetPath: 'assets/images/namaz.png',
                        onTap: () => context.push('/prayer'),
                        width: 45,
                        height: 45,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileRoza,
                      title: 'Roza & Fasting',
                      description:
                          'Track Suhoor & Iftar timings, Ramadan fasting progress, and voluntary fasts.',
                      stepIndex: 5,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Roza',
                        assetPath: 'assets/images/roza.png',
                        onTap: () => context.push('/roza'),
                        width: 50,
                        height: 45,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileSadqa,
                      title: 'Sadaqah & Zakat',
                      description:
                          'Calculate Zakat obligation accurately and track charitable Sadaqah contributions.',
                      stepIndex: 6,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Sadqa',
                        assetPath: 'assets/images/sadqa.png',
                        onTap: () => context.push('/sadqa'),
                        width: 38,
                        height: 45,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileTasbeeh,
                      title: 'Digital Tasbeeh',
                      description:
                          'Interactive digital counter with haptic feedback for daily Dhikr and Tasbeeh.',
                      stepIndex: 7,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Tasbeeh',
                        assetPath: 'assets/images/tasbeeh.png',
                        onTap: () => context.push('/tasbeeh'),
                        width: 45,
                        height: 45,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileAsmaUlHusna,
                      title: '99 Names of Allah',
                      description:
                          'Explore 99 Beautiful Names of Allah (Asma-ul-Husna) with meanings and audio.',
                      stepIndex: 8,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Asma-ul-Husna',
                        assetPath: 'assets/images/asma-ul-husna.png',
                        onTap: () => context.push('/asma-ul-husna'),
                        width: 40,
                        height: 44,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileDua,
                      title: 'Masnoon Duas',
                      description:
                          'Comprehensive collection of authentic Islamic supplications for all daily occasions.',
                      stepIndex: 9,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: "Dua'een",
                        assetPath: 'assets/images/dua.png',
                        onTap: () => context.push('/dua'),
                        width: 45,
                        height: 45,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileBooks,
                      title: 'Islamic Books',
                      description:
                          'Read curated Islamic literature, Hadith collections, and spiritual guidance books.',
                      stepIndex: 10,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Books',
                        assetPath: 'assets/images/books.png',
                        onTap: () => context.push('/books'),
                        width: 48,
                        height: 43,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileSciIslam,
                      title: 'Science in Islam',
                      description:
                          'Discover Quranic scientific revelations and historical Islamic scientific achievements.',
                      stepIndex: 11,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Sci-Islam',
                        assetPath: 'assets/images/scifi-islam.png',
                        onTap: () => context.push('/sci-islam'),
                        width: 45,
                        height: 44,
                      ),
                    ),
                    AppShowcase(
                      globalKey: ShowcaseService.keyTileReminder,
                      title: 'Custom Reminders',
                      description:
                          'Set personalized notification alerts for daily Adhkar, Tahajjud, and fasting days.',
                      stepIndex: 12,
                      totalSteps: 15,
                      child: _FeatureTile(
                        title: 'Reminder',
                        assetPath: 'assets/images/reminder.png',
                        onTap: () => context.push('/reminder'),
                        width: 36,
                        height: 43,
                      ),
                    ),
                  ],
                ),
              ),



              const SizedBox(height: 12),

              // 4. Daily Quote Box Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FAF2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Centered Arabic Quote
                    Text(
                      'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                        color: const Color(0xFF1A3512),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Translation below it
                    Text(
                      '"So remember Me; I will remember you. And be grateful to Me and do not deny Me."',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF2A531D),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bottom Left Corner: Author / Source with Icon
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FlutterIslamicIcons.quran2,
                            size: 15,
                            color: Color(0xFF8C6D53),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Quran • Surah Al-Baqarah 2:152',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8C6D53),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentNamazInfo {
  final String name;
  final DateTime start;
  final DateTime end;
  final IconData icon;

  _CurrentNamazInfo(this.name, this.start, this.end, this.icon);
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String assetPath;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _FeatureTile({
    required this.title,
    required this.assetPath,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetPath,
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.grid_view_rounded,
              size: 36,
              color: Color(0xFFD97724),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF2A531D),
            ),
          ),
        ],
      ),
    );
  }
}
