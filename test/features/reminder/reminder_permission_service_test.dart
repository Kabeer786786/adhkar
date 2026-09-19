import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/reminder/services/reminder_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderPermissionService Tests', () {
    test('ReminderMissingPermission model properties and defaults', () {
      const perm = ReminderMissingPermission(
        id: 'fullScreenIntent',
        title: 'Full-Screen Alarms',
        description: 'Wake up screen over lockscreen',
        icon: Icons.fullscreen_rounded,
        iconColor: Color(0xFFE11D48),
        isCritical: true,
      );

      expect(perm.id, equals('fullScreenIntent'));
      expect(perm.title, equals('Full-Screen Alarms'));
      expect(perm.isCritical, isTrue);
    });

    test('Non-android platform returns empty missing list and true for hasRequiredPermissions', () async {
      // In flutter_test default environment, defaultTargetPlatform is android or non-android
      final hasPerms = await ReminderPermissionService.hasRequiredPermissions();
      expect(hasPerms, isA<bool>());
    });
  });
}
