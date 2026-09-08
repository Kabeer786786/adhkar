import 'dart:convert';
import 'dart:io';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../domain/quiet_hours_model.dart';

class QuietHoursService {
  static final QuietHoursService _instance = QuietHoursService._internal();
  factory QuietHoursService() => _instance;
  QuietHoursService._internal();

  static const MethodChannel _channel = MethodChannel('com.sprnt.adhkar/quiet_hours');
  static const int baseLegacyNotificationId = 8880;

  final DoNotDisturbPlugin _dnd = DoNotDisturbPlugin();

  /// Check if the current platform supports system-level DND manipulation
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Check whether Android Notification Policy Access (DND permission) is granted
  Future<bool> isDndPermissionGranted() async {
    if (!isSupported) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('isDndPermissionGranted');
      if (granted != null) return granted;
    } catch (_) {}

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
      final opened = await _channel.invokeMethod<bool>('openDndSettings');
      if (opened == true) return;
    } catch (_) {}

    try {
      await _dnd.openNotificationPolicyAccessSettings();
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
      await openAppSettings();
    }
  }

  /// Open Android's native Do Not Disturb automation & schedules system page
  Future<void> openDndSchedulesSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('openDndSchedulesSettings');
    } catch (e) {
      debugPrint('Error opening DND schedules settings: $e');
      await openDndPermissionSettings();
    }
  }

  /// Get current system interruption filter (1=all, 2=priority, 3=none, 4=alarms)
  Future<int?> getCurrentDndFilter() async {
    if (!isSupported) return null;
    try {
      final filter = await _channel.invokeMethod<int>('getDndFilter');
      if (filter != null) return filter;
    } catch (_) {}

    try {
      final filter = await _dnd.getDNDStatus();
      return filter.index;
    } catch (e) {
      debugPrint('Error getting current DND filter: $e');
      return null;
    }
  }

  /// Set system interruption filter using DND policy directly
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

  /// Enable or disable DND mode silently
  Future<bool> setDndMode(bool enable) async {
    if (!isSupported) return false;
    try {
      final success = await _channel.invokeMethod<bool>('setDndMode', {'enable': enable});
      return success ?? false;
    } catch (e) {
      debugPrint('Error setting native DND mode: $e');
      final target = enable ? InterruptionFilter.priority : InterruptionFilter.all;
      return await setDndFilter(target);
    }
  }

  /// Checks whether Quiet Hours is active right now
  Future<bool> isQuietHoursCurrentlyActive(List<QuietHours>? fallbackSchedules) async {
    if (!isSupported) return false;
    try {
      final active = await _channel.invokeMethod<bool>('isQuietHoursActive');
      if (active != null) return active;
    } catch (_) {}

    if (fallbackSchedules != null && fallbackSchedules.isNotEmpty) {
      final now = DateTime.now();
      return fallbackSchedules.any((s) => s.enabled && s.isTimeInQuietHours(now));
    }
    return false;
  }

  /// Synchronize a list of Quiet Hours schedules with the native OS AlarmManager engine.
  /// Purely silent: NO notifications, NO alarms, NO sounds.
  Future<List<QuietHours>> syncQuietHoursList(
    List<QuietHours> schedules,
    StorageService storageService,
  ) async {
    // Cancel any old legacy notifications so no remnant alerts ever appear
    await _cancelLegacyNotifications();

    if (!isSupported || schedules.isEmpty) {
      await _cancelAllNativeAlarms();
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
        final currentFilterIndex = await getCurrentDndFilter();
        final success = await setDndMode(true);
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
        await setDndMode(false);
        updatedList = updatedList.map((s) => s.copyWith(adhkarOwnsDnd: false, updatedAt: now)).toList();
      }
    }

    // Save updated list to Hive local storage
    await storageService.saveQuietHoursList(updatedList.map((s) => s.toJson()).toList());

    // Schedule exact native background alarms in Android AlarmManager
    await _scheduleNativeBackgroundAlarms(updatedList);

    return updatedList;
  }

  /// Registers exact alarms in Android AlarmManager via native MethodChannel.
  /// These alarms wake up QuietHoursReceiver even when the app is completely closed or screen is off.
  Future<void> _scheduleNativeBackgroundAlarms(List<QuietHours> schedules) async {
    if (!isSupported) return;
    try {
      final jsonList = schedules.map((s) => s.toJson()).toList();
      final schedulesJson = jsonEncode(jsonList);
      await _channel.invokeMethod('scheduleQuietHours', {
        'schedulesJson': schedulesJson,
      });
      debugPrint('[QuietHoursService] Synchronized ${schedules.length} schedules with native AlarmManager.');
    } catch (e) {
      debugPrint('Error scheduling native Quiet Hours alarms: $e');
    }
  }

  /// Cancels all native alarms
  Future<void> _cancelAllNativeAlarms() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('cancelAllQuietHours');
    } catch (e) {
      debugPrint('Error canceling native Quiet Hours alarms: $e');
    }
  }

  /// Cancels any remnant notifications scheduled by older versions of Quiet Hours
  Future<void> _cancelLegacyNotifications() async {
    try {
      final notificationService = NotificationService();
      for (int id = baseLegacyNotificationId; id <= baseLegacyNotificationId + 100; id++) {
        await notificationService.cancel(id);
      }
    } catch (e) {
      debugPrint('Error cleaning up legacy quiet notifications: $e');
    }
  }
}
