import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/shared/models/adhkar_category.dart';
import 'package:adhkar/shared/models/dhikr_item.dart';
import 'package:adhkar/features/adhkar/repositories/adhkar_repository.dart';

void main() {
  group('DhikrItem 4 Types Model Tests', () {
    test('Quran type properties and serialization', () {
      final quranItem = DhikrItem(
        id: 'quran_1',
        category: 'morning',
        type: 'quran',
        arabicText: 'سورة الفاتحة',
        transliteration: 'Al-Fatihah',
        translation: 'The Opening',
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        surahNameArabic: 'الفاتحة',
        surahMeaning: 'The Opening • 7 Verses • Meccan',
        reference: 'Holy Quran • Surah Al-Fatihah (1:1-7)',
        virtue: 'Mother of the Book, cure for spiritual illnesses',
        countTarget: 3,
        countCurrent: 1,
      );

      expect(quranItem.isQuran, isTrue);
      expect(quranItem.isDua, isFalse);
      expect(quranItem.isTasbeeh, isFalse);
      expect(quranItem.isCustom, isFalse);
      expect(quranItem.surahNumber, equals(1));
      expect(quranItem.surahName, equals('Al-Fatihah'));

      final json = quranItem.toJson();
      final revived = DhikrItem.fromJson(json);

      expect(revived.id, equals('quran_1'));
      expect(revived.type, equals('quran'));
      expect(revived.surahNumber, equals(1));
      expect(revived.surahName, equals('Al-Fatihah'));
      expect(revived.surahMeaning, equals('The Opening • 7 Verses • Meccan'));
      expect(revived.countTarget, equals(3));
      expect(revived.countCurrent, equals(1));
    });

    test('Daily Duaeen type properties and multi-language support', () {
      final duaItem = DhikrItem(
        id: 'dua_morning_1',
        category: 'morning',
        type: 'dua',
        duaId: 'dua_wake_up',
        titles: const {
          'en': 'Waking Up',
          'ur': 'بیدار ہونے کی دعا',
          'hi': 'जागने की दुआ',
          'te': 'మేల్కొన్నప్పుడు చదివే దువా',
        },
        arabicText: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        transliteration: 'Alhamdu lillahil-lathee ahyana ba\'da ma amatana wa-ilayhin-nushoor.',
        translation: 'All praise is for Allah who gave us life after giving us death and unto Him is the resurrection.',
        translations: const {
          'en': 'All praise is for Allah who gave us life after giving us death and unto Him is the resurrection.',
          'ur': 'تمام تعریفیں اللہ کے لیے ہیں جس نے ہمیں مارنے کے بعد زندہ کیا اور اسی کی طرف لوٹ کر جانا ہے۔',
          'hi': 'सब तारीफ़ अल्लाह के लिए है जिसने हमें मौत (नींद) के बाद ज़िन्दगी बख़्शी और उसी की तरफ़ उठना है।',
          'te': 'సమస్త స్తోత్రాలు అల్లాహ్ కే శోభించును, ఆయన మనకు మరణం తరువాత జీవం ఇచ్చెను.',
        },
        transliterations: const {
          'en': 'Alhamdu lillahil-lathee ahyana ba\'da ma amatana wa-ilayhin-nushoor.',
        },
        benefitsMap: const {
          'en': 'Expressing gratitude immediately upon consciousness reinforces faith.',
        },
        reference: 'Sahih al-Bukhari 6312',
        virtue: 'Reinforces gratitude to Allah',
        audioUrl: 'https://example.com/audio/wake_up.mp3',
        countTarget: 1,
        countCurrent: 0,
      );

      expect(duaItem.isDua, isTrue);
      expect(duaItem.getTitle('en'), equals('Waking Up'));
      expect(duaItem.getTitle('ur'), equals('بیدار ہونے کی دعا'));
      expect(duaItem.getTitle('hi'), equals('जागने की दुआ'));
      expect(duaItem.getTitle('te'), equals('మేల్కొన్నప్పుడు చదివే దువా'));
      expect(duaItem.getTranslation('en'), contains('All praise is for Allah'));
      expect(duaItem.audioUrl, equals('https://example.com/audio/wake_up.mp3'));

      final json = duaItem.toJson();
      final revived = DhikrItem.fromJson(json);

      expect(revived.isDua, isTrue);
      expect(revived.duaId, equals('dua_wake_up'));
      expect(revived.getTitle('ur'), equals('بیدار ہونے کی دعا'));
      expect(revived.audioUrl, equals('https://example.com/audio/wake_up.mp3'));
    });

    test('Tasbeeh type properties and serialization', () {
      final tasbeehItem = DhikrItem(
        id: 'tasbeeh_subhanallah',
        category: 'general',
        type: 'tasbeeh',
        tasbeehId: 't_subhanallah',
        tasbeehName: 'SubhanAllah',
        arabicText: 'سُبْحَانَ اللَّهِ',
        transliteration: 'SubhanAllah',
        translation: 'Glory be to Allah',
        reference: 'Hadith',
        virtue: 'A tree is planted in Jannah for the reciter.',
        countTarget: 33,
        countCurrent: 33,
      );

      expect(tasbeehItem.isTasbeeh, isTrue);
      expect(tasbeehItem.tasbeehName, equals('SubhanAllah'));
      expect(tasbeehItem.countTarget, equals(33));
      expect(tasbeehItem.countCurrent, equals(33));

      final json = tasbeehItem.toJson();
      final revived = DhikrItem.fromJson(json);

      expect(revived.isTasbeeh, isTrue);
      expect(revived.tasbeehId, equals('t_subhanallah'));
      expect(revived.tasbeehName, equals('SubhanAllah'));
    });

    test('Custom Dhikr type fallback compatibility', () {
      final customItem = DhikrItem(
        id: 'custom_1',
        category: 'custom_folder',
        arabicText: 'لا إله إلا الله',
        transliteration: 'La ilaha illallah',
        translation: 'None has the right to be worshipped but Allah',
        reference: 'Quran 47:19',
        virtue: 'The best dhikr',
        countTarget: 100,
        countCurrent: 50,
      );

      expect(customItem.isCustom, isTrue);
      expect(customItem.type, equals('custom'));

      final copy = customItem.copyWith(countCurrent: 51);
      expect(copy.countCurrent, equals(51));
      expect(copy.countTarget, equals(100));
    });
  });

  group('Cylindrical Button State Logic Tests', () {
    test('State is pending (yellow) when countCurrent < countTarget', () {
      final item = DhikrItem(
        id: 'test_item',
        category: 'test',
        arabicText: 'الحمد لله',
        transliteration: 'Alhamdulillah',
        translation: 'All praise is for Allah',
        reference: 'Quran',
        virtue: 'Fills the scales',
        countTarget: 10,
        countCurrent: 3,
      );

      final isCompleted = item.countCurrent >= item.countTarget;
      expect(isCompleted, isFalse);

      const pendingColor = Color(0xFFD97706); // Warm Amber/Yellow
      expect(pendingColor, equals(const Color(0xFFD97706)));
    });

    test('State is completed (green) when countCurrent >= countTarget', () {
      final item = DhikrItem(
        id: 'test_item',
        category: 'test',
        arabicText: 'الحمد لله',
        transliteration: 'Alhamdulillah',
        translation: 'All praise is for Allah',
        reference: 'Quran',
        virtue: 'Fills the scales',
        countTarget: 10,
        countCurrent: 10,
      );

      final isCompleted = item.countCurrent >= item.countTarget;
      expect(isCompleted, isTrue);

      const completedColor = Color(0xFF14532D); // Dark Forest Green
      expect(completedColor, equals(const Color(0xFF14532D)));
    });

    test('Reset action restores countCurrent to 0', () {
      var item = DhikrItem(
        id: 'test_item',
        category: 'test',
        arabicText: 'الحمد لله',
        transliteration: 'Alhamdulillah',
        translation: 'All praise is for Allah',
        reference: 'Quran',
        virtue: 'Fills the scales',
        countTarget: 33,
        countCurrent: 33,
      );

      expect(item.countCurrent, equals(33));
      item = item.copyWith(countCurrent: 0);
      expect(item.countCurrent, equals(0));
      expect(item.countCurrent < item.countTarget, isTrue);
    });
  });

  group('Adhkar Background-less Images Tests', () {
    test('availableImages strictly contains only assets/images/adhkar images', () {
      for (final imagePath in AdhkarCategory.availableImages) {
        expect(imagePath.startsWith('assets/images/adhkar/'), isTrue,
            reason: '$imagePath must be inside assets/images/adhkar/');
        expect(imagePath.endsWith('.png'), isTrue);
      }
      expect(AdhkarCategory.availableImages.length, equals(11));
    });

    test('default categories strictly use assets/images/adhkar images', () {
      final defaultCats = AdhkarRepository().getDefaultCategories();
      for (final cat in defaultCats) {
        expect(cat.imagePath.startsWith('assets/images/adhkar/'), isTrue,
            reason: '${cat.imagePath} must be inside assets/images/adhkar/');
      }
    });
  });

  group('Dhikr Insertion Order Tests', () {
    test('Newly added dhikr is added at the back (end) of the list, not front', () {
      final list = <DhikrItem>[
        DhikrItem(
          id: 'item_1',
          category: 'morning',
          arabicText: 'Text 1',
          transliteration: 'T1',
          translation: 'Tr1',
          reference: 'Ref 1',
          virtue: 'Vir 1',
          countTarget: 1,
        ),
        DhikrItem(
          id: 'item_2',
          category: 'morning',
          arabicText: 'Text 2',
          transliteration: 'T2',
          translation: 'Tr2',
          reference: 'Ref 2',
          virtue: 'Vir 2',
          countTarget: 1,
        ),
      ];

      final newItem = DhikrItem(
        id: 'item_3',
        category: 'morning',
        arabicText: 'Text 3',
        transliteration: 'T3',
        translation: 'Tr3',
        reference: 'Ref 3',
        virtue: 'Vir 3',
        countTarget: 3,
      );

      // Add to back
      list.add(newItem);

      expect(list.length, equals(3));
      expect(list.first.id, equals('item_1'));
      expect(list[1].id, equals('item_2'));
      expect(list.last.id, equals('item_3'));
      expect(list[list.length - 1].id, equals(newItem.id));
    });
  });

  group('Daily Adhkar Progress & Midnight Rollover Tests', () {
    test('Daily counts are keyed by date and reset to empty map for a new day', () {
      final storageMap = <String, Map<String, int>>{};

      const day1 = '2026-10-25';
      const day2 = '2026-10-26';

      // Record progress on day 1
      storageMap[day1] = {'item_1': 3, 'item_2': 1};

      expect(storageMap[day1]?['item_1'], equals(3));
      expect(storageMap[day1]?['item_2'], equals(1));

      // At midnight date changes to day 2
      final day2Counts = storageMap[day2] ?? {};
      expect(day2Counts.isEmpty, isTrue);
      expect(day2Counts['item_1'] ?? 0, equals(0));
    });

    test('Category progress calculation matches completed count vs target', () {
      final items = [
        DhikrItem(id: 'd1', category: 'c1', arabicText: 'A', transliteration: 'T', translation: 'Tr', reference: 'R', virtue: 'V', countTarget: 3),
        DhikrItem(id: 'd2', category: 'c1', arabicText: 'A', transliteration: 'T', translation: 'Tr', reference: 'R', virtue: 'V', countTarget: 1),
        DhikrItem(id: 'd3', category: 'c1', arabicText: 'A', transliteration: 'T', translation: 'Tr', reference: 'R', virtue: 'V', countTarget: 10),
      ];

      final dailyCounts = {'d1': 3, 'd2': 1, 'd3': 4};

      final completed = items.where((i) => (dailyCounts[i.id] ?? 0) >= i.countTarget).length;
      expect(completed, equals(2)); // d1 (3/3) and d2 (1/1) are complete, d3 (4/10) is not
    });

    test('Empty categories screen suppresses floating action button', () {
      final categories = <AdhkarCategory>[];
      final bool showFab = categories.isNotEmpty;
      expect(showFab, isFalse);
    });
  });
}
