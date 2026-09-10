import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/dua_item.dart';

class DuaRepository {
  static List<DuaItem>? _cachedDuas;

  /// Asynchronously loads all 197 Duas from assets/data/duaeen.json.
  Future<List<DuaItem>> loadAllDuas() async {
    if (_cachedDuas != null && _cachedDuas!.isNotEmpty) {
      return _cachedDuas!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/duaeen.json');
      final List<dynamic> rawList = json.decode(jsonString) as List<dynamic>;

      final loaded = rawList.map((item) {
        return DuaItem.fromJson(item as Map<String, dynamic>);
      }).toList();

      // Prioritize Top Duas at the beginning of the list
      _cachedDuas = _prioritizeTopDuas(loaded);
      return _cachedDuas!;
    } catch (_) {
      // Fallback to built-in curated Duas if asset load fails
      _cachedDuas = _curatedDefaultDuas;
      return _cachedDuas!;
    }
  }

  /// Returns cached Duas if already loaded, or curated built-in defaults.
  List<DuaItem> getDefaultDuas() {
    if (_cachedDuas != null && _cachedDuas!.isNotEmpty) {
      return _cachedDuas!;
    }
    return _curatedDefaultDuas;
  }

  /// Prioritizes the most essential, widely recited daily Duas at the top
  List<DuaItem> _prioritizeTopDuas(List<DuaItem> list) {
    const topIds = [
      'hisn_waking_up_1',
      'hisn_waking_up_2',
      'hisn_food_before_1',
      'hisn_food_after_1',
      'hisn_restroom_entering',
      'hisn_restroom_leaving',
      'hisn_home_leaving_1',
      'hisn_home_entering',
      'hisn_morning_protection_1',
      'hisn_sleep_before_1',
      'hisn_distress_general',
      'hisn_forgiveness_sayyid',
      'hisn_travel_riding',
      'hisn_mosque_entering',
    ];

    final topDuas = <DuaItem>[];
    final remainingDuas = <DuaItem>[];

    final Map<String, DuaItem> mapById = {
      for (final dua in list) dua.id: dua,
    };

    for (final id in topIds) {
      if (mapById.containsKey(id)) {
        topDuas.add(mapById[id]!);
        mapById.remove(id);
      }
    }

    remainingDuas.addAll(list.where((d) => !topIds.contains(d.id)));
    return [...topDuas, ...remainingDuas];
  }

