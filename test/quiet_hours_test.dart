import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/quiet_hours/domain/quiet_hours_model.dart';
import 'package:adhkar/features/quiet_hours/services/dnd_service.dart';

void main() {
  group('QuietHours Model & Time Logic Tests', () {
    test('Standard Same-Day Schedule (1:15 PM - 1:40 PM)', () {
      final quietHours = QuietHours(
        id: 'test_standard',
        startHour: 13,
        startMinute: 15,
        endHour: 13,
        endMinute: 40,
        enabled: true,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(quietHours.isOvernight, isFalse);

      // Before start time (1:14 PM)
      final at114 = DateTime(2026, 8, 15, 13, 14);
      expect(quietHours.isTimeInQuietHours(at114), isFalse);

      // At start time (1:15 PM)
      final at115 = DateTime(2026, 8, 15, 13, 15);
      expect(quietHours.isTimeInQuietHours(at115), isTrue);

      // During active range (1:30 PM)
      final at130 = DateTime(2026, 8, 15, 13, 30);
      expect(quietHours.isTimeInQuietHours(at130), isTrue);

      // At end time (1:40 PM) - should be false (end time boundary)
      final at140 = DateTime(2026, 8, 15, 13, 40);
      expect(quietHours.isTimeInQuietHours(at140), isFalse);

      // After end time (1:41 PM)
      final at141 = DateTime(2026, 8, 15, 13, 41);
      expect(quietHours.isTimeInQuietHours(at141), isFalse);
    });

    test('Overnight Schedule (10:00 PM - 6:00 AM)', () {
      final quietHours = QuietHours(
        id: 'test_overnight',
        startHour: 22,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
        enabled: true,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(quietHours.isOvernight, isTrue);

      // Before start (9:59 PM)
      final at2159 = DateTime(2026, 8, 15, 21, 59);
      expect(quietHours.isTimeInQuietHours(at2159), isFalse);

      // Start time (10:00 PM)
      final at2200 = DateTime(2026, 8, 15, 22, 0);
      expect(quietHours.isTimeInQuietHours(at2200), isTrue);

      // Midnight (12:00 AM)
      final at0000 = DateTime(2026, 8, 16, 0, 0);
      expect(quietHours.isTimeInQuietHours(at0000), isTrue);

      // Early morning (5:59 AM)
      final at0559 = DateTime(2026, 8, 16, 5, 59);
      expect(quietHours.isTimeInQuietHours(at0559), isTrue);

      // End time (6:00 AM)
      final at0600 = DateTime(2026, 8, 16, 6, 0);
      expect(quietHours.isTimeInQuietHours(at0600), isFalse);

      // After end time (6:01 AM)
      final at0601 = DateTime(2026, 8, 16, 6, 1);
      expect(quietHours.isTimeInQuietHours(at0601), isFalse);
    });

    test('Weekday Filtering (Mon-Fri Only)', () {
      // 2026-08-15 is Saturday (weekday = 6)
      // 2026-08-17 is Monday (weekday = 1)
      final quietHours = QuietHours(
        id: 'test_weekdays',
        startHour: 13,
        startMinute: 15,
        endHour: 13,
        endMinute: 40,
        enabled: true,
        repeatDaily: false,
        weekdays: const [1, 2, 3, 4, 5], // Mon..Fri
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Saturday 1:20 PM
      final saturday = DateTime(2026, 8, 15, 13, 20);
      expect(quietHours.isTimeInQuietHours(saturday), isFalse);

      // Monday 1:20 PM
      final monday = DateTime(2026, 8, 17, 13, 20);
      expect(quietHours.isTimeInQuietHours(monday), isTrue);
    });

    test('Disabled Quiet Hours returns false', () {
      final quietHours = QuietHours(
        id: 'test_disabled',
        startHour: 13,
        startMinute: 15,
        endHour: 13,
        endMinute: 40,
        enabled: false,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final during = DateTime(2026, 8, 15, 13, 30);
      expect(quietHours.isTimeInQuietHours(during), isFalse);
    });

    test('Next Occurrence Calculation', () {
      final quietHours = QuietHours(
        id: 'test_next',
        startHour: 13,
        startMinute: 15,
        endHour: 13,
        endMinute: 40,
        enabled: true,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final fromBefore = DateTime(2026, 8, 15, 12, 0);
      final nextStart = quietHours.getNextStartOccurrence(fromBefore);
      expect(nextStart, DateTime(2026, 8, 15, 13, 15));

      final fromAfter = DateTime(2026, 8, 15, 14, 0);
      final nextStartTomorrow = quietHours.getNextStartOccurrence(fromAfter);
      expect(nextStartTomorrow, DateTime(2026, 8, 16, 13, 15));
    });

    test('JSON Serialization and Deserialization', () {
      final original = QuietHours(
        id: 'test_json',
        startHour: 14,
        startMinute: 30,
        endHour: 15,
        endMinute: 0,
        enabled: true,
        repeatDaily: false,
        weekdays: const [1, 3, 5],
        originalDndFilter: 1,
        adhkarOwnsDnd: true,
        createdAt: DateTime(2026, 8, 15, 10, 0),
        updatedAt: DateTime(2026, 8, 15, 10, 0),
      );

      final json = original.toJson();
      final restored = QuietHours.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.startHour, original.startHour);
      expect(restored.startMinute, original.startMinute);
      expect(restored.endHour, original.endHour);
      expect(restored.endMinute, original.endMinute);
      expect(restored.enabled, original.enabled);
      expect(restored.repeatDaily, original.repeatDaily);
      expect(restored.weekdays, original.weekdays);
      expect(restored.originalDndFilter, original.originalDndFilter);
      expect(restored.adhkarOwnsDnd, original.adhkarOwnsDnd);
    });

    test('Multiple Quiet Hours Schedules List', () {
      final schedules = [
        QuietHours(
          id: 'morning',
          title: 'Morning Focus',
          startHour: 8,
          startMinute: 0,
          endHour: 9,
          endMinute: 0,
          enabled: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        QuietHours(
          id: 'afternoon',
          title: 'Afternoon Prayer',
          startHour: 13,
          startMinute: 15,
          endHour: 13,
          endMinute: 40,
          enabled: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      final at830 = DateTime(2026, 8, 15, 8, 30);
      final at1320 = DateTime(2026, 8, 15, 13, 20);
      final at1100 = DateTime(2026, 8, 15, 11, 0);

      expect(schedules.any((s) => s.isTimeInQuietHours(at830)), isTrue);
      expect(schedules.any((s) => s.isTimeInQuietHours(at1320)), isTrue);
      expect(schedules.any((s) => s.isTimeInQuietHours(at1100)), isFalse);
    });

    test('Boundary Schedule: 12:00 AM to 6:00 AM', () {
      final quietHours = QuietHours(
        id: 'midnight_to_morning',
        startHour: 0,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
        enabled: true,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(quietHours.isOvernight, isFalse);

      final at1159Prev = DateTime(2026, 8, 15, 23, 59);
      final atMidnight = DateTime(2026, 8, 16, 0, 0);
      final at3am = DateTime(2026, 8, 16, 3, 0);
      final at6am = DateTime(2026, 8, 16, 6, 0);

      expect(quietHours.isTimeInQuietHours(at1159Prev), isFalse);
      expect(quietHours.isTimeInQuietHours(atMidnight), isTrue);
      expect(quietHours.isTimeInQuietHours(at3am), isTrue);
      expect(quietHours.isTimeInQuietHours(at6am), isFalse);
    });

    test('Boundary Schedule: 11:59 PM to 12:01 AM (2-Minute Midnight Crossing)', () {
      final quietHours = QuietHours(
        id: 'two_min_crossing',
        startHour: 23,
        startMinute: 59,
        endHour: 0,
        endMinute: 1,
        enabled: true,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(quietHours.isOvernight, isTrue);

      final at2358 = DateTime(2026, 8, 15, 23, 58);
      final at2359 = DateTime(2026, 8, 15, 23, 59);
      final at0000 = DateTime(2026, 8, 16, 0, 0);
      final at0001 = DateTime(2026, 8, 16, 0, 1);

      expect(quietHours.isTimeInQuietHours(at2358), isFalse);
      expect(quietHours.isTimeInQuietHours(at2359), isTrue);
      expect(quietHours.isTimeInQuietHours(at0000), isTrue);
      expect(quietHours.isTimeInQuietHours(at0001), isFalse);
    });

    test('DndScheduleModel and DndStateModel Parsing', () {
      final stateMap = {
        'filter': 2,
        'isDndActive': true,
        'adhkarOwnsDnd': true,
      };
      final state = DndStateModel.fromMap(stateMap);
      expect(state.filter, 2);
      expect(state.isDndActive, isTrue);
      expect(state.adhkarOwnsDnd, isTrue);

      final scheduleMap = {
        'enabled': true,
        'startHour': 22,
        'startMinute': 30,
        'endHour': 6,
        'endMinute': 0,
        'repeatDaily': true,
        'weekdays': [1, 2, 3, 4, 5, 6, 7],
        'nextEnableTimestamp': 1757437800000,
        'nextDisableTimestamp': 1757464800000,
        'timeZone': 'Asia/Kolkata',
        'lastKnownDndState': 'ENABLED',
        'adhkarOwnsDnd': true,
      };
      final schedule = DndScheduleModel.fromMap(scheduleMap);
      expect(schedule.enabled, isTrue);
      expect(schedule.startHour, 22);
      expect(schedule.startMinute, 30);
      expect(schedule.endHour, 6);
      expect(schedule.endMinute, 0);
      expect(schedule.repeatDaily, isTrue);
      expect(schedule.weekdays.length, 7);
      expect(schedule.timeZone, 'Asia/Kolkata');
      expect(schedule.lastKnownDndState, 'ENABLED');
      expect(schedule.adhkarOwnsDnd, isTrue);
      expect(schedule.nextEnableTime, isNotNull);
      expect(schedule.nextDisableTime, isNotNull);
    });
  });
}
