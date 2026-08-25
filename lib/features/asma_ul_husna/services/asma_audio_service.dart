import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../core/services/media_download_service.dart';
import '../data/asma_ul_husna_data.dart';
import '../data/asma_ul_husna_model.dart';

class AsmaAudioController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  ConcatenatingAudioSource? _playlistSource;
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

      _isBuffering =
          processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;
      _isPlaying = playing && processingState != ProcessingState.completed;

      if (processingState == ProcessingState.completed) {
        _onAudioCompleted();
      }

      notifyListeners();
    });

    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < asmaUlHusnaList.length) {
        if (_currentIndex != index) {
          _currentIndex = index;
          notifyListeners();
          _preloadNextItems(index);
        }
      }
    });
  }

  Future<void> _ensurePlaylistInitialized() async {
    if (_playlistSource != null) return;

    final children = <AudioSource>[];
    for (int i = 0; i < asmaUlHusnaList.length; i++) {
      final item = asmaUlHusnaList[i];
      final mediaItem = MediaItem(
        id: 'asma_${item.number}',
        album: 'Asma ul Husna (${item.number}/99)',
        title: '${item.number}. ${item.name} - ${item.transliteration}',
        artist: '${item.shortMeaning} (${item.number}/99)',
      );

      final remoteUrl = item.remoteUrl.isNotEmpty
          ? item.remoteUrl
          : 'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/asma-ul-husna/${item.number}.mp3';

      children.add(AudioSource.uri(Uri.parse(remoteUrl), tag: mediaItem));
    }

    _playlistSource = ConcatenatingAudioSource(children: children);
    await _player.setAudioSource(_playlistSource!, preload: false);
  }

  void _onAudioCompleted() {
    if (_currentIndex >= 0 && _currentIndex < asmaUlHusnaList.length - 1) {
      playIndex(_currentIndex + 1);
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Play audio for a specific name index.
  Future<bool> playIndex(
    int index, {
    BuildContext? context,
    WidgetRef? ref,
  }) async {
    if (index < 0 || index >= asmaUlHusnaList.length) return false;

    await _ensurePlaylistInitialized();

    _currentIndex = index;
    notifyListeners();

    try {
      await _player.seek(Duration.zero, index: index);
      await _player.setSpeed(_speed);
      await _player.play();

      _preloadNextItems(index);
      return true;
    } catch (e) {
      debugPrint('Error playing audio for Asma-ul-Husna index $index: $e');
      return false;
    }
  }

  void _cacheItemInBackground(AsmaUlHusna item) async {
    try {
      final url = item.remoteUrl.isNotEmpty
          ? item.remoteUrl
          : 'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/asma-ul-husna/${item.number}.mp3';

      await MediaDownloadService.instance.downloadFile(
        relativePath: item.localRelativePath,
        remoteUrl: url,
      );
    } catch (_) {}
  }

  void _preloadNextItems(int currentIndex) {
    for (int offset = 1; offset <= 2; offset++) {
      final nextIndex = currentIndex + offset;
      if (nextIndex < asmaUlHusnaList.length) {
        final nextItem = asmaUlHusnaList[nextIndex];
        _cacheItemInBackground(nextItem);
      }
    }
  }

  Future<void> togglePlayPause({BuildContext? context, WidgetRef? ref}) async {
    if (_currentIndex < 0) {
      await playIndex(0, context: context, ref: ref);
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> playNext({BuildContext? context, WidgetRef? ref}) async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_currentIndex < asmaUlHusnaList.length - 1) {
      await playIndex(_currentIndex + 1, context: context, ref: ref);
    }
  }

  Future<void> playPrevious({BuildContext? context, WidgetRef? ref}) async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_currentIndex > 0) {
      await playIndex(_currentIndex - 1, context: context, ref: ref);
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
    _currentIndexSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}
