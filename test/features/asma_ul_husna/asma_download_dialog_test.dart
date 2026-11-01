import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/core/services/media_download_service.dart';
import 'package:adhkar/features/asma_ul_husna/presentation/widgets/asma_download_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = Directory.systemTemp.createTempSync('asma_test_');
    MediaDownloadService.instance.cachedAudioDir = tempDir;
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'AsmaDownloadDialog shows once per day when not downloaded and not prompted today',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    late BuildContext capturedContext;
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    // Call showOncePerDay
    await AsmaDownloadDialog.showOncePerDay(capturedContext, capturedRef);
    await tester.pumpAndSettle();

    // The download bottom sheet should now be visible
    expect(find.text('Download 99 Names Audio?'), findsOneWidget);
    expect(find.text('Stream Online'), findsOneWidget);
    expect(find.text('Download All'), findsOneWidget);

    // Verify today's date key was stored in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    expect(prefs.getString('asma_download_last_prompt_date'), equals(todayKey));

    // Dismiss the bottom sheet by tapping Stream Online
    await tester.tap(find.text('Stream Online'));
    await tester.pumpAndSettle();
    expect(find.text('Download 99 Names Audio?'), findsNothing);

    // Call again on the same day - should NOT show the dialog again
    await AsmaDownloadDialog.showOncePerDay(capturedContext, capturedRef);
    await tester.pumpAndSettle();
    expect(find.text('Download 99 Names Audio?'), findsNothing);
  });

  testWidgets('AsmaDownloadDialog does not show if already prompted today',
      (WidgetTester tester) async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'asma_download_last_prompt_date': todayKey,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    late BuildContext capturedContext;
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    await AsmaDownloadDialog.showOncePerDay(capturedContext, capturedRef);
    await tester.pumpAndSettle();

    expect(find.text('Download 99 Names Audio?'), findsNothing);
  });

  testWidgets('AsmaDownloadDialog shows if last prompted date is from yesterday',
      (WidgetTester tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);
    SharedPreferences.setMockInitialValues({
      'asma_download_last_prompt_date': yesterdayKey,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    late BuildContext capturedContext;
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    await AsmaDownloadDialog.showOncePerDay(capturedContext, capturedRef);
    await tester.pumpAndSettle();

    expect(find.text('Download 99 Names Audio?'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    expect(prefs.getString('asma_download_last_prompt_date'), equals(todayKey));
  });
}
