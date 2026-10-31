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
        imagePath: 'assets/images/adhkar/morning_adhkar.png',
        gradientIndex: 1,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'evening',
        title: 'Evening Adhkar',
        subtitle:
            'Evening Duas & Adhkar for peace, protection and divine blessings.',
        titleAr: 'أذكار المساء',
        imagePath: 'assets/images/adhkar/evening_adhkar.png',
        gradientIndex: 2,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'salah',
        title: 'After Salah Adhkar',
        subtitle: 'Recommended Dhikr and Tasbeeh after obligatory prayers.',
        titleAr: 'أذكار بعد الصلاة',
        imagePath: 'assets/images/adhkar/after_salah_adhkar.png',
        gradientIndex: 0,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'sleep',
        title: 'Before Sleep Adhkar',
        subtitle: 'Nightly Duas & Adhkar for peaceful sleep and protection.',
        titleAr: 'أذكار النوم',
        imagePath: 'assets/images/adhkar/night_adhkar.png',
        gradientIndex: 4,
        isDefault: true,
      ),
      AdhkarCategory(
        id: 'duas',
        title: 'Daily Duas',
        subtitle:
            'Comprehensive Quranic and Sunnah Duas & Adhkar for daily life.',
        titleAr: 'أدعية يومية',
        imagePath: 'assets/images/adhkar/daily_duaeen.png',
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
    DhikrItem(
      id: 'e_waqiah',
      category: 'evening',
      arabicText: 'سُورَةُ الْوَاقِعَةِ',
      transliteration: 'Surah Al-Waqi\'ah (Chapter 56)',
      translation:
          'Recitation of Surah Al-Waqi\'ah in the evening brings spiritual richness and protection from poverty.',
      reference: 'Bayhaqi (Shu\'ab al-Iman 2269)',
      virtue:
          'Whoever recites Surah Al-Waqi\'ah every night will never be afflicted by poverty.',
      countTarget: 1,
      surahNumber: 56,
      surahName: 'Al-Waqi\'ah',
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
    DhikrItem(
      id: 'sl_mulk',
      category: 'sleep',
      arabicText: 'سُورَةُ الْمُلْكِ',
      transliteration: 'Surah Al-Mulk (Chapter 67)',
      translation:
          'Recitation of Surah Al-Mulk (Tabarak) before sleep protects from the punishment of the grave.',
      reference: 'At-Tirmidhi (2891), Sahih',
      virtue:
          'Intercedes for its reciter until he is forgiven and shields from the trials of the grave.',
      countTarget: 1,
      surahNumber: 67,
      surahName: 'Al-Mulk',
    ),
    DhikrItem(
      id: 'sl_sajdah',
      category: 'sleep',
      arabicText: 'سُورَةُ السَّجْدَةِ',
      transliteration: 'Surah As-Sajdah (Chapter 32)',
      translation:
          'The Prophet (ﷺ) would not sleep until he recited Surah As-Sajdah and Surah Al-Mulk.',
      reference: 'At-Tirmidhi (2892), Ahmad',
      virtue: 'Prophetic sunnah for night protection and reflection.',
      countTarget: 1,
      surahNumber: 32,
      surahName: 'As-Sajdah',
    ),
  ];

  static const List<DhikrItem> _dailyDuas = [
    // 1. TYPE: QURAN
    DhikrItem(
      id: 'd_quran_ikhlas',
      category: 'duas',
      type: 'quran',
      surahNumber: 112,
      surahName: 'Al-Ikhlas',
      surahNameArabic: 'الإخلاص',
      surahMeaning: 'The Sincerity • 4 Verses • Meccan',
      arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      transliteration:
          'Qul Huwallahu Ahad, Allahus-Samad, Lam yalid wa lam yoolad, Wa lam yakun lahu kufuwan ahad.',
      translation:
          'Say: He is Allah, [who is] One. Allah, the Eternal Refuge. He neither begets nor is born, Nor is there to Him any equivalent.',
      reference: 'Holy Quran • Surah Al-Ikhlas (112:1-4)',
      virtue:
          'Equal to one-third of the Quran. Reciting it repeatedly brings divine love, protection, and eternal paradise.',
      countTarget: 3,
    ),

    // 2. TYPE: DAILY DUA (Multi-language)
    DhikrItem(
      id: 'd_dua_rabbana',
      category: 'duas',
      type: 'dua',
      duaId: 'dua_rabbana_hasanah',
      titles: {
        'en': 'Supplication for Goodness in Both Worlds',
        'ur': 'دنیا اور آخرت کی بھلائی کی دعا',
        'hi': 'दोनों जहां की भलाई की दुआ',
        'te': 'ఇహ పరలోకాల మేలు కొరకు దుఆ',
      },
      translations: {
        'en':
            'Our Lord, give us in this world that which is good and in the Hereafter that which is good, and save us from the punishment of the Fire.',
        'ur':
            'اے ہمارے پروردگار! ہمیں دنیا میں بھی بھلائی دے اور آخرت میں بھی بھلائی دے اور ہمیں عذابِ جہنم سے بچا۔',
        'hi':
            'ऐ हमारे रब! हमें दुनिया में भी भलाई दे और आख़िरत में भी भलाई दे और हमें आग के अज़ाब से बचा।',
        'te':
            'ఓ మా ప్రభూ! మాకు ఈ లోకంలోనూ మేలు చేయి, పరలోకంలోనూ మేలు చేయి మరియు నరకాగ్ని శిక్ష నుండి మమ్ములను కాపాడు.',
      },
      transliterations: {
        'en':
            'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar.',
        'ur': 'ربنا آتنا فی الدنیا حسنۃ وفی الآخرۃ حسنۃ وقنا عذاب النار',
        'hi':
            'रब्बना आतीना फ़िद-दुनिया ह़सनतन वफ़िल-आख़िरती ह़सनतन वक़िना अज़ाबन-नार।',
        'te':
            'రబ్బనా ఆతినా ఫిద్-దున్యా హసనతవ్-వఫిల్-ఆఖిరతి హసనతవ్-వఖినా అజాబన్-నార్.',
      },
      benefitsMap: {
        'en':
            'The most frequent and comprehensive supplication of the Prophet Muhammad (ﷺ). Encompasses all spiritual, physical, and worldly needs.',
        'ur':
            'حضور اکرم صلی اللہ علیہ وسلم کی کثرت سے پڑھی جانے والی دعا۔ دنیا و آخرت کی تمام بھلائیوں کی ضامن۔',
      },
      arabicText:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar.',
      translation:
          'Our Lord, give us in this world that which is good and in the Hereafter that which is good, and save us from the punishment of the Fire.',
      reference: 'Quran (Surah Al-Baqarah 2:201)',
      virtue:
          'The most comprehensive dua taught in the Quran and favored by the Prophet (ﷺ).',
      countTarget: 3,
    ),

    // 3. TYPE: TASBEEH
    DhikrItem(
      id: 'd_tasbeeh_subhanallah',
      category: 'duas',
      type: 'tasbeeh',
      tasbeehId: 't_subhanallah_bihamdihi',
      tasbeehName: 'SubhanAllah wa biHamdihi',
      arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'SubhanAllahi wa bihamdihi',
      translation: 'Glory be to Allah and Praise be to Him',
      reference: 'Sahih al-Bukhari 6405',
      virtue:
          'Whoever says it 100 times a day, their sins will be wiped away even if they were like the foam of the sea.',
      countTarget: 33,
    ),

    // 4. TYPE: CUSTOM DHIKR
    DhikrItem(
      id: 'd_custom_istighfar',
      category: 'duas',
      type: 'custom',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ رَبِّي مِنْ كُلِّ ذَنْبٍ وَأَتُوبُ إِلَيْهِ',
      transliteration:
          'Astaghfirullaha Rabbi min kulli dhambin wa atoobu ilayh',
      translation:
          'I seek forgiveness from Allah, my Lord, from every sin and I turn to Him in repentance.',
      reference: 'Daily Sunnah Istighfar',
      virtue:
          'Continuous repentance brings immense peace, sustenance, relief from anxiety, and divine pardon.',
      countTarget: 10,
    ),
  ];
}
