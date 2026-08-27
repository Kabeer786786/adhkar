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
  static const String defaultRingtone = 'Iphone Ringtone';

  /// Available audio choices shown in the UI dropdown.
  static const List<String> soundOptions = [
    'Iphone Ringtone',
    'Glassy Bell',
    'Galaxy Bells',
    'Samsung Ringtone',
    'Madinah Azaan',
    'Default Ringtone',
  ];

  /// Mapping from sound title to local Flutter asset path.
  static const Map<String, String> audioAssetPaths = {
    'Iphone Ringtone': 'assets/audios/iphone_original.mp3',
    'iPhone Ringtone': 'assets/audios/iphone_original.mp3',
    'iphone_original': 'assets/audios/iphone_original.mp3',
    'Glassy Bell': 'assets/audios/glassy_bell.mp3',
    'glassy_bell': 'assets/audios/glassy_bell.mp3',
    'Galaxy Bells': 'assets/audios/galaxy_bells.mp3',
    'galaxy_bells': 'assets/audios/galaxy_bells.mp3',
    'Samsung Ringtone': 'assets/audios/samsung_ringtone.mp3',
    'samsung_ringtone': 'assets/audios/samsung_ringtone.mp3',
    'Madinah Azaan': 'assets/audios/madina_azaan.mp3',
    'Madina Azaan': 'assets/audios/madina_azaan.mp3',
    'Azaan': 'assets/audios/madina_azaan.mp3',
    'Default Ringtone': 'assets/audios/ringtone.ogg',
    'Alarm Ringtone': 'assets/audios/ringtone.ogg',
    'Ringtone': 'assets/audios/ringtone.ogg',
    'Digital Alarm': 'assets/audios/digital_alarm.ogg',
    'Gentle Chime': 'assets/audios/glassy_bell.mp3',
  };

  /// Returns the asset path for a given [soundType], with intelligent fallbacks.
  static String getAssetPath(String? soundType) {
    if (soundType == null || soundType.isEmpty) {
      return audioAssetPaths[defaultRingtone]!;
    }
    if (audioAssetPaths.containsKey(soundType)) {
      return audioAssetPaths[soundType]!;
    }
    final lower = soundType.toLowerCase();
    if (lower.contains('iphone')) {
      return audioAssetPaths['Iphone Ringtone']!;
    }
    if (lower.contains('glassy')) {
      return audioAssetPaths['Glassy Bell']!;
    }
    if (lower.contains('galaxy')) {
      return audioAssetPaths['Galaxy Bells']!;
    }
    if (lower.contains('samsung')) {
      return audioAssetPaths['Samsung Ringtone']!;
    }
    if (lower.contains('azaan') || lower.contains('adhan')) {
      return audioAssetPaths['Madinah Azaan']!;
    }
    if (lower.contains('digital')) {
      return audioAssetPaths['Digital Alarm']!;
    }
    return audioAssetPaths['Default Ringtone']!;
  }

  /// Returns the raw Android resource name (without extension) for notification channels.
  static String getRawResourceName(String? soundType) {
    if (soundType == null || soundType.isEmpty) return 'iphone_original';
    final lower = soundType.toLowerCase();
    if (lower.contains('iphone')) return 'iphone_original';
    if (lower.contains('glassy')) return 'glassy_bell';
    if (lower.contains('galaxy')) return 'galaxy_bells';
    if (lower.contains('samsung')) return 'samsung_ringtone';
    if (lower.contains('azaan') || lower.contains('adhan')) return 'madina_azaan';
    if (lower.contains('ringtone')) return 'ringtone';
    return 'iphone_original';
  }
}
