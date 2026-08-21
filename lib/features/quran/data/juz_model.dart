class JuzModel {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String surahRange;
  final int startPage;
  final int endPage;

  const JuzModel({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.surahRange,
    required this.startPage,
    required this.endPage,
  });
}

const List<JuzModel> juzList = [
  JuzModel(number: 1, nameArabic: 'آلم', nameEnglish: 'Alif Laam Meem', surahRange: 'Surah 1:1 - 2:141', startPage: 1, endPage: 21),
  JuzModel(number: 2, nameArabic: 'سَيَقُولُ', nameEnglish: 'Sayaqool', surahRange: 'Surah 2:142 - 2:252', startPage: 22, endPage: 41),
  JuzModel(number: 3, nameArabic: 'تِلْكَ الرُّسُلُ', nameEnglish: 'Tilkar Rusul', surahRange: 'Surah 2:253 - 3:92', startPage: 42, endPage: 61),
  JuzModel(number: 4, nameArabic: 'لَنْ تَنَالُوا', nameEnglish: 'Lan Tanaalu', surahRange: 'Surah 3:93 - 4:23', startPage: 62, endPage: 81),
  JuzModel(number: 5, nameArabic: 'وَالْمُحْصَنَاتُ', nameEnglish: 'Wal Muhsanat', surahRange: 'Surah 4:24 - 4:147', startPage: 82, endPage: 101),
  JuzModel(number: 6, nameArabic: 'لا يُحِبُّ اللَّهُ', nameEnglish: 'La Yuhibbullahu', surahRange: 'Surah 4:148 - 5:81', startPage: 102, endPage: 121),
  JuzModel(number: 7, nameArabic: 'وَإِذَا سَمِعُوا', nameEnglish: 'Wa Iza Samiu', surahRange: 'Surah 5:82 - 6:110', startPage: 122, endPage: 141),
  JuzModel(number: 8, nameArabic: 'وَلَوْ أَنَّنَا', nameEnglish: 'Wa Lau Annana', surahRange: 'Surah 6:111 - 7:87', startPage: 142, endPage: 161),
  JuzModel(number: 9, nameArabic: 'قَالَ الْمَلأُ', nameEnglish: 'Qalal Malao', surahRange: 'Surah 7:88 - 8:40', startPage: 162, endPage: 181),
  JuzModel(number: 10, nameArabic: 'وَاعْلَمُوا', nameEnglish: 'Walamu', surahRange: 'Surah 8:41 - 9:92', startPage: 182, endPage: 201),
  JuzModel(number: 11, nameArabic: 'يَعْتَذِرُونَ', nameEnglish: 'Yatazeroona', surahRange: 'Surah 9:93 - 11:5', startPage: 202, endPage: 221),
  JuzModel(number: 12, nameArabic: 'وَمَا مِنْ دَابَّةٍ', nameEnglish: 'Wa Mamin Dabbatin', surahRange: 'Surah 11:6 - 12:52', startPage: 222, endPage: 241),
  JuzModel(number: 13, nameArabic: 'وَمَا أُبَرِّئُ', nameEnglish: 'Wa Ma Ubarriu', surahRange: 'Surah 12:53 - 14:52', startPage: 242, endPage: 261),
  JuzModel(number: 14, nameArabic: 'رُبَمَا', nameEnglish: 'Rubama', surahRange: 'Surah 15:1 - 16:128', startPage: 262, endPage: 281),
  JuzModel(number: 15, nameArabic: 'سُبْحَانَ الَّذِي', nameEnglish: 'Subhanallazi', surahRange: 'Surah 17:1 - 18:74', startPage: 282, endPage: 301),
  JuzModel(number: 16, nameArabic: 'قَالَ أَلَمْ', nameEnglish: 'Qala Alam', surahRange: 'Surah 18:75 - 20:135', startPage: 302, endPage: 321),
  JuzModel(number: 17, nameArabic: 'اقْتَرَبَ لِلنَّاسِ', nameEnglish: 'Iqtaraba Linnasi', surahRange: 'Surah 21:1 - 22:78', startPage: 322, endPage: 341),
  JuzModel(number: 18, nameArabic: 'قَدْ أَفْلَحَ', nameEnglish: 'Qad Aflaha', surahRange: 'Surah 23:1 - 25:20', startPage: 342, endPage: 361),
  JuzModel(number: 19, nameArabic: 'وَقَالَ الَّذِينَ', nameEnglish: 'Wa Qalallazina', surahRange: 'Surah 25:21 - 27:55', startPage: 362, endPage: 381),
  JuzModel(number: 20, nameArabic: 'أَمَّنْ خَلَقَ', nameEnglish: 'Aman Khalaqa', surahRange: 'Surah 27:56 - 29:45', startPage: 382, endPage: 401),
  JuzModel(number: 21, nameArabic: 'اتْلُ مَا أُوحِيَ', nameEnglish: 'Utlu Ma Ohiya', surahRange: 'Surah 29:46 - 33:30', startPage: 402, endPage: 421),
  JuzModel(number: 22, nameArabic: 'وَمَنْ يَقْنُتْ', nameEnglish: 'Wa Manyaqnut', surahRange: 'Surah 33:31 - 36:27', startPage: 422, endPage: 441),
  JuzModel(number: 23, nameArabic: 'وَمَا لِيَ', nameEnglish: 'Wa Maliya', surahRange: 'Surah 36:28 - 39:31', startPage: 442, endPage: 461),
  JuzModel(number: 24, nameArabic: 'فَمَنْ أَظْلَمُ', nameEnglish: 'Faman Azlamu', surahRange: 'Surah 39:32 - 41:46', startPage: 462, endPage: 481),
  JuzModel(number: 25, nameArabic: 'إِلَيْهِ يُرَدُّ', nameEnglish: 'Elaahe Yuraddu', surahRange: 'Surah 41:47 - 45:37', startPage: 482, endPage: 501),
  JuzModel(number: 26, nameArabic: 'حم', nameEnglish: 'Ha Meem', surahRange: 'Surah 46:1 - 51:30', startPage: 502, endPage: 521),
  JuzModel(number: 27, nameArabic: 'قَالَ فَمَا خَطْبُكُمْ', nameEnglish: 'Qala Fama Khatbukum', surahRange: 'Surah 51:31 - 57:29', startPage: 522, endPage: 541),
  JuzModel(number: 28, nameArabic: 'قَدْ سَمِعَ اللَّهُ', nameEnglish: 'Qad Samiallahu', surahRange: 'Surah 58:1 - 66:12', startPage: 542, endPage: 561),
  JuzModel(number: 29, nameArabic: 'تَبَارَكَ الَّذِي', nameEnglish: 'Tabarakallazi', surahRange: 'Surah 67:1 - 77:50', startPage: 562, endPage: 581),
  JuzModel(number: 30, nameArabic: 'عَمَّ يَتَسَاءَلُونَ', nameEnglish: 'Amma Yatasaaloon', surahRange: 'Surah 78:1 - 114:6', startPage: 582, endPage: 604),
];
