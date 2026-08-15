import '../models/calendar_type.dart';
import '../models/hijri_date.dart';
import '../../services/hijri_service.dart';

/// Abstract data source interface for retrieving Hijri date and calendar data.
abstract class HijriCalendarDataSource {
  Future<HijriDate?> getHijriDate({
    required DateTime date,
    required CalendarType calendarType,
    required HijriRegion region,
  });

  Future<HijriCalendarMonthData?> getHijriMonth({
    required int year,
    required int month,
    required CalendarType calendarType,
    required HijriRegion region,
  });
}
