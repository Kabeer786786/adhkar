import '../models/calendar_type.dart';
import '../models/regional_calendar_rule.dart';

/// Resolves regional offset rules and computes the shifted target Gregorian date.
class RegionalCalendarResolver {
  /// Resolves target Gregorian date for Hijri conversion based on regional rules.
  /// Shifts Gregorian date (e.g. gregorianDate + (-1 day)) rather than modifying Hijri numbers directly.
  DateTime resolveTargetGregorianDate({
    required DateTime gregorianDate,
    required CalendarType calendarType,
    required HijriRegion region,
    int? customOffsetOverride,
  }) {
    if (calendarType == CalendarType.global || region == HijriRegion.global) {
      return gregorianDate;
    }

    final rule = HijriRegionConfig.getRuleForRegion(region);
    if (!rule.usesRegionalCalendar) {
      return gregorianDate;
    }

    final offsetDays = customOffsetOverride ?? rule.defaultOffsetDays;
    return gregorianDate.add(Duration(days: offsetDays));
  }

  /// Retrieves the numeric day offset for a region.
  int getOffsetDays({
    required CalendarType calendarType,
    required HijriRegion region,
    int? customOffsetOverride,
  }) {
    if (calendarType == CalendarType.global || region == HijriRegion.global) {
      return 0;
    }
    final rule = HijriRegionConfig.getRuleForRegion(region);
    if (!rule.usesRegionalCalendar) return 0;
    return customOffsetOverride ?? rule.defaultOffsetDays;
  }
}
