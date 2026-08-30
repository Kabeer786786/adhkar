import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../calendar/models/calendar_type.dart';
import '../calendar/providers/calendar_providers.dart';
import '../utils/hijri_date.dart';
import '../../shared/providers/app_providers.dart';

class HijriDateData {
  final int day;
  final int monthNumber;
  final String monthEn;
  final String monthAr;
  final int year;
  final String formatted;
  final String region;
  final String source;
  final bool isAladhan;

  const HijriDateData({
    required this.day,
    required this.monthNumber,
    required this.monthEn,
    required this.monthAr,
    required this.year,
    required this.formatted,
    required this.region,
    required this.source,
    required this.isAladhan,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'monthNumber': monthNumber,
    'monthEn': monthEn,
    'monthAr': monthAr,
    'year': year,
    'formatted': formatted,
    'region': region,
    'source': source,
    'isAladhan': isAladhan,
  };

  factory HijriDateData.fromJson(Map<String, dynamic> json) {
    return HijriDateData(
      day: (json['day'] as num?)?.toInt() ?? 1,
      monthNumber: (json['monthNumber'] as num?)?.toInt() ?? 1,
      monthEn: json['monthEn'] as String? ?? 'Muharram',
      monthAr: json['monthAr'] as String? ?? 'مُحَرَّم',
      year: (json['year'] as num?)?.toInt() ?? 1448,
      formatted: json['formatted'] as String? ?? '',
      region: json['region'] as String? ?? 'Global',
      source: json['source'] as String? ?? '',
      isAladhan: json['isAladhan'] as bool? ?? false,
    );
  }

  factory HijriDateData.fromAlgorithmic(
    DateTime date, {
    String region = 'Local',
    int dayOffset = 0,
  }) {
    final hijri = HijriDate.fromGregorian(date, dayOffset: dayOffset);
    return HijriDateData(
      day: hijri.day,
      monthNumber: hijri.month,
      monthEn: hijri.monthNameEn,
      monthAr: hijri.monthNameAr,
      year: hijri.year,
      formatted: '${hijri.day} ${hijri.monthNameEn} ${hijri.year} AH',
      region: region,
      source: 'algorithmic',
      isAladhan: false,
    );
  }
}

class HijriCalendarDayData {
  final int hijriDay;
  final int gregorianDay;
  final String gregorianMonth;
  final int gregorianYear;
  final String gregorianWeekday;
  final int dayOfWeek;

  const HijriCalendarDayData({
    required this.hijriDay,
    required this.gregorianDay,
    required this.gregorianMonth,
    required this.gregorianYear,
    required this.gregorianWeekday,
    required this.dayOfWeek,
  });

  Map<String, dynamic> toJson() => {
    'hijri_day': hijriDay,
    'gregorian_day': gregorianDay,
    'gregorian_month': gregorianMonth,
    'gregorian_year': gregorianYear,
    'gregorian_weekday': gregorianWeekday,
    'day_of_week': dayOfWeek,
  };

  factory HijriCalendarDayData.fromJson(Map<String, dynamic> json) {
    return HijriCalendarDayData(
      hijriDay: (json['hijri_day'] as num?)?.toInt() ?? 1,
      gregorianDay: (json['gregorian_day'] as num?)?.toInt() ?? 1,
      gregorianMonth: json['gregorian_month'] as String? ?? '',
      gregorianYear: (json['gregorian_year'] as num?)?.toInt() ?? 2026,
      gregorianWeekday: json['gregorian_weekday'] as String? ?? '',
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
    );
  }
}

class HijriCalendarMonthData {
  final int monthNumber;
  final String monthEn;
  final String monthAr;
  final int year;
  final int totalDays;
  final List<HijriCalendarDayData> days;
  final bool isAladhan;

  const HijriCalendarMonthData({
    required this.monthNumber,
    required this.monthEn,
    required this.monthAr,
    required this.year,
    required this.totalDays,
    required this.days,
    required this.isAladhan,
  });

  Map<String, dynamic> toJson() => {
    'monthNumber': monthNumber,
    'monthEn': monthEn,
    'monthAr': monthAr,
    'year': year,
    'totalDays': totalDays,
    'days': days.map((d) => d.toJson()).toList(),
    'isAladhan': isAladhan,
  };

