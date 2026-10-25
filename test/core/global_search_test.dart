import 'dart:io';
import 'package:adhkar/core/services/global_search_service.dart';
import 'package:adhkar/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storageService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('adhkar_search_test_');
    storageService = StorageService();
    await storageService.initFromPath(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('GlobalSearchService Catalog Tests', () {
    final service = GlobalSearchService();

    test('Catalog contains all comprehensive data sources', () {
      final catalog = service.getCatalog();
      expect(catalog.isNotEmpty, isTrue);

      // Verify Surahs count (all 114)
      final surahs = catalog.where((i) => i.categoryType == GlobalSearchCategory.quran).toList();
      expect(surahs.length, equals(114));

      // Verify Juz count (all 30)
      final juzList = catalog.where((i) => i.categoryType == GlobalSearchCategory.juz).toList();
      expect(juzList.length, equals(30));

      // Verify Asma ul Husna count (all 99)
      final asmaList = catalog.where((i) => i.categoryType == GlobalSearchCategory.asmaUlHusna).toList();
      expect(asmaList.length, equals(99));

      // Verify Scientific Islam items
      final sciList = catalog.where((i) => i.categoryType == GlobalSearchCategory.scientificIslam).toList();
      expect(sciList.isNotEmpty, isTrue);

      // Verify Books
      final books = catalog.where((i) => i.categoryType == GlobalSearchCategory.books).toList();
      expect(books.isNotEmpty, isTrue);

      // Verify Tasbeeh items
      final tasbeehs = catalog.where((i) => i.categoryType == GlobalSearchCategory.tasbeeh).toList();
      expect(tasbeehs.isNotEmpty, isTrue);

      // Verify Features
      final features = catalog.where((i) => i.categoryType == GlobalSearchCategory.features).toList();
      expect(features.isNotEmpty, isTrue);
    });

    test('Search returns top 10 matches maximum', () {
      // Very broad search query that matches dozens of items (e.g. 'al')
      final matches = service.search('al');
      expect(matches.length, lessThanOrEqualTo(10));
      expect(matches.length, equals(10));
    });

    test('Search for specific Surah ranks top match accurately', () {
      final matches = service.search('Al-Baqarah');
      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.title, contains('Al-Baqarah'));
      expect(matches.first.categoryType, equals(GlobalSearchCategory.quran));
    });

    test('Search for Juz / Para finds Juz 30', () {
      final matches = service.search('Amma');
      expect(matches.isNotEmpty, isTrue);
      final hasJuz30 = matches.any((m) => m.title.contains('Juz 30') || m.subtitle.contains('Amma'));
      expect(hasJuz30, isTrue);
    });

    test('Search for Asma Ul Husna finds Ar-Rahman', () {
      final matches = service.search('Ar-Rahman');
      expect(matches.isNotEmpty, isTrue);
      final hasRahman = matches.any((m) => m.title.contains('Ar-Rahman'));
      expect(hasRahman, isTrue);
    });

    test('Search for Scientific Islam finds Pulsars / Black Holes', () {
      final matches = service.search('Pulsar');
      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.categoryType, equals(GlobalSearchCategory.scientificIslam));
    });

    test('Search with category filter restricts results to that category', () {
      final quranOnly = service.search('the', filterCategory: GlobalSearchCategory.quran);
      expect(quranOnly.isNotEmpty, isTrue);
      expect(quranOnly.every((i) => i.categoryType == GlobalSearchCategory.quran), isTrue);
      expect(quranOnly.length, lessThanOrEqualTo(10));
    });
  });

  group('StorageService Search History Tests (Recent 25 cap)', () {
    test('Stores and retrieves search history with recent-first ordering', () async {
      await storageService.clearSearchHistory();
      expect(storageService.getSearchHistory(), isEmpty);

      await storageService.addSearchHistory('Surah Yasin');
      await storageService.addSearchHistory('Qibla');

      final history = storageService.getSearchHistory();
      expect(history.length, equals(2));
      expect(history.first, equals('Qibla'));
      expect(history.last, equals('Surah Yasin'));
    });

    test('Re-searching existing term moves it to top without duplicates', () async {
      await storageService.clearSearchHistory();
      await storageService.addSearchHistory('Fajr');
      await storageService.addSearchHistory('Duas');
      await storageService.addSearchHistory('fajr'); // duplicate in lowercase

      final history = storageService.getSearchHistory();
      expect(history.length, equals(2));
      expect(history.first.toLowerCase(), equals('fajr'));
    });

    test('Removes individual search history item', () async {
      await storageService.clearSearchHistory();
      await storageService.addSearchHistory('Item 1');
      await storageService.addSearchHistory('Item 2');
      await storageService.addSearchHistory('Item 3');

      await storageService.removeSearchHistoryItem('Item 2');
      final history = storageService.getSearchHistory();
      expect(history.length, equals(2));
      expect(history.contains('Item 2'), isFalse);
    });

    test('Strictly enforces 25 items cap and removes overflowing oldest ones', () async {
      await storageService.clearSearchHistory();

      // Add 30 distinct searches
      for (int i = 1; i <= 30; i++) {
        await storageService.addSearchHistory('Search Query #$i');
      }

      final history = storageService.getSearchHistory();
      // Must not exceed 25 items
      expect(history.length, equals(25));
      // Most recent should be #30
      expect(history.first, equals('Search Query #30'));
      // Oldest kept should be #6
      expect(history.last, equals('Search Query #6'));
      // Oldest overflow (#1 through #5) must be removed
      expect(history.contains('Search Query #1'), isFalse);
      expect(history.contains('Search Query #5'), isFalse);
    });
  });
}
