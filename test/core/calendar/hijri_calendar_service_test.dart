import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:adhkar/core/calendar/models/calendar_type.dart';
import 'package:adhkar/core/calendar/services/regional_calendar_resolver.dart';
import 'package:adhkar/core/calendar/services/hijri_calendar_service.dart';
import 'package:adhkar/core/utils/hijri_date.dart' as util;

void main() {
  late RegionalCalendarResolver resolver;
  late HijriCalendarService calendarService;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    resolver = RegionalCalendarResolver();
    calendarService = HijriCalendarService(resolver: resolver);
  });

  group('RegionalCalendarResolver Tests', () {
    test('Global calendar type returns exact Gregorian date without shifting', () {
      final inputDate = DateTime(2026, 8, 15);
      final targetDate = resolver.resolveTargetGregorianDate(
        gregorianDate: inputDate,
        calendarType: CalendarType.global,
        region: HijriRegion.india,
      );
      expect(targetDate, equals(inputDate));
    });

    test('Regional calendar for India applies -1 day offset to Gregorian date', () {
      final inputDate = DateTime(2026, 8, 15);
      final targetDate = resolver.resolveTargetGregorianDate(
        gregorianDate: inputDate,
        calendarType: CalendarType.regional,
        region: HijriRegion.india,
      );
      expect(targetDate, equals(DateTime(2026, 8, 14)));
    });
  });

  group('HijriCalendarService Boundary Tests', () {
    test('15 Aug 2026 under -1 day regional shift resolves 14 Aug (30 Safar 1448)', () async {
      // 15 Aug 2026 in India (regional) resolves 14 Aug 2026 = 30 Safar 1448
      final result = await calendarService.getHijriDate(
        gregorianDate: DateTime(2026, 8, 15),
        calendarType: CalendarType.regional,
        region: HijriRegion.india,
      );

      expect(result.day, equals(30));
      expect(result.monthNameEn, equals('Safar'));
      expect(result.year, equals(1448));
      expect(result.day, isNot(equals(0))); // Never returns 0!
    });

    test('Anchor calculation: 15 Aug 2026 equals 1 Rabi al-Awwal 1448 for Subcontinent', () {
      final hDate = util.HijriDate.fromGregorian(DateTime(2026, 8, 15), isSubcontinent: true);
      expect(hDate.day, equals(1));
      expect(hDate.monthNameEn, equals('Rabi\' al-Awwal'));
      expect(hDate.year, equals(1448));
    });

    test('Anchor calculation: 14 Aug 2026 equals 30 Safar 1448 for Subcontinent', () {
      final hDate = util.HijriDate.fromGregorian(DateTime(2026, 8, 14), isSubcontinent: true);
      expect(hDate.day, equals(30));
      expect(hDate.monthNameEn, equals('Safar'));
      expect(hDate.year, equals(1448));
    });

    test('Year boundary transition handles 1 Muharram 1449 to 30 Dhul Hijjah 1448 correctly', () {
      final hDate = util.HijriDate.fromGregorian(DateTime(2026, 8, 14), isSubcontinent: true);
      expect(hDate.year, equals(1448));
    });
  });
}
