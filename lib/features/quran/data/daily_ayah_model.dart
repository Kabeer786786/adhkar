import 'dart:convert';

/// Represents the Daily Quran Ayah fetched from Al-Quran Cloud API.
class DailyAyahModel {
  final int number; // Global Quran ayah number (1..6236)
  final String arabicText;
  final String translationText;
  final int surahNumber;
  final String surahName; // Arabic name, e.g. "سُورَةُ البَقَرَةِ"
  final String surahEnglishName; // e.g. "Al-Baqara"
  final String surahEnglishTranslation; // e.g. "The Cow"
  final int numberOfAyahsInSurah;
  final int numberInSurah;
  final int juz;
  final int page;
  final int ruku;
  final int manzil;
  final int hizbQuarter;
  final bool sajda;
  final String dateKey; // Format: YYYY-MM-DD

  const DailyAyahModel({
    required this.number,
    required this.arabicText,
    required this.translationText,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.surahEnglishTranslation,
    required this.numberOfAyahsInSurah,
    required this.numberInSurah,
    required this.juz,
    this.page = 1,
    this.ruku = 1,
    this.manzil = 1,
    this.hizbQuarter = 1,
    this.sajda = false,
    required this.dateKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'arabicText': arabicText,
      'translationText': translationText,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'surahEnglishName': surahEnglishName,
      'surahEnglishTranslation': surahEnglishTranslation,
      'numberOfAyahsInSurah': numberOfAyahsInSurah,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'page': page,
      'ruku': ruku,
      'manzil': manzil,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
      'dateKey': dateKey,
    };
  }

  factory DailyAyahModel.fromMap(Map<String, dynamic> map) {
    return DailyAyahModel(
      number: (map['number'] as num?)?.toInt() ?? 255,
      arabicText: map['arabicText'] as String? ?? '',
      translationText: map['translationText'] as String? ?? '',
      surahNumber: (map['surahNumber'] as num?)?.toInt() ?? 2,
      surahName: map['surahName'] as String? ?? 'سُورَةُ البَقَرَةِ',
      surahEnglishName: map['surahEnglishName'] as String? ?? 'Al-Baqara',
      surahEnglishTranslation:
          map['surahEnglishTranslation'] as String? ?? 'The Cow',
      numberOfAyahsInSurah:
          (map['numberOfAyahsInSurah'] as num?)?.toInt() ?? 286,
      numberInSurah: (map['numberInSurah'] as num?)?.toInt() ?? 248,
      juz: (map['juz'] as num?)?.toInt() ?? 2,
      page: (map['page'] as num?)?.toInt() ?? 40,
      ruku: (map['ruku'] as num?)?.toInt() ?? 33,
      manzil: (map['manzil'] as num?)?.toInt() ?? 1,
      hizbQuarter: (map['hizbQuarter'] as num?)?.toInt() ?? 16,
      sajda: map['sajda'] as bool? ?? false,
      dateKey: map['dateKey'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DailyAyahModel.fromJson(String source) =>
      DailyAyahModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Creates a [DailyAyahModel] by combining Al-Quran Cloud API data
  /// from `quran-uthmani` and `en.sahih` editions.
  factory DailyAyahModel.fromApiData({
    required Map<String, dynamic> uthmaniData,
    required Map<String, dynamic> sahihData,
    required String dateKey,
  }) {
    final surahMap = uthmaniData['surah'] as Map<String, dynamic>? ??
        sahihData['surah'] as Map<String, dynamic>? ??
        {};

    dynamic sajdaVal = uthmaniData['sajda'] ?? sahihData['sajda'];
    bool isSajda = false;
    if (sajdaVal is bool) {
      isSajda = sajdaVal;
    } else if (sajdaVal != null && sajdaVal != false) {
      isSajda = true;
    }

    return DailyAyahModel(
      number: (uthmaniData['number'] as num?)?.toInt() ??
          (sahihData['number'] as num?)?.toInt() ??
          255,
      arabicText: uthmaniData['text'] as String? ?? '',
      translationText: sahihData['text'] as String? ?? '',
      surahNumber: (surahMap['number'] as num?)?.toInt() ?? 2,
      surahName: surahMap['name'] as String? ?? 'سُورَةُ البَقَرَةِ',
      surahEnglishName: surahMap['englishName'] as String? ?? 'Al-Baqara',
      surahEnglishTranslation:
          surahMap['englishNameTranslation'] as String? ?? 'The Cow',
      numberOfAyahsInSurah:
          (surahMap['numberOfAyahs'] as num?)?.toInt() ?? 286,
      numberInSurah: (uthmaniData['numberInSurah'] as num?)?.toInt() ??
          (sahihData['numberInSurah'] as num?)?.toInt() ??
          248,
      juz: (uthmaniData['juz'] as num?)?.toInt() ??
          (sahihData['juz'] as num?)?.toInt() ??
          2,
      page: (uthmaniData['page'] as num?)?.toInt() ?? 1,
      ruku: (uthmaniData['ruku'] as num?)?.toInt() ?? 1,
      manzil: (uthmaniData['manzil'] as num?)?.toInt() ?? 1,
      hizbQuarter: (uthmaniData['hizbQuarter'] as num?)?.toInt() ?? 1,
      sajda: isSajda,
      dateKey: dateKey,
    );
  }

  /// Curated default fallback Ayah from Surah Al-Baqarah
  static const DailyAyahModel defaultAyah = DailyAyahModel(
    number: 255,
    arabicText:
        'وَقَالَ لَهُمْ نَبِيُّهُمْ إِنَّ ءَايَةَ مُلْكِهِۦٓ أَن يَأْتِيَكُمُ ٱلتَّابُوتُ فِيهِ سَكِينَةٌۭ مِّن رَّبِّكُمْ وَبَقِيَّةٌۭ مِّمَّا تَرَكَ ءَالُ مُوسَىٰ وَءَالُ هَٰرُونَ تَحْمِلُهُ ٱلْمَلَٰٓئِكَةُ ۚ إِنَّ فِى ذَٰلِكَ لَءَايَةًۭ لَّكُمْ إِن كُنتُم مُّؤْمِنِينَ',
    translationText:
        'And their prophet said to them, "Indeed, a sign of his kingship is that the chest will come to you in which is assurance from your Lord and a remnant of what the family of Moses and the family of Aaron had left, carried by the angels. Indeed in that is a sign for you, if you are believers."',
    surahNumber: 2,
    surahName: 'سُورَةُ البَقَرَةِ',
    surahEnglishName: 'Al-Baqara',
    surahEnglishTranslation: 'The Cow',
    numberOfAyahsInSurah: 286,
    numberInSurah: 248,
    juz: 2,
    page: 40,
    ruku: 33,
    manzil: 1,
    hizbQuarter: 16,
    sajda: false,
    dateKey: 'default',
  );
}
