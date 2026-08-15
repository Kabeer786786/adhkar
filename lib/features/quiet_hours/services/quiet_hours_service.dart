import 'dart:io';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../domain/quiet_hours_model.dart';

class QuietHoursService {
  static final QuietHoursService _instance = QuietHoursService._internal();
  factory QuietHoursService() => _instance;
  QuietHoursService._internal();

  static const int baseNotificationId = 8880;

  final DoNotDisturbPlugin _dnd = DoNotDisturbPlugin();

  /// Check if the current platform supports system-level DND manipulation
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Check whether Android Notification Policy Access (DND permission) is granted
  Future<bool> isDndPermissionGranted() async {
    if (!isSupported) return false;
    try {
      return await _dnd.isNotificationPolicyAccessGranted();
    } catch (e) {
      debugPrint('Error checking DND permission: $e');
      final status = await Permission.accessNotificationPolicy.status;
      return status.isGranted;
    }
  }

  /// Open Android Notification Policy Access settings page
  Future<void> openDndPermissionSettings() async {
    if (!isSupported) return;
    try {
      await _dnd.openNotificationPolicyAccessSettings();
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
      await openAppSettings();
    }
  }

  /// Get current system interruption filter (1=all, 2=priority, 3=none, 4=alarms)
  Future<int?> getCurrentDndFilter() async {
    if (!isSupported) return null;
    try {
      final filter = await _dnd.getDNDStatus();
      return filter.index;
    } catch (e) {
      debugPrint('Error getting current DND filter: $e');
      return null;
    }
  }

  /// Set system interruption filter using DND policy
  Future<bool> setDndFilter(InterruptionFilter filter) async {
    if (!isSupported) return false;
    try {
      final granted = await isDndPermissionGranted();
      if (!granted) return false;
      await _dnd.setInterruptionFilter(filter);
      return true;
    } catch (e) {
      debugPrint('Error setting DND filter: $e');
      return false;
    }
  }

  /// Synchronize a list of Quiet Hours schedules with the OS and schedule background alarms.
  Future<List<QuietHours>> syncQuietHoursList(
    List<QuietHours> schedules,
    StorageService storageService,
  ) async {
    if (!isSupported || schedules.isEmpty) {
      await _cancelAllBackgroundSchedules(schedules);
      return schedules;
    }

    final hasPermission = await isDndPermissionGranted();
    final now = DateTime.now();

    final activeSchedules = schedules.where((s) => s.enabled && s.isTimeInQuietHours(now)).toList();
    final shouldBeActive = activeSchedules.isNotEmpty;
    final anyAdhkarOwns = schedules.any((s) => s.adhkarOwnsDnd);

    List<QuietHours> updatedList = List.from(schedules);

    if (shouldBeActive && hasPermission) {
      if (!anyAdhkarOwns) {
        // Capture previous filter before Adhkar activates Priority DND
        final currentFilterIndex = await getCurrentDndFilter();
        final success = await setDndFilter(InterruptionFilter.priority);
        if (success) {
          updatedList = updatedList.map((s) {
            if (s.enabled && s.isTimeInQuietHours(now)) {
              return s.copyWith(
                originalDndFilter: currentFilterIndex,
                adhkarOwnsDnd: true,
                updatedAt: now,
              );
            }
            return s;
          }).toList();
        }
      }
    } else {
      if (anyAdhkarOwns) {
        // Quiet Hours ended - restore user's previous system state
        final ownedSchedule = schedules.firstWhere((s) => s.adhkarOwnsDnd, orElse: () => schedules.first);
        await _restoreOriginalDnd(ownedSchedule);
        updatedList = updatedList.map((s) => s.copyWith(adhkarOwnsDnd: false, updatedAt: now)).toList();
      }
    }

    // Save updated list
    await storageService.saveQuietHoursList(updatedList.map((s) => s.toJson()).toList());

    // Schedule background OS alarms for next start & end occurrences
    await _scheduleBackgroundAlarms(updatedList);

    return updatedList;
  }

  Future<void> _restoreOriginalDnd(QuietHours model) async {
    try {
      final originalIndex = model.originalDndFilter;
      InterruptionFilter targetFilter = InterruptionFilter.all;
      if (originalIndex != null &&
          originalIndex >= 0 &&
          originalIndex < InterruptionFilter.values.length) {
        targetFilter = InterruptionFilter.values[originalIndex];
      }
      await setDndFilter(targetFilter);
    } catch (e) {
      debugPrint('Error restoring original DND state: $e');
      await setDndFilter(InterruptionFilter.all);
    }
  }

  Future<void> _scheduleBackgroundAlarms(List<QuietHours> schedules) async {
    try {
      final notificationService = NotificationService();

      for (int i = 0; i < schedules.length; i++) {
        final schedule = schedules[i];
        final idStart = baseNotificationId + (i * 2) + 1;
        final idEnd = baseNotificationId + (i * 2) + 2;

        await notificationService.cancel(idStart);
        await notificationService.cancel(idEnd);

        if (schedule.enabled) {
          final now = DateTime.now();
          final nextStart = schedule.getNextStartOccurrence(now);
          final nextEnd = schedule.getNextEndOccurrence(now);

          await notificationService.scheduleCustomReminderNotification(
            id: idStart,
            title: '${schedule.title} Quiet Hours Started',
            body: 'Do Not Disturb policy is active during ${schedule.title}.',
            scheduledTime: nextStart,
            reminderId: 'quiet_start_${schedule.id}',
          );

          await notificationService.scheduleCustomReminderNotification(
            id: idEnd,
            title: '${schedule.title} Quiet Hours Ended',
            body: 'Quiet Hours ended. Normal notifications restored.',
            scheduledTime: nextEnd,
            reminderId: 'quiet_end_${schedule.id}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling Quiet Hours background alarms: $e');
    }
  }

  Future<void> _cancelAllBackgroundSchedules(List<QuietHours> schedules) async {
    try {
      final notificationService = NotificationService();
      for (int i = 0; i < schedules.length + 5; i++) {
        final idStart = baseNotificationId + (i * 2) + 1;
        final idEnd = baseNotificationId + (i * 2) + 2;
        await notificationService.cancel(idStart);
        await notificationService.cancel(idEnd);
      }
    } catch (e) {
      debugPrint('Error canceling Quiet Hours schedules: $e');
    }
  }
}
