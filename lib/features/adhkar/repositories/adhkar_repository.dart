import '../../../shared/models/adhkar_category.dart';
import '../../../shared/models/dhikr_item.dart';

class AdhkarRepository {
  List<DhikrItem> getAllDefaultAdhkar() {
    return [
      ..._morningAdhkar,
      ..._eveningAdhkar,
      ..._afterSalahAdhkar,
      ..._sleepAdhkar,
      ..._dailyDuas,
    ];
  }

  List<AdhkarCategory> getDefaultCategories() {
    return const [
      AdhkarCategory(
        id: 'morning',
        title: 'Morning Adhkar',
        subtitle:
            'Duas & Adhkar to read after Fajr until sunrise for protection & peace.',
        titleAr: 'أذكار الصباح',
        imagePath: 'assets/images/reminder.png',
        gradientIndex: 1,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'evening',
        title: 'Evening Adhkar',
        subtitle:
            'Evening Duas & Adhkar for peace, protection and divine blessings.',
        titleAr: 'أذكار المساء',
        imagePath: 'assets/images/memorize.png',
        gradientIndex: 2,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'salah',
        title: 'After Salah Adhkar',
        subtitle: 'Recommended Dhikr and Tasbeeh after obligatory prayers.',
        titleAr: 'أذكار بعد الصلاة',
        imagePath: 'assets/images/tasbeeh.png',
        gradientIndex: 0,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'sleep',
        title: 'Before Sleep Adhkar',
        subtitle: 'Nightly Duas & Adhkar for peaceful sleep and protection.',
        titleAr: 'أذكار النوم',
        imagePath: 'assets/images/books.png',
        gradientIndex: 4,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'duas',
        title: 'Daily Duas',
        subtitle:
            'Comprehensive Quranic and Sunnah Duas & Adhkar for daily life.',
        titleAr: 'أدعية يومية',
        imagePath: 'assets/images/dua.png',
        gradientIndex: 6,
        isDefault: true,
      ),
    ];
  }

