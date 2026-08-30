import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../models/calendar_type.dart';
import '../models/hijri_date.dart';
import 'hijri_calendar_data_source.dart';
import '../../services/hijri_service.dart';

class RemoteHijriDataSource implements HijriCalendarDataSource {
  final Dio _dio;

  RemoteHijriDataSource({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<HijriDate?> getHijriDate({
    required DateTime date,
    required CalendarType calendarType,
    required HijriRegion region,
  }) async {
    final isSubcontinent =
        calendarType == CalendarType.regional &&
        (region == HijriRegion.india ||
            region == HijriRegion.pakistan ||
            region == HijriRegion.bangladesh);

    if (isSubcontinent) {
      try {
        final res = await _dio.get(
          'https://chandkitarikh.today/api.php?endpoint=today',
          options: Options(responseType: ResponseType.json),
        );
        if (res.data is Map && res.data['success'] == true) {
          final data = res.data['data']['hijri'];
          final gData = res.data['data']['gregorian'];
          final apiDateStr = gData['date'] as String?;
          final todayStr = DateFormat('yyyy-MM-dd').format(date);

          if (apiDateStr == todayStr) {
            return HijriDate(
              day: (data['day'] as num).toInt(),
              month: (data['month']['number'] as num).toInt(),
              year: (data['year'] as num).toInt(),
              monthNameEn: data['month']['en'] as String,
              monthNameAr: data['month']['ar'] as String,
              weekday: DateFormat('EEEE').format(date),
              formatted: data['formatted'] as String,
              region: region.displayName,
              source: 'chandkitarikh.today',
              isAladhan: false,
            );
          }
        }
      } catch (_) {}
    }

    // Fallback to Aladhan API for global or non-today dates
    try {
      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final url = 'https://api.aladhan.com/v1/gToH/$dateStr';
      final res = await _dio.get(url);
      if (res.data is Map && res.data['code'] == 200) {
        final hijri = res.data['data']['hijri'];
        return HijriDate(
          day: int.parse(hijri['day'].toString()),
          month: int.parse(hijri['month']['number'].toString()),
          year: int.parse(hijri['year'].toString()),
          monthNameEn: hijri['month']['en'].toString(),
          monthNameAr: hijri['month']['ar'].toString(),
          weekday: hijri['weekday']['en'].toString(),
          formatted:
              '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH',
          region: 'Global',
          source: 'aladhan.com',
          isAladhan: true,
        );
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<HijriCalendarMonthData?> getHijriMonth({
    required int year,
    required int month,
    required CalendarType calendarType,
    required HijriRegion region,
  }) async {
    final isSubcontinent =
        calendarType == CalendarType.regional &&
        (region == HijriRegion.india ||
            region == HijriRegion.pakistan ||
            region == HijriRegion.bangladesh);

    if (isSubcontinent) {
      return _buildSubcontinentMonthData(year, month);
    }

    // Fallback to Aladhan monthly calendar API
    try {
      final url = 'https://api.aladhan.com/v1/gToHCalendar/$month/$year';
      final res = await _dio.get(url);
      if (res.data is Map && res.data['code'] == 200) {
        final daysRaw = res.data['data'] as List? ?? [];
        final days = <HijriCalendarDayData>[];

        for (var d in daysRaw) {
          final h = d['hijri'];
          final g = d['gregorian'];
          days.add(
            HijriCalendarDayData(
              hijriDay: int.parse(h['day'].toString()),
              gregorianDay: int.parse(g['day'].toString()),
              gregorianMonth: g['month']['en'].toString(),
              gregorianYear: int.parse(g['year'].toString()),
              gregorianWeekday: g['weekday']['en'].toString(),
              dayOfWeek: 0,
            ),
          );
        }

        if (days.isNotEmpty) {
          final firstH = daysRaw.first['hijri'];
          return HijriCalendarMonthData(
            monthNumber: int.parse(firstH['month']['number'].toString()),
            monthEn: firstH['month']['en'].toString(),
            monthAr: firstH['month']['ar'].toString(),
            year: int.parse(firstH['year'].toString()),
            totalDays: days.length,
            days: days,
            isAladhan: true,
          );
        }
      }
    } catch (_) {}

    return null;
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
