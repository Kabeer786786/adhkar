import 'dart:async';
import '../models/calendar_type.dart';
import '../models/hijri_date.dart';
import 'local_calendar_data_source.dart';
import 'remote_hijri_data_source.dart';
import '../../services/hijri_service.dart';

class CalendarRepository {
  final LocalCalendarDataSource _local;
  final RemoteHijriDataSource _remote;

  // In-flight request deduplication map to prevent duplicate concurrent network calls
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  CalendarRepository({
    LocalCalendarDataSource? local,
    RemoteHijriDataSource? remote,
  })  : _local = local ?? LocalCalendarDataSource(),
        _remote = remote ?? RemoteHijriDataSource();

  Future<HijriDate?> getHijriDate({
    required DateTime date,
    required CalendarType calendarType,
    required HijriRegion region,
  }) async {
    // 1. Check local cache
    final cached = await _local.getHijriDate(
      date: date,
      calendarType: calendarType,
      region: region,
    );
    if (cached != null) return cached;

    // 2. In-flight request deduplication key
    final dateStr = '${date.year}-${date.month}-${date.day}';
    final requestKey = 'date_${dateStr}_${calendarType.name}_${region.code}';

    if (_inFlightRequests.containsKey(requestKey)) {
      return await (_inFlightRequests[requestKey] as Future<HijriDate?>);
    }

    final fetchFuture = _remote.getHijriDate(
      date: date,
      calendarType: calendarType,
      region: region,
    );
    _inFlightRequests[requestKey] = fetchFuture;

    try {
      final remoteData = await fetchFuture;
      if (remoteData != null) {
        await _local.saveHijriDate(
          date: date,
          calendarType: calendarType,
          region: region,
          hijriDate: remoteData,
        );
      }
      return remoteData;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  Future<HijriCalendarMonthData?> getHijriMonth({
    required int year,
    required int month,
    required CalendarType calendarType,
    required HijriRegion region,
  }) async {
    // 1. Check local cache
    final cached = await _local.getHijriMonth(
      year: year,
      month: month,
      calendarType: calendarType,
      region: region,
    );
    if (cached != null) return cached;

    // 2. Request deduplication
    final requestKey = 'month_${year}_${month}_${calendarType.name}_${region.code}';

    if (_inFlightRequests.containsKey(requestKey)) {
      return await (_inFlightRequests[requestKey] as Future<HijriCalendarMonthData?>);
    }

    final fetchFuture = _remote.getHijriMonth(
      year: year,
      month: month,
      calendarType: calendarType,
      region: region,
    );
    _inFlightRequests[requestKey] = fetchFuture;

    try {
      final remoteData = await fetchFuture;
      if (remoteData != null) {
        await _local.saveHijriMonth(
          year: year,
          month: month,
          calendarType: calendarType,
          region: region,
          monthData: remoteData,
        );
      }
      return remoteData;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }
}
