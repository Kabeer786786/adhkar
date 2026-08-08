import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhkar/core/services/storage_service.dart';
import 'package:adhkar/shared/providers/app_providers.dart';
import 'package:adhkar/shared/widgets/m3_card.dart';
import 'package:adhkar/shared/widgets/section_header.dart';

class FakeStorageService extends StorageService {
  @override
  String getCalculationMethod() => 'MWL';
  @override
  String getAsrJuristic() => 'Standard';
  @override
  String getThemeMode() => 'system';
  @override
  Map<String, dynamic>? getSavedLocation() => null;
  @override
  List<String> getSalahRecordsForDate(String dateKey) => [];
  @override
  int getTasbeehCount(String zikrId) => 0;
  @override
  int getLifetimeTasbeehCount([String? tasbeehId]) => 0;
}

void main() {
  testWidgets('M3Card and SectionHeader render cleanly', (WidgetTester tester) async {
    final fakeStorage = FakeStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(title: 'Adhkar Test Header'),
                M3Card(child: Text('Card Content')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Adhkar Test Header'), findsOneWidget);
    expect(find.text('Card Content'), findsOneWidget);
  });
}
