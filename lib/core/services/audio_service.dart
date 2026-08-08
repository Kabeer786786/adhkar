import 'package:just_audio/just_audio.dart';

class AudioPlaybackState {
  final bool isPlaying;
  final bool isBuffering;
  final String? currentAudioUrl;
  final Duration position;
  final Duration duration;

  const AudioPlaybackState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.currentAudioUrl,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
}

class AppAudioService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Stream<AudioPlaybackState> get playbackStateStream {
    return _player.playerStateStream.map((state) {
      return AudioPlaybackState(
        isPlaying: state.playing,
        isBuffering: state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading,
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
    await _player.dispose();
  }
}
