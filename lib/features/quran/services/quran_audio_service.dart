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
  StreamSubscription<int?>? _currentIndexSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  ConcatenatingAudioSource? _playlistSource;
  List<AyahModel> _playlist = [];
  int _currentIndex = -1; // -1 means player inactive
  String _title = '';
  int? _surahNumber;

  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isLoopSingle = false;
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
  bool get isLoopSingle => _isLoopSingle;
  double get speed => _speed;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;

  void toggleLoopSingle() {
    _isLoopSingle = !_isLoopSingle;
    _player.setLoopMode(_isLoopSingle ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

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
        _isPlaying = false;
        notifyListeners();
      }

      notifyListeners();
    });

    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        if (_currentIndex != index) {
          _currentIndex = index;
          _errorMessage = null;
          notifyListeners();
          _preloadNextItems(index);
        }
      }
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

  void _cacheItemInBackground(AyahModel ayah) async {
    try {
      final url = ayah.remoteUrl.isNotEmpty
          ? ayah.remoteUrl
          : 'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/quran-verses/${ayah.number}.mp3';

      await MediaDownloadService.instance.downloadFile(
        relativePath: ayah.localRelativePath,
        remoteUrl: url,
      );
    } catch (_) {}
  }

  void _preloadNextItems(int currentIndex) {
    for (int offset = 1; offset <= 3; offset++) {
      final nextIndex = currentIndex + offset;
      if (nextIndex < _playlist.length) {
        final nextAyah = _playlist[nextIndex];
        _cacheItemInBackground(nextAyah);
      }
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

    final targetSurahNumber = surahNumber ?? ayahs.first.surahNumber ?? 1;
    final bool isSamePlaylist = _playlist.isNotEmpty &&
        _surahNumber == targetSurahNumber &&
        _playlist.length == ayahs.length &&
        _playlist.first.number == ayahs.first.number;

    _title = title;
    _surahNumber = targetSurahNumber;
    _errorMessage = null;

    if (isSamePlaylist && _playlistSource != null) {
      _currentIndex = startIndex;
      notifyListeners();
      try {
        await _player.seek(Duration.zero, index: startIndex);
        await _player.setSpeed(_speed);
        await _player.play();
        _preloadNextItems(startIndex);
      } catch (e) {
        debugPrint('Error seeking in existing playlist: $e');
      }
      return;
    }

    _playlist = List.from(ayahs);
    _currentIndex = startIndex;
    notifyListeners();

    final surahTitle = _title.isNotEmpty ? _title : 'Surah $targetSurahNumber';
    final List<AudioSource> sources = [];

    for (int i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      final mediaItem = MediaItem(
        id: 'quran_${targetSurahNumber}_${ayah.numberInSurah}',
        album: '$surahTitle (The Noble Qur\'an)',
        title: '$surahTitle • Verse ${ayah.numberInSurah}',
        artist: 'The Noble Qur\'an Recitation',
        extras: {
          'type': 'quran',
          'surahNumber': targetSurahNumber,
          'surahName': surahTitle,
          'route':
              '/quran/surah?num=$targetSurahNumber&name=${Uri.encodeComponent(surahTitle)}',
        },
      );

      final File localFile =
          await MediaDownloadService.instance.getLocalFile(ayah.localRelativePath);
      final bool isLocal =
          await localFile.exists() && (await localFile.length()) > 0;

      if (isLocal) {
        sources.add(AudioSource.file(localFile.path, tag: mediaItem));
      } else {
        final url = ayah.remoteUrl.isNotEmpty
            ? ayah.remoteUrl
            : 'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/quran-verses/${ayah.number}.mp3';
        sources.add(AudioSource.uri(Uri.parse(url), tag: mediaItem));
      }
    }

    _playlistSource = ConcatenatingAudioSource(children: sources);

    try {
      await _player.setAudioSource(
        _playlistSource!,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
        preload: true,
      );
      await _player.setSpeed(_speed);
      await _player.setLoopMode(_isLoopSingle ? LoopMode.one : LoopMode.off);
      await _player.play();
      _preloadNextItems(startIndex);
    } catch (e) {
      debugPrint('Error playing playlist: $e');
      _errorMessage = 'Unable to play audio. Check internet connection.';
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentIndex < 0 && _playlist.isNotEmpty) {
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
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> playPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_currentIndex == 0) {
      await _player.seek(Duration.zero);
      await _player.play();
    }
  }

  /// Jump directly to a specific verse index in the current playlist
  Future<void> playIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      notifyListeners();
      if (_playlistSource != null) {
        try {
          await _player.seek(Duration.zero, index: index);
          await _player.setSpeed(_speed);
          await _player.play();
          _preloadNextItems(index);
        } catch (e) {
          debugPrint('Error seeking to index $index: $e');
        }
      } else {
        await playPlaylist(_playlist, index, title: _title, surahNumber: _surahNumber);
      }
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
    _currentIndexSubscription?.cancel();
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