  /// Curated default Duas with multi-language and audio URLs
  static final List<DuaItem> _curatedDefaultDuas = [
    const DuaItem(
      id: 'hisn_waking_up_1',
      title: 'Primary Supplication Upon Waking Up',
      titles: {
        'en': 'Primary Supplication Upon Waking Up',
        'ur': 'سو کر اٹھنے کی دعا',
        'hi': 'सोकर उठने की दुआ',
        'te': 'నిద్రలేచిన తర్వాత చదివే దువా',
      },
      category: 'Morning',
      arabic: 'الْحَمْدُ للَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا، وَإِلَيْهِ النُّشُورُ',
      transliteration: 'Al-ḥamdu lillāhil-ladhī aḥyānā ba\'da mā amātanā wa-ilayhin-nushūr.',
      transliterations: {
        'en': 'Al-ḥamdu lillāhil-ladhī aḥyānā ba\'da mā amātanā wa-ilayhin-nushūr.',
        'hi': 'अल्हम्दु लिल्लाहिल-लज़ी अह्याना बअदा मा अमातना व-इलैहिन-नुशूर।',
        'te': 'అల్హమ్దు లిల్లాహిల్-లజీ అహ్యానా బఅద మా అమాతనా వ-ఇలైహిన్-నుషూర్.',
      },
      translation: 'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
      translations: {
        'en': 'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
        'ur': 'تمام تعریفیں اللہ کے لیے ہیں جس نے ہمیں مارنے کے بعد زندہ کیا اور اسی کی طرف اٹھ کر جانا ہے۔',
        'hi': 'तमाम तारीफ़ें अल्लाह के लिए हैं जिसने हमें मारने (सुलाने) के बाद ज़िंदा किया और उसी की तरफ़ उठकर जाना है।',
        'te': 'మనల్ని మరణింపజేసిన (నిద్రపుచ్చిన) తర్వాత తిరిగి ప్రాణం పోసిన అల్లాహ్ కే సర్వ స్తోత్రాలు, మరియు తిరిగి ఆయన వద్దకే వెళ్ళవలసి ఉంది.',
      },
      repeatCount: 1,
      reference: 'Hisnul Muslim, Dua #1 (Sahih al-Bukhari 6312)',
      benefits: 'Recite this immediately upon waking up to thank Allah for a new day of life.',
      benefitsMap: {
        'en': 'Recite this immediately upon waking up to thank Allah for a new day of life.',
        'ur': 'یہ دعا صبح بیدار ہوتے ہی پڑھیں تاکہ نئی زندگی ملنے پر اللہ کا شکر ادا کیا جا سکے۔',
        'hi': 'यह दुआ सुबह सोकर उठते ही पढ़ें ताकि नई ज़िंदगी मिलने पर अल्लाह का शुक्र अदा किया जा सके।',
        'te': 'నిద్రలేవగానే కొత్త రోజు ప్రసాదించినందుకు అల్లాహ్ కు కృతజ్ఞతలు తెలుపుతూ ఈ దువా చదవాలి.',
      },
      audioUrl: 'http://www.hisnmuslim.com/audio/ar/1.mp3',
    ),
    const DuaItem(
      id: 'hisn_restroom_entering',
      title: 'Entering the Restroom',
      titles: {
        'en': 'Entering the Restroom',
        'ur': 'بیت الخلاء میں داخل ہونے کی دعا',
        'hi': 'बैतुल-ख़ला (टॉयलेट) में जाने की दुआ',
        'te': 'మరుగుదొడ్డిలోకి వెళ్ళే ముందు చదివే దువా',
      },
      category: 'Hygiene',
      arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبْثِ وَالْخَبائِث',
      transliteration: 'Allāhumma innī a\'ūthu bika minal-khubthi wal-khabā\'ith.',
      transliterations: {
        'en': 'Allāhumma innī a\'ūthu bika minal-khubthi wal-khabā\'ith.',
        'hi': 'अल्लाहुम्मा इन्नी अऊज़ु बिका मिनल-ख़ुब्सी वल-ख़बाइसी।',
        'te': 'అల్లాహుమ్మ ఇన్నీ అఊజు బిక మినల్-ఖుబ్సి వల్-ఖబాయిస్.',
      },
      translation: 'O Allah, I seek refuge with You from all wicked and evil things (both male and female devils).',
      translations: {
        'en': 'O Allah, I seek refuge with You from all wicked and evil things (both male and female devils).',
        'ur': 'اے اللہ! میں ناپاک جنوں اور ناپاک جننیوں سے تیری پناہ مانگتا ہوں۔',
        'hi': 'ऐ अल्लाह! मैं ख़बीस जिन्नों (नर और मादा) की बुराई से तेरी पनाह मांगता हूँ।',
        'te': 'ఓ అల్లాహ్! నేను దుష్ట శక్తులు మరియు చెడుల నుండి నీ శరణు కోరుతున్నాను.',
      },
      repeatCount: 1,
      reference: 'Hisnul Muslim, Dua #10 (Sahih al-Bukhari 142)',
      benefits: 'Provides spiritual protection when entering designated wash areas.',
      benefitsMap: {
        'en': 'Provides spiritual protection when entering designated wash areas.',
        'ur': 'بیت الخلاء میں داخل ہوتے وقت شیطانی اثرات سے حفاظت کے لیے۔',
        'hi': 'टॉयलेट में दाख़िल होते वक़्त शैतानी शर से हिफ़ाज़त के लिए।',
        'te': 'మరుగుదొడ్డిలోకి వెళ్ళేటప్పుడు చెడు ప్రభావాల నుండి రక్షణ కోసం.',
      },
      audioUrl: 'http://www.hisnmuslim.com/audio/ar/10.mp3',
    ),
    const DuaItem(
      id: 'hisn_restroom_leaving',
      title: 'Leaving the Restroom',
      titles: {
        'en': 'Leaving the Restroom',
        'ur': 'بیت الخلاء سے نکلنے کی دعا',
        'hi': 'बैतुल-ख़ला से बाहर आने की दुआ',
        'te': 'మరుగుదొడ్డి నుండి బయటకు వచ్చిన తర్వాత చదివే దువా',
      },
      category: 'Hygiene',
      arabic: 'غُفْرَانَكَ',
      transliteration: 'Ghufrānak.',
      transliterations: {
        'en': 'Ghufrānak.',
        'hi': 'गुफ़्-रानक।',
        'te': 'గుఫ్రానక్.',
      },
      translation: 'I seek Your forgiveness, O Allah.',
      translations: {
        'en': 'I seek Your forgiveness, O Allah.',
        'ur': 'اے اللہ! میں تیری بخشش کا طلبگار ہوں۔',
        'hi': 'ऐ अल्लाह! मैं तेरी मग़फ़िरत (माफ़ी) चाहता हूँ।',
        'te': 'ఓ అల్లాహ్! నేను నీ క్షమాపణను కోరుతున్నాను.',
      },
      repeatCount: 1,
      reference: 'Hisnul Muslim, Dua #11 (Abu Dawud 17)',
      benefits: 'Gratitude for relief and seeking divine forgiveness.',
      benefitsMap: {
        'en': 'Gratitude for relief and seeking divine forgiveness.',
        'ur': 'نجاست اور تکلیف سے نجات پر اللہ کا شکر اور بخشش کی طلب۔',
        'hi': 'गंदगी से निजात मिलने पर अल्लाह का शुक्र और माफ़ी की तलब।',
        'te': 'ఉపశమనం పొందినందుకు కృతజ్ఞత మరియు క్షమాపణ కోరడం.',
      },
      audioUrl: 'http://www.hisnmuslim.com/audio/ar/11.mp3',
    ),
    const DuaItem(
      id: 'hisn_home_leaving_1',
      title: 'Leaving the Home',
      titles: {
        'en': 'Leaving the Home',
        'ur': 'گھر سے نکلتے وقت کی دعا',
        'hi': 'घर से निकलते वक़्त की दुआ',
        'te': 'ఇంటి నుండి బయటకు వెళ్ళేటప్పుడు చదివే దువా',
      },
      category: 'Travel',
      arabic: 'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ',
      transliteration: 'Bismillāh, tawakkaltu \'alallāh, walā ḥawla walā quwwata illā billāh.',
      transliterations: {
        'en': 'Bismillāh, tawakkaltu \'alallāh, walā ḥawla walā quwwata illā billāh.',
        'hi': 'बिस्मिल्लाहि, तवक्कलतु अलल्लाहि, वला हौला वला कुव्वता इल्ला बिल्लाह।',
        'te': 'బిస్మిల్లాహి, తవక్కల్తు అలల్లాహి, వలా హౌల వలా ఖువ్వత ఇల్లా బిల్లాహ్.',
      },
      translation: 'In the name of Allah, I place my trust in Allah, and there is no power nor might except with Allah.',
      translations: {
        'en': 'In the name of Allah, I place my trust in Allah, and there is no power nor might except with Allah.',
        'ur': 'اللہ کے نام کے ساتھ، میں نے اللہ پر بھروسہ کیا، اور گناہوں سے بچنے اور نیکی کرنے کی کوئی طاقت نہیں مگر اللہ کی مدد سے۔',
        'hi': 'अल्लाह के नाम से, मैंने अल्लाह पर भरोसा किया, और बुराई से बचने और नेकी करने की कोई ताक़त नहीं मगर अल्लाह की मदद से।',
        'te': 'అల్లాహ్ పేరుతో, నేను అల్లాహ్ పైనే భరోసా ఉంచాను, మరియు అల్లాహ్ దయ లేకుండా ఏ శక్తి మరియు సామర్థ్యం లేదు.',
      },
      repeatCount: 1,
      reference: 'Hisnul Muslim, Dua #16 (Abu Dawud 5095)',
      benefits: 'An angel proclaims: You are guided, defended, and protected, and Shaytan retreats from you.',
      benefitsMap: {
        'en': 'An angel proclaims: You are guided, defended, and protected, and Shaytan retreats from you.',
        'ur': 'فرشتہ کہتا ہے: تجھے کفایت کی گئی، تجھے بچایا گیا، اور شیطان تجھ سے دور ہو جاتا ہے۔',
        'hi': 'फ़रिश्ता कहता है: तुझे हिदायत दी गई, तेरी हिफ़ाज़त की गई, और शैतान तुझसे दूर हो जाता है।',
        'te': 'దేవదూత ప్రకటిస్తాడు: నీకు మార్గదర్శకత్వం, రక్షణ లభించింది మరియు సైతాను నీ నుండి దూరమవుతాడు.',
      },
      audioUrl: 'http://www.hisnmuslim.com/audio/ar/16.mp3',
    ),
    const DuaItem(
      id: 'hisn_food_before_1',
      title: 'Before Eating Food',
      titles: {
        'en': 'Before Eating Food',
        'ur': 'کھانا کھانے سے پہلے کی دعا',
        'hi': 'खाना खाने से पहले की दुआ',
        'te': 'భోజనం చేసే ముందు చదివే దువా',
      },
      category: 'Food',
      arabic: 'بِسْمِ اللَّهِ [وَعَلَى بَرَكَةِ اللَّهِ]',
      transliteration: 'Bismillāhi [wa \'alā barakatillāh].',
      transliterations: {
        'en': 'Bismillāhi [wa \'alā barakatillāh].',
        'hi': 'बिस्मिल्लाहि [व अला बरकतिल्लाह]।',
        'te': 'బిస్మిల్లాహి [వ అలా బరకతిల్లాహ్].',
      },
      translation: 'In the name of Allah [and with the blessings of Allah].',
      translations: {
        'en': 'In the name of Allah [and with the blessings of Allah].',
        'ur': 'اللہ کے نام کے ساتھ [اور اللہ کی برکت پر کھانا شروع کرتا ہوں]۔',
        'hi': 'अल्लाह के नाम के साथ [और अल्लाह की बरकत पर मैं खाना शुरू करता हूँ]।',
        'te': 'అల్లాహ్ పేరుతో మరియు అల్లాహ్ ఆశీర్వాదాలతో నేను తింటున్నాను.',
      },
      repeatCount: 1,
      reference: 'Hisnul Muslim, Dua #183 (Abu Dawud 3767)',
      benefits: 'Prevents Shaytan from sharing in the food and brings Barakah.',
      benefitsMap: {
        'en': 'Prevents Shaytan from sharing in the food and brings Barakah.',
        'ur': 'کھانے میں برکت پیدا ہوتی ہے اور شیطان اس میں شریک نہیں ہو سکتا۔',
        'hi': 'खाने में बरकत आती है और शैतान उसमें शरीक नहीं हो पाता।',
        'te': 'ఆహారంలో శుభాలు కలుగుతాయి మరియు సైతాను పాలుపంచుకోలేడు.',
      },
      audioUrl: 'http://www.hisnmuslim.com/audio/ar/183.mp3',
    ),
    const DuaItem(
      id: 'hisn_food_after_1',
      title: 'After Finishing the Meal',
      titles: {
        'en': 'After Finishing the Meal',
        'ur': 'کھانے کے بعد کی دعا',
        'hi': 'खाने के बाद की दुआ',
        'te': 'భోజనం ముగించిన తర్వాత చదివే దువా',
      },
      category: 'Food',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا، وَرَزَقَنِيهِ، مِنْ غَيْرِ حَوْلٍ مِنِّي وَلاَ قُوَّةٍ',
      transliteration: 'Al-ḥamdu lillāhil-ladhī aṭ\'amanī hādhā, warazaqanīhi, min ghayri ḥawlin minnī walā quwwah.',
      transliterations: {
        'en': 'Al-ḥamdu lillāhil-ladhī aṭ\'amanī hādhā, warazaqanīhi, min ghayri ḥawlin minnī walā quwwah.',
        'hi': 'अल्हम्दु लिल्लाहिल-लज़ी अतअमनी हाज़ा, व-रज़क़नीहि, मिन ग़ैरी हौलिम-मिन्नी वला कुव्वह।',
        'te': 'అల్హమ్దు లిల్లాహిల్-లజీ అత-అమనీ హాజా, వ-రజఖనీహి, మిన్ గైరి హౌలిమ్-మిన్నీ వలా ఖువ్వహ్.',
      },
      translation: 'All praise is for Allah who fed me this and provided it for me without any might or power from myself.',
      translations: {
        'en': 'All praise is for Allah who fed me this and provided it for me without any might or power from myself.',
        'ur': 'تمام تعریفیں اللہ کے لیے ہیں جس نے مجھے یہ کھلایا اور میری طاقت و قدرت کے بغیر مجھے یہ عطا کیا۔',
        'hi': 'तमाम तारीफ़ें अल्लाह के लिए हैं जिसने मुझे यह खिलाया और मेरी किसी ताक़त के बग़ैर यह रिज़्क़ अता फ़रमाया।',
        'te': 'నాలో ఎటువంటి శక్తి మరియు సామర్థ్యం లేకుండా నాకు ఈ ఆహారాన్ని ప్రసాదించిన అల్లాహ్ కే సర్వ స్తోత్రాలు.',
      },
      repeatCount: 1,
      reference: 'Hisnul Muslim, Dua #185 (Abu Dawud 4023)',
      benefits: 'Whoever says this after eating will have their past sins forgiven.',
      benefitsMap: {
        'en': 'Whoever says this after eating will have their past sins forgiven.',
        'ur': 'جو شخص یہ دعا پڑھے اس کے پچھلے گناہ معاف کر دیے جاتے ہیں۔',
        'hi': 'जो शख़्स यह दुआ पढ़े उसके पिछले गुनाह माफ़ कर दिए जाते हैं।',
        'te': 'ఈ దువా చదివిన వారి గత పాపాలు క్షమించబడతాయి.',
      },
      audioUrl: 'http://www.hisnmuslim.com/audio/ar/185.mp3',
    ),
    const DuaItem(
      id: 'hisn_sleep_before_1',
      title: 'Supplication Before Sleeping',
      titles: {
        'en': 'Supplication Before Sleeping',
        'ur': 'سوتے وقت کی دعا',
        'hi': 'सोते वक़्त की दुआ',
        'te': 'నిద్రపోయే ముందు చదివే దువా',
      },
      category: 'Sleep',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      transliteration: 'Bismika Allāhumma amūtu wa-aḥyā.',
      transliterations: {
        'en': 'Bismika Allāhumma amūtu wa-aḥyā.',
        'hi': 'बिस्मिका अल्लाहुम्मा अमूतु व-अह्या।',
        'te': 'బిస్మికా అల్లాహుమ్మ అమూతు వ-అహ్యా.',
      },
      translation: 'In Your name, O Allah, I die and I live.',
      translations: {
        'en': 'In Your name, O Allah, I die and I live.',
        'ur': 'اے اللہ! تیرے ہی نام کے ساتھ میں مرتا (سوتا) ہوں اور جیتا (جاگتا) ہوں۔',
        'hi': 'ऐ अल्लाह! तेरे नाम के साथ मैं मरता (सोता) हूँ और जीता (जागता) हूँ।',
        'te': 'ఓ అల్లాహ్! నీ పేరుతోనే నేను మరణిస్తాను (నిద్రపోతాను) మరియు జీవిస్తాను (మేల్కొంటాను).',
      },
      repeatCount: 1,
      reference: 'Hisnul Muslim, Dua #100 (Sahih al-Bukhari 6324)',
      benefits: 'Entrusts your soul into Allah\'s divine care during sleep.',
      benefitsMap: {
        'en': 'Entrusts your soul into Allah\'s divine care during sleep.',
        'ur': 'نیند کی حالت میں اپنی جان اللہ کی حفاظت و پناہ میں سونپنا۔',
        'hi': 'नींद की हालत में अपनी जान अल्लाह की हिफ़ाज़त में सौंपना।',
        'te': 'నిద్రలో ఉన్నప్పుడు ప్రాణాన్ని అల్లాహ్ సంరక్షణలో ఉంచడం.',
      },
      audioUrl: 'http://www.hisnmuslim.com/audio/ar/100.mp3',
    ),
  ];
}
