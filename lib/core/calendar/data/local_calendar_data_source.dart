import 'package:hive_flutter/hive_flutter.dart';
import '../models/calendar_type.dart';
import '../models/hijri_date.dart';
import 'hijri_calendar_data_source.dart';
import '../../services/hijri_service.dart';

class LocalCalendarDataSource implements HijriCalendarDataSource {
  static const String _boxName = 'hijri_calendar_cache_box';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  String _dateKey(DateTime date, CalendarType type, HijriRegion region) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'date_${dateStr}_${type.name}_${region.code}';
  }

  String _monthKey(int year, int month, CalendarType type, HijriRegion region) {
    return 'month_${year}_${month}_${type.name}_${region.code}';
  }

  @override
  Future<HijriDate?> getHijriDate({
    required DateTime date,
    required CalendarType calendarType,
    required HijriRegion region,
  }) async {
    try {
      final box = await _getBox();
      final key = _dateKey(date, calendarType, region);
      final raw = box.get(key);
      if (raw != null && raw is Map) {
        return HijriDate.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveHijriDate({
    required DateTime date,
    required CalendarType calendarType,
    required HijriRegion region,
    required HijriDate hijriDate,
  }) async {
    try {
      final box = await _getBox();
      final key = _dateKey(date, calendarType, region);
      await box.put(key, hijriDate.toJson());
    } catch (_) {}
  }

  @override
  Future<HijriCalendarMonthData?> getHijriMonth({
    required int year,
    required int month,
    required CalendarType calendarType,
    required HijriRegion region,
  }) async {
    try {
      final box = await _getBox();
      final key = _monthKey(year, month, calendarType, region);
      final raw = box.get(key);
      if (raw != null && raw is Map) {
        return HijriCalendarMonthData.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveHijriMonth({
    required int year,
    required int month,
    required CalendarType calendarType,
    required HijriRegion region,
    required HijriCalendarMonthData monthData,
  }) async {
    try {
      final box = await _getBox();
      final key = _monthKey(year, month, calendarType, region);
      await box.put(key, monthData.toJson());
    } catch (_) {}
  }
}
