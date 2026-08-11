import 'dart:async';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AlarmAudioService {
  static final AlarmAudioService _instance = AlarmAudioService._internal();
  factory AlarmAudioService() => _instance;
  AlarmAudioService._internal();

  AudioPlayer? _audioPlayer;
  Timer? _autoStopTimer;
  Timer? _vibrationTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Starts the alarm sound and continuous vibration for a maximum of 10 seconds.
  Future<void> startAlarm({
    bool sound = true,
    bool vibration = true,
    String soundType = 'Azaan',
  }) async {
    await stopAlarm(); // Stop any active alarm

    _isPlaying = true;

    // 1. Play Audio using standard media stream (without overriding system volume)
    if (sound) {
      try {
        _audioPlayer = AudioPlayer();
        // Try playing Athan / Alarm audio stream or asset
        try {
          await _audioPlayer!.setAsset('assets/audio/athan.mp3');
        } catch (_) {
          // Reliable fallback audio stream if asset is not present
          await _audioPlayer!.setUrl(
            'https://raw.githubusercontent.com/islamic-network/athan-mp3/master/mecca.mp3',
          );
        }
        await _audioPlayer!.setLoopMode(LoopMode.one);
        await _audioPlayer!.play();
      } catch (e) {
        // Fallback gracefully if network/audio is unavailable
      }
    }

    // 2. Continuous Strong Vibration Pulses
    if (vibration) {
      _triggerVibrationPulse();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
        if (_isPlaying) {
          _triggerVibrationPulse();
        }
      });
    }

    // 3. Strict 10-Second Auto-Stop Timer
    _autoStopTimer = Timer(const Duration(seconds: 10), () {
      stopAlarm();
    });
  }

  void _triggerVibrationPulse() {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }

  /// Stops all audio playback and vibration immediately.
  Future<void> stopAlarm() async {
    _isPlaying = false;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
      } catch (_) {}
      _audioPlayer = null;
    }
  }
}
