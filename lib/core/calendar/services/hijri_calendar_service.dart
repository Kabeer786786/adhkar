import '../data/calendar_repository.dart';
import '../models/calendar_type.dart';
import '../models/hijri_date.dart';
import 'regional_calendar_resolver.dart';
import '../../utils/hijri_date.dart' as util;
import '../../services/hijri_service.dart';

class HijriCalendarService {
  final CalendarRepository _repository;
  final RegionalCalendarResolver _resolver;

  HijriCalendarService({
    CalendarRepository? repository,
    RegionalCalendarResolver? resolver,
  })  : _repository = repository ?? CalendarRepository(),
        _resolver = resolver ?? RegionalCalendarResolver();

  /// Returns the exact [HijriDate] for a given [gregorianDate], applying regional date-shifting rules.
  Future<HijriDate> getHijriDate({
    required DateTime gregorianDate,
    required CalendarType calendarType,
    required HijriRegion region,
    int? customOffsetOverride,
  }) async {
    final cleanGregorianDate = DateTime(
      gregorianDate.year,
      gregorianDate.month,
      gregorianDate.day,
    );

    // 1. Calculate shifted target Gregorian date based on regional rules
    final targetGregorianDate = _resolver.resolveTargetGregorianDate(
      gregorianDate: cleanGregorianDate,
      calendarType: calendarType,
      region: region,
      customOffsetOverride: customOffsetOverride,
    );

    // 2. Query repository for the target Gregorian date
    final repoResult = await _repository.getHijriDate(
      date: targetGregorianDate,
      calendarType: calendarType,
      region: region,
    );

    if (repoResult != null) {
      return repoResult;
    }

    // 3. Fallback to anchor/algorithmic calculation on the target Gregorian date
    final isSubcontinent = calendarType == CalendarType.regional &&
        (region == HijriRegion.india ||
            region == HijriRegion.pakistan ||
            region == HijriRegion.bangladesh);

    final localHijri = util.HijriDate.fromGregorian(
      targetGregorianDate,
      isSubcontinent: isSubcontinent,
    );

    return HijriDate(
      day: localHijri.day,
      month: localHijri.month,
      year: localHijri.year,
      monthNameEn: localHijri.monthNameEn,
      monthNameAr: localHijri.monthNameAr,
      weekday: _getWeekdayName(targetGregorianDate.weekday),
      formatted: '${localHijri.day} ${localHijri.monthNameEn} ${localHijri.year} AH',
      region: region.displayName,
      source: 'algorithmic',
      isAladhan: false,
    );
  }

  /// Retrieves full monthly calendar dataset.
  Future<HijriCalendarMonthData?> getHijriMonth({
    required int year,
    required int month,
    required CalendarType calendarType,
    required HijriRegion region,
  }) async {
    return await _repository.getHijriMonth(
      year: year,
      month: month,
      calendarType: calendarType,
      region: region,
    );
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
      default:
        return 'Sunday';
    }
  }
}
