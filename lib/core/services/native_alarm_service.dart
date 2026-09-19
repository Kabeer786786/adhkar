import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../config/routes/app_router.dart';
import 'alarm_audio_service.dart';

enum VolumeButtonAction {
  stopAlarm('stopAlarm', 'Stop Alarm', 'Stop alarm sound & vibration immediately and clear active alert.'),
  snoozeAlarm('snoozeAlarm', 'Snooze Alarm', 'Silence alarm immediately and ring again after the snooze duration.'),
  doNothing('doNothing', 'Do Nothing', 'Keep alarm ringing and allow normal volume adjustment.');

  final String value;
  final String title;
  final String description;

  const VolumeButtonAction(this.value, this.title, this.description);

  static VolumeButtonAction fromValue(String? val) {
    return VolumeButtonAction.values.firstWhere(
      (e) => e.value == val,
      orElse: () => VolumeButtonAction.stopAlarm,
    );
  }
}

enum ScreenOffAction {
  stopAlarm('stopAlarm', 'Stop Alarm', 'Stop sound and vibration when screen turns off or power button is pressed.'),
  continueAlarm('continueAlarm', 'Continue Alarm', 'Keep ringing until explicitly dismissed or snoozed.');

  final String value;
  final String title;
  final String description;

  const ScreenOffAction(this.value, this.title, this.description);

  static ScreenOffAction fromValue(String? val) {
    return ScreenOffAction.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ScreenOffAction.continueAlarm,
    );
  }
}

/// Service interfacing with native Android AlarmScheduler, AlarmReceiver, and AlarmStateManager.
/// Ensures alarms accurately trigger, dismiss, and snooze with synchronized state.
class NativeAlarmService {
  static final NativeAlarmService instance = NativeAlarmService._();
  NativeAlarmService._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel =
      MethodChannel('com.sprnt.adhkar/alarm_scheduler');

  static final StreamController<String> _dismissAlarmController =
      StreamController<String>.broadcast();
  static Stream<String> get onDismissAlarm => _dismissAlarmController.stream;

  static final StreamController<int> _snoozeAlarmController =
      StreamController<int>.broadcast();
  static Stream<int> get onSnoozeAlarm => _snoozeAlarmController.stream;

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
      final args = call.arguments as Map<dynamic, dynamic>?;
      final reason = args?['reason'] as String? ?? 'NativeDismiss';
      try {
        AlarmAudioService().stopAlarm();
      } catch (_) {}
      _dismissAlarmController.add(reason);
      _closeAlarmRouteIfOpen();
    } else if (call.method == 'onAlarmSnoozed') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final minutes = (args?['minutes'] as num?)?.toInt() ?? 10;
      try {
        AlarmAudioService().stopAlarm();
      } catch (_) {}
      _snoozeAlarmController.add(minutes);
      _closeAlarmRouteIfOpen();
    }
  }

  static void _closeAlarmRouteIfOpen() {
    try {
      final currentLoc =
          appRouter.routerDelegate.currentConfiguration.uri.toString();
      if (currentLoc.startsWith('/alarm')) {
        if (appRouter.canPop()) {
          appRouter.pop();
        } else {
          appRouter.go('/');
        }
      }
    } catch (_) {}
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
        if (reminderId != null) 'reminderId': reminderId,
        if (prayerName != null) 'prayerName': prayerName,
        if (notifId != null) 'notifId': notifId,
      });
    } catch (e) {
      debugPrint('[NativeAlarmService] cancelNotification error: $e');
    }
  }

  /// Retrieves persisted native interaction settings for volume button & screen-off behavior.
  Future<Map<String, String>> getAlarmInteractionSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return {
        'volumeButtonAction': VolumeButtonAction.stopAlarm.value,
        'screenOffAction': ScreenOffAction.continueAlarm.value,
      };
    }
    try {
      final res = await _channel.invokeMethod('getAlarmInteractionSettings');
      if (res is Map) {
        return Map<String, String>.from(res.map((k, v) => MapEntry(k.toString(), v.toString())));
      }
    } catch (e) {
      debugPrint('[NativeAlarmService] getAlarmInteractionSettings error: $e');
    }
    return {
      'volumeButtonAction': VolumeButtonAction.stopAlarm.value,
      'screenOffAction': ScreenOffAction.continueAlarm.value,
    };
  }

  /// Persists alarm interaction settings to native SharedPreferences.
  Future<void> saveAlarmInteractionSettings({
    required VolumeButtonAction volumeButtonAction,
    required ScreenOffAction screenOffAction,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('saveAlarmInteractionSettings', {
        'volumeButtonAction': volumeButtonAction.value,
        'screenOffAction': screenOffAction.value,
      });
    } catch (e) {
      debugPrint('[NativeAlarmService] saveAlarmInteractionSettings error: $e');
    }
  }

  /// Centralized, idempotent stop function across Flutter & Native Android.
  Future<bool> stopActiveAlarm({required String reason}) async {
    try {
      await AlarmAudioService().stopAlarm();
    } catch (_) {}

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final bool? res = await _channel.invokeMethod<bool>('stopActiveAlarm', {
          'reason': reason,
        });
        return res ?? true;
      } catch (e) {
        debugPrint('[NativeAlarmService] stopActiveAlarm error: $e');
      }
    }
    return true;
  }

  /// Reliable snooze workflow that silences current alarm and schedules snooze.
  Future<bool> snoozeActiveAlarm({required String reason, int minutes = 10}) async {
    try {
      await AlarmAudioService().stopAlarm();
    } catch (_) {}

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final bool? res = await _channel.invokeMethod<bool>('snoozeActiveAlarm', {
          'reason': reason,
          'minutes': minutes,
        });
        return res ?? true;
      } catch (e) {
        debugPrint('[NativeAlarmService] snoozeActiveAlarm error: $e');
      }
    }
    return true;
  }

  /// Checks if native alarm is currently actively ringing.
  Future<bool> isAlarmActive() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AlarmAudioService().isPlaying;
    }
    try {
      final bool? active = await _channel.invokeMethod<bool>('isAlarmActive');
      return active ?? false;
    } catch (e) {
      debugPrint('[NativeAlarmService] isAlarmActive error: $e');
      return false;
    }
  }

  /// Informs native Android that an alarm has started ringing in Flutter.
  /// Activates MediaSession volume key interception and registers ScreenOff listener.
  Future<void> notifyAlarmStarted({
    String? reminderId,
    String? title,
    String? soundType,
    String? prayerName,
    int? notifId,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('notifyAlarmStarted', {
        'reminderId': reminderId,
        'title': title,
        'soundType': soundType,
        'prayerName': prayerName,
        'notifId': notifId,
      });
    } catch (e) {
      debugPrint('[NativeAlarmService] notifyAlarmStarted error: $e');
    }
  }

  /// Informs native Android that the active alarm was stopped or dismissed in Flutter.
  Future<void> notifyAlarmStopped({String reason = 'FlutterAlarmStopped'}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('notifyAlarmStopped', {'reason': reason});
    } catch (e) {
      debugPrint('[NativeAlarmService] notifyAlarmStopped error: $e');
    }
  }
}
