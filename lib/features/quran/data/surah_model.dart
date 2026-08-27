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
    final surahNum = json['number'] as int;
    final rawAyahs = json['ayahs'] as List<dynamic>? ?? [];
    final parsedAyahs = rawAyahs
        .map((a) => AyahModel.fromJson(a as Map<String, dynamic>, surahNumber: surahNum))
        .toList();

    return SurahModel(
      number: surahNum,
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
  final int? surahNumber;
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
    this.surahNumber,
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

  /// Cleaned Arabic text with Bismillah stripped from verse 1 for surahs 2-114 (since Bismillah is placed in the header)
  String get displayArabicText {
    var text = arabicText
        .replaceAll(RegExp(r'\s*\(\d+:\d+\)\s*'), '')
        .replaceAll(RegExp(r'\s*﴿\d+:\d+﴾\s*'), '')
        .replaceAll(RegExp(r'\s*﴿\d+﴾\s*'), '')
        .replaceAll('\uFEFF', '')
        .trim();

    if (numberInSurah == 1 && number != 1) {
      final bismillahRegex = RegExp(
        r'^(?:[\uFEFF\s]*بّ?ِ?سْمِ\s+[ٱا]للَّ?ٰ?هِ\s+[ٱا]لرَّحْمَٰ?نِ\s+[ٱا]لرَّحِيمِ\s*|[\uFEFF\s]*بّ?ِ?سْمِ\s+اللَّهِ\s+الرَّحْمَٰنِ\s+الرَّحِيمِ\s*)',
      );
      final match = bismillahRegex.firstMatch(text);
      if (match != null && match.end < text.length) {
        text = text.substring(match.end).trim();
      }
    }
    return text;
  }

  factory AyahModel.fromJson(Map<String, dynamic> json, {int? surahNumber}) {
    final num = json['number'] as int;
    final fileName = json['audio_filename'] as String? ?? '$num.mp3';
    final remote = json['remote_url'] as String? ??
        'https://pub-25ef4bcbbacc4eaebd26c9c4f3e19216.r2.dev/quran-verses/$num.mp3';

    return AyahModel(
      number: num,
      numberInSurah: json['numberInSurah'] as int? ?? num,
      surahNumber: surahNumber ?? json['surahNumber'] as int?,
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
        surahNumber,
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
