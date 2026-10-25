import 'package:equatable/equatable.dart';

class DhikrItem extends Equatable {
  final String id;
  final String category;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String reference;
  final String virtue;
  final int countTarget;
  final int countCurrent;
  final String? audioUrl;
  final int? surahNumber;
  final String? surahName;

  // 4 Types support: 'quran', 'dua', 'tasbeeh', 'custom'
  final String type;
  final String? surahNameArabic;
  final String? surahMeaning;
  final String? duaId;
  final Map<String, String>? titles;
  final Map<String, String>? translations;
  final Map<String, String>? transliterations;
  final Map<String, String>? benefitsMap;
  final String? tasbeehId;
  final String? tasbeehName;

  const DhikrItem({
    required this.id,
    required this.category,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.reference,
    required this.virtue,
    required this.countTarget,
    this.countCurrent = 0,
    this.audioUrl,
    this.surahNumber,
    this.surahName,
    this.type = 'custom',
    this.surahNameArabic,
    this.surahMeaning,
    this.duaId,
    this.titles,
    this.translations,
    this.transliterations,
    this.benefitsMap,
    this.tasbeehId,
    this.tasbeehName,
  });

  bool get isSurah => surahNumber != null && surahNumber! > 0;
  bool get isQuran => type == 'quran' || isSurah;
  bool get isDua => type == 'dua';
  bool get isTasbeeh => type == 'tasbeeh';
  bool get isCustom => type == 'custom' && !isSurah;

  String getTitle([String lang = 'en']) {
    if (titles != null && titles!.containsKey(lang) && titles![lang]!.isNotEmpty) {
      return titles![lang]!;
    }
    if (surahName != null && surahName!.isNotEmpty) {
      return 'Surah $surahName';
    }
    if (tasbeehName != null && tasbeehName!.isNotEmpty) {
      return tasbeehName!;
    }
    return translation.isNotEmpty ? translation : 'Dhikr';
  }

  String getTranslation([String lang = 'en']) {
    if (translations != null && translations!.containsKey(lang) && translations![lang]!.isNotEmpty) {
      return translations![lang]!;
    }
    return translation;
  }

  String getTransliteration([String lang = 'en']) {
    if (transliterations != null && transliterations!.containsKey(lang) && transliterations![lang]!.isNotEmpty) {
      return transliterations![lang]!;
    }
    return transliteration;
  }

  String getBenefits([String lang = 'en']) {
    if (benefitsMap != null && benefitsMap!.containsKey(lang) && benefitsMap![lang]!.isNotEmpty) {
      return benefitsMap![lang]!;
    }
    return virtue;
  }

  DhikrItem copyWith({
    String? id,
    String? category,
    String? arabicText,
    String? transliteration,
    String? translation,
    String? reference,
    String? virtue,
    int? countTarget,
    int? countCurrent,
    String? audioUrl,
    int? surahNumber,
    String? surahName,
    String? type,
    String? surahNameArabic,
    String? surahMeaning,
    String? duaId,
    Map<String, String>? titles,
    Map<String, String>? translations,
    Map<String, String>? transliterations,
    Map<String, String>? benefitsMap,
    String? tasbeehId,
    String? tasbeehName,
  }) {
    return DhikrItem(
      id: id ?? this.id,
      category: category ?? this.category,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      reference: reference ?? this.reference,
      virtue: virtue ?? this.virtue,
      countTarget: countTarget ?? this.countTarget,
      countCurrent: countCurrent ?? this.countCurrent,
      audioUrl: audioUrl ?? this.audioUrl,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      type: type ?? this.type,
      surahNameArabic: surahNameArabic ?? this.surahNameArabic,
      surahMeaning: surahMeaning ?? this.surahMeaning,
      duaId: duaId ?? this.duaId,
      titles: titles ?? this.titles,
      translations: translations ?? this.translations,
      transliterations: transliterations ?? this.transliterations,
      benefitsMap: benefitsMap ?? this.benefitsMap,
      tasbeehId: tasbeehId ?? this.tasbeehId,
      tasbeehName: tasbeehName ?? this.tasbeehName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'arabicText': arabicText,
      'transliteration': transliteration,
      'translation': translation,
      'reference': reference,
      'virtue': virtue,
      'countTarget': countTarget,
      'countCurrent': countCurrent,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (surahNumber != null) 'surahNumber': surahNumber,
      if (surahName != null) 'surahName': surahName,
      'type': type,
      if (surahNameArabic != null) 'surahNameArabic': surahNameArabic,
      if (surahMeaning != null) 'surahMeaning': surahMeaning,
      if (duaId != null) 'duaId': duaId,
      if (titles != null) 'titles': titles,
      if (translations != null) 'translations': translations,
      if (transliterations != null) 'transliterations': transliterations,
      if (benefitsMap != null) 'benefitsMap': benefitsMap,
      if (tasbeehId != null) 'tasbeehId': tasbeehId,
      if (tasbeehName != null) 'tasbeehName': tasbeehName,
    };
  }

  factory DhikrItem.fromJson(Map<String, dynamic> json) {
    final surahNum = (json['surahNumber'] as num?)?.toInt();
    final rawType = json['type'] as String?;
    final resolvedType = rawType ?? ((surahNum != null && surahNum > 0) ? 'quran' : 'custom');

    Map<String, String>? parseMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return null;
    }

    return DhikrItem(
      id: json['id'] as String,
      category: (json['category'] as String?) ?? 'custom',
      arabicText: (json['arabicText'] as String?) ?? '',
      transliteration: (json['transliteration'] as String?) ?? '',
      translation: (json['translation'] as String?) ?? '',
      reference: (json['reference'] as String?) ?? '',
      virtue: (json['virtue'] as String?) ?? '',
      countTarget: (json['countTarget'] as num?)?.toInt() ?? 1,
      countCurrent: (json['countCurrent'] as num?)?.toInt() ?? 0,
      audioUrl: json['audioUrl'] as String?,
      surahNumber: surahNum,
      surahName: json['surahName'] as String?,
      type: resolvedType,
      surahNameArabic: json['surahNameArabic'] as String?,
      surahMeaning: json['surahMeaning'] as String?,
      duaId: json['duaId'] as String?,
      titles: parseMap(json['titles']),
      translations: parseMap(json['translations']),
      transliterations: parseMap(json['transliterations']),
      benefitsMap: parseMap(json['benefitsMap']),
      tasbeehId: json['tasbeehId'] as String?,
      tasbeehName: json['tasbeehName'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        category,
        arabicText,
        transliteration,
        translation,
        reference,
        virtue,
        countTarget,
        countCurrent,
        audioUrl,
        surahNumber,
        surahName,
        type,
        surahNameArabic,
        surahMeaning,
        duaId,
        titles,
        translations,
        transliterations,
        benefitsMap,
        tasbeehId,
        tasbeehName,
      ];
}
