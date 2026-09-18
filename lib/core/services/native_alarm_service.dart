import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../config/routes/app_router.dart';
import 'alarm_audio_service.dart';

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
        final notifId = data['notif_id'] as int?;

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
        if (notifId != null && notifId != 0) {
          queryParams['notif_id'] = notifId.toString();
        }

        final queryString = Uri(queryParameters: queryParams).query;
        final targetUrl = '/alarm?$queryString';
        _navigateToAlarm(targetUrl);
      }
    } else if (call.method == 'dismissAlarm') {
      try {
        AlarmAudioService().stopAlarm();
      } catch (_) {}
      final currentLoc =
          appRouter.routerDelegate.currentConfiguration.uri.toString();
      if (currentLoc.startsWith('/alarm')) {
        if (appRouter.canPop()) {
          appRouter.pop();
        } else {
          appRouter.go('/');
        }
      }
    }
  }

  static void _navigateToAlarm(String targetUrl) {
    final currentLoc =
        appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (currentLoc == targetUrl) return;

    if (currentLoc.startsWith('/alarm')) {
      appRouter.go(targetUrl);
      return;
    }

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

  /// Checks if the application has permission to launch full-screen intents on Android 14+ (API 34+).
  Future<bool> canUseFullScreenIntent() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return granted ?? true;
    } catch (e) {
      debugPrint('[NativeAlarmService] canUseFullScreenIntent error: $e');
      return true;
    }
  }

  /// Opens the system Settings page for "Special App Access -> Full-Screen Intents" on Android 14+.
  Future<void> openFullScreenIntentSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('openFullScreenIntentSettings');
    } catch (e) {
      debugPrint('[NativeAlarmService] openFullScreenIntentSettings error: $e');
    }
  }

  /// Checks if the device screen is currently locked with keyguard.
  Future<bool> isDeviceLocked() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? locked = await _channel.invokeMethod<bool>('isDeviceLocked');
      return locked ?? false;
    } catch (e) {
      debugPrint('[NativeAlarmService] isDeviceLocked error: $e');
      return false;
    }
  }

  /// Cancels active Android notification for reminderId, prayerName, or notifId.
  Future<void> cancelNotification({String? reminderId, String? prayerName, int? notifId}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('cancelNotification', {
        ?'reminderId': reminderId,
        ?'prayerName': prayerName,
        ?'notifId': notifId,
      });
    } catch (e) {
      debugPrint('[NativeAlarmService] cancelNotification error: $e');
    }
  }
}
