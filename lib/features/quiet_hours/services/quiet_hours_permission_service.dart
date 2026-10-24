import 'package:flutter/material.dart';
import 'quiet_hours_service.dart';

class QuietHoursMissingPermission {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isCritical;

  const QuietHoursMissingPermission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.isCritical = true,
  });
}

class QuietHoursPermissionService {
  /// Checks permissions needed for Quiet Hours.
  /// DND access is required on Android to silence notifications and calls.
  /// Battery optimization is optional.
  static Future<List<QuietHoursMissingPermission>> getMissingPermissions() async {
    final service = QuietHoursService();
    if (!service.isSupported) {
      return [];
    }

    final List<QuietHoursMissingPermission> missing = [];

    // 1. Do Not Disturb (DND) / Notification Policy Access - REQUIRED
    try {
      final isDndGranted = await service.isDndPermissionGranted();
      if (!isDndGranted) {
        missing.add(
          const QuietHoursMissingPermission(
            id: 'dnd',
            title: 'Do Not Disturb (DND) Access',
            description:
                'Required: Adhkar needs Do Not Disturb permission to automatically silence calls, notifications, and alerts during your quiet hours.',
            icon: Icons.do_not_disturb_on_rounded,
            iconColor: Color(0xFF9333EA),
            isCritical: true,
          ),
        );
      }
    } catch (_) {}

    // 2. Battery Optimization - OPTIONAL
    try {
      final batteryIgnored = await service.isBatteryOptimizationIgnored();
      if (!batteryIgnored) {
        missing.add(
          const QuietHoursMissingPermission(
            id: 'battery',
            title: 'Unrestricted Background Battery',
            description:
                'Optional: Prevents Android from delaying quiet hours background schedules during aggressive power-saving mode.',
            icon: Icons.battery_charging_full_rounded,
            iconColor: Color(0xFF059669),
            isCritical: false,
          ),
        );
      }
    } catch (_) {}

    return missing;
  }

  /// Returns true if all critical permissions required for Quiet Hours are granted.
  static Future<bool> hasRequiredPermissions() async {
    final service = QuietHoursService();
    if (!service.isSupported) return true;
    final dndGranted = await service.isDndPermissionGranted();
    return dndGranted;
  }
}
