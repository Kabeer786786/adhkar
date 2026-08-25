/// Centralized configuration for Reminder and Alarm sound options.
///
/// ============================================================================
/// HOW TO ADD FUTURE AUDIO FILES TO THE APP:
/// ============================================================================
/// 1. Copy your audio file (e.g. `my_new_azaan.mp3`) into the `assets/audios/` folder:
///    `d:\Projects\Apps\adhkar\assets\audios\my_new_azaan.mp3`
///
/// 2. Ensure `assets/audios/` is declared under `flutter: assets:` in `pubspec.yaml`.
///
/// 3. Add your sound title to [soundOptions] list below, for example:
///    ```dart
///    static const List<String> soundOptions = [
///      'Madinah Azaan',
///      'Default Ringtone',
///      'My New Azaan', // <-- Add your title here
///    ];
///    ```
///
/// 4. Map the sound title to its asset path in [audioAssetPaths] map below:
///    ```dart
///    static const Map<String, String> audioAssetPaths = {
///      'Madinah Azaan': 'assets/audios/madina_azaan.mp3',
///      'Madina Azaan': 'assets/audios/madina_azaan.mp3',
///      'My New Azaan': 'assets/audios/my_new_azaan.mp3', // <-- Add mapping here
///    };
///    ```
/// ============================================================================
class ReminderAudioConfig {
  static const String defaultSound = 'Madinah Azaan';
  static const String defaultRingtone = 'Default Ringtone';

  /// Available audio choices shown in the UI dropdown.
  static const List<String> soundOptions = [
    'Madinah Azaan',
    'Default Ringtone',
  ];

  /// Mapping from sound title to local Flutter asset path.
  static const Map<String, String> audioAssetPaths = {
    'Madinah Azaan': 'assets/audios/madina_azaan.mp3',
    'Madina Azaan': 'assets/audios/madina_azaan.mp3',
  };

  /// Returns the asset path for a given [soundType], or null if it's default ringtone or unknown.
  static String? getAssetPath(String? soundType) {
    if (soundType == null || soundType.isEmpty) {
      return audioAssetPaths[defaultSound];
    }
    return audioAssetPaths[soundType];
  }
}
