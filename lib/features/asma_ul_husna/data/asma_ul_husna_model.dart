class AsmaUlHusna {
  final int number;
  final String name;
  final String transliteration;
  final String meaning;
  final String audioUrl;

  const AsmaUlHusna({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.meaning,
    required this.audioUrl,
  });

  factory AsmaUlHusna.fromJson(Map<String, dynamic> json) {
    final num = json['number'] as int;
    final en = json['en'] as Map<String, dynamic>? ?? {};
    return AsmaUlHusna(
      number: num,
      name: json['name'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      meaning: en['meaning'] as String? ?? '',
      audioUrl: 'https://cdn.islamic.network/asma-al-husna/audio/$num.mp3',
    );
  }
}
