import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../data/asma_ul_husna_data.dart';
import '../data/asma_ul_husna_model.dart';

class AsmaAudioController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _isPlaying = false;
  bool _isBuffering = false;
  int _currentIndex = -1; // -1 means player closed / inactive
  double _speed = 1.0;

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  int get currentIndex => _currentIndex;
  double get speed => _speed;
  AsmaUlHusna? get currentName =>
      (_currentIndex >= 0 && _currentIndex < asmaUlHusnaList.length)
          ? asmaUlHusnaList[_currentIndex]
          : null;

  AudioPlayer get player => _player;

  AsmaAudioController() {
    _initAudio();
  }

  void _initAudio() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      _isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;
      _isPlaying = playing && processingState != ProcessingState.completed;

      if (processingState == ProcessingState.completed) {
        _onAudioCompleted();
      }

      notifyListeners();
    });
  }

  void _onAudioCompleted() {
    if (_currentIndex >= 0 && _currentIndex < asmaUlHusnaList.length - 1) {
      playIndex(_currentIndex + 1);
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= asmaUlHusnaList.length) return;
    _currentIndex = index;
    notifyListeners();

    try {
      final name = asmaUlHusnaList[index];
      await _player.setUrl(name.audioUrl);
      await _player.setSpeed(_speed);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio for index $index: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentIndex < 0) {
      await playIndex(0);
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> playNext() async {
    if (_currentIndex < asmaUlHusnaList.length - 1) {
      await playIndex(_currentIndex + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      await playIndex(_currentIndex - 1);
    }
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _player.setSpeed(speed);
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentIndex = -1;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}
