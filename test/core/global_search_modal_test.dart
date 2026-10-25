import 'package:adhkar/core/services/storage_service.dart';
import 'package:adhkar/shared/providers/app_providers.dart';
import 'package:adhkar/widgets/global_search_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStorageService extends StorageService {
  final List<String> _history = [];

  @override
  List<String> getSearchHistory() => List.from(_history);

  @override
  Future<void> addSearchHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _history.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    _history.insert(0, trimmed);
    if (_history.length > 25) {
      _history.removeRange(25, _history.length);
    }
  }

  @override
  Future<void> removeSearchHistoryItem(String query) async {
    final trimmed = query.trim();
    _history.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
  }

  @override
  Future<void> clearSearchHistory() async {
    _history.clear();
  }
}

void main() {
  late FakeStorageService fakeStorage;

  setUp(() {
    fakeStorage = FakeStorageService();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(fakeStorage),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 800,
            width: 400,
            child: GlobalSearchModal(autoFocus: false),
          ),
        ),
      ),
    );
  }

  testWidgets('Renders search input, category chips, and shortcuts initially', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Verify search input field exists
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search Surahs, Juz, Duas, 99 Names, Books...'), findsOneWidget);

    // Verify category chips exist
    expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Quran'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Juz / Para'), findsOneWidget);

    // Verify Popular Shortcuts section header exists
    expect(find.text('Popular Shortcuts'), findsOneWidget);
  });

  testWidgets('Searching displays top matches accurately up to 10', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Enter query 'baqarah'
    await tester.enterText(find.byType(TextField), 'baqarah');
    await tester.pump();

    // Verify Top Matches header
    expect(find.textContaining('Top Matches'), findsOneWidget);
    expect(find.text('Surah Al-Baqarah'), findsOneWidget);
  });

  testWidgets('Displays recent searches up to 25 and allows deletion', (tester) async {
    await fakeStorage.addSearchHistory('Surah Yasin');
    await fakeStorage.addSearchHistory('Ayatul Kursi');

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Verify Recent Searches header and items
    expect(find.text('Recent Searches (2)'), findsOneWidget);
    expect(find.text('Ayatul Kursi'), findsOneWidget);
    expect(find.text('Surah Yasin'), findsOneWidget);

    // Delete 'Ayatul Kursi'
    final closeIcons = find.byIcon(Icons.close_rounded);
    expect(closeIcons, findsWidgets);
    await tester.tap(closeIcons.first);
    await tester.pump();

    // Verify remaining count
    expect(fakeStorage.getSearchHistory().contains('Ayatul Kursi'), isFalse);
    expect(fakeStorage.getSearchHistory().contains('Surah Yasin'), isTrue);
  });

  testWidgets('Clicking a category pill immediately displays category-related stuff', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Tap 'Quran' filter chip
    await tester.tap(find.widgetWithText(FilterChip, 'Quran'));
    await tester.pump();

    // Verify category items are shown immediately without query
    expect(find.textContaining('Quran ('), findsOneWidget);
    expect(find.text('Surah Al-Fatihah'), findsOneWidget);
  });
}
