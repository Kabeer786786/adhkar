import 'package:flutter/foundation.dart';
import '../../../core/services/notification_service.dart';
import '../domain/reminder_model.dart';

class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._internal();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._internal();

  final NotificationService _notificationService = NotificationService();

  int generateNotificationId(String reminderId) {
    return reminderId.hashCode.abs() % 100000000;
  }

  Future<void> scheduleReminder(CustomReminder reminder) async {
    final notifId = generateNotificationId(reminder.id);
    
    // Always cancel existing schedule first for idempotency
    await _notificationService.cancel(notifId);

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
        soundType: reminder.soundType ?? 'Default Ringtone',
      );
      debugPrint(
        '[ReminderScheduler] Scheduled ${reminder.title} (ID $notifId) for $nextTrigger',
      );
    }
  }

  Future<void> cancelReminder(String id) async {
    final notifId = generateNotificationId(id);
    await _notificationService.cancel(notifId);
    debugPrint('[ReminderScheduler] Cancelled notification ID $notifId for reminder $id');
  }

  Future<void> rescheduleAll(List<CustomReminder> reminders) async {
    debugPrint('[ReminderScheduler] Rescheduling all ${reminders.length} reminders...');
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }
}
