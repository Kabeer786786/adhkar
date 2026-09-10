import 'package:adhkar/core/services/storage_service.dart';
import 'package:adhkar/features/home/presentation/widgets/daily_ayah_card.dart';
import 'package:adhkar/features/quran/data/daily_ayah_model.dart';
import 'package:adhkar/features/quran/presentation/providers/daily_ayah_provider.dart';
import 'package:adhkar/features/quran/services/daily_ayah_service.dart';
import 'package:adhkar/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// In-memory fake StorageService for testing
class FakeStorageService implements StorageService {
  final Map<String, dynamic> _storage = {};

  @override
  dynamic getGenericData(String key) => _storage[key];

  @override
  Future<void> saveGenericData(String key, dynamic value) async {
    _storage[key] = value;
  }

  // Stubs for other methods of StorageService interface
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleUthmaniData = {
    "number": 255,
    "text":
        "وَقَالَ لَهُمْ نَبِيُّهُمْ إِنَّ ءَايَةَ مُلْكِهِۦٓ أَن يَأْتِيَكُمُ ٱلتَّابُوتُ فِيهِ سَكِينَةٌۭ مِّن رَّبِّكُمْ وَبَقِيَّةٌۭ مِّمَّا تَرَكَ ءَالُ مُوسَىٰ وَءَالُ هَٰرُونَ تَحْمِلُهُ ٱلْمَلَٰٓئِكَةُ ۚ إِنَّ فِى ذَٰلِكَ لَءَايَةًۭ لَّكُمْ إِن كُنتُم مُّؤْمِنِينَ",
    "edition": {
      "identifier": "quran-uthmani",
      "language": "ar",
      "name": "القرآن الكريم برسم العثماني (uthmani)",
      "englishName": "Uthmani",
      "format": "text",
      "type": "quran",
      "direction": "rtl"
    },
    "surah": {
      "number": 2,
      "name": "سُورَةُ البَقَرَةِ",
      "englishName": "Al-Baqara",
      "englishNameTranslation": "The Cow",
      "numberOfAyahs": 286,
      "revelationType": "Medinan"
    },
    "numberInSurah": 248,
    "juz": 2,
    "manzil": 1,
    "page": 40,
    "ruku": 33,
    "hizbQuarter": 16,
    "sajda": false
  };

  final sampleSahihData = {
    "number": 255,
    "text":
        "And their prophet said to them, \"Indeed, a sign of his kingship is that the chest will come to you in which is assurance from your Lord and a remnant of what the family of Moses and the family of Aaron had left, carried by the angels. Indeed in that is a sign for you, if you are believers.\"",
    "edition": {
      "identifier": "en.sahih",
      "language": "en",
      "name": "Saheeh International",
      "englishName": "Saheeh International",
      "format": "text",
      "type": "translation",
      "direction": "ltr"
    },
    "surah": {
      "number": 2,
      "name": "سُورَةُ البَقَرَةِ",
      "englishName": "Al-Baqara",
      "englishNameTranslation": "The Cow",
      "numberOfAyahs": 286,
      "revelationType": "Medinan"
    },
    "numberInSurah": 248,
    "juz": 2,
    "manzil": 1,
    "page": 40,
    "ruku": 33,
    "hizbQuarter": 16,
    "sajda": false
  };

