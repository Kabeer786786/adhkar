import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/tasbeeh/utils/tasbeeh_vibration_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasbeehVibrationHelper Tests', () {
    const alarmChannel = MethodChannel('com.sprnt.adhkar/alarm_scheduler');
    final List<MethodCall> nativeCalls = [];
    final List<String> hapticCalls = [];

    setUp(() {
      nativeCalls.clear();
      hapticCalls.clear();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(alarmChannel, (MethodCall methodCall) async {
        nativeCalls.add(methodCall);
        return true;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate') {
          final String? type = methodCall.arguments as String?;
          hapticCalls.add(type ?? 'vibrate');
        }
        return null;
      });
    });

    tearDown(() {
      TasbeehVibrationHelper.cancel();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(alarmChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('triggerCompletionAlarmVibration invokes native vibrate with notification pattern',
        () async {
      expect(TasbeehVibrationHelper.isVibrating, isFalse);

      final future = TasbeehVibrationHelper.triggerCompletionAlarmVibration();

      expect(TasbeehVibrationHelper.isVibrating, isTrue);

      await future;

      expect(TasbeehVibrationHelper.isVibrating, isFalse);

      // Verify native alarmChannel was invoked with vibrate method
      expect(nativeCalls.length, equals(1));
      expect(nativeCalls.first.method, equals('vibrate'));

      final args = nativeCalls.first.arguments as Map<dynamic, dynamic>;
      expect(args['pattern'], equals([0, 500, 200, 500]));
      expect(args['duration'], equals(800));

      // No multiple haptic taps should be generated
      expect(hapticCalls.isEmpty, isTrue);
    });

    test('cancel() immediately invokes cancelVibration and resets isVibrating',
        () async {
      TasbeehVibrationHelper.cancel();

      expect(TasbeehVibrationHelper.isVibrating, isFalse);
      expect(nativeCalls.any((call) => call.method == 'cancelVibration'), isTrue);
    });

    test('fallback to HapticFeedback when native vibration returns false or fails',
        () async {
      // Configure channel to return false
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(alarmChannel, (MethodCall methodCall) async {
        return false;
      });

      await TasbeehVibrationHelper.triggerCompletionAlarmVibration();

      expect(TasbeehVibrationHelper.isVibrating, isFalse);
      expect(hapticCalls.isNotEmpty, isTrue);
    });
  });
}
