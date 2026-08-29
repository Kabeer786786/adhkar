import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/reminder/domain/reminder_model.dart';
import 'package:adhkar/features/reminder/services/reminder_scheduler.dart';

void main() {
  group('CustomReminder Model Tests', () {
    test('Serialization and Deserialization works correctly', () {
      final now = DateTime(2026, 8, 15, 10, 0);
      final reminder = CustomReminder(
        id: 'test_rem_1',
        title: 'Read Morning Adhkar',
        description: 'Ayatul Kursi & Adhkar',
        hour: 6,
        minute: 30,
        startDate: DateTime(2026, 8, 15),
        frequency: ReminderFrequency.daily,
        customDays: const [1, 2, 3, 4, 5, 6, 7],
        duration: AlarmDuration.seconds30,
        soundEnabled: true,
        vibrationEnabled: true,
        notificationEnabled: true,
        isEnabled: true,
        turnedOffDate: null,
        createdAt: now,
        updatedAt: now,
        timezone: 'Asia/Kolkata',
      );

      final json = reminder.toJson();
      final restored = CustomReminder.fromJson(json);

      expect(restored.id, equals('test_rem_1'));
      expect(restored.title, equals('Read Morning Adhkar'));
      expect(restored.description, equals('Ayatul Kursi & Adhkar'));
      expect(restored.hour, equals(6));
      expect(restored.minute, equals(30));
      expect(restored.frequency, equals(ReminderFrequency.daily));
      expect(restored.customDays, equals([1, 2, 3, 4, 5, 6, 7]));
      expect(restored.duration, equals(AlarmDuration.seconds30));
      expect(restored.soundEnabled, isTrue);
      expect(restored.vibrationEnabled, isTrue);
      expect(restored.notificationEnabled, isTrue);
      expect(restored.isEnabled, isTrue);
      expect(restored.turnedOffDate, isNull);
    });

    test('Formatted days text helper formats correctly', () {
      final dailyRem = CustomReminder(
        id: '1',
        title: 'Test',
        hour: 8,
        minute: 0,
        frequency: ReminderFrequency.daily,
        customDays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timezone: 'UTC',
      );
      expect(dailyRem.formattedDays, equals('Every day'));

      final weekdayRem = CustomReminder(
        id: '2',
        title: 'Test',
        hour: 8,
        minute: 0,
        frequency: ReminderFrequency.custom,
        customDays: const [1, 2, 3, 4, 5],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timezone: 'UTC',
      );
      expect(weekdayRem.formattedDays, equals('Weekdays'));

      final weekendRem = CustomReminder(
        id: '3',
        title: 'Test',
        hour: 8,
        minute: 0,
        frequency: ReminderFrequency.custom,
        customDays: const [6, 7],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timezone: 'UTC',
      );
      expect(weekendRem.formattedDays, equals('Weekends'));
    });
  });

  group('Next Occurrence Calculation Strategy Tests', () {
    test('Daily frequency calculates today if in future, else tomorrow', () {
      final fromTime = DateTime(2026, 8, 15, 6, 0); // 6:00 AM on 15 Aug 2026

      // Reminder set for 6:30 AM
      final remLater = CustomReminder(
        id: 'rem_later',
        title: 'Morning',
        hour: 6,
        minute: 30,
        frequency: ReminderFrequency.daily,
        createdAt: fromTime,
        updatedAt: fromTime,
        timezone: 'UTC',
      );

      final nextLater = remLater.calculateNextOccurrence(fromTime);
      expect(nextLater, equals(DateTime(2026, 8, 15, 6, 30)));

      // Reminder set for 5:30 AM (already past for today)
      final remEarlier = CustomReminder(
        id: 'rem_earlier',
        title: 'Early',
        hour: 5,
        minute: 30,
        frequency: ReminderFrequency.daily,
        createdAt: fromTime,
        updatedAt: fromTime,
        timezone: 'UTC',
      );

      final nextEarlier = remEarlier.calculateNextOccurrence(fromTime);
      expect(nextEarlier, equals(DateTime(2026, 8, 16, 5, 30)));
    });

    test('Turn off today skips today occurrence and schedules for tomorrow', () {
      final fromTime = DateTime(2026, 8, 15, 6, 0); // 6:00 AM on 15 Aug 2026

      final remTurnedOffToday = CustomReminder(
        id: 'rem_skipped',
        title: 'Skipped Today',
        hour: 6,
        minute: 30,
        frequency: ReminderFrequency.daily,
        turnedOffDate: '2026-08-15',
        createdAt: fromTime,
        updatedAt: fromTime,
        timezone: 'UTC',
      );

      final next = remTurnedOffToday.calculateNextOccurrence(fromTime);
      expect(next, equals(DateTime(2026, 8, 16, 6, 30))); // Scheduled for 16th (Tomorrow)
    });

    test('Turn off today automatically reactivates on the next day', () {
      final nextDay = DateTime(2026, 8, 16, 6, 0); // 6:00 AM on 16 Aug 2026

      final remSkippedYesterday = CustomReminder(
        id: 'rem_skipped',
        title: 'Skipped Yesterday',
        hour: 6,
        minute: 30,
        frequency: ReminderFrequency.daily,
        turnedOffDate: '2026-08-15', // Turned off yesterday
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
        timezone: 'UTC',
      );

      final next = remSkippedYesterday.calculateNextOccurrence(nextDay);
      expect(next, equals(DateTime(2026, 8, 16, 6, 30))); // Active today!
    });

    test('Custom weekday reminders find the next matching day', () {
      // 15 Aug 2026 is Saturday (weekday 6)
      final saturday15 = DateTime(2026, 8, 15, 10, 0);

      // Scheduled for Monday (1) and Friday (5) at 9:00 AM
      final customRem = CustomReminder(
        id: 'custom_rem',
        title: 'Mon & Fri',
        hour: 9,
        minute: 0,
        frequency: ReminderFrequency.custom,
        customDays: const [1, 5],
        createdAt: saturday15,
        updatedAt: saturday15,
        timezone: 'UTC',
      );

      final next = customRem.calculateNextOccurrence(saturday15);
      // Next matching day after Saturday is Monday 17 Aug 2026
      expect(next, equals(DateTime(2026, 8, 17, 9, 0)));
    });

    test('Disabled reminder returns null next occurrence', () {
      final now = DateTime.now();
      final disabledRem = CustomReminder(
        id: 'disabled',
        title: 'Disabled',
        hour: 10,
        minute: 0,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
        timezone: 'UTC',
      );

      final next = disabledRem.calculateNextOccurrence(now);
      expect(next, isNull);
    });
  });

  group('ReminderScheduler Tests', () {
    test('generateNotificationId produces deterministic collision-safe IDs', () {
      final scheduler = ReminderScheduler();
      final id1 = scheduler.generateNotificationId('preset_morning_adhkar');
      final id2 = scheduler.generateNotificationId('preset_morning_adhkar');
      final id3 = scheduler.generateNotificationId('preset_evening_adhkar');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(id1, greaterThanOrEqualTo(0));
      expect(id1, lessThan(100000000));
    });
  });
}
