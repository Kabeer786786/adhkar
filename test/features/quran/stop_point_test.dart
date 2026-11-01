import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:adhkar/core/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stop_point_test_');
    storage = StorageService();
    await storage.initFromPath(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Quran Stop Point Tests', () {
    test('Middle of Surah stop point resumes next ayah in same Surah', () async {
      await storage.saveQuranStopPoint(
        surahNumber: 1,
        surahNameEnglish: 'Al-Fatiha',
        surahNameArabic: 'الفاتحة',
        markedAyahNumber: 3,
        totalAyahs: 7,
        resumeAyahNumber: 4,
        resumeSurahNumber: 1,
        resumeSurahNameEnglish: 'Al-Fatiha',
        resumeSurahNameArabic: 'الفاتحة',
      );

      final sp = storage.getStopPointForSurah(1);
      expect(sp, isNotNull);
      expect(sp!['markedAyahNumber'], equals(3));
      expect(sp['resumeAyahNumber'], equals(4));
      expect(sp['resumeSurahNumber'], equals(1));
      expect(sp['isLastOfQuran'], isFalse);

      expect(storage.getLastReadSurah(), equals(1));
      expect(storage.getLastReadAyah(), equals(4));
    });

    test('Last Ayah of Surah resumes next Surah at Ayah 1', () async {
      await storage.saveQuranStopPoint(
        surahNumber: 1,
        surahNameEnglish: 'Al-Fatiha',
        surahNameArabic: 'الفاتحة',
        markedAyahNumber: 7,
        totalAyahs: 7,
        resumeAyahNumber: 1,
        resumeSurahNumber: 2,
        resumeSurahNameEnglish: 'Al-Baqarah',
        resumeSurahNameArabic: 'البقرة',
        isLastOfQuran: false,
      );

      final sp = storage.getStopPointForSurah(1);
      expect(sp, isNotNull);
      expect(sp!['markedAyahNumber'], equals(7));
      expect(sp['resumeAyahNumber'], equals(1));
      expect(sp['resumeSurahNumber'], equals(2));
      expect(sp['resumeSurahNameEnglish'], equals('Al-Baqarah'));
      expect(sp['isLastOfQuran'], isFalse);

      expect(storage.getLastReadSurah(), equals(2));
      expect(storage.getLastReadAyah(), equals(1));
    });

    test('Last Ayah of Surah 114 (End of Quran) points to stop point without going to first', () async {
      await storage.saveQuranStopPoint(
        surahNumber: 114,
        surahNameEnglish: 'An-Nas',
        surahNameArabic: 'الناس',
        markedAyahNumber: 6,
        totalAyahs: 6,
        resumeAyahNumber: 6,
        resumeSurahNumber: 114,
        resumeSurahNameEnglish: 'An-Nas',
        resumeSurahNameArabic: 'الناس',
        isLastOfQuran: true,
      );

      final sp = storage.getStopPointForSurah(114);
      expect(sp, isNotNull);
      expect(sp!['markedAyahNumber'], equals(6));
      expect(sp['resumeAyahNumber'], equals(6));
      expect(sp['resumeSurahNumber'], equals(114));
      expect(sp['isLastOfQuran'], isTrue);

      expect(storage.getLastReadSurah(), equals(114));
      expect(storage.getLastReadAyah(), equals(6));
    });

    test('Last Ayah of Juz resumes next Juz at its first ayah', () async {
      await storage.saveQuranStopPoint(
        surahNumber: 2,
        surahNameEnglish: 'Al-Baqarah',
        surahNameArabic: 'البقرة',
        juzNumber: 1,
        markedAyahNumber: 141,
        totalAyahs: 148,
        resumeAyahNumber: 142,
        resumeSurahNumber: 2,
        resumeSurahNameEnglish: 'Al-Baqarah',
        resumeSurahNameArabic: 'البقرة',
        resumeJuzNumber: 2,
        isLastOfQuran: false,
      );

      final sp = storage.getStopPointForJuz(1);
      expect(sp, isNotNull);
      expect(sp!['markedAyahNumber'], equals(141));
      expect(sp['resumeAyahNumber'], equals(142));
      expect(sp['resumeJuzNumber'], equals(2));
      expect(sp['isLastOfQuran'], isFalse);

      expect(storage.getLastReadJuz(), equals(2));
    });

    test('Last Ayah of Juz 30 (End of Quran) points to stop point without going to first', () async {
      await storage.saveQuranStopPoint(
        surahNumber: 114,
        surahNameEnglish: 'An-Nas',
        surahNameArabic: 'الناس',
        juzNumber: 30,
        markedAyahNumber: 6,
        totalAyahs: 564,
        resumeAyahNumber: 6,
        resumeSurahNumber: 114,
        resumeSurahNameEnglish: 'An-Nas',
        resumeSurahNameArabic: 'الناس',
        resumeJuzNumber: 30,
        isLastOfQuran: true,
      );

      final sp = storage.getStopPointForJuz(30);
      expect(sp, isNotNull);
      expect(sp!['markedAyahNumber'], equals(6));
      expect(sp['resumeAyahNumber'], equals(6));
      expect(sp['resumeJuzNumber'], equals(30));
      expect(sp['isLastOfQuran'], isTrue);

      expect(storage.getLastReadJuz(), equals(30));
    });

    test('Juz stop point stores and resolves specific Juz name in English and Arabic', () async {
      await storage.saveQuranStopPoint(
        surahNumber: 2,
        surahNameEnglish: 'Sayaqool',
        surahNameArabic: 'سَيَقُولُ',
        juzNumber: 2,
        markedAyahNumber: 150,
        totalAyahs: 111,
        resumeAyahNumber: 151,
        resumeSurahNumber: 2,
        resumeSurahNameEnglish: 'Al-Baqarah',
        resumeSurahNameArabic: 'البقرة',
        resumeJuzNumber: 2,
        isLastOfQuran: false,
      );

      final sp = storage.getStopPointForJuz(2);
      expect(sp, isNotNull);
      expect(sp!['juzNumber'], equals(2));
      expect(sp['surahNameEnglish'], equals('Sayaqool'));
      expect(sp['surahNameArabic'], equals('سَيَقُولُ'));
    });
  });
}
