import 'dart:async';
import 'package:just_audio/just_audio.dart';

class AudioPlaybackState {
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final String? currentAudioUrl;
  final Duration position;
  final Duration duration;

  const AudioPlaybackState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.currentAudioUrl,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
}

class AppAudioService {
  final AudioPlayer _player;
  final bool _isInternalPlayer;
  StreamSubscription<PlayerState>? _completionSub;

  AppAudioService([AudioPlayer? player])
      : _player = player ?? AudioPlayer(),
        _isInternalPlayer = player == null {
    _completionSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    });
  }

  AudioPlayer get player => _player;

  Stream<AudioPlaybackState> get playbackStateStream {
    return _player.playerStateStream.map((state) {
      final isCompleted = state.processingState == ProcessingState.completed;
      final isPlaying = state.playing && !isCompleted;
      final isBuffering = (state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading) &&
          !isCompleted;

      return AudioPlaybackState(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        isCompleted: isCompleted,
        position: _player.position,
        duration: _player.duration ?? Duration.zero,
      );
    });
  }

  Future<void> playUrl(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {}
  }

  Future<void> playAsset(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (_) {}
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    _completionSub?.cancel();
    if (_isInternalPlayer) {
      await _player.dispose();
    } else {
      await _player.stop();
    }
  }
}
