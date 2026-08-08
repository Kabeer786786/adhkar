class DuaItem {
  final String id;
  final String title;
  final String category;
  final String arabic;
  final String transliteration;
  final String translation;
  final int repeatCount;
  final String reference;
  final String benefits;
  final String imagePath;
  final bool isCustom;

  const DuaItem({
    required this.id,
    required this.title,
    required this.category,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.repeatCount,
    required this.reference,
    required this.benefits,   
    this.imagePath = 'assets/images/dua.png',
    this.isCustom = false,
  });

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    return DuaItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Daily',
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      repeatCount: json['repeatCount'] as int? ?? 1,
      reference: json['reference'] as String? ?? '',
      benefits: json['benefits'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? 'assets/images/dua.png',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'arabic': arabic,
      'transliteration': transliteration,
      'translation': translation,
      'repeatCount': repeatCount,
      'reference': reference,
      'benefits': benefits,
      'imagePath': imagePath,
      'isCustom': isCustom,
    };
  }

  DuaItem copyWith({
    String? id,
    String? title,
    String? category,
    String? arabic,
    String? transliteration,
    String? translation,
    int? repeatCount,
    String? reference,
    String? benefits,
    String? imagePath,
    bool? isCustom,
  }) {
    return DuaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      repeatCount: repeatCount ?? this.repeatCount,
      reference: reference ?? this.reference,
      benefits: benefits ?? this.benefits,
      imagePath: imagePath ?? this.imagePath,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
