import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/services/prayer_calculation_service.dart';
import 'package:adhkar/core/services/storage_service.dart';
import 'package:adhkar/features/home/presentation/widgets/forbidden_sajda_widget.dart';

// Mock storage for testing
class MockStorageService extends Fake implements StorageService {
  final Map<String, List<String>> _subPrayers = {};

  @override
  List<String> getSubPrayerRecords(String dateKey, String prayerKey) {
    return _subPrayers['${dateKey}_$prayerKey'] ?? [];
  }

  @override
  Future<void> setSubPrayerRecords(
    String dateKey,
    String prayerKey,
    List<String> records,
  ) async {
    _subPrayers['${dateKey}_$prayerKey'] = records;
  }
}

void main() {
  group('ForbiddenSajdaService Tests', () {
    late PrayerTimeResult prayerTimes;
    late MockStorageService storage;

    setUp(() {
      ForbiddenSajdaService.isTestMode = false;
      storage = MockStorageService();
      prayerTimes = PrayerTimeResult(
        fajr: DateTime(2026, 10, 25, 5, 0),
        sunrise: DateTime(2026, 10, 25, 6, 15),
        dhuhr: DateTime(2026, 10, 25, 12, 15),
        asr: DateTime(2026, 10, 25, 15, 30),
        maghrib: DateTime(2026, 10, 25, 18, 0),
        isha: DateTime(2026, 10, 25, 19, 15),
        qiyam: DateTime(2026, 10, 25, 3, 30),
      );
    });

    test('20-Second Test Rotation cycles through all 3 pills correctly', () {
      // 0..19s: Sunrise (Red)
      final atSec0 = DateTime(2026, 10, 25, 10, 0, 5);
      final info1 = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: atSec0,
        storage: storage,
        overrideTestMode: true,
      );
      expect(info1, isNotNull);
      expect(info1!.type, ForbiddenSajdaType.sunrise);
      expect(info1.primaryColor, const Color(0xFFDC2626));

      // 20..39s: Zawal (Yellow)
      final atSec25 = DateTime(2026, 10, 25, 10, 0, 25);
      final info2 = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: atSec25,
        storage: storage,
        overrideTestMode: true,
      );
      expect(info2, isNotNull);
      expect(info2!.type, ForbiddenSajdaType.zawal);
      expect(info2.primaryColor, const Color(0xFFD97706));

      // 40..59s: Ghurub (Yellow)
      final atSec45 = DateTime(2026, 10, 25, 10, 0, 45);
      final info3 = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: atSec45,
        storage: storage,
        overrideTestMode: true,
      );
      expect(info3, isNotNull);
      expect(info3!.type, ForbiddenSajdaType.ghurub);
      expect(info3.primaryColor, const Color(0xFFD97706));
    });

    test('1. Sunrise forbidden window (Tulu): exactly at sunrise and for 20 mins (Red)', () {
      // 5 minutes before sunrise: null
      final beforeSunrise = DateTime(2026, 10, 25, 6, 10);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: beforeSunrise,
          storage: storage,
        ),
        isNull,
      );

      // Exactly at sunrise (06:15): active & Red
      final atSunrise = DateTime(2026, 10, 25, 6, 15);
      final infoAtSunrise = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: atSunrise,
        storage: storage,
      );
      expect(infoAtSunrise, isNotNull);
      expect(infoAtSunrise!.type, ForbiddenSajdaType.sunrise);
      expect(infoAtSunrise.primaryColor, const Color(0xFFDC2626)); // Red
      expect(infoAtSunrise.pillText, 'Sajda Forbidden');

      // 10 minutes after sunrise (06:25): active
      final midSunrise = DateTime(2026, 10, 25, 6, 25);
      final infoMid = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: midSunrise,
        storage: storage,
      );
      expect(infoMid, isNotNull);
      expect(infoMid!.type, ForbiddenSajdaType.sunrise);

      // Exactly at sunrise + 20 mins (06:35): pill is removed (null)
      final after20Mins = DateTime(2026, 10, 25, 6, 35);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: after20Mins,
          storage: storage,
        ),
        isNull,
      );
    });

    test('2. Pre-Dhuhr forbidden window (Zawal): 15 mins before Dhuhr (Yellow)', () {
      // 20 minutes before Dhuhr (11:55): null
      final beforeZawal = DateTime(2026, 10, 25, 11, 55);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: beforeZawal,
          storage: storage,
        ),
        isNull,
      );

      // Exactly 15 minutes before Dhuhr (12:00): active & Yellow
      final atZawalStart = DateTime(2026, 10, 25, 12, 0);
      final infoZawal = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: atZawalStart,
        storage: storage,
      );
      expect(infoZawal, isNotNull);
      expect(infoZawal!.type, ForbiddenSajdaType.zawal);
      expect(infoZawal.primaryColor, const Color(0xFFD97706)); // Yellow/Amber
      expect(infoZawal.pillText, 'Sajda Forbidden');

      // 5 minutes before Dhuhr (12:10): active
      final midZawal = DateTime(2026, 10, 25, 12, 10);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: midZawal,
          storage: storage,
        ),
        isNotNull,
      );

      // At Dhuhr start time (12:15): pill is removed (null)
      final atDhuhr = DateTime(2026, 10, 25, 12, 15);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: atDhuhr,
          storage: storage,
        ),
        isNull,
      );
    });

    test('3. Pre-Maghrib 10 mins window (Ghurub): Yellow with Asr exception', () {
      // 15 minutes before Maghrib (17:45): null
      final beforeGhurub = DateTime(2026, 10, 25, 17, 45);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: beforeGhurub,
          storage: storage,
        ),
        isNull,
      );

      // 5 minutes before Maghrib (17:55) when user did NOT pray Asr:
      final atGhurub = DateTime(2026, 10, 25, 17, 55);
      final infoNoAsr = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: atGhurub,
        storage: storage,
      );
      expect(infoNoAsr, isNotNull);
      expect(infoNoAsr!.type, ForbiddenSajdaType.ghurub);
      expect(infoNoAsr.primaryColor, const Color(0xFFD97706)); // Yellow
      expect(infoNoAsr.isAsrExceptionApplicable, isTrue);
      expect(infoNoAsr.hasPrayedAsr, isFalse);
      expect(infoNoAsr.pillText, 'Sajda Forbidden (Asr Exception)');

      // When user HAS prayed Asr on that day:
      storage.setSubPrayerRecords('2026-10-25', 'Asr', ['asr_farz']);
      final infoWithAsr = ForbiddenSajdaService.getForbiddenSajdaInfo(
        prayerTimes: prayerTimes,
        now: atGhurub,
        storage: storage,
      );
      expect(infoWithAsr, isNotNull);
      expect(infoWithAsr!.hasPrayedAsr, isTrue);
      expect(infoWithAsr.pillText, 'Sajda Forbidden (Asr Exception)');

      // At Maghrib start time (18:00): null
      final atMaghrib = DateTime(2026, 10, 25, 18, 0);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: atMaghrib,
          storage: storage,
        ),
        isNull,
      );
    });

    test('4. Normal prayer times (afternoon, night) return null', () {
      final afternoon = DateTime(2026, 10, 25, 14, 0);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: afternoon,
          storage: storage,
        ),
        isNull,
      );

      final night = DateTime(2026, 10, 25, 21, 30);
      expect(
        ForbiddenSajdaService.getForbiddenSajdaInfo(
          prayerTimes: prayerTimes,
          now: night,
          storage: storage,
        ),
        isNull,
      );
    });
  });
}
