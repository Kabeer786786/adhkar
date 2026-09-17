import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../config/routes/app_router.dart';

/// Service interfacing with native Android AlarmScheduler & AlarmReceiver.
/// Ensures alarms accurately trigger the AlarmScreen even when the app is closed/killed.
class NativeAlarmService {
  static final NativeAlarmService instance = NativeAlarmService._();
  NativeAlarmService._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel =
      MethodChannel('com.sprnt.adhkar/alarm_scheduler');

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onAlarmTriggered') {
      final data = call.arguments as Map<dynamic, dynamic>?;
      if (data != null) {
        final reminderId = data['reminder_id'] as String?;
        final prayerName = data['prayer_name'] as String?;
        final title = data['alarm_title'] as String?;
        final soundType = data['sound_type'] as String?;

        final queryParams = <String, String>{};
        if (reminderId != null && reminderId.isNotEmpty) {
          queryParams['id'] = reminderId;
        }
        if (prayerName != null && prayerName.isNotEmpty) {
          queryParams['prayer'] = prayerName;
        }
        if (title != null && title.isNotEmpty) {
          queryParams['title'] = title;
        }
        if (soundType != null && soundType.isNotEmpty) {
          queryParams['sound'] = soundType;
        }

        final queryString = Uri(queryParameters: queryParams).query;
        final targetUrl = '/alarm?$queryString';
        _navigateToAlarm(targetUrl);
      }
    } else if (call.method == 'dismissAlarm') {
      final currentLoc =
          appRouter.routerDelegate.currentConfiguration.uri.toString();
      if (currentLoc.startsWith('/alarm') && appRouter.canPop()) {
        appRouter.pop();
      }
    }
  }

  static void _navigateToAlarm(String targetUrl) {
    final currentLoc =
        appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (currentLoc == targetUrl || currentLoc.startsWith('/alarm')) return;

    if (currentLoc == '/' || currentLoc.isEmpty || currentLoc == '/splash') {
      appRouter.go(targetUrl);
    } else {
      appRouter.push(targetUrl);
    }
  }

  Future<void> scheduleAlarm({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool sound = true,
    bool vibration = true,
    String soundType = 'Default Ringtone',
    String? prayerName,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'id': id,
        'title': title,
        'body': body,
        'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
        'sound': sound,
        'vibration': vibration,
        'soundType': soundType,
        'prayerName': prayerName,
      });
    } catch (e) {
      debugPrint('[NativeAlarmService] scheduleAlarm error: $e');
    }
  }

  Future<void> cancelAlarm(String id) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
    } catch (e) {
      debugPrint('[NativeAlarmService] cancelAlarm error: $e');
    }
  }

  Future<void> cancelAllAlarms() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('cancelAllAlarms');
    } catch (e) {
      debugPrint('[NativeAlarmService] cancelAllAlarms error: $e');
    }
  }

  Future<Map<String, dynamic>?> getPendingAlarm() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final res = await _channel.invokeMethod('getPendingAlarm');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('[NativeAlarmService] getPendingAlarm error: $e');
    }
    return null;
  }
}