  factory HijriCalendarMonthData.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List? ?? [];
    return HijriCalendarMonthData(
      monthNumber: (json['monthNumber'] as num?)?.toInt() ?? 1,
      monthEn: json['monthEn'] as String? ?? '',
      monthAr: json['monthAr'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 1448,
      totalDays: (json['totalDays'] as num?)?.toInt() ?? rawDays.length,
      days: rawDays
          .map(
            (e) => HijriCalendarDayData.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      isAladhan: json['isAladhan'] as bool? ?? false,
    );
  }
}

class HijriService {
  final Dio _dio;
  static const String _chandKiTarikhBaseUrl =
      'https://chandkitarikh.today/api.php';
  static const String _aladhanBaseUrl = 'https://api.aladhan.com/v1';

  HijriService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {'Accept': 'application/json'},
            ),
          );

  static bool isChandKiTarikhRegion(String? country) {
    if (country == null || country.trim().isEmpty)
      return true; // Default India/Subcontinent
    final c = country.trim().toLowerCase();
    return c.contains('india') ||
        c.contains('pakistan') ||
        c.contains('bangladesh') ||
        c == 'in' ||
        c == 'pk' ||
        c == 'bd';
  }

  /// Get today's Hijri Date with 12 AM daily cache rule.
  /// Dynamically computes and updates regional day offset for IN/PK/BD vs standard math.
  Future<HijriDateData> getTodayHijriDate({
    String? country,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final isSubcontinent = isChandKiTarikhRegion(country);
    final targetRegionKey = isSubcontinent ? (country ?? 'India') : 'Aladhan';

    try {
      final box = await Hive.openBox('hijri_cache_box');
      final cachedDateKey = box.get('hijri_today_date_key') as String?;
      final cachedRegionKey = box.get('hijri_today_region_key') as String?;
      final cachedRaw = box.get('hijri_today_data');

      // Daily cache hit check
      if (cachedDateKey == todayKey &&
          cachedRegionKey == targetRegionKey &&
          cachedRaw != null &&
          cachedRaw is Map) {
        return HijriDateData.fromJson(Map<String, dynamic>.from(cachedRaw));
      }

      // If new day (past 12 AM) or region changed, clear old cache & fetch fresh
      if (cachedDateKey != todayKey || cachedRegionKey != targetRegionKey) {
        await box.delete('hijri_today_data');
      }

      HijriDateData freshData;
      int computedOffset = 0;

      if (isSubcontinent) {
        freshData = await _fetchChandKiTarikhToday();
        // Compute day offset relative to standard un-offset algorithmic math for today
        final algorithmicStandard = HijriDate.fromGregorian(now, dayOffset: 0);
        computedOffset = freshData.day - algorithmicStandard.day;
        // If day wrapped across month boundary (e.g. 1 vs 30), normalize offset
        if (computedOffset > 15) computedOffset -= 30;
        if (computedOffset < -15) computedOffset += 30;
        if (computedOffset == 0)
          computedOffset = -1; // Default -1 offset for South Asia
      } else {
        freshData = await _fetchAladhanToday(
          date: now,
          latitude: latitude,
          longitude: longitude,
        );
        computedOffset = 0;
      }

      // Store regional offset in cache for past history & app-wide sync
      await box.put('hijri_regional_day_offset', computedOffset);
      await box.put('hijri_today_date_key', todayKey);
      await box.put('hijri_today_region_key', targetRegionKey);
      await box.put('hijri_today_data', freshData.toJson());

      return freshData;
    } catch (e) {
      // Return cached data if available on error, otherwise fallback to algorithmic with offset
      try {
        final box = await Hive.openBox('hijri_cache_box');
        final cachedRaw = box.get('hijri_today_data');
        if (cachedRaw != null && cachedRaw is Map) {
          return HijriDateData.fromJson(Map<String, dynamic>.from(cachedRaw));
        }
      } catch (_) {}

      final defaultOffset = isSubcontinent ? -1 : 0;
      return HijriDateData.fromAlgorithmic(
        now,
        region: country ?? 'Local',
        dayOffset: defaultOffset,
      );
    }
  }

  Future<HijriDateData> _fetchChandKiTarikhToday() async {
    final response = await _dio.get('$_chandKiTarikhBaseUrl?endpoint=today');
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data['data'];
      if (data != null && data['hijri'] != null) {
        final hijri = data['hijri'];
        final month = hijri['month'] ?? {};
        final day = (hijri['day'] as num).toInt();
        final monthNum = (month['number'] as num).toInt();
        final monthEn = month['en'] as String? ?? '';
        final monthAr = month['ar'] as String? ?? '';
        final year = (hijri['year'] as num).toInt();
        final formatted =
            hijri['formatted'] as String? ?? '$day $monthEn $year AH';
        final region = data['region'] as String? ?? 'India';

        return HijriDateData(
          day: day,
          monthNumber: monthNum,
          monthEn: monthEn,
          monthAr: monthAr,
          year: year,
          formatted: formatted,
          region: region,
          source: 'chandkitarikh',
          isAladhan: false,
        );
      }
    }
    throw Exception('Failed to parse chandkitarikh today response');
  }

