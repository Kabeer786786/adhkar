import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:adhkar/core/services/storage_service.dart';

void main() {
  late StorageService storage;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_test_');
    storage = StorageService();
    await storage.initFromPath(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Registration Modal 3-day Cooldown Tests', () {
    test('Initial state: should prompt if user has never been prompted', () {
      expect(storage.getLastRegistrationPromptDate(), isNull);
      expect(storage.shouldPromptRegistrationModal(), isTrue);
    });

    test('After prompt recorded: should NOT prompt immediately or within 3 days', () async {
      final now = DateTime.now();
      await storage.recordRegistrationPromptDate(now);

      expect(storage.getLastRegistrationPromptDate(), isNotNull);
      // Immediately after recording prompt
      expect(storage.shouldPromptRegistrationModal(), isFalse);

      // 1 day later
      final oneDayLater = now.add(const Duration(days: 1));
      final diffOneDay = oneDayLater.difference(storage.getLastRegistrationPromptDate()!);
      expect(diffOneDay < const Duration(days: 3), isTrue);

      // 2 days and 23 hours later
      final almostThreeDays = now.add(const Duration(days: 2, hours: 23));
      final diffAlmost = almostThreeDays.difference(storage.getLastRegistrationPromptDate()!);
      expect(diffAlmost < const Duration(days: 3), isTrue);
    });

    test('After 3 days: should prompt again', () async {
      // Prompted 3 days and 1 hour ago
      final pastDate = DateTime.now().subtract(const Duration(days: 3, hours: 1));
      await storage.recordRegistrationPromptDate(pastDate);

      expect(storage.shouldPromptRegistrationModal(), isTrue);
    });

    test('Custom interval works correctly', () async {
      final now = DateTime.now().subtract(const Duration(days: 2));
      await storage.recordRegistrationPromptDate(now);

      // With default 3 days interval -> false
      expect(storage.shouldPromptRegistrationModal(interval: const Duration(days: 3)), isFalse);

      // With 1 day interval -> true
      expect(storage.shouldPromptRegistrationModal(interval: const Duration(days: 1)), isTrue);
    });
  });
}
