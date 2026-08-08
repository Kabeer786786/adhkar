import 'package:equatable/equatable.dart';

class SurahModel extends Equatable {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String nameTranslation;
  final int verseCount;
  final String revelationType;

  const SurahModel({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameTranslation,
    required this.verseCount,
    required this.revelationType,
  });

  @override
  List<Object?> get props => [
        number,
        nameArabic,
        nameEnglish,
        nameTranslation,
        verseCount,
        revelationType,
      ];
}

class AyahModel extends Equatable {
  final int number;
  final int numberInSurah;
  final String arabicText;
  final String englishTranslation;
  final String? audioUrl;

  const AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.arabicText,
    required this.englishTranslation,
    this.audioUrl,
  });

  @override
  List<Object?> get props => [
        number,
        numberInSurah,
        arabicText,
        englishTranslation,
        audioUrl,
      ];
}
