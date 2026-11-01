import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/adhkar/presentation/widgets/swipable_status_pill.dart';

void main() {
  group('SwipableStatusPill Widget Tests', () {
    testWidgets('Renders Pending state with hourglass icon and text',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipableStatusPill(
                isDone: false,
                isDark: false,
                onComplete: () => completed = true,
              ),
            ),
          ),
        ),
      );

      // Verify text and icon
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
      expect(completed, isFalse);
    });

    testWidgets('Tapping Pending pill calls onComplete', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipableStatusPill(
                isDone: false,
                isDark: false,
                onComplete: () => completed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SwipableStatusPill));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('Swiping Pending pill to the right calls onComplete',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipableStatusPill(
                isDone: false,
                isDark: false,
                onComplete: () => completed = true,
              ),
            ),
          ),
        ),
      );

      // Drag horizontally to the right across the pill
      await tester.drag(find.byType(SwipableStatusPill), const Offset(100, 0));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('Renders Done state with tick icon and text', (tester) async {
      bool reset = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipableStatusPill(
                isDone: true,
                isDark: true,
                onComplete: () {},
                onReset: () => reset = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(reset, isFalse);

      // Tapping when Done triggers onReset
      await tester.tap(find.byType(SwipableStatusPill));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(reset, isTrue);
    });
  });

  group('Bottom Bar Plus Button Visibility Tests', () {
    test('Plus button is shown only when countTarget > 1', () {
      bool shouldShowPlusButton(int target) => target > 1;

      expect(shouldShowPlusButton(1), isFalse);
      expect(shouldShowPlusButton(0), isFalse);
      expect(shouldShowPlusButton(2), isTrue);
      expect(shouldShowPlusButton(3), isTrue);
      expect(shouldShowPlusButton(33), isTrue);
      expect(shouldShowPlusButton(100), isTrue);
    });
  });
}