  group('DailyAyahModel Tests', () {
    test('Constructs from API payload correctly', () {
      final model = DailyAyahModel.fromApiData(
        uthmaniData: sampleUthmaniData,
        sahihData: sampleSahihData,
        dateKey: '2026-09-10',
      );

      expect(model.number, 255);
      expect(model.arabicText, startsWith('وَقَالَ لَهُمْ نَبِيُّهُمْ'));
      expect(model.translationText, startsWith('And their prophet said to them'));
      expect(model.surahNumber, 2);
      expect(model.surahName, 'سُورَةُ البَقَرَةِ');
      expect(model.surahEnglishName, 'Al-Baqara');
      expect(model.surahEnglishTranslation, 'The Cow');
      expect(model.numberOfAyahsInSurah, 286);
      expect(model.numberInSurah, 248);
      expect(model.juz, 2);
      expect(model.page, 40);
      expect(model.ruku, 33);
      expect(model.sajda, isFalse);
      expect(model.dateKey, '2026-09-10');
    });

    test('Json serialization and deserialization roundtrip', () {
      final model = DailyAyahModel.fromApiData(
        uthmaniData: sampleUthmaniData,
        sahihData: sampleSahihData,
        dateKey: '2026-09-10',
      );

      final jsonStr = model.toJson();
      final restored = DailyAyahModel.fromJson(jsonStr);

      expect(restored.number, model.number);
      expect(restored.arabicText, model.arabicText);
      expect(restored.translationText, model.translationText);
      expect(restored.surahNumber, model.surahNumber);
      expect(restored.surahName, model.surahName);
      expect(restored.surahEnglishName, model.surahEnglishName);
      expect(restored.numberInSurah, model.numberInSurah);
      expect(restored.juz, model.juz);
      expect(restored.dateKey, model.dateKey);
    });

    test('Default fallback ayah is valid', () {
      const def = DailyAyahModel.defaultAyah;
      expect(def.number, 255);
      expect(def.arabicText.isNotEmpty, isTrue);
      expect(def.translationText.isNotEmpty, isTrue);
      expect(def.surahName, 'سُورَةُ البَقَرَةِ');
      expect(def.surahEnglishName, 'Al-Baqara');
      expect(def.numberInSurah, 248);
      expect(def.juz, 2);
    });
  });

  group('DailyAyahService Tests', () {
    test('Returns cached ayah if cached today', () async {
      final fakeStorage = FakeStorageService();
      final model = DailyAyahModel.fromApiData(
        uthmaniData: sampleUthmaniData,
        sahihData: sampleSahihData,
        dateKey: '2026-09-10',
      );
      // Cache with current date
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);
      final todayModel = DailyAyahModel(
        number: model.number,
        arabicText: model.arabicText,
        translationText: model.translationText,
        surahNumber: model.surahNumber,
        surahName: model.surahName,
        surahEnglishName: model.surahEnglishName,
        surahEnglishTranslation: model.surahEnglishTranslation,
        numberOfAyahsInSurah: model.numberOfAyahsInSurah,
        numberInSurah: model.numberInSurah,
        juz: model.juz,
        dateKey: todayKey,
      );

      await fakeStorage.saveGenericData(
        'daily_ayah_cache_key',
        todayModel.toJson(),
      );

      final service = DailyAyahService(fakeStorage);
      final fetched = await service.getDailyAyah(forceRefresh: false);

      expect(fetched.number, 255);
      expect(fetched.dateKey, todayKey);
    });

    test('getCachedAyah returns null if nothing is cached', () {
      final fakeStorage = FakeStorageService();
      final service = DailyAyahService(fakeStorage);
      expect(service.getCachedAyah(), isNull);
    });
  });

  group('DailyAyahCard Widget Tests', () {
    testWidgets('Renders Arabic text, translation, Surah and Juz correctly', (tester) async {
      final fakeStorage = FakeStorageService();
      final model = DailyAyahModel.fromApiData(
        uthmaniData: sampleUthmaniData,
        sahihData: sampleSahihData,
        dateKey: '2026-09-10',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(fakeStorage),
            dailyAyahProvider.overrideWith((ref) => DailyAyahNotifier(DailyAyahService(fakeStorage))
              ..state = AsyncValue.data(model)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DailyAyahCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Arabic text
      expect(find.text(model.arabicText), findsOneWidget);

      // Check Translation text
      expect(find.text('"${model.translationText}"'), findsOneWidget);

      // Check single-line citation with English name, Arabic name in brackets, and surah:verse
      expect(
        find.text('Quran • ${model.surahEnglishName} (${model.surahName}) ${model.surahNumber}:${model.numberInSurah}'),
        findsOneWidget,
      );

      // Verify header badge, copy button, refresh button, and Read Surah are removed
      expect(find.text('Ayah of the Day'), findsNothing);
      expect(find.byIcon(Icons.copy_rounded), findsNothing);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.text('Read Surah'), findsNothing);
    });
  });
}
