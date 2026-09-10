import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Professional background AudioHandler for Adhkar app.
///
/// Encapsulates a single [AudioPlayer] instance and interfaces directly with
/// Android's MediaSession / AudioService foreground service.
///
/// Ensures:
/// 1. Playback continues uninterrupted across app minimize, screen lock, and
///    task switcher swipe dismissal (so long as OS has not force-stopped the process).
/// 2. Notification controls strictly display: [Previous], [Play/Pause], [Next].
///    The square STOP button is eliminated.
/// 3. Notification small icon uses monochrome transparent drawable `ic_notification`.
class AdhkarAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  AdhkarAudioHandler() {
    _initAudioHandler();
  }

  void _initAudioHandler() {
    // 1. Sync playback state whenever player state or playback event updates
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (Object e, StackTrace st) {
        debugPrint('[AdhkarAudioHandler] Playback event error: $e');
      },
    );

    _player.playerStateStream.listen(
      (_) => _broadcastState(),
      onError: (Object e, StackTrace st) {
        debugPrint('[AdhkarAudioHandler] Player state error: $e');
      },
    );

    // 2. Sync active media item and queue from player's sequence state
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;

      final currentSource = sequenceState.currentSource;
      if (currentSource?.tag is MediaItem) {
        final currentMediaItem = currentSource!.tag as MediaItem;
        mediaItem.add(currentMediaItem);
      }

      final items = sequenceState.effectiveSequence
          .map((source) => source.tag)
          .whereType<MediaItem>()
          .toList();

      if (items.isNotEmpty) {
        queue.add(items);
      }

      _broadcastState();
    });

    // 3. Emit initial state immediately
    _broadcastState();
  }

  /// Map just_audio ProcessingState to audio_service AudioProcessingState
  AudioProcessingState _transformProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Broadcast current playback state to MediaSession and notification.
  /// Controls strictly limited to Previous, Play/Pause, Next (NO stop button).
  void _broadcastState() {
    final playing = _player.playing;
    final processingState = _player.processingState;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setSpeed,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _transformProcessingState(processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }

  // --- AudioHandler Overrides ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0) {
      await _player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // --- Custom Helper Methods ---

  /// Set the audio source with optional initial index & position
  Future<void> setAudioSource(
    AudioSource source, {
    int? initialIndex,
    Duration? initialPosition,
    bool preload = true,
  }) async {
    await _player.setAudioSource(
      source,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
      preload: preload,
    );
  }

  /// Set the loop mode on the underlying player
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  /// Release resources when disposing
  Future<void> disposePlayer() async {
    await _player.dispose();
  }
}
