import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/services/prayer_calculation_service.dart';
import 'package:adhkar/core/utils/hijri_date.dart';

void main() {
  group('PrayerCalculationService Tests', () {
    test('Calculates valid prayer times for Makkah', () {
      final now = DateTime(2026, 7, 23, 12, 0);
      final result = PrayerCalculationService.calculate(
        date: now,
        latitude: 21.4225,
        longitude: 39.8262,
        methodName: 'MAKKAH',
      );

      expect(result.fajr.isBefore(result.sunrise), true);
      expect(result.sunrise.isBefore(result.dhuhr), true);
      expect(result.dhuhr.isBefore(result.asr), true);
      expect(result.asr.isBefore(result.maghrib), true);
      expect(result.maghrib.isBefore(result.isha), true);
    });
  });

  group('HijriDate Converter Tests', () {
    test('Formats Hijri date correctly', () {
      final date = DateTime(2026, 7, 23);
      final hijri = HijriDate.fromGregorian(date);

      expect(hijri.year, greaterThan(1440));
      expect(hijri.formatEn().contains('AH'), true);
    });
  });
}
