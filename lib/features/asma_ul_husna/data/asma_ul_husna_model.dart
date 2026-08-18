class AsmaUlHusna {
  final int number;
  final String name;
  final String transliteration;
  final String shortMeaning;
  final String longMeaning;
  final String audioUrl;

  const AsmaUlHusna({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.shortMeaning,
    required this.longMeaning,
    required this.audioUrl,
  });

  /// Backward-compatibility getter for `meaning`
  String get meaning => shortMeaning;

  factory AsmaUlHusna.fromJson(Map<String, dynamic> json) { 
    final num = json['number'] as int;
    final en = json['en'] as Map<String, dynamic>?;
    final name = json['name'] as String? ?? json['arabic'] as String? ?? '';
    final audioRaw = json['audio'] as String?;

    String computedAudioUrl;
    if (audioRaw != null && audioRaw.isNotEmpty) { 
      if (audioRaw.startsWith('http')) { 
        computedAudioUrl = audioRaw;
      } else {
        computedAudioUrl = 'https://islamicapi.com${audioRaw.startsWith('/') ? '' : '/'}$audioRaw';
      }
    } else {
      computedAudioUrl = 'https://cdn.islamic.network/asma-al-husna/audio/$num.mp3';
    }

    return AsmaUlHusna(
      number: num,
      name: name,
      transliteration: json['transliteration'] as String? ?? '',
      shortMeaning: json['shortMeaning'] as String? ??
          json['translation'] as String? ??
          json['english'] as String? ??
          en?['meaning'] as String? ??
          '',
      longMeaning: json['longMeaning'] as String? ??
          json['meaning'] as String? ??
          en?['meaning'] as String? ??
          '',
      audioUrl: computedAudioUrl,
    );
  }
}
