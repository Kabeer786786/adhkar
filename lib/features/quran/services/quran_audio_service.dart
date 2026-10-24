import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/services/adhkar_audio_handler.dart';
import '../../../core/services/media_download_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../data/surah_model.dart';

class QuranAudioController extends ChangeNotifier {
  final AdhkarAudioHandler _audioHandler;
  AudioPlayer get _player => _audioHandler.player;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<SequenceState?>? _sequenceSubscription;

  ConcatenatingAudioSource? _playlistSource;
  List<AyahModel> _playlist = [];
  int _currentIndex = -1; // -1 means player inactive
  String _title = '';
  int? _surahNumber;
  bool _isSettingUpSource = false;

  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isLoopSurah = false;
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
  bool get isLoopSurah => _isLoopSurah;
  bool get isLoopSingle => _isLoopSurah;
  double get speed => _speed;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;

  void toggleRepeatSurah() {
    _isLoopSurah = !_isLoopSurah;
    _player.setLoopMode(_isLoopSurah ? LoopMode.all : LoopMode.off);
    notifyListeners();
  }

  void toggleLoopSingle() => toggleRepeatSurah();

  AyahModel? get currentAyah =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  AudioPlayer get player => _player;

  QuranAudioController(this._audioHandler) {
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

    _sequenceSubscription = _player.sequenceStateStream.listen((seqState) {
      if (_isSettingUpSource) return;
      if (seqState == null) return;
      final currentTag = seqState.currentSource?.tag;
      if (currentTag is MediaItem) {
        if (currentTag.extras?['type'] != 'quran') {
          if (_currentIndex != -1 || _playlistSource != null) {
            _currentIndex = -1;
            _isPlaying = false;
            // Invalidate stale playlist so it gets rebuilt next time
            _playlistSource = null;
            _playlist = [];
            notifyListeners();
          }
        }
      }
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

    // Only reuse if same playlist AND player still has our source active
    if (isSamePlaylist && _playlistSource != null && _player.audioSource == _playlistSource) {
      _currentIndex = startIndex;
      _isPlaying = true;
      notifyListeners();
      try {
        await _player.seek(Duration.zero, index: startIndex);
        await _player.setSpeed(_speed);
        await _player.play();
        _preloadNextItems(startIndex);
        return;
      } catch (e) {
        debugPrint('Error seeking in existing playlist: $e');
        // Playlist was invalidated externally, fall through to rebuild
        _playlistSource = null;
      }
    }

    _isSettingUpSource = true;
    _playlist = List.from(ayahs);
    _currentIndex = startIndex;
    _isPlaying = true;
    notifyListeners();

    try {
      // Cleanly stop any ongoing playback from other audio features
      await _player.stop();

      final surahTitle = _title.isNotEmpty ? _title : 'Surah $targetSurahNumber';
      final List<AudioSource> sources = [];
      final audioDir = await MediaDownloadService.instance.audioDirectory;

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

        final localFile = File('${audioDir.path}/${ayah.localRelativePath}');
        final bool isLocal = localFile.existsSync() && localFile.lengthSync() > 0;

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

      await _player.setAudioSource(
        _playlistSource!,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
        preload: false,
      );
      await _player.setSpeed(_speed);
      await _player.setLoopMode(_isLoopSurah ? LoopMode.all : LoopMode.off);
      await _player.play();
      _preloadNextItems(startIndex);
    } catch (e) {
      debugPrint('Error playing playlist: $e');
      _errorMessage = 'Unable to play audio. Check internet connection.';
      _isPlaying = false;
      _playlistSource = null;
      notifyListeners();
    } finally {
      _isSettingUpSource = false;
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
      // Only seek if our playlist is still the active source
      if (_playlistSource != null && _player.audioSource == _playlistSource) {
        try {
          await _player.seek(Duration.zero, index: index);
          await _player.setSpeed(_speed);
          await _player.play();
          _preloadNextItems(index);
        } catch (e) {
          debugPrint('Error seeking to index $index: $e');
          _playlistSource = null;
          await playPlaylist(_playlist, index, title: _title, surahNumber: _surahNumber);
        }
      } else {
        _playlistSource = null;
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
    await _audioHandler.stop();
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
    _sequenceSubscription?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for QuranAudioController
final quranAudioProvider = ChangeNotifierProvider<QuranAudioController>((ref) {
  final audioHandler = ref.watch(adhkarAudioHandlerProvider);
  final controller = QuranAudioController(audioHandler);
  ref.onDispose(() => controller.dispose());
  return controller;
});
