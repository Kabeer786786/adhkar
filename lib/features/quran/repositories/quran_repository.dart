import '../../../shared/models/surah_model.dart';

class QuranRepository {
  List<SurahModel> getSurahs() {
    return const [
      SurahModel(number: 1, nameArabic: 'الفاتحة', nameEnglish: 'Al-Fatiha', nameTranslation: 'The Opening', verseCount: 7, revelationType: 'Meccan'),
      SurahModel(number: 2, nameArabic: 'البقرة', nameEnglish: 'Al-Baqarah', nameTranslation: 'The Cow', verseCount: 286, revelationType: 'Medinan'),
      SurahModel(number: 3, nameArabic: 'آل عمران', nameEnglish: 'Ali \'Imran', nameTranslation: 'Family of Imran', verseCount: 200, revelationType: 'Medinan'),
      SurahModel(number: 4, nameArabic: 'النساء', nameEnglish: 'An-Nisa', nameTranslation: 'The Women', verseCount: 176, revelationType: 'Medinan'),
      SurahModel(number: 5, nameArabic: 'المائدة', nameEnglish: 'Al-Ma\'idah', nameTranslation: 'The Table Spread', verseCount: 120, revelationType: 'Medinan'),
      SurahModel(number: 18, nameArabic: 'الكهف', nameEnglish: 'Al-Kahf', nameTranslation: 'The Cave', verseCount: 110, revelationType: 'Meccan'),
      SurahModel(number: 36, nameArabic: 'يس', nameEnglish: 'Ya-Sin', nameTranslation: 'Ya-Sin', verseCount: 83, revelationType: 'Meccan'),
      SurahModel(number: 55, nameArabic: 'الرحمن', nameEnglish: 'Ar-Rahman', nameTranslation: 'The Beneficent', verseCount: 78, revelationType: 'Medinan'),
      SurahModel(number: 67, nameArabic: 'الملك', nameEnglish: 'Al-Mulk', nameTranslation: 'The Sovereignty', verseCount: 30, revelationType: 'Meccan'),
      SurahModel(number: 112, nameArabic: 'الإخلاص', nameEnglish: 'Al-Ikhlas', nameTranslation: 'Sincerity', verseCount: 4, revelationType: 'Meccan'),
      SurahModel(number: 113, nameArabic: 'الفلق', nameEnglish: 'Al-Falaq', nameTranslation: 'The Daybreak', verseCount: 5, revelationType: 'Meccan'),
      SurahModel(number: 114, nameArabic: 'الناس', nameEnglish: 'An-Nas', nameTranslation: 'Mankind', verseCount: 6, revelationType: 'Meccan'),
    ];
  }

  List<AyahModel> getAyahsForSurah(int surahNumber) {
    if (surahNumber == 1) {
      return const [
        AyahModel(number: 1, numberInSurah: 1, arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', englishTranslation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.'),
        AyahModel(number: 2, numberInSurah: 2, arabicText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', englishTranslation: '[All] praise is [due] to Allah, Lord of the worlds -'),
        AyahModel(number: 3, numberInSurah: 3, arabicText: 'الرَّحْمَٰنِ الرَّحِيمِ', englishTranslation: 'The Entirely Merciful, the Especially Merciful,'),
        AyahModel(number: 4, numberInSurah: 4, arabicText: 'مَالِكِ يَوْمِ الدِّينِ', englishTranslation: 'Sovereign of the Day of Recompense.'),
        AyahModel(number: 5, numberInSurah: 5, arabicText: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', englishTranslation: 'It is You we worship and You we ask for help.'),
        AyahModel(number: 6, numberInSurah: 6, arabicText: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', englishTranslation: 'Guide us to the straight path -'),
        AyahModel(number: 7, numberInSurah: 7, arabicText: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', englishTranslation: 'The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.'),
      ];
    } else if (surahNumber == 112) {
      return const [
        AyahModel(number: 1, numberInSurah: 1, arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ', englishTranslation: 'Say, "He is Allah, [who is] One,'),
        AyahModel(number: 2, numberInSurah: 2, arabicText: 'اللَّهُ الصَّمَدُ', englishTranslation: 'Allah, the Eternal Refuge.'),
        AyahModel(number: 3, numberInSurah: 3, arabicText: 'لَمْ يَلِدْ وَلَمْ يُولَدْ', englishTranslation: 'He neither begets nor is born,'),
        AyahModel(number: 4, numberInSurah: 4, arabicText: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ', englishTranslation: 'Nor is there to Him any equivalent."'),
      ];
    }

    return List.generate(5, (index) {
      return AyahModel(
        number: index + 1,
        numberInSurah: index + 1,
        arabicText: 'وَقُل رَّبِّ زِدْنِي عِلْمًا وَاهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
        englishTranslation: 'And say: My Lord, increase me in knowledge. Guide us on the straight path.',
      );
    });
  }
}
