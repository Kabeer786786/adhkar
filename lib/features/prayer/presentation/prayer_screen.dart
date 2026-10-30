import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../home/presentation/widgets/forbidden_sajda_widget.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/hijri_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_calculation_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/calendar/models/calendar_type.dart';
import '../../../core/calendar/providers/calendar_providers.dart';
import '../../../core/utils/hijri_date.dart';
import '../../../core/utils/hijri_date_helper.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../../shared/widgets/hijri_disclaimer_chip.dart';
import '../domain/prayer_models.dart';
import 'widgets/prayer_detail_modal.dart';
import 'widgets/salah_history_card.dart';
import 'widgets/salah_history_detail_modal.dart';

import '../../../shared/widgets/app_shimmer.dart';
import '../../../shared/widgets/location_selection_modal.dart';
import '../data/repositories/aladhan_repository.dart';
import 'providers/aladhan_providers.dart';

import '../../../shared/widgets/feature_intro_modal.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _timetableScrollController = ScrollController();
  final GlobalKey _activeCardKey = GlobalKey();
  DateTime _selectedDate = DateTime.now();
  bool _isChangingDate = false;
  Timer? _ticker;

  int _historyFilterDays = 7; // Default 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0 && mounted) {
        _triggerScrollToActive();
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureIntroModal.show(context, FeatureIntroType.namaz);
      _triggerScrollToActive();
    });
  }

  void _triggerScrollToActive() { 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _activeCardKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.22,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabController.dispose();
    _timetableScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _isChangingDate = true;
        _selectedDate = picked;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _isChangingDate = false;
        });
        if (DateUtils.isSameDay(picked, DateTime.now())) {
          _triggerScrollToActive();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPrayer = ref.watch(currentPrayerProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final method = ref.watch(calculationMethodProvider);
    final juristic = ref.watch(asrJuristicProvider);
    final location = locationAsync.value ?? LocationService.defaultLocation;

    // Fetch AlAdhan API prayer times with fallback to local calculation
    final aladhanAsync = ref.watch(aladhanPrayerTimesProvider(_selectedDate));
    final fetchResult = aladhanAsync.value;

    final prayerTimes =
        fetchResult?.result ??
        PrayerCalculationService.calculate(
          date: _selectedDate,
          latitude: location.latitude,
          longitude: location.longitude,
          methodName: method,
          juristicAsr: juristic,
        );

    final isApiSuccess = fetchResult?.source == PrayerTimeSource.apiRemote;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prayer Timetable',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.75,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded),
            tooltip: 'Change City / Location',
            onPressed: () => LocationSelectionModal.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.colorScheme.primary,
          labelColor: context.colorScheme.primary,
          unselectedLabelColor: context.colorScheme.onSurfaceVariant,
          dividerColor: Colors.transparent,
          labelStyle: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Today\'s Timings'),
            Tab(text: 'Salah Log & History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimetableTab(
            prayerTimes,
            currentPrayer,
            location,
            method,
            isApiSuccess,
            fetchResult,
          ),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  String _determineCurrentPrayerKey(PrayerTimeResult times, DateTime now) {
    final sunriseEnd = times.sunrise.add(const Duration(minutes: 20));
    final zawalStart = times.dhuhr.subtract(const Duration(minutes: 15));
    final ghurubStart = times.maghrib.subtract(const Duration(minutes: 10));
    final tahajjudTime = DateTime(
      times.fajr.year,
      times.fajr.month,
      times.fajr.day,
      times.qiyam.hour,
      times.qiyam.minute,
    );

    if (now.isBefore(times.fajr)) {
      if (!now.isBefore(tahajjudTime)) {
        return 'Tahajjud';
      }
      return 'Isha';
    } else if (now.isBefore(times.sunrise)) {
      return 'Fajr';
    } else if (now.isBefore(sunriseEnd)) {
      return 'Sunrise_Prohibited';
    } else if (now.isBefore(zawalStart)) {
      return 'Ishraq';
    } else if (now.isBefore(times.dhuhr)) {
      return 'Zawal_Prohibited';
    } else if (now.isBefore(times.asr)) {
      return 'Dhuhr';
    } else if (now.isBefore(ghurubStart)) {
      return 'Asr';
    } else if (now.isBefore(times.maghrib)) {
      return 'Ghurub_Prohibited';
    } else if (now.isBefore(times.isha)) {
      return 'Maghrib';
    } else {
      return 'Isha';
    }
  }

  Widget _buildTimetableTab(
    PrayerTimeResult prayerTimes,
    NextPrayerInfo? currentPrayer,
    LocationData location,
    String method,
    bool isApiSuccess,
    PrayerTimeFetchResult? fetchResult,
  ) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final gregorianStr = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isFriday = _selectedDate.weekday == DateTime.friday;
    final storage = ref.watch(storageServiceProvider);
    final now = DateTime.now();

    final currentActiveKey = isToday
        ? _determineCurrentPrayerKey(prayerTimes, now)
        : '';

    final sunriseInfo = ForbiddenSajdaService.getSunriseInfo(prayerTimes);
    final zawalInfo = ForbiddenSajdaService.getZawalInfo(prayerTimes);
    final ghurubInfo = ForbiddenSajdaService.getGhurubInfo(
      prayerTimes,
      storage,
      date: _selectedDate,
    );

    final todayHijri = ref.watch(todayHijriProvider).value;
    final calPref = ref.watch(calendarPreferenceProvider);

    String hijriStr;
    if (isToday && todayHijri != null) {
      hijriStr = todayHijri.formatted;
    } else {
      final isSubcontinent =
          calPref.calendarType == CalendarType.regional &&
          (calPref.region == HijriRegion.india ||
              calPref.region == HijriRegion.pakistan ||
              calPref.region == HijriRegion.bangladesh);
      final hDate = HijriDate.fromGregorian(
        _selectedDate,
        isSubcontinent: isSubcontinent,
      );
      hijriStr = '${hDate.day} ${hDate.monthNameEn} ${hDate.year} AH';
    }
    final isAladhan = todayHijri?.isAladhan ?? false;

    final prayerList = _buildPrayerList(prayerTimes, isFriday: isFriday);

    final locationDisplayName = location.country.isNotEmpty
        ? '${location.city}, ${location.country}'
        : location.city;

    return RefreshIndicator(
      color: const Color(0xFF2A531D),
      onRefresh: () async {
        ref.invalidate(aladhanPrayerTimesProvider(_selectedDate));
        ref.invalidate(prayerTimesProvider);
        ref.invalidate(currentPrayerProvider);
        ref.invalidate(nextPrayerProvider);
        if (mounted) {
          setState(() {});
        }
      },
      child: ListView(
        controller: _timetableScrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (isAladhan)
            const HijriDisclaimerChip(
              isAladhan: true,
              margin: EdgeInsets.only(bottom: 12),
            ),
          // --- Location Header Banner ---
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationDisplayName,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${location.latitude.toStringAsFixed(4)}°, ${location.longitude.toStringAsFixed(4)}°',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onPressed: () => LocationSelectionModal.show(context),
                ),
              ],
            ),
          ),
          // --- Top Header Card: Gregorian Date, Hijri Date, Calendar Icon ---
          Padding(
            padding: const EdgeInsets.only(
              bottom: 16,
              top: 0,
              left: 5,
              right: 5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                gregorianStr,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: context.colorScheme.onSurface,
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hijriStr,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Calendar Icon Button Right Justified
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Icon(
                      Icons.calendar_month,
                      size: 28,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Date Changing Loader Banner ---
          if (_isChangingDate)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF2A531D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Updating prayer timings for selected date...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                ],
              ),
            ),

          // --- Prayer Cards List with Shimmer Effect ---
          AppShimmer(
            isLoading: _isChangingDate,
            child: Column(
              children: [
                for (final prayer in prayerList) ...[
                  // 1. Prohibited Time: Sunrise (Tulu) - Between Fajr and Ishraq
                  if (prayer.key == 'Ishraq')
                    ForbiddenTimeCard(
                      key: isToday && (currentActiveKey == 'Sunrise_Prohibited')
                          ? _activeCardKey
                          : null,
                      info: sunriseInfo,
                      isCurrent:
                          isToday && (currentActiveKey == 'Sunrise_Prohibited'),
                    ),

                  // 2. Prohibited Time: Zawal (Zenith) - Before Dhuhr / Jumma
                  if (prayer.key == 'Dhuhr')
                    ForbiddenTimeCard(
                      key: isToday && (currentActiveKey == 'Zawal_Prohibited')
                          ? _activeCardKey
                          : null,
                      info: zawalInfo,
                      isCurrent:
                          isToday && (currentActiveKey == 'Zawal_Prohibited'),
                    ),

                  // 3. Prohibited Time: Sunset (Ghurub / After Asr) - Before Maghrib
                  if (prayer.key == 'Maghrib')
                    ForbiddenTimeCard(
                      key: isToday && (currentActiveKey == 'Ghurub_Prohibited')
                          ? _activeCardKey
                          : null,
                      info: ghurubInfo,
                      isCurrent:
                          isToday && (currentActiveKey == 'Ghurub_Prohibited'),
                    ),

                  // Normal Prayer Card
                  _buildPrayerCard(
                    key: isToday && (currentActiveKey == prayer.key)
                        ? _activeCardKey
                        : null,
                    prayer: prayer,
                    isToday: isToday,
                    currentActiveKey: currentActiveKey,
                    isFriday: isFriday,
                    dateKey: dateKey,
                    storage: storage,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPrayerCard({
    Key? key,
    required PrayerDetail prayer,
    required bool isToday,
    required String currentActiveKey,
    required bool isFriday,
    required String dateKey,
    required StorageService storage,
  }) {
    final isCurrent = isToday && (currentActiveKey == prayer.key);
    final isFridayJumma = isFriday && prayer.key == 'Dhuhr';
    final timeStr = DateFormat('hh:mm a').format(prayer.time);

    // Get completed sub-prayers
    final completedSubIds = storage.getSubPrayerRecords(dateKey, prayer.key);

    final isFuture = (isToday && prayer.key == 'Tahajjud')
        ? false
        : prayer.time.isAfter(DateTime.now());
    final isHighlight = isCurrent;

    // Background decoration styling
    BoxDecoration cardDecoration;
    if (isHighlight) {
      if (isFridayJumma) {
        cardDecoration = BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDarkMode
                ? [const Color(0xFF064E3B), const Color(0xFF133629)]
                : [const Color(0xFFDCFCE7), const Color(0xFFFEFCE8)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        );
      } else {
        cardDecoration = BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF163E2E)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        );
      }
    } else {
      cardDecoration = BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1A2818)
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      );
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: prayer.isZawal
              ? null
              : () {
                  if (isFuture) {
                    AppFloatingToast.showInfo(
                      context,
                      message:
                          'Upcoming prayer cannot be marked as completed yet',
                    );
                  } else {
                    _openPrayerDetail(
                      prayer,
                      dateKey,
                      completedSubIds,
                      isFuture: isFuture,
                    );
                  }
                },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.only(
              left: 20,
              right: 24,
              top: 14,
              bottom: 14,
            ),
            decoration: cardDecoration,
            child: Row(
              children: [
                const SizedBox(width: 4),
                // Icon (Kaaba on Friday for Jumma, else sky icon)
                Icon(
                  prayer.icon,
                  color: isHighlight
                      ? const Color(0xFF047857)
                      : _getPrayerIconColor(
                          prayer.key,
                          context,
                          isFriday: isFriday,
                        ),
                  size: 28,
                ),
                const SizedBox(width: 16),

                // Prayer Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            prayer.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isHighlight
                                  ? (context.isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF064E3B))
                                  : context.colorScheme.onSurface,
                            ),
                          ),
                          
                          if (isFridayJumma) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF047857),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Friday Special',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        prayer.subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: isHighlight
                              ? (context.isDarkMode
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFF047857))
                              : context.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time Display
                Text(
                  timeStr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: isHighlight
                        ? (context.isDarkMode
                              ? Colors.white
                              : const Color(0xFF064E3B))
                        : context.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPrayerIconColor(
    String prayerKey,
    BuildContext context, {
    bool isFriday = false,
  }) {
    switch (prayerKey) {
      case 'Fajr':
        return const Color(0xFF0284C7);
      case 'Ishraq':
      case 'Shuruq':
        return const Color(0xFFF59E0B);
      case 'Dhuhr':
        return isFriday ? const Color(0xFF047857) : const Color(0xFFD97706);
      case 'Asr':
        return const Color(0xFFEAB308);
      case 'Maghrib':
        return const Color(0xFFF97316);
      case 'Isha':
        return const Color(0xFF3730A3);
      case 'Tahajjud':
        return const Color(0xFF6B21A8);
      default:
        return context.colorScheme.primary;
    }
  }

  List<PrayerDetail> _buildPrayerList(
    PrayerTimeResult times, {
    bool isFriday = false,
  }) {
    final tahajjudTime = DateTime(
      times.fajr.year,
      times.fajr.month,
      times.fajr.day,
      times.qiyam.hour,
      times.qiyam.minute,
    );

    return [ 
      PrayerDetail(
        key: 'Tahajjud',
        title: 'Tahajjud',
        subtitle: 'Late Night',
        icon: CupertinoIcons.moon_stars_fill,
        time: tahajjudTime,
        subPrayers: const [
          SubPrayerItem(id: 'tahajjud_nafeel', title: 'Nafeel', rakats: 4),
        ],
      ),
      PrayerDetail(
        key: 'Fajr',
        title: 'Fajr',
        subtitle: 'Before Sunrise',
        icon: CupertinoIcons.cloud_sun_fill,
        time: times.fajr,
        subPrayers: const [
          SubPrayerItem(id: 'fajr_sunnat', title: 'Sunnat', rakats: 2),
          SubPrayerItem(id: 'fajr_farz', title: 'Farz', rakats: 2),
        ],
      ),
      PrayerDetail(
        key: 'Ishraq',
        title: 'Ishraq',
        subtitle: 'Post-Sunrise (Nafeel)',
        icon: CupertinoIcons.sun_min_fill,
        time: times.sunrise.add(const Duration(minutes: 20)),
        subPrayers: const [
          SubPrayerItem(id: 'shuruq_ishraq', title: 'Ishraq Nafeel', rakats: 2),
          SubPrayerItem(id: 'shuruq_chast', title: 'Chast Nafeel', rakats: 2),
        ],
      ),
      if (isFriday)
        PrayerDetail(
          key: 'Dhuhr',
          title: 'Jumma',
          subtitle: 'Friday Prayer',
          icon: FlutterIslamicIcons.solidKaaba,
          time: times.dhuhr,
          subPrayers: const [
            SubPrayerItem(
              id: 'jumma_sunnat_1',
              title: 'Sunnat (Before Farz)',
              rakats: 4,
            ),
            SubPrayerItem(id: 'jumma_farz', title: 'Jummah Farz', rakats: 2),
            SubPrayerItem(
              id: 'jumma_sunnat_2',
              title: 'Sunnat (After Farz)',
              rakats: 2,
            ),
            SubPrayerItem(
              id: 'jumma_sunnat_3',
              title: 'Sunnat (Additional)',
              rakats: 4,
            ),
            SubPrayerItem(id: 'jumma_nafeel', title: 'Nafeel', rakats: 2),
          ],
        )
      else
        PrayerDetail(
          key: 'Dhuhr',
          title: 'Dhuhr',
          subtitle: 'Noon',
          icon: CupertinoIcons.sun_max_fill,
          time: times.dhuhr,
          subPrayers: const [
            SubPrayerItem(
              id: 'dhuhr_sunnat_1',
              title: 'Sunnat (Before)',
              rakats: 4,
            ),
            SubPrayerItem(id: 'dhuhr_farz', title: 'Farz', rakats: 4),
            SubPrayerItem(
              id: 'dhuhr_sunnat_2',
              title: 'Sunnat (After)',
              rakats: 2,
            ),
            SubPrayerItem(id: 'dhuhr_nafeel', title: 'Nafeel', rakats: 2),
          ],
        ),
      PrayerDetail(
        key: 'Asr',
        title: 'Asr',
        subtitle: 'Afternoon',
        icon: CupertinoIcons.cloud_sun_fill,
        time: times.asr,
        subPrayers: const [
          SubPrayerItem(id: 'asr_sunnat', title: 'Sunnat', rakats: 4),
          SubPrayerItem(id: 'asr_farz', title: 'Farz', rakats: 4),
        ],
      ),
      PrayerDetail(
        key: 'Maghrib',
        title: 'Maghrib',
        subtitle: 'Sunset',
        icon: CupertinoIcons.sunset_fill,
        time: times.maghrib,
        subPrayers: const [
          SubPrayerItem(id: 'maghrib_farz', title: 'Farz', rakats: 3),
          SubPrayerItem(id: 'maghrib_sunnat', title: 'Sunnat', rakats: 2),
          SubPrayerItem(id: 'maghrib_nafeel', title: 'Nafeel', rakats: 2),
          SubPrayerItem(
            id: 'maghrib_awabeen',
            title: 'Awabeen Nafeel',
            rakats: 6,
          ),
        ],
      ),
      PrayerDetail(
        key: 'Isha',
        title: 'Isha',
        subtitle: 'Night',
        icon: CupertinoIcons.moon_stars_fill,
        time: times.isha,
        subPrayers: const [
          SubPrayerItem(
            id: 'isha_sunnat_1',
            title: 'Sunnat (Before)',
            rakats: 4,
          ),
          SubPrayerItem(id: 'isha_farz', title: 'Farz', rakats: 4),
          SubPrayerItem(
            id: 'isha_sunnat_2',
            title: 'Sunnat (After)',
            rakats: 2,
          ),
          SubPrayerItem(id: 'isha_nafeel', title: 'Nafeel', rakats: 2),
          SubPrayerItem(id: 'isha_wajib', title: 'Wajib (Witr)', rakats: 3),
        ],
      ),
    ];
  }

  void _openPrayerDetail(
    PrayerDetail prayer,
    String dateKey,
    List<String> completedSubIds, {
    bool isFuture = false,
  }) {
    final subItemsWithStatus = prayer.subPrayers.map((item) {
      return item.copyWith(isCompleted: completedSubIds.contains(item.id));
    }).toList();

    PrayerDetailModal.show(
      context: context,
      prayerTitle: prayer.title,
      prayerSubtitle: prayer.subtitle,
      dateKey: dateKey,
      subPrayers: subItemsWithStatus,
      isFuture: isFuture,
      onSave: (completedIds) async {
        final storage = ref.read(storageServiceProvider);
        await storage.setSubPrayerRecords(dateKey, prayer.key, completedIds);
        setState(() {});
      },
    );
  }

  Widget _buildHistoryTab() {
    final storage = ref.watch(storageServiceProvider);

    final datesList = List.generate(_historyFilterDays, (index) {
      return DateTime.now().subtract(Duration(days: index));
    });

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Timeline Filter Header Bar
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Timeline Log',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: (context.isDarkMode
                      ? const Color(0xFF1A2818)
                      : const Color(0xFFF9F9F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _historyFilterDays,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
                      DropdownMenuItem(value: 14, child: Text('Last 2 Weeks')),
                      DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
                      DropdownMenuItem(value: 90, child: Text('Last 3 Months')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _historyFilterDays = val);
                      }
                    },
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of Daily Cards (Recent first)
        ...datesList.map((date) {
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final summary = _getDailyRakatsSummary(storage, dateKey);
          final isFridayDate = date.weekday == DateTime.friday;

          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final todayHijri = ref.watch(todayHijriProvider).value;
          final calPref = ref.watch(calendarPreferenceProvider);

          String hijriStr;
          if (isToday && todayHijri != null) {
            hijriStr = todayHijri.formatted;
          } else {
            final isSubcontinent =
                calPref.calendarType == CalendarType.regional &&
                (calPref.region == HijriRegion.india ||
                    calPref.region == HijriRegion.pakistan ||
                    calPref.region == HijriRegion.bangladesh);
            final hDate = HijriDate.fromGregorian(
              date,
              isSubcontinent: isSubcontinent,
            );
            hijriStr = '${hDate.day} ${hDate.monthNameEn} ${hDate.year} AH';
          }

          return SalahHistoryCard(
            date: date,
            hijriDate: hijriStr,
            completedFarz: summary.completedFarz,
            completedWajib: summary.completedWajib,
            completedSunnat: summary.completedSunnat,
            totalSunnat: isFridayDate ? 24 : 20,
            completedNafeel: summary.completedNafeel,
            onTap: () {
              SalahHistoryDetailModal.show(
                context: context,
                date: date,
                hijriDate: hijriStr,
                storage: storage,
              );
            },
          );
        }),
      ],
    );
  }

  _DailyRakatsSummary _getDailyRakatsSummary(
    StorageService storage,
    String dateKey,
  ) {
    int farz = 0;
    int wajib = 0;
    int sunnat = 0;
    int nafeel = 0;

    const prayerKeys = [
      'Fajr',
      'Ishraq',
      'Shuruq',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
      'Tahajjud',
    ];

    for (final pKey in prayerKeys) {
      final completedSubIds = storage.getSubPrayerRecords(dateKey, pKey);
      for (final id in completedSubIds) {
        switch (id) {
          // Farz (Total 5 prayers)
          case 'fajr_farz':
          case 'dhuhr_farz':
          case 'jumma_farz':
          case 'asr_farz':
          case 'maghrib_farz':
          case 'isha_farz':
            farz += 1;
            break;

          // Wajib (Total 1)
          case 'isha_wajib':
            wajib += 1;
            break;

          // Sunnat (Total 20, or 24 on Friday)
          case 'fajr_sunnat':
            sunnat += 2;
            break;
          case 'dhuhr_sunnat_1':
          case 'jumma_sunnat_1':
            sunnat += 4;
            break;
          case 'dhuhr_sunnat_2':
          case 'jumma_sunnat_2':
            sunnat += 2;
            break;
          case 'jumma_sunnat_3':
            sunnat += 4;
            break;
          case 'asr_sunnat':
            sunnat += 4;
            break;
          case 'maghrib_sunnat':
            sunnat += 2;
            break;
          case 'isha_sunnat_1':
            sunnat += 4;
            break;
          case 'isha_sunnat_2':
            sunnat += 2;
            break;

          // Nafeel (Total 20)
          case 'shuruq_ishraq':
            nafeel += 2;
            break;
          case 'shuruq_chast':
            nafeel += 2;
            break;
          case 'dhuhr_nafeel':
          case 'jumma_nafeel':
            nafeel += 2;
            break;
          case 'maghrib_nafeel':
            nafeel += 2;
            break;
          case 'maghrib_awabeen':
            nafeel += 6;
            break;
          case 'isha_nafeel':
            nafeel += 2;
            break;
          case 'tahajjud_nafeel':
            nafeel += 4;
            break;
        }
      }
    }

    // Fallback if main prayer status toggled directly without sub-prayer checklist
    final oldMainRecords = storage.getSalahRecordsForDate(dateKey);
    if (farz == 0 && oldMainRecords.isNotEmpty) {
      if (oldMainRecords.contains('Fajr')) farz += 1;
      if (oldMainRecords.contains('Dhuhr')) farz += 1;
      if (oldMainRecords.contains('Asr')) farz += 1;
      if (oldMainRecords.contains('Maghrib')) farz += 1;
      if (oldMainRecords.contains('Isha')) farz += 1;
    }

    return _DailyRakatsSummary(
      completedFarz: farz,
      completedWajib: wajib,
      completedSunnat: sunnat,
      completedNafeel: nafeel,
    );
  }
}

class _DailyRakatsSummary {
  final int completedFarz;
  final int completedWajib;
  final int completedSunnat;
  final int completedNafeel;

  const _DailyRakatsSummary({
    required this.completedFarz,
    required this.completedWajib,
    required this.completedSunnat,
    required this.completedNafeel,
  });
}
