import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/surah_model.dart';
import '../data/quran_data.dart';

class QuranRepository {
  static List<SurahModel>? _cachedSurahs;

  /// Asynchronously loads full 114 Surahs dataset if available, or returns `quranSurahsList`
  Future<List<SurahModel>> loadQuranData() async {
    if (_cachedSurahs != null && _cachedSurahs!.isNotEmpty) {
      return _cachedSurahs!;
    }
    try {
      final jsonString = await rootBundle.loadString('assets/data/quran_verses.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _cachedSurahs = jsonList
          .map((s) => SurahModel.fromJson(s as Map<String, dynamic>))
          .toList();
      return _cachedSurahs!;
    } catch (e) {
      return getSurahs();
    }
  }

  /// Returns synchronous list from `lib/features/quran/data/quran_data.dart`
  List<SurahModel> getSurahs() {
    if (_cachedSurahs != null && _cachedSurahs!.isNotEmpty) {
      return _cachedSurahs!;
    }
    return quranSurahsList;
  }

  /// Returns ayahs for a given Surah number
  List<AyahModel> getAyahsForSurah(int surahNumber) {
    final list = _cachedSurahs ?? quranSurahsList;
    final surah = list.firstWhere(
      (s) => s.number == surahNumber,
      orElse: () => list.first,
    );
    return surah.ayahs;
  }

  /// Returns ayahs belonging to a specific Juz (Para) number (1-30)
  List<AyahModel> getAyahsForJuz(int juzNumber) {
    final list = _cachedSurahs ?? quranSurahsList;
    final List<AyahModel> juzAyahs = [];
    for (final surah in list) {
      for (final ayah in surah.ayahs) {
        if (ayah.juz == juzNumber) {
          juzAyahs.add(ayah);
        }
      }
    }
    if (juzAyahs.isEmpty) {
      return getAyahsForSurah(1);
    }
    return juzAyahs;
  }
}
