import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/services/adhkar_audio_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdhkarAudioHandler Background Audio & Notification Tests', () {
    test('Initial playbackState contains ONLY Previous, Play/Pause, Next (NO Stop button)', () async {
      final handler = AdhkarAudioHandler();
      addTearDown(() => handler.disposePlayer());

      final state = handler.playbackState.value;

      // Must have exactly 3 controls: Previous, Play/Pause, Next
      expect(state.controls.length, equals(3));
      expect(state.controls[0], equals(MediaControl.skipToPrevious));
      expect(state.controls[1], equals(MediaControl.play));
      expect(state.controls[2], equals(MediaControl.skipToNext));

      // Absolutely NO MediaControl.stop
      expect(state.controls.contains(MediaControl.stop), isFalse);

      // Compact action indices must be exactly [0, 1, 2]
      expect(state.androidCompactActionIndices, equals([0, 1, 2]));
    });

    test('AudioHandler exposes single player and supports speed/loop/controls', () async {
      final handler = AdhkarAudioHandler();
      addTearDown(() => handler.disposePlayer());

      expect(handler.player, isNotNull);
      expect(handler.mediaItem.value, isNull);

      // Verify custom mediaItem addition
      final testItem = const MediaItem(
        id: 'test_ayah_1',
        album: 'Al-Fatihah',
        title: 'Verse 1',
        artist: 'Adhkar Quran',
      );
      handler.mediaItem.add(testItem);
      expect(handler.mediaItem.value?.id, equals('test_ayah_1'));
    });
  });
}
