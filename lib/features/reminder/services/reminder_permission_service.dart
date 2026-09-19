import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/native_alarm_service.dart';

class ReminderMissingPermission {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isCritical;

  const ReminderMissingPermission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.isCritical = true,
  });
}

class ReminderPermissionService {
  /// Checks all permissions required for Reminders to ring reliably when the app is closed or screen is off.
  static Future<List<ReminderMissingPermission>> getMissingPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return [];
    }

    final List<ReminderMissingPermission> missing = [];

    // 1. Notification Permission (Android 13+ / API 33+)
    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        missing.add(
          const ReminderMissingPermission(
            id: 'notification',
            title: 'Notification Access',
            description:
                'Required to display reminder alerts, banner notifications, and audible sound.',
            icon: Icons.notifications_active_rounded,
            iconColor: Color(0xFF2563EB),
            isCritical: true,
          ),
        );
      }
    } catch (_) {}

    // 2. Exact Alarm Permission (Android 12+ / API 31+)
    try {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (!alarmStatus.isGranted) {
        missing.add(
          const ReminderMissingPermission(
            id: 'alarm',
            title: 'Exact Alarm & Scheduling',
            description:
                'Required to trigger reminders at the exact scheduled second without power-saving delays.',
            icon: Icons.alarm_rounded,
            iconColor: Color(0xFFD97724),
            isCritical: true,
          ),
        );
      }
    } catch (_) {}

    // 3. Full-Screen Intent Permission (Android 14+ / API 34+)
    try {
      final canFsi = await NativeAlarmService.instance.canUseFullScreenIntent();
      if (!canFsi) {
        missing.add(
          const ReminderMissingPermission(
            id: 'fullScreenIntent',
            title: 'Full-Screen Alarms',
            description:
                'Required to wake up your screen and display the alarm UI over the lock screen when your phone is off.',
            icon: Icons.fullscreen_rounded,
            iconColor: Color(0xFFE11D48),
            isCritical: true,
          ),
        );
      }
    } catch (_) {}

    // 4. Ignore Battery Optimizations (Unrestricted Background Execution)
    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        missing.add(
          const ReminderMissingPermission(
            id: 'battery',
            title: 'Unrestricted Background Battery',
            description:
                'Prevents Android from putting alarms to sleep or killing the app while in the background.',
            icon: Icons.battery_charging_full_rounded,
            iconColor: Color(0xFF059669),
            isCritical: true,
          ),
        );
      }
    } catch (_) {}

    // 5. System Alert Window / Appear On Top (Needed by OEMs like Xiaomi, Oppo, Vivo, Samsung)
    try {
      final overlayStatus = await Permission.systemAlertWindow.status;
      if (!overlayStatus.isGranted) {
        missing.add(
          const ReminderMissingPermission(
            id: 'systemAlertWindow',
            title: 'Display Over Other Apps',
            description:
                'Allows the full-screen alarm screen to immediately pop up when the app is in the background or closed.',
            icon: Icons.layers_outlined,
            iconColor: Color(0xFFF59E0B),
            isCritical: false,
          ),
        );
      }
    } catch (_) {}

    return missing;
  }

  /// Returns true if all critical permissions needed for Reminders & Alarms are granted.
  static Future<bool> hasRequiredPermissions() async {
    final missing = await getMissingPermissions();
    return missing.where((p) => p.isCritical).isEmpty;
  }
}
