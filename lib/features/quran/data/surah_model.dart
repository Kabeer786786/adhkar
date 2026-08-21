import 'package:equatable/equatable.dart';

class SurahModel extends Equatable {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String nameTranslation;
  final int verseCount;
  final String revelationType;
  final List<AyahModel> ayahs;

  const SurahModel({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameTranslation,
    required this.verseCount,
    required this.revelationType,
    this.ayahs = const [],
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'] as List<dynamic>? ?? [];
    final parsedAyahs = rawAyahs
        .map((a) => AyahModel.fromJson(a as Map<String, dynamic>))
        .toList();

    return SurahModel(
      number: json['number'] as int,
      nameArabic: json['name'] as String? ?? json['nameArabic'] as String? ?? '',
      nameEnglish: json['englishName'] as String? ?? json['nameEnglish'] as String? ?? '',
      nameTranslation: json['englishNameTranslation'] as String? ?? json['nameTranslation'] as String? ?? '',
      verseCount: parsedAyahs.isNotEmpty
          ? parsedAyahs.length
          : (json['verseCount'] as int? ?? 0),
      revelationType: json['revelationType'] as String? ?? 'Meccan',
      ayahs: parsedAyahs,
    );
  }

  @override
  List<Object?> get props => [
        number,
        nameArabic,
        nameEnglish,
        nameTranslation,
        verseCount,
        revelationType,
        ayahs,
      ];
}

class AyahModel extends Equatable {
  final int number;
  final int numberInSurah;
  final String arabicText;
  final String englishTranslation;
  final String transliteration;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final dynamic sajda;
  final String audioFileName;
  final String remoteUrl;

  const AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.arabicText,
    required this.englishTranslation,
    this.transliteration = '',
    this.juz = 1,
    this.manzil = 1,
    this.page = 1,
    this.ruku = 1,
    this.hizbQuarter = 1,
    this.sajda = false,
    this.audioFileName = '',
    this.remoteUrl = '',
  });

  /// Relative path for local storage audio caching (e.g. 'quran/1.mp3')
  String get localRelativePath => 'quran/${audioFileName.isEmpty ? "$number.mp3" : audioFileName}';

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    final num = json['number'] as int;
    final fileName = json['audio_filename'] as String? ?? '$num.mp3';
    final remote = json['remote_url'] as String? ??
        'https://github.com/Kabeer786786/adhkar/releases/download/v1.0.0/quran-$num.mp3';

    return AyahModel(
      number: num,
      numberInSurah: json['numberInSurah'] as int? ?? num,
      arabicText: json['text'] as String? ?? json['arabicText'] as String? ?? '',
      englishTranslation: json['translation'] as String? ?? json['englishTranslation'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      juz: json['juz'] as int? ?? 1,
      manzil: json['manzil'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      ruku: json['ruku'] as int? ?? 1,
      hizbQuarter: json['hizbQuarter'] as int? ?? 1,
      sajda: json['sajda'],
      audioFileName: fileName,
      remoteUrl: remote,
    );
  }

  @override
  List<Object?> get props => [
        number,
        numberInSurah,
        arabicText,
        englishTranslation,
        transliteration,
        juz,
        manzil,
        page,
        ruku,
        hizbQuarter,
        sajda,
        audioFileName,
        remoteUrl,
      ];
}
