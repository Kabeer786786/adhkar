/// Centralized configuration for Reminder and Alarm sound options.
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
    'Digital Alarm',
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
    'madina_azaan': 'assets/audios/madina_azaan.mp3',
    'Default Ringtone': 'assets/audios/ringtone.ogg',
    'Alarm Ringtone': 'assets/audios/ringtone.ogg',
    'Ringtone': 'assets/audios/ringtone.ogg',
    'ringtone': 'assets/audios/ringtone.ogg',
    'Digital Alarm': 'assets/audios/digital_alarm.ogg',
    'digital_alarm': 'assets/audios/digital_alarm.ogg',
    'Gentle Chime': 'assets/audios/glassy_bell.mp3',
  };

  /// Normalizes any given sound name / alias into one of the canonical [soundOptions].
  static String canonicalSoundName(String? soundType) {
    if (soundType == null || soundType.trim().isEmpty) {
      return defaultRingtone;
    }
    final trimmed = soundType.trim();
    if (soundOptions.contains(trimmed)) {
      return trimmed;
    }
    final lower = trimmed.toLowerCase();
    if (lower.contains('iphone')) {
      return 'Iphone Ringtone';
    }
    if (lower.contains('glassy')) {
      return 'Glassy Bell';
    }
    if (lower.contains('galaxy')) {
      return 'Galaxy Bells';
    }
    if (lower.contains('samsung')) {
      return 'Samsung Ringtone';
    }
    if (lower.contains('azaan') || lower.contains('adhan')) {
      return 'Madinah Azaan';
    }
    if (lower.contains('digital')) {
      return 'Digital Alarm';
    }
    if (lower.contains('ringtone')) {
      return 'Default Ringtone';
    }
    return defaultRingtone;
  }

  /// Returns the asset path for a given [soundType], with intelligent fallbacks.
  static String getAssetPath(String? soundType) {
    final canonical = canonicalSoundName(soundType);
    return audioAssetPaths[canonical] ?? audioAssetPaths[defaultRingtone]!;
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
    if (lower.contains('digital')) return 'ringtone';
    return 'iphone_original';
  }
}