  Future<HijriDateData> _fetchAladhanToday({
    required DateTime date,
    double? latitude,
    double? longitude,
  }) async {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    final query = <String, dynamic>{};
    if (latitude != null && longitude != null) {
      query['latitude'] = latitude;
      query['longitude'] = longitude;
    }

    final url = latitude != null && longitude != null
        ? '$_aladhanBaseUrl/timings/$formattedDate'
        : '$_aladhanBaseUrl/gToH/$formattedDate';

    final response = await _dio.get(url, queryParameters: query);
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data['data'];
      final hijri = (data != null && data['date'] != null)
          ? data['date']['hijri']
          : (data != null && data['hijri'] != null ? data['hijri'] : data);

      if (hijri != null) {
        final day = int.tryParse(hijri['day'].toString()) ?? date.day;
        final month = hijri['month'] ?? {};
        final monthNum = (month['number'] as num?)?.toInt() ?? 1;
        final monthEn = month['en'] as String? ?? '';
        final monthAr = month['ar'] as String? ?? '';
        final year = int.tryParse(hijri['year'].toString()) ?? 1448;
        final formatted = '$day $monthEn $year AH';

        return HijriDateData(
          day: day,
          monthNumber: monthNum,
          monthEn: monthEn,
          monthAr: monthAr,
          year: year,
          formatted: formatted,
          region: 'Global',
          source: 'aladhan',
          isAladhan: true,
        );
      }
    }
    throw Exception('Failed to parse Aladhan today response');
  }

  /// Get monthly calendar with month caching.
  /// Past & previously loaded months are saved in cache so no re-fetching is required.
  Future<HijriCalendarMonthData> getCalendarMonth(
    int hijriYear,
    int hijriMonth, {
    String? country,
    double? latitude,
    double? longitude,
  }) async {
    final isSubcontinent = isChandKiTarikhRegion(country);

    if (isSubcontinent) {
      return _buildSubcontinentMonthData(hijriYear, hijriMonth);
    }

    final targetRegionKey = 'Aladhan';
    final cacheKey = 'month_cal_${targetRegionKey}_${hijriYear}_$hijriMonth';

    try {
      final box = await Hive.openBox('hijri_cache_box');
      final cachedRaw = box.get(cacheKey);
      if (cachedRaw != null && cachedRaw is Map) {
        return HijriCalendarMonthData.fromJson(
          Map<String, dynamic>.from(cachedRaw),
        );
      }

      final monthData = await _fetchAladhanHijriCalendar(
        hijriYear,
        hijriMonth,
        latitude: latitude,
        longitude: longitude,
      );

      // Save in cache
      await box.put(cacheKey, monthData.toJson());

      return monthData;
    } catch (e) {
      return _buildFallbackMonthData(
        hijriYear,
        hijriMonth,
        isSubcontinent: false,
      );
    }
  }

  Future<HijriCalendarMonthData> _fetchAladhanHijriCalendar(
    int hijriYear,
    int hijriMonth, {
    double? latitude,
    double? longitude,
  }) async {
    final lat = latitude ?? 28.6139; // Delhi default
    final lng = longitude ?? 77.2090;

    final response = await _dio.get(
      '$_aladhanBaseUrl/hijriCalendar/$hijriYear/$hijriMonth',
      queryParameters: {'latitude': lat, 'longitude': lng},
    );

    if (response.statusCode == 200 && response.data is Map) {
      final rawList = response.data['data'] as List? ?? [];
      if (rawList.isNotEmpty) {
        final firstItem = rawList.first;
        final firstHijri = firstItem['date']['hijri'];
        final monthEn = firstHijri['month']['en'] as String? ?? '';
        final monthAr = firstHijri['month']['ar'] as String? ?? '';

        final days = <HijriCalendarDayData>[];
        for (final item in rawList) {
          final hDate = item['date']['hijri'];
          final gDate = item['date']['gregorian'];

          final hDay = int.parse(hDate['day'].toString());
          final gDay = int.parse(gDate['day'].toString());
          final gMonth = gDate['month']['en'] as String? ?? '';
          final gYear = int.parse(gDate['year'].toString());
          final gWeekday = gDate['weekday']['en'] as String? ?? '';

          // Determine dayOfWeek (0=Sun, 1=Mon... 6=Sat)
          int dow = 0;
          switch (gWeekday.toLowerCase()) {
            case 'sunday':
              dow = 0;
              break;
            case 'monday':
              dow = 1;
              break;
            case 'tuesday':
              dow = 2;
              break;
            case 'wednesday':
              dow = 3;
              break;
            case 'thursday':
              dow = 4;
              break;
            case 'friday':
              dow = 5;
              break;
            case 'saturday':
              dow = 6;
              break;
          }

          days.add(
            HijriCalendarDayData(
              hijriDay: hDay,
              gregorianDay: gDay,
              gregorianMonth: gMonth,
              gregorianYear: gYear,
              gregorianWeekday: gWeekday,
              dayOfWeek: dow,
            ),
          );
        }

        return HijriCalendarMonthData(
          monthNumber: hijriMonth,
          monthEn: monthEn,
          monthAr: monthAr,
          year: hijriYear,
          totalDays: days.length,
          days: days,
          isAladhan: true,
        );
      }
    }
    throw Exception('Failed to fetch Aladhan hijri calendar');
  }

  /// Convert Gregorian Date (YYYY-MM-DD) to Hijri Date with regional -1 offset for IN/PK/BD
  Future<HijriDateData> convertGregorianToHijri(
    DateTime date, {
    String? country,
  }) async {
    final isSubcontinent = isChandKiTarikhRegion(country);

    if (isSubcontinent) {
      final hDate = HijriDate.fromGregorian(date, isSubcontinent: true);
      return HijriDateData(
        day: hDate.day,
        monthNumber: hDate.month,
        monthEn: hDate.monthNameEn,
        monthAr: hDate.monthNameAr,
        year: hDate.year,
        formatted: '${hDate.day} ${hDate.monthNameEn} ${hDate.year} AH',
        region: country ?? 'India',
        source: 'subcontinent_anchor',
        isAladhan: false,
      );
    } else {
      try {
        final aladhanFormatted = DateFormat('dd-MM-yyyy').format(date);
        final response = await _dio.get(
          '$_aladhanBaseUrl/gToH/$aladhanFormatted',
        );
        if (response.statusCode == 200 && response.data is Map) {
          final data = response.data['data'];
          final hijri = data != null ? data['hijri'] : null;
          if (hijri != null) {
            final day = int.parse(hijri['day'].toString());
            final month = hijri['month'] ?? {};
            final monthNum = (month['number'] as num).toInt();
            final monthEn = month['en'] as String? ?? '';
            final monthAr = month['ar'] as String? ?? '';
            final year = int.parse(hijri['year'].toString());

            return HijriDateData(
              day: day,
              monthNumber: monthNum,
              monthEn: monthEn,
              monthAr: monthAr,
              year: year,
              formatted: '$day $monthEn $year AH',
              region: 'Global',
              source: 'aladhan',
              isAladhan: true,
            );
          }
        }
      } catch (_) {}
    }

    final offset = isSubcontinent ? -1 : 0;
    return HijriDateData.fromAlgorithmic(
      date,
      region: country ?? 'Local',
      dayOffset: offset,
    );
  }

  HijriCalendarMonthData _buildFallbackMonthData(
    int year,
    int month, {
    required bool isSubcontinent,
  }) {
    const monthNamesEn = [
      'Muharram',
      'Safar',
      'Rabi\' al-Awwal',
      'Rabi\' al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhul-Qi\'dah',
      'Dhul-Hijjah',
    ];
    const monthNamesAr = [
      'مُحَرَّم',
      'صَفَر',
      'رَبِيع الأَوَّل',
      'رَبِيع الآخِر',
      'جُمَادَى الأُولَى',
      'جُمَادَى الآخِرَة',
      'رَجَب',
      'شَعْبَان',
      'رَمَضَان',
      'شَوَّال',
      'ذُو القَعْدَة',
      'ذُو الحِجَّة',
    ];

    final days = <HijriCalendarDayData>[];
    for (int i = 1; i <= 29; i++) {
      days.add(
        HijriCalendarDayData(
          hijriDay: i,
          gregorianDay: i,
          gregorianMonth: 'Fallback',
          gregorianYear: 2026,
          gregorianWeekday: 'Day',
          dayOfWeek: (i % 7),
        ),
      );
    }

    return HijriCalendarMonthData(
      monthNumber: month,
      monthEn: monthNamesEn[(month - 1).clamp(0, 11)],
      monthAr: monthNamesAr[(month - 1).clamp(0, 11)],
      year: year,
      totalDays: 29,
      days: days,
      isAladhan: !isSubcontinent,
    );
  }

  HijriCalendarMonthData _buildSubcontinentMonthData(int year, int month) {
    const monthNamesEn = [
      'Muharram',
      'Safar',
      'Rabi\' al-Awwal',
      'Rabi\' al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhul-Qi\'dah',
      'Dhul-Hijjah',
    ];
    const monthNamesAr = [
      'مُحَرَّم',
      'صَفَر',
      'رَبِيع الأَوَّل',
      'رَبِيع الآخِر',
      'جُمَادَى الأُولَى',
      'جُمَادَى الآخِرَة',
      'رَجَب',
      'شَعْبَان',
      'رَمَضَان',
      'شَوَّال',
      'ذُو القَعْدَة',
      'ذُو الحِجَّة',
    ];

    const monthLengths = [30, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    final totalDays = monthLengths[(month - 1) % 12];

    final anchorGregorian = DateTime(2026, 8, 15);
    int monthsDiff = month - 3 + (year - 1448) * 12;

    DateTime firstDayGregorian = anchorGregorian;
    if (monthsDiff > 0) {
      int daysToAdd = 0;
      for (int m = 3; m < 3 + monthsDiff; m++) {
        daysToAdd += monthLengths[(m - 1) % 12];
      }
      firstDayGregorian = anchorGregorian.add(Duration(days: daysToAdd));
    } else if (monthsDiff < 0) {
      int daysToSub = 0;
      for (int m = 2; m >= 3 + monthsDiff; m--) {
        daysToSub += monthLengths[(m - 1) % 12];
      }
      firstDayGregorian = anchorGregorian.subtract(Duration(days: daysToSub));
    }

    final days = <HijriCalendarDayData>[];
    for (int d = 1; d <= totalDays; d++) {
      final currentGDate = firstDayGregorian.add(Duration(days: d - 1));
      days.add(
        HijriCalendarDayData(
          hijriDay: d,
          gregorianDay: currentGDate.day,
          gregorianMonth: DateFormat('MMM').format(currentGDate),
          gregorianYear: currentGDate.year,
          gregorianWeekday: DateFormat('EEE').format(currentGDate),
          dayOfWeek: currentGDate.weekday % 7,
        ),
      );
    }

    return HijriCalendarMonthData(
      monthNumber: month,
      monthEn: monthNamesEn[(month - 1) % 12],
      monthAr: monthNamesAr[(month - 1) % 12],
      year: year,
      totalDays: totalDays,
      days: days,
      isAladhan: false,
    );
  }
}

// --- Riverpod Providers ---

final hijriServiceProvider = Provider<HijriService>((ref) {
  return HijriService();
});

final todayHijriProvider = FutureProvider<HijriDateData>((ref) async {
  final service = ref.watch(hijriServiceProvider);
  final locationAsync = ref.watch(currentLocationProvider);
  final calPref = ref.watch(calendarPreferenceProvider);
  final location = locationAsync.value;

  final activeRegion =
      calPref.region == HijriRegion.global && location?.country != null
      ? HijriRegionExtension.fromCountryCode(location!.country)
      : calPref.region;

  final countryCode = calPref.calendarType == CalendarType.global
      ? 'GLOBAL'
      : activeRegion.code;

  return await service.getTodayHijriDate(
    country: countryCode,
    latitude: location?.latitude,
    longitude: location?.longitude,
  );
});
