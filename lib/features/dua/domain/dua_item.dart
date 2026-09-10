class DuaItem {
  final String id;
  final String title;
  final Map<String, String>? titles;
  final String category;
  final String arabic;
  final String transliteration;
  final Map<String, String>? transliterations;
  final String translation;
  final Map<String, String>? translations;
  final int repeatCount;
  final String reference;
  final String benefits;
  final Map<String, String>? benefitsMap;
  final String imagePath;
  final String? audioUrl;
  final bool isCustom;

  const DuaItem({
    required this.id,
    required this.title,
    this.titles,
    required this.category,
    required this.arabic,
    required this.transliteration,
    this.transliterations,
    required this.translation,
    this.translations,
    required this.repeatCount,
    required this.reference,
    required this.benefits,
    this.benefitsMap,
    this.imagePath = 'assets/images/dua.png',
    this.audioUrl,
    this.isCustom = false,
  });

  String getTitle([String lang = 'en']) {
    if (titles != null && titles!.containsKey(lang) && titles![lang]!.isNotEmpty) {
      return titles![lang]!;
    }
    return title;
  }

  String getTransliteration([String lang = 'en']) {
    if (transliterations != null &&
        transliterations!.containsKey(lang) &&
        transliterations![lang]!.isNotEmpty) {
      return transliterations![lang]!;
    }
    return transliteration;
  }

  String getTranslation([String lang = 'en']) {
    if (translations != null &&
        translations!.containsKey(lang) &&
        translations![lang]!.isNotEmpty) {
      return translations![lang]!;
    }
    return translation;
  }

  String getBenefits([String lang = 'en']) {
    if (benefitsMap != null &&
        benefitsMap!.containsKey(lang) &&
        benefitsMap![lang]!.isNotEmpty) {
      return benefitsMap![lang]!;
    }
    return benefits;
  }

  static String cleanCategory(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('waking') || lower == 'morning & waking') return 'Morning';
    if (lower.contains('morning')) return 'Morning';
    if (lower.contains('sleep') || lower.contains('bedtime')) return 'Sleep';
    if (lower.contains('restroom') || lower.contains('hygiene')) return 'Hygiene';
    if (lower.contains('adhan') || lower.contains('call to prayer')) return 'Adhan';
    if (lower.contains('after prayer')) return 'Prayer';
    if (lower.contains('prayer') || lower.contains('salah')) return 'Prayer';
    if (lower.contains('food') || lower.contains('fasting')) return 'Food';
    if (lower.contains('travel') || lower.contains('home & travel')) return 'Travel';
    if (lower.contains('distress') || lower.contains('fear')) return 'Distress';
    if (lower.contains('health') || lower.contains('healing')) return 'Healing';
    if (lower.contains('forgiveness') || lower.contains('repentance')) return 'Forgiveness';
    if (lower.contains('faith') || lower.contains('protection')) return 'Protection';
    if (lower.contains('guidance') || lower.contains('decision')) return 'Guidance';
    if (lower.contains('wealth') || lower.contains('sustenance')) return 'Sustenance';
    if (lower.contains('family') || lower.contains('children')) return 'Family';
    if (lower.contains('marriage') || lower.contains('love')) return 'Marriage';
    if (lower.contains('social') || lower.contains('etiquette')) return 'Etiquette';
    if (lower.contains('weather') || lower.contains('nature')) return 'Nature';
    if (lower.contains('hajj') || lower.contains('umrah')) return 'Hajj';
    if (lower.contains('end of life') || lower.contains('funeral') || lower.contains('death')) return 'Afterlife';
    if (lower.contains('dhikr')) return 'Dhikr';
    if (lower.contains('mosque')) return 'Mosque';
    if (lower.contains('clothing')) return 'Clothing';
    if (lower.contains('general')) return 'General';

    final words = raw.trim().split(RegExp(r'\s+'));
    if (words.length <= 2) {
      return words
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return words
        .take(2)
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    String arabic = '';
    Map<String, String>? transliterations;
    String transliteration = '';

    if (json['dua'] is Map) {
      final duaMap = json['dua'] as Map<String, dynamic>;
      arabic = (duaMap['arabic'] as String?) ?? '';
      if (duaMap['transliteration'] is Map) {
        transliterations = (duaMap['transliteration'] as Map).map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        );
        transliteration = transliterations['en'] ??
            (transliterations.values.isNotEmpty ? transliterations.values.first : '');
      } else if (duaMap['transliteration'] is String) {
        transliteration = duaMap['transliteration'] as String;
      }
    } else {
      arabic = json['arabic'] as String? ?? '';
      if (json['transliterations'] is Map) {
        transliterations = (json['transliterations'] as Map).map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        );
        transliteration = transliterations['en'] ?? (json['transliteration'] as String? ?? '');
      } else {
        transliteration = json['transliteration'] as String? ?? '';
      }
    }

    Map<String, String>? titles;
    String title = '';
    if (json['title'] is Map) {
      titles = (json['title'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      title = titles['en'] ?? (titles.values.isNotEmpty ? titles.values.first : '');
    } else if (json['titles'] is Map) {
      titles = (json['titles'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      title = titles['en'] ?? (json['title'] as String? ?? '');
    } else {
      title = json['title'] as String? ?? '';
    }

    Map<String, String>? translations;
    String translation = '';
    if (json['translation'] is Map) {
      translations = (json['translation'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      translation = translations['en'] ??
          (translations.values.isNotEmpty ? translations.values.first : '');
    } else if (json['translations'] is Map) {
      translations = (json['translations'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      translation = translations['en'] ?? (json['translation'] as String? ?? '');
    } else {
      translation = json['translation'] as String? ?? '';
    }

    Map<String, String>? benefitsMap;
    String benefits = '';
    if (json['benefits'] is Map) {
      benefitsMap = (json['benefits'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      benefits = benefitsMap['en'] ??
          (benefitsMap.values.isNotEmpty ? benefitsMap.values.first : '');
    } else if (json['benefitsMap'] is Map) {
      benefitsMap = (json['benefitsMap'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      benefits = benefitsMap['en'] ?? (json['benefits'] as String? ?? '');
    } else {
      benefits = json['benefits'] as String? ?? '';
    }

    final rawCategory = json['category'] as String? ?? 'General';
    final category = cleanCategory(rawCategory);

    return DuaItem(
      id: json['id'] as String? ?? '',
      title: title,
      titles: titles,
      category: category,
      arabic: arabic,
      transliteration: transliteration,
      transliterations: transliterations,
      translation: translation,
      translations: translations,
      repeatCount: (json['repeatCount'] as num?)?.toInt() ?? 1,
      reference: json['reference'] as String? ?? '',
      benefits: benefits,
      benefitsMap: benefitsMap,
      imagePath: json['imagePath'] as String? ?? 'assets/images/dua.png',
      audioUrl: json['audioUrl'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (titles != null) 'titles': titles,
      'category': category,
      'arabic': arabic,
      'transliteration': transliteration,
      if (transliterations != null) 'transliterations': transliterations,
      'translation': translation,
      if (translations != null) 'translations': translations,
      'repeatCount': repeatCount,
      'reference': reference,
      'benefits': benefits,
      if (benefitsMap != null) 'benefitsMap': benefitsMap,
      'imagePath': imagePath,
      if (audioUrl != null) 'audioUrl': audioUrl,
      'isCustom': isCustom,
    };
  }

  DuaItem copyWith({
    String? id,
    String? title,
    Map<String, String>? titles,
    String? category,
    String? arabic,
    String? transliteration,
    Map<String, String>? transliterations,
    String? translation,
    Map<String, String>? translations,
    int? repeatCount,
    String? reference,
    String? benefits,
    Map<String, String>? benefitsMap,
    String? imagePath,
    String? audioUrl,
    bool? isCustom,
  }) {
    return DuaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      titles: titles ?? this.titles,
      category: category ?? this.category,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      transliterations: transliterations ?? this.transliterations,
      translation: translation ?? this.translation,
      translations: translations ?? this.translations,
      repeatCount: repeatCount ?? this.repeatCount,
      reference: reference ?? this.reference,
      benefits: benefits ?? this.benefits,
      benefitsMap: benefitsMap ?? this.benefitsMap,
      imagePath: imagePath ?? this.imagePath,
      audioUrl: audioUrl ?? this.audioUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