  List<DhikrItem> getAdhkarByCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return List<DhikrItem>.from(_morningAdhkar);
      case 'evening':
        return List<DhikrItem>.from(_eveningAdhkar);
      case 'salah':
        return List<DhikrItem>.from(_afterSalahAdhkar);
      case 'sleep':
        return List<DhikrItem>.from(_sleepAdhkar);
      case 'duas':
      default:
        return List<DhikrItem>.from(_dailyDuas);
    }
  }

  static const List<DhikrItem> _morningAdhkar = [
    DhikrItem(
      id: 'm1',
      category: 'morning',
      arabicText:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      transliteration:
          'Asbahna wa-asbahal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la shareeka lah.',
      translation:
          'We have reached the morning and at this very time all sovereignty belongs to Allah, praise is for Allah. None has the right to be worshipped except Allah alone.',
      reference: 'Muslim 4/2088',
      virtue:
          'Whosoever recites this in the morning will be granted protection and peace throughout the day.',
      countTarget: 1,
    ),
    DhikrItem(
      id: 'm2',
      category: 'morning',
      arabicText:
          'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
      transliteration:
          'Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namootu wa ilaykan-nushoor.',
      translation:
          'O Allah, by Your leave we reach the morning and by Your leave we reach the evening, by Your leave we live and die and unto You is our resurrection.',
      reference: 'Tirmidhi 3/142',
      virtue:
          'Expresses total reliance and submission to Allah at the start of the day.',
      countTarget: 1,
    ),
    DhikrItem(
      id: 'm3',
      category: 'morning',
      arabicText:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
      transliteration:
          'Allahumma anta Rabbee la ilaha illa anta, khalaqtanee wa ana \'abduka, wa ana \'ala \'ahdika wa wa\'dika mas-tata\'tu.',
      translation:
          'O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant, and I abide by Your covenant.',
      reference: 'Sayyid al-Istighfar (Bukhari 7/150)',
      virtue:
          'If recited during the day with firm belief and one dies that day, he will enter Paradise.',
      countTarget: 1,
    ),
    DhikrItem(
      id: 'm4',
      category: 'morning',
      arabicText:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      transliteration:
          'Subhanallahi wa bihamdihi: \'Adada khalqihi, wa rida nafsihi, wa zinata \'arshihi, wa midada kalimatihi.',
      translation:
          'Glory is to Allah and praise is to Him, by the number of His creation and His pleasure, and by the weight of His Throne.',
      reference: 'Muslim 4/2090',
      virtue:
          'Recompensed with reward heavier than all morning Adhkar combined.',
      countTarget: 3,
    ),
    DhikrItem(
      id: 'm5',
      category: 'morning',
      arabicText:
          'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      transliteration:
          'Bismillahil-ladhi la yadurru ma\'as-mihi shay\'un fil-ardi wa la fis-sama\'i wa Huwas-Samee\'ul-\'Aleem.',
      translation:
          'In the Name of Allah with Whose Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, All-Knowing.',
      reference: 'Abu Dawud 4/323',
      virtue:
          'Whoever recites it three times in the morning will not be afflicted by any sudden calamity until evening.',
      countTarget: 3,
    ),
  ];

  static const List<DhikrItem> _eveningAdhkar = [
    DhikrItem(
      id: 'e1',
      category: 'evening',
      arabicText:
          'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      transliteration:
          'Amsayna wa amsal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la shareeka lah.',
      translation:
          'We have reached the evening and at this very time all sovereignty belongs to Allah, praise is for Allah.',
      reference: 'Muslim 4/2088',
      virtue: 'Protection and divine peace throughout the night.',
      countTarget: 1,
    ),
    DhikrItem(
      id: 'e2',
      category: 'evening',
      arabicText:
          'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      transliteration:
          'A\'udhu bikalimatil-lahit-tammati min sharri ma khalaq.',
      translation:
          'I seek refuge in the Perfect Words of Allah from the evil of what He has created.',
      reference: 'Muslim 4/2081',
      virtue:
          'Whoever recites it three times in the evening will not be harmed by any creature during that night.',
      countTarget: 3,
    ),
  ];

  static const List<DhikrItem> _afterSalahAdhkar = [
    DhikrItem(
      id: 's1',
      category: 'salah',
      arabicText:
          'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ. اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration:
          'Astaghfirullah (3x). Allahumma antas-Salamu wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram.',
      translation:
          'I seek forgiveness from Allah. O Allah, You are As-Salam (Peace) and from You is peace. Blessed are You, O Owner of Majesty and Honor.',
      reference: 'Muslim 1/414',
      virtue: 'Recited immediately upon completing every obligatory prayer.',
      countTarget: 1,
    ),
    DhikrItem(
      id: 's2',
      category: 'salah',
      arabicText:
          'سُبْحَانَ اللَّهِ (33)، الْحَمْدُ لِلَّهِ (33)، اللَّهُ أَكْبَرُ (33)، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration:
          'SubhanAllah (33x), Alhamdulillah (33x), Allahu Akbar (33x), La ilaha illallahu wahdahu la shareeka lah...',
      translation:
          'Glory to Allah (33), Praise to Allah (33), Allah is the Greatest (33). None has the right to be worshipped except Allah alone.',
      reference: 'Muslim 1/418',
      virtue:
          'Sins will be forgiven even if they were like the foam of the sea.',
      countTarget: 99,
    ),
  ];

  static const List<DhikrItem> _sleepAdhkar = [
    DhikrItem(
      id: 'sl1',
      category: 'sleep',
      arabicText:
          'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِاسْمِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا',
      transliteration:
          'Bismika Rabbee wada\'tu janbee, wa bismika arfa\'uh, fa-in amsakta nafsee farhamha...',
      translation:
          'In Your name my Lord, I lie down, and in Your name I rise. If You take my soul, have mercy upon it, and if You release it, protect it.',
      reference: 'Bukhari 11/126',
      virtue: 'Angel protection while sleeping.',
      countTarget: 1,
    ),
  ];

  static const List<DhikrItem> _dailyDuas = [
    DhikrItem(
      id: 'd1',
      category: 'duas',
      arabicText:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar.',
      translation:
          'Our Lord, give us in this world that which is good and in the Hereafter that which is good, and save us from the punishment of the Fire.',
      reference: 'Surah Al-Baqarah 2:201',
      virtue: 'The most comprehensive dua taught in the Quran.',
      countTarget: 3,
    ),
  ];
}
