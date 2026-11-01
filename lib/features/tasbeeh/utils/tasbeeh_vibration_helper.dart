import 'dart:async';
import 'package:flutter/services.dart';
import '../../../../core/services/native_alarm_service.dart';

/// Helper for providing tactile vibration feedback for Tasbeeh completion.
class TasbeehVibrationHelper {
  TasbeehVibrationHelper._();

  static bool _isVibrating = false;
  static bool get isVibrating => _isVibrating;
  static int _vibrationSessionId = 0;

  /// Default rigorous notification vibration pattern:
  /// 0ms wait, 500ms strong vibration, 200ms pause, 500ms strong vibration.
  /// Activates the hardware vibrator motor at full power like a phone notification,
  /// avoiding confusing multiple short haptic ticks.
  static const List<int> defaultNotificationPattern = [0, 500, 200, 500];

  /// Triggers a rigorous phone vibration like an incoming notification.
  /// Uses the device's native hardware vibrator motor rather than short marble-like haptic taps.
  static Future<void> triggerCompletionAlarmVibration({
    List<int> pattern = defaultNotificationPattern,
    int durationMillis = 800, 
  }) async {
    final sessionId = ++_vibrationSessionId;
    _isVibrating = true;

    try {
      final success = await NativeAlarmService.vibrate(
        pattern: pattern,
        durationMillis: durationMillis,
      );

      // Fallback for non-Android platforms or where native vibrator is unavailable
      if (!success && _vibrationSessionId == sessionId) {
        await HapticFeedback.vibrate();
      }
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    } finally {
      if (_vibrationSessionId == sessionId) {
        _isVibrating = false;
      }
    }
  }

  /// Immediately cancels any ongoing completion vibration.
  static void cancel() {
    _vibrationSessionId++;
    _isVibrating = false;
    NativeAlarmService.cancelVibration();
  }
}
