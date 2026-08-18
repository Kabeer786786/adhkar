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
    return AsmaUlHusna(
      number: num,
      name: name,
      transliteration: json['transliteration'] as String? ?? '',
      shortMeaning:
          json['shortMeaning'] as String? ??
          json['english'] as String? ??
          en?['meaning'] as String? ??
          '',
      longMeaning:
          json['longMeaning'] as String? ??
          json['meaning'] as String? ??
          en?['meaning'] as String? ??
          '',
      audioUrl: 'https://islamicapi.com/audio/asma-ul-husna/$name.mp3',
    );
  }
}
