import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/dua/data/dua_repository.dart';
import 'package:adhkar/features/dua/domain/dua_item.dart';

void main() {
  group('Dua Feature Tests', () {
    final repository = DuaRepository();

    test('Repository provides at least 10 default Duas', () {
      final me = repository.getDefaultDuas();
      expect(me.length, greaterThanOrEqualTo(10));
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
  });
}
