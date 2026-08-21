// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/services/media_download_service.dart';
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

  /// Play audio for a specific name index.
  /// Checks local cache first; if missing, streams from Cloudflare R2 and
  /// caches individually in the background.
  Future<bool> playIndex(
    int index, {
    BuildContext? context,
    WidgetRef? ref,
  }) async {
    if (index < 0 || index >= asmaUlHusnaList.length) return false;
    final item = asmaUlHusnaList[index];

    final File localFile =
        await MediaDownloadService.instance.getLocalFile(item.localRelativePath);

    final bool exists = await localFile.exists() && (await localFile.length()) > 0;

    _currentIndex = index;
    notifyListeners();

    try {
      if (exists) {
        await _player.setAudioSource(AudioSource.file(localFile.path));
      } else {
        // Stream directly from R2 URL
        final remoteUrl = item.remoteUrl.isNotEmpty
            ? item.remoteUrl
            : 'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/asma-ul-husna/${item.number}.mp3';

        await _player.setAudioSource(AudioSource.uri(Uri.parse(remoteUrl)));

        // Background cache current item
        _cacheItemInBackground(item);
      }

      await _player.setSpeed(_speed);
      await _player.play();

      // Preload next 1-2 items
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
    if (_currentIndex < asmaUlHusnaList.length - 1) {
      await playIndex(_currentIndex + 1, context: context, ref: ref);
    }
  }

  Future<void> playPrevious({BuildContext? context, WidgetRef? ref}) async {
    if (_currentIndex > 0) {
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
    _player.dispose();
    super.dispose();
  }
}
