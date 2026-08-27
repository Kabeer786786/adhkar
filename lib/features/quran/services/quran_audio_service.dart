import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../core/services/media_download_service.dart';
import '../data/surah_model.dart';

class QuranAudioController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  List<AyahModel> _playlist = [];
  int _currentIndex = -1; // -1 means player inactive
  String _title = '';
  int? _surahNumber;

  bool _isPlaying = false;
  bool _isBuffering = false;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;

  List<AyahModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  String get title => _title;
  int? get surahNumber => _surahNumber;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  double get speed => _speed;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;

  AyahModel? get currentAyah =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  AudioPlayer get player => _player;

  QuranAudioController() {
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

    _positionSubscription = _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSubscription = _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  void _onAudioCompleted() {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length - 1) {
      _currentIndex++;
      _playCurrentAyah();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Start playing a playlist of ayahs starting at [startIndex].
  Future<void> playPlaylist(
    List<AyahModel> ayahs,
    int startIndex, {
    String title = '',
    int? surahNumber,
  }) async {
    if (ayahs.isEmpty || startIndex < 0 || startIndex >= ayahs.length) return;

    _playlist = List.from(ayahs);
    _currentIndex = startIndex;
    _title = title;
    _surahNumber = surahNumber ?? ayahs.first.surahNumber ?? 1;
    _errorMessage = null;
    notifyListeners();

    await _playCurrentAyah();
  }

  /// Internal playback method for current ayah in playlist.
  Future<void> _playCurrentAyah() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    final ayah = _playlist[_currentIndex];
    _errorMessage = null;

    final File localFile =
        await MediaDownloadService.instance.getLocalFile(ayah.localRelativePath);
    final bool isLocal =
        await localFile.exists() && (await localFile.length()) > 0;

    final surahNum = _surahNumber ?? ayah.surahNumber ?? 1;
    final surahTitle = _title.isNotEmpty ? _title : 'Surah $surahNum';

    final mediaItem = MediaItem(
      id: 'quran_${surahNum}_${ayah.numberInSurah}',
      album: 'Surah $surahTitle (The Noble Qur\'an)',
      title: '$surahTitle • Verse ${ayah.numberInSurah}',
      artist: 'The Noble Qur\'an Recitation',
      artUri: Uri.parse('asset:///assets/logo.png'),
      extras: {
        'type': 'quran',
        'surahNumber': surahNum,
        'surahName': surahTitle,
        'route': '/quran/surah?num=$surahNum&name=${Uri.encodeComponent(surahTitle)}',
      },
    );

    try {
      if (isLocal) {
        await _player.setAudioSource(
          AudioSource.file(
            localFile.path,
            tag: mediaItem,
          ),
        );
      } else {
        // Stream directly from Cloudflare R2
        final url = ayah.remoteUrl.isNotEmpty
            ? ayah.remoteUrl
            : 'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/quran-verses/${ayah.number}.mp3';

        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            tag: mediaItem,
          ),
        );

        // Background cache of current verse
        _cacheVerseInBackground(ayah);
      }

      await _player.setSpeed(_speed);
      await _player.play();

      // Preload next 1–2 verses for smooth gapless playback
      _preloadNextVerses();
    } catch (e) {
      debugPrint('Error playing verse audio (Ayah ${ayah.numberInSurah}): $e');
      _errorMessage = 'Unable to play audio. Check internet connection.';
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Cache current streaming verse in background for future offline use.
  void _cacheVerseInBackground(AyahModel ayah) async {
    try {
      final url = ayah.remoteUrl.isNotEmpty
          ? ayah.remoteUrl
          : 'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/quran-verses/${ayah.number}.mp3';

      await MediaDownloadService.instance.downloadFile(
        relativePath: ayah.localRelativePath,
        remoteUrl: url,
      );
    } catch (_) {
      // Ignore background caching errors (e.g. offline during stream)
    }
  }

  /// Preload/cache the next 1–2 verses so consecutive verses play without gaps.
  void _preloadNextVerses() {
    for (int offset = 1; offset <= 2; offset++) {
      final nextIndex = _currentIndex + offset;
      if (nextIndex < _playlist.length) {
        final nextAyah = _playlist[nextIndex];
        _cacheVerseInBackground(nextAyah);
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentIndex < 0 && _playlist.isNotEmpty) {
      _currentIndex = 0;
      await _playCurrentAyah();
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> playNext() async {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await _playCurrentAyah();
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrentAyah();
    }
  }

  /// Jump directly to a specific verse index in the current playlist
  Future<void> playIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      notifyListeners();
      await _playCurrentAyah();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
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
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// Riverpod provider for QuranAudioController
final quranAudioProvider = ChangeNotifierProvider<QuranAudioController>((ref) {
  final controller = QuranAudioController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
