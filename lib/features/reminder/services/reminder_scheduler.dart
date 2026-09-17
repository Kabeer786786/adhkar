import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../config/routes/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/native_alarm_service.dart';
import '../domain/reminder_model.dart';

class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._internal();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._internal() {
    _startForegroundWatcher();
  }

  final NotificationService _notificationService = NotificationService();
  Timer? _foregroundTimer;
  List<CustomReminder> _cachedReminders = [];
  final Set<String> _triggeredKeysThisMinute = <String>{};

  /// Secondary in-app UI trigger: pushes AlarmScreen when app is in foreground.
  /// Background notifications are the PRIMARY trigger mechanism.
  void _startForegroundWatcher() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkForegroundTriggers();
    });
  }

  void _checkForegroundTriggers() {
    if (_cachedReminders.isEmpty) return;
    final now = DateTime.now();
    final minuteKey =
        '${now.year}-${now.month}-${now.day}-${now.hour}:${now.minute}';

    for (final reminder in _cachedReminders) {
      if (!reminder.isEnabled) continue;
      if (reminder.isTurnedOffFor(now)) continue;

      if (reminder.hour == now.hour && reminder.minute == now.minute) {
        final triggerId = '${reminder.id}_$minuteKey';
        if (_triggeredKeysThisMinute.contains(triggerId)) continue;

        // Check if reminder is scheduled for today
        if (reminder.frequency == ReminderFrequency.once) {
          final sDate = reminder.startDate ?? now;
          if (sDate.year != now.year ||
              sDate.month != now.month ||
              sDate.day != now.day) {
            continue;
          }
        } else if (reminder.frequency == ReminderFrequency.custom ||
            reminder.frequency == ReminderFrequency.weekly) {
          if (!reminder.customDays.contains(now.weekday)) continue;
        } else if (reminder.frequency == ReminderFrequency.monthly) {
          final targetDay = reminder.startDate?.day ?? now.day;
          if (now.day != targetDay) continue;
        }

        _triggeredKeysThisMinute.add(triggerId);
        final currentLoc = appRouter.routerDelegate.currentConfiguration.uri.toString();
        if (currentLoc.startsWith('/alarm')) {
          debugPrint('[ReminderScheduler] Already on AlarmScreen. Skipping duplicate push.');
          continue;
        }
        debugPrint(
          '[ReminderScheduler] Foreground trigger: Popping AlarmScreen for ${reminder.title}',
        );
        appRouter.push('/alarm?id=${reminder.id}');
      }
    }

    if (now.minute == 0 &&
        now.second == 0 &&
        _triggeredKeysThisMinute.length > 50) {
      _triggeredKeysThisMinute.clear();
    }
  }

  /// Generates a unique notification ID from a reminder ID string.
  int generateNotificationId(String reminderId) {
    return reminderId.hashCode.abs() % 100000000;
  }

  /// Generates a unique per-weekday notification ID by offsetting the base ID.
  /// weekday: 1=Mon ... 7=Sun
  int _generateWeekdayNotificationId(String reminderId, int weekday) {
    final base = generateNotificationId(reminderId);
    // Use high bits to avoid collision: base + (weekday * 100000)
    return (base + weekday * 100000) % 100000000;
  }

  Future<void> scheduleReminder(CustomReminder reminder) async {
    final notifId = generateNotificationId(reminder.id);

    // Cancel all existing notifications for this reminder (base + per-weekday)
    await _cancelAllNotificationsForReminder(reminder.id);

    // Update cache
    _cachedReminders.removeWhere((r) => r.id == reminder.id);
    if (reminder.isEnabled) {
      _cachedReminders.add(reminder);
    }

    if (!reminder.isEnabled) {
      debugPrint(
        '[ReminderScheduler] Reminder ${reminder.id} disabled. Cancelled.',
      );
      return;
    }

    if (!reminder.notificationEnabled) {
      debugPrint(
        '[ReminderScheduler] Reminder ${reminder.id} notification disabled. Skipping schedule.',
      );
      return;
    }

    final nextTrigger = reminder.calculateNextOccurrence(DateTime.now());
    if (nextTrigger == null) {
      debugPrint(
        '[ReminderScheduler] No next occurrence calculated for ${reminder.id}',
      );
      return;
    }

    if (reminder.frequency == ReminderFrequency.custom) {
      // Schedule a SEPARATE notification for EACH custom weekday.
      // Each uses DateTimeComponents.dayOfWeekAndTime so it repeats weekly on that day.
      await _scheduleCustomDayNotifications(reminder);
    } else if (reminder.frequency == ReminderFrequency.monthly) {
      // Monthly: schedule a one-shot notification for the next monthly occurrence.
      // It will be re-scheduled on app startup and on trigger.
      await _notificationService.scheduleCustomReminderNotification(
        id: notifId,
        title: reminder.title,
        body: reminder.description ?? 'It\'s time for your scheduled reminder.',
        scheduledTime: nextTrigger,
        reminderId: reminder.id,
        sound: reminder.soundEnabled,
        vibration: reminder.vibrationEnabled,
        soundType: reminder.soundType ?? 'Iphone Ringtone',
        matchDateTimeComponents: null, // One-shot, re-scheduled on app restart
      );
      debugPrint(
        '[ReminderScheduler] Scheduled monthly ${reminder.title} (ID $notifId) for $nextTrigger',
      );
    } else {
      // Once, Daily, Weekly
      DateTimeComponents? matchComponents;
      if (reminder.frequency == ReminderFrequency.daily) {
        matchComponents = DateTimeComponents.time;
      } else if (reminder.frequency == ReminderFrequency.weekly) {
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
      }
      // once: matchComponents = null (fires once, never repeats)

      await _notificationService.scheduleCustomReminderNotification(
        id: notifId,
        title: reminder.title,
        body: reminder.description ?? 'It\'s time for your scheduled reminder.',
        scheduledTime: nextTrigger,
        reminderId: reminder.id,
        sound: reminder.soundEnabled,
        vibration: reminder.vibrationEnabled,
        soundType: reminder.soundType ?? 'Iphone Ringtone',
        matchDateTimeComponents: matchComponents,
      );
      debugPrint(
        '[ReminderScheduler] Scheduled ${reminder.title} (ID $notifId) for $nextTrigger (recurrence: $matchComponents)',
      );
    }

    // Also schedule exact native Android AlarmManager alarm so alarm screen pops even when app is killed
    await NativeAlarmService.instance.scheduleAlarm(
      id: reminder.id,
      title: reminder.title,
      body: reminder.description ?? 'It\'s time for your scheduled reminder.',
      scheduledTime: nextTrigger,
      sound: reminder.soundEnabled,
      vibration: reminder.vibrationEnabled,
      soundType: reminder.soundType ?? 'Iphone Ringtone',
    );
  }

  /// Schedules one background notification per weekday in [reminder.customDays].
  /// Each notification repeats weekly on its assigned day via DateTimeComponents.dayOfWeekAndTime.
  Future<void> _scheduleCustomDayNotifications(CustomReminder reminder) async {
    final now = DateTime.now();

    for (final weekday in reminder.customDays) {
      final perDayId = _generateWeekdayNotificationId(reminder.id, weekday);

      // Calculate the next occurrence of this specific weekday
      DateTime candidate = DateTime(now.year, now.month, now.day, reminder.hour, reminder.minute);
      if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      while (candidate.weekday != weekday) {
        candidate = candidate.add(const Duration(days: 1));
      }

      await _notificationService.scheduleCustomReminderNotification(
        id: perDayId,
        title: reminder.title,
        body: reminder.description ?? 'It\'s time for your scheduled reminder.',
        scheduledTime: candidate,
        reminderId: reminder.id,
        sound: reminder.soundEnabled,
        vibration: reminder.vibrationEnabled,
        soundType: reminder.soundType ?? 'Iphone Ringtone',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      await NativeAlarmService.instance.scheduleAlarm(
        id: '${reminder.id}_$weekday',
        title: reminder.title,
        body: reminder.description ?? 'It\'s time for your scheduled reminder.',
        scheduledTime: candidate,
        sound: reminder.soundEnabled,
        vibration: reminder.vibrationEnabled,
        soundType: reminder.soundType ?? 'Iphone Ringtone',
      );

      debugPrint(
        '[ReminderScheduler] Scheduled custom-day ${reminder.title} (ID $perDayId) for weekday $weekday at $candidate',
      );
    }
  }

  /// Cancels all notifications for a reminder: the base ID plus all 7 possible per-weekday IDs.
  Future<void> _cancelAllNotificationsForReminder(String reminderId) async {
    final baseId = generateNotificationId(reminderId);
    final allIds = <int>[
      baseId,
      for (int weekday = 1; weekday <= 7; weekday++)
        _generateWeekdayNotificationId(reminderId, weekday),
    ];
    await _notificationService.cancelMultiple(allIds);

    // Cancel native alarms
    await NativeAlarmService.instance.cancelAlarm(reminderId);
    for (int weekday = 1; weekday <= 7; weekday++) {
      await NativeAlarmService.instance.cancelAlarm('${reminderId}_$weekday');
    }
  }

  Future<void> cancelReminder(String id) async {
    _cachedReminders.removeWhere((r) => r.id == id);
    await _cancelAllNotificationsForReminder(id);
    debugPrint(
      '[ReminderScheduler] Cancelled all notifications for reminder $id',
    );
  }

  /// Re-schedules all reminders. Called on app startup and boot to ensure
  /// background notifications survive app kill, reboot, and updates.
  Future<void> rescheduleAll(List<CustomReminder> reminders) async {
    _cachedReminders = List<CustomReminder>.from(reminders);
    debugPrint(
      '[ReminderScheduler] Rescheduling all ${reminders.length} reminders...',
    );
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }
}
