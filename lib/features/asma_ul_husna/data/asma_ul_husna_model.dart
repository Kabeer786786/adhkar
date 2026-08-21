class AsmaUlHusna {
  final int number;
  final String name;
  final String transliteration;
  final String shortMeaning;
  final String longMeaning;
  final String audioUrl;
  final String audioFileName;
  final String remoteUrl;

  const AsmaUlHusna({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.shortMeaning,
    required this.longMeaning,
    required this.audioUrl,
    required this.audioFileName,
    required this.remoteUrl,
  });

  /// Backward-compatibility getter for `meaning`
  String get meaning => shortMeaning;

  /// Relative path for local storage caching (e.g. 'asma_ul_husna/1.mp3')
  String get localRelativePath => 'asma_ul_husna/$audioFileName';

  factory AsmaUlHusna.fromJson(Map<String, dynamic> json) {
    final num = json['number'] as int;
    final en = json['en'] as Map<String, dynamic>?;
    final name = json['name'] as String? ?? json['arabic'] as String? ?? '';
    final audioRaw = json['audio'] as String?;
    final fileName = json['audio_filename'] as String? ?? '$num.mp3';
    final remote = json['remote_url'] as String? ??
        'https://github.com/Kabeer786786/adhkar/releases/download/v1.0.0/asma-ul-husna-$num.mp3';

    String computedAudioUrl;
    if (audioRaw != null && audioRaw.isNotEmpty) {
      if (audioRaw.startsWith('http')) {
        computedAudioUrl = audioRaw;
      } else {
        computedAudioUrl = 'https://islamicapi.com${audioRaw.startsWith('/') ? '' : '/'}$audioRaw';
      }
    } else {
      computedAudioUrl = remote;
    }

    return AsmaUlHusna(
      number: num,
      name: name,
      transliteration: json['transliteration'] as String? ?? '',
      shortMeaning: json['shortMeaning'] as String? ??
          json['short_meaning'] as String? ??
          json['translation'] as String? ??
          json['english'] as String? ??
          en?['meaning'] as String? ??
          '',
      longMeaning: json['longMeaning'] as String? ??
          json['long_meaning'] as String? ??
          json['meaning'] as String? ??
          en?['meaning'] as String? ??
          '',
      audioUrl: computedAudioUrl,
      audioFileName: fileName,
      remoteUrl: remote,
    );
  }
}
