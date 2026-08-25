import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _notificationSelectController =
      StreamController<String?>.broadcast();

  Stream<String?> get onNotificationSelected =>
      _notificationSelectController.stream;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          _notificationSelectController.add(details.payload);
        }
      },
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) { 
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse?.payload != null) {
      final payload = launchDetails.notificationResponse!.payload;
      if (payload != null && payload.isNotEmpty) {
        // Small delay to ensure listeners are bound
        Future.delayed(const Duration(milliseconds: 500), () {
          _notificationSelectController.add(payload);
        });
      }
    }
    _configureLocalTimezone();
  }

  void _configureLocalTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      // Default to Asia/Kolkata if +05:30 (IST) or attempt to match location by offset
      if (offset.inMinutes == 330) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } else {
        // Try system location or fallback to Asia/Kolkata
        try {
          final tzName = now.timeZoneName;
          if (tzName.isNotEmpty && tz.timeZoneDatabase.locations.containsKey(tzName)) {
            tz.setLocalLocation(tz.getLocation(tzName));
          } else {
            tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
          }
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        }
      }
    } catch (_) {
      // Fallback safeguard
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'adhkar_main_channel_v3',
      'Adhkar Reminders',
      channelDescription: 'Notifications for Prayer Times and Daily Adhkar',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails, payload: payload);
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    bool sound = true,
    bool vibration = true,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'adhkar_prayer_channel_v3',
      'Prayer Alerts',
      channelDescription: 'Adhan and Prayer Time Reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: sound,
      enableVibration: vibration,
      fullScreenIntent: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      'Time for $prayerName Prayer',
      'It is time for $prayerName prayer. Come to success.',
      tzScheduled,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleCustomReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String reminderId,
    bool sound = true,
    bool vibration = true,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'adhkar_reminder_channel_v3',
      'Custom Reminders & Alarms',
      channelDescription: 'Custom Alarm and Adhkar Reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: sound,
      enableVibration: vibration,
      fullScreenIntent: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final payload = 'reminder_id:$reminderId';

    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body.isNotEmpty ? body : 'It\'s time for your scheduled reminder.',
      tzScheduled,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
