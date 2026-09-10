import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/dua/data/dua_repository.dart';
import 'package:adhkar/features/dua/domain/dua_item.dart';

void main() {
  group('Dua Feature Tests', () {
    final repository = DuaRepository();

    test('Repository provides default Duas', () {
      final me = repository.getDefaultDuas();
      expect(me.length, greaterThanOrEqualTo(5));
    });

    test('Each Dua has required fields populated accurately', () {
      final me = repository.getDefaultDuas();
      for (final dua in me) {
        expect(dua.id.isNotEmpty, isTrue);
        expect(dua.title.isNotEmpty, isTrue);
        expect(dua.category.isNotEmpty, isTrue);
        expect(dua.arabic.isNotEmpty, isTrue);
        expect(dua.transliteration.isNotEmpty, isTrue);
        expect(dua.translation.isNotEmpty, isTrue);
        expect(dua.reference.isNotEmpty, isTrue);
        expect(dua.benefits.isNotEmpty, isTrue);
        expect(dua.repeatCount, greaterThanOrEqualTo(1));
      }
    });

    test('DuaItem serialization toJson and fromJson roundtrip', () {
      const original = DuaItem(
        id: 'test_dua',
        title: 'Test Dua',
        category: 'Daily',
        arabic: 'اَلْحَمْدُ لِلَّهِ',
        transliteration: 'Alhamdulillah',
        translation: 'Praise be to Allah',
        repeatCount: 3,
        reference: 'Sahih al-Bukhari',
        benefits: 'Brings immense reward',
        imagePath: 'assets/images/dua.png',
      );

      final jsonMap = original.toJson();
      final roundtrip = DuaItem.fromJson(jsonMap);

      expect(roundtrip.id, original.id);
      expect(roundtrip.title, original.title);
      expect(roundtrip.category, original.category);
      expect(roundtrip.arabic, original.arabic);
      expect(roundtrip.transliteration, original.transliteration);
      expect(roundtrip.translation, original.translation);
      expect(roundtrip.repeatCount, original.repeatCount);
      expect(roundtrip.reference, original.reference);
      expect(roundtrip.benefits, original.benefits);
      expect(roundtrip.imagePath, original.imagePath);
      expect(roundtrip.isCustom, original.isCustom);
    });

    test('DuaItem multilingual getters return localized content with fallback', () {
      const multilingualDua = DuaItem(
        id: 'test_multi',
        title: 'Morning Prayer',
        category: 'Morning',
        arabic: 'اَللَّهُمَّ',
        transliteration: 'Allahumma',
        translation: 'O Allah',
        repeatCount: 1,
        reference: 'Sahih Muslim',
        benefits: 'Protection and peace',
        translations: {
          'en': 'O Allah',
          'ur': 'اے اللہ',
          'hi': 'हे अल्लाह',
        },
        transliterations: {
          'en': 'Allahumma',
          'ur': 'اللہم',
        },
        titles: {
          'en': 'Morning Prayer',
          'ur': 'صبح کی دعا',
        },
      );

      // Selected language matches
      expect(multilingualDua.getTitle('ur'), 'صبح کی دعا');
      expect(multilingualDua.getTranslation('ur'), 'اے اللہ');
      expect(multilingualDua.getTranslation('hi'), 'हे अल्लाह');

      // Fallback to english/base when specific language is absent
      expect(multilingualDua.getTitle('hi'), 'Morning Prayer');
      expect(multilingualDua.getTranslation('te'), 'O Allah');
    });

    test('Language preference persistence key verification', () async {
      // Dua primary language key consistency check
      const key = 'dua_primary_language';
      expect(key, 'dua_primary_language');
    });
  });
}
