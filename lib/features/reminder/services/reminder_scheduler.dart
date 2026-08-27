import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../config/routes/app_router.dart';
import '../../../core/services/notification_service.dart';
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
        }

        _triggeredKeysThisMinute.add(triggerId);
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

  int generateNotificationId(String reminderId) {
    return reminderId.hashCode.abs() % 100000000;
  }

  Future<void> scheduleReminder(CustomReminder reminder) async {
    final notifId = generateNotificationId(reminder.id);

    // Always cancel existing schedule first for idempotency
    await _notificationService.cancel(notifId);

    // Update cache
    _cachedReminders.removeWhere((r) => r.id == reminder.id);
    if (reminder.isEnabled) {
      _cachedReminders.add(reminder);
    }

    if (!reminder.isEnabled) {
      debugPrint('[ReminderScheduler] Reminder ${reminder.id} disabled. Cancelled.');
      return;
    }

    final nextTrigger = reminder.calculateNextOccurrence(DateTime.now());
    if (nextTrigger == null) {
      debugPrint('[ReminderScheduler] No next occurrence calculated for ${reminder.id}');
      return;
    }

    if (reminder.notificationEnabled) {
      await _notificationService.scheduleCustomReminderNotification(
        id: notifId,
        title: reminder.title,
        body: reminder.description ?? 'It\'s time for your scheduled reminder.',
        scheduledTime: nextTrigger,
        reminderId: reminder.id,
        sound: reminder.soundEnabled,
        vibration: reminder.vibrationEnabled,
        soundType: reminder.soundType ?? 'Iphone Ringtone',
      );
      debugPrint(
        '[ReminderScheduler] Scheduled ${reminder.title} (ID $notifId) for $nextTrigger',
      );
    }
  }

  Future<void> cancelReminder(String id) async {
    _cachedReminders.removeWhere((r) => r.id == id);
    final notifId = generateNotificationId(id);
    await _notificationService.cancel(notifId);
    debugPrint('[ReminderScheduler] Cancelled notification ID $notifId for reminder $id');
  }

  Future<void> rescheduleAll(List<CustomReminder> reminders) async {
    _cachedReminders = List<CustomReminder>.from(reminders);
    debugPrint('[ReminderScheduler] Rescheduling all ${reminders.length} reminders...');
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }
}
