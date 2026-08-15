import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
import '../../../shared/widgets/hijri_disclaimer_chip.dart';
import '../domain/prayer_models.dart';
import 'widgets/prayer_detail_modal.dart'; 
import 'widgets/salah_history_card.dart';
import 'widgets/salah_history_detail_modal.dart';

import '../../../shared/widgets/app_shimmer.dart';
import '../../../shared/widgets/location_selection_modal.dart';
import '../data/repositories/aladhan_repository.dart';
import 'providers/aladhan_providers.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen>
    with SingleTickerProviderStateMixin { 
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isChangingDate = false;

  int _historyFilterDays = 7; // Default 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final todayHijri = ref.watch(todayHijriProvider).value;
    final calPref = ref.watch(calendarPreferenceProvider);

    String hijriStr;
    if (isToday && todayHijri != null) {
      hijriStr = todayHijri.formatted;
    } else {
      final isSubcontinent = calPref.calendarType == CalendarType.regional &&
          (calPref.region == HijriRegion.india ||
              calPref.region == HijriRegion.pakistan ||
              calPref.region == HijriRegion.bangladesh);
      final hDate = HijriDate.fromGregorian(_selectedDate, isSubcontinent: isSubcontinent);
      hijriStr = '${hDate.day} ${hDate.monthNameEn} ${hDate.year} AH';
    }
    final isAladhan = todayHijri?.isAladhan ?? false;

    final prayerList = _buildPrayerList(prayerTimes);

    final locationDisplayName = location.country.isNotEmpty
        ? '${location.city}, ${location.country}' 
        : location.city;

    return ListView(
      physics: const BouncingScrollPhysics(),
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
            color: context.colorScheme.primaryContainer.withValues(alpha: 0.4),
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
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: isApiSuccess ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(
              //         isApiSuccess ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
              //         size: 12,
              //         color: isApiSuccess ? Colors.green : Colors.orange,
              //       ),
              //       const SizedBox(width: 4),
              //       Text(
              //         isApiSuccess ? 'AlAdhan API' : 'Calculated',
              //         style: TextStyle(
              //           fontSize: 10,
              //           fontWeight: FontWeight.bold,
              //           color: isApiSuccess ? Colors.green[800] : Colors.orange[800],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onPressed: () => LocationSelectionModal.show(context),
              ),
            ],
          ),
        ),
        // --- Top Header Card: Gregorian Date, Hijri Date, Calendar Icon ---
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 0, left: 5, right: 5),
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
            children: prayerList.map((prayer) {
              final isCurrent =
                  isToday &&
                  (currentPrayer?.name == prayer.key ||
                      (currentPrayer?.name == 'Fajr' && prayer.key == 'Fajr'));
              final timeStr = DateFormat('hh:mm a').format(prayer.time);

              final storage = ref.watch(storageServiceProvider);

              // Get completed sub-prayers
              final completedSubIds = storage.getSubPrayerRecords(
                dateKey,
                prayer.key,
              );

              // Check card highlight color
              final isHighlight = isCurrent && !prayer.isZawal;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: prayer.isZawal
                        ? null
                        : () => _openPrayerDetail(prayer, dateKey, completedSubIds),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 24,
                        top: 14,
                        bottom: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isHighlight
                            ? (context.isDarkMode
                                  ? const Color(0xFF133629)
                                  : const Color(0xFFE6F4EA))
                            : (context.isDarkMode
                                  ? const Color(0xFF1A2818)
                                  : const Color(0xFFF9F9F9)),
                        borderRadius: BorderRadius.circular(16),
                        border: isHighlight
                            ? Border.all(color: const Color(0xFF10B981), width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          // Weather/Sky Icon in Circular Container
                          Icon(
                            prayer.icon,
                            color: isHighlight
                                ? const Color(0xFF047857)
                                : _getPrayerIconColor(prayer.key, context),
                            size: 28,
                          ),
                          const SizedBox(width: 16),

                          // Prayer Name & Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prayer.title,
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isHighlight
                                        ? (context.isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF064E3B))
                                        : context.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 0),
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
                              fontSize: 16,
                              color: isHighlight
                                  ? (context.isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF064E3B))
                                  : context.colorScheme.onSurface,
                            ),
                          ),

                          if (prayer.isZawal)
                            Icon(
                              Icons.block_rounded,
                              size: 20,
                              color: context.colorScheme.outline,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Color _getPrayerIconColor(String prayerKey, BuildContext context) {
    switch (prayerKey) {
      case 'Fajr':
        return const Color(0xFF0284C7);
      case 'Shuruq':
        return const Color(0xFFF59E0B);
      case 'Dhuhr':
        return const Color(0xFFD97706);
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

  List<PrayerDetail> _buildPrayerList(PrayerTimeResult times) {
    return [
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
        key: 'Ish',
        title: 'Shuruq',
        subtitle: 'Sunrise',
        icon: CupertinoIcons.sunrise_fill,
        time: times.sunrise,
        subPrayers: const [
          SubPrayerItem(id: 'shuruq_ishraq', title: 'Ishraq Nafeel', rakats: 2),
          SubPrayerItem(id: 'shuruq_chast', title: 'Chast Nafeel', rakats: 2),
        ],
      ),
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
      PrayerDetail(
        key: 'Tahajjud',
        title: 'Tahajjud',
        subtitle: 'Late Night',
        icon: CupertinoIcons.moon_stars_fill,
        time: times.qiyam,
        subPrayers: const [
          SubPrayerItem(id: 'tahajjud_nafeel', title: 'Nafeel', rakats: 4),
        ],
      ),
    ];
  }

  void _openPrayerDetail(
    PrayerDetail prayer,
    String dateKey,
    List<String> completedSubIds,
  ) {
    final subItemsWithStatus = prayer.subPrayers.map((item) {
      return item.copyWith(isCompleted: completedSubIds.contains(item.id));
    }).toList();

    PrayerDetailModal.show(
      context: context,
      prayerTitle: prayer.title,
      prayerSubtitle: prayer.subtitle,
      dateKey: dateKey,
      subPrayers: subItemsWithStatus,
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

          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final todayHijri = ref.watch(todayHijriProvider).value;
          final calPref = ref.watch(calendarPreferenceProvider);

          String hijriStr;
          if (isToday && todayHijri != null) {
            hijriStr = todayHijri.formatted;
          } else {
            final isSubcontinent = calPref.calendarType == CalendarType.regional &&
                (calPref.region == HijriRegion.india ||
                    calPref.region == HijriRegion.pakistan ||
                    calPref.region == HijriRegion.bangladesh);
            final hDate = HijriDate.fromGregorian(date, isSubcontinent: isSubcontinent);
            hijriStr = '${hDate.day} ${hDate.monthNameEn} ${hDate.year} AH';
          }

          return SalahHistoryCard(
            date: date,
            hijriDate: hijriStr,
            completedFarz: summary.completedFarz,
            completedWajib: summary.completedWajib,
            completedSunnat: summary.completedSunnat,
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
          case 'asr_farz':
          case 'maghrib_farz':
          case 'isha_farz':
            farz += 1;
            break;

          // Wajib (Total 1)
          case 'isha_wajib':
            wajib += 1;
            break;

          // Sunnat (Total 20)
          case 'fajr_sunnat':
            sunnat += 2;
            break;
          case 'dhuhr_sunnat_1':
            sunnat += 4;
            break;
          case 'dhuhr_sunnat_2':
            sunnat += 2;
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
