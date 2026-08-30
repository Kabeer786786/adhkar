import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String settingsBoxName = 'settings_box';
  static const String tasbeehBoxName = 'tasbeeh_box';
  static const String bookmarksBoxName = 'bookmarks_box';
  static const String adhkarBoxName = 'adhkar_box';
  static const String hijriCacheBoxName = 'hijri_cache_box';

  late Box _settingsBox;
  late Box _tasbeehBox;
  late Box _bookmarksBox;
  late Box _adhkarBox;
  late Box _hijriBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(settingsBoxName);
    _tasbeehBox = await Hive.openBox(tasbeehBoxName);
    _bookmarksBox = await Hive.openBox(bookmarksBoxName);
    _adhkarBox = await Hive.openBox(adhkarBoxName);
    _hijriBox = await Hive.openBox(hijriCacheBoxName);
  }
  // --- Generic Persistence Helpers ---
  dynamic getGenericData(String key) {
    return _adhkarBox.get(key);
  }

  Future<void> saveGenericData(String key, dynamic value) async {
    await _adhkarBox.put(key, value);
  }

  List<String> getCustomCategories(String featureKey) {
    final data = _adhkarBox.get('custom_categories_$featureKey');
    if (data != null && data is List) {
      return List<String>.from(data.map((e) => e.toString()));
    }
    return [];
  }

  Future<void> saveCustomCategory(String featureKey, String categoryName) async {
    final current = getCustomCategories(featureKey);
    if (!current.contains(categoryName)) {
      current.add(categoryName);
      await _adhkarBox.put('custom_categories_$featureKey', current);
    }
  }

  // --- Settings & Preferences ---
  String getThemeMode() {
    return _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  }

  Future<void> setThemeMode(String value) async {
    await _settingsBox.put('theme_mode', value);
  }

  bool isDarkMode() {
    return _settingsBox.get('is_dark_mode', defaultValue: false) as bool;
  }

  Future<void> setDarkMode(bool value) async {
    await _settingsBox.put('is_dark_mode', value);
  }

  String getLanguage() {
    return _settingsBox.get('language', defaultValue: 'en') as String;
  }

  Future<void> setLanguage(String value) async {
    await _settingsBox.put('language', value);
  }

  String getArabicFont() {
    return _settingsBox.get('arabic_font', defaultValue: 'digitalKhattIndoPak') as String;
  }

  Future<void> setArabicFont(String value) async {
    await _settingsBox.put('arabic_font', value);
  }

  // --- Location ---
  Map<String, dynamic>? getSavedLocation() {
    final data = _settingsBox.get('saved_location');
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> setSavedLocation(double lat, double lng, String city, String country) async {
    await _settingsBox.put('saved_location', {
      'lat': lat,
      'lng': lng,
      'city': city,
      'country': country,
    });
  }

  double? getLatitude() => getSavedLocation()?['lat'] as double?;
  double? getLongitude() => getSavedLocation()?['lng'] as double?;
  String? getCity() => getSavedLocation()?['city'] as String?;

  // --- Prayer Calculation Method & Juristic School ---
  String getCalculationMethod() {
    return _settingsBox.get('calc_method', defaultValue: 'KARACHI') as String;
  }

  Future<void> setCalculationMethod(dynamic method) async {
    await _settingsBox.put('calc_method', method.toString());
  }

  String getAsrJuristic() {
    return _settingsBox.get('asr_juristic', defaultValue: 'Hanafi') as String;
  }

  Future<void> setAsrJuristic(String school) async {
    await _settingsBox.put('asr_juristic', school);
  }

  bool isAutoLocation() {
    return _settingsBox.get('auto_location', defaultValue: true) as bool;
  }

  Future<void> setAutoLocation(bool value) async {
    await _settingsBox.put('auto_location', value);
  }

  // --- Hijri Date Cache ---
  String? getCachedHijriDate(String dateKey) {
    return _hijriBox.get('hijri_$dateKey') as String?;
  }

  Future<void> setCachedHijriDate(String dateKey, String hijriDateStr) async {
    await _hijriBox.put('hijri_$dateKey', hijriDateStr);
  }

  Future<void> setHijriLastFetchedMs(int timestamp) async {
    await _hijriBox.put('hijri_last_fetched_ms', timestamp);
  }

  // --- Prayer Notifications & Records ---
  Map<String, dynamic>? getPrayerNotificationConfig(String prayerKey) {
    final data = _settingsBox.get('prayer_notif_$prayerKey');
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> setPrayerNotificationConfig(String prayerKey, Map<String, dynamic> config) async {
    await _settingsBox.put('prayer_notif_$prayerKey', config);
  }

  List<String> getSubPrayerRecords(String dateKey, String prayerKey) {
    final data = _settingsBox.get('sub_prayer_${dateKey}_$prayerKey');
    if (data != null && data is List) {
      return List<String>.from(data.map((e) => e.toString()));
    }
    return [];
  }

  Future<void> setSubPrayerRecords(String dateKey, String prayerKey, List<String> records) async {
    await _settingsBox.put('sub_prayer_${dateKey}_$prayerKey', records);
  }

  List<String> getSalahRecordsForDate(String dateKey) {
    final data = _settingsBox.get('salah_records_$dateKey');
    if (data != null && data is List) {
      return List<String>.from(data.map((e) => e.toString()));
    }
    return [];
  }

  // --- Adhkar Items & Progress ---
  List<Map<String, dynamic>>? getSavedAdhkarCategories() {
    final data = _adhkarBox.get('adhkar_categories');
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> saveAdhkarCategories(List<Map<String, dynamic>> categories) async {
    await _adhkarBox.put('adhkar_categories', categories);
  }

  List<Map<String, dynamic>>? getSavedAdhkarItems() {
    final data = _adhkarBox.get('adhkar_items');
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> saveAdhkarItems(List<Map<String, dynamic>> items) async {
    await _adhkarBox.put('adhkar_items', items);
  }

  Map<String, int> getDailyAdhkarCounts(String dateKey) {
    final data = _adhkarBox.get('adhkar_daily_$dateKey');
    if (data != null && data is Map) {
      return Map<String, int>.from(data.map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
    }
    return {};
  }

  Future<void> saveDailyAdhkarCount(String dateKey, String dhikrId, int count) async {
    final map = getDailyAdhkarCounts(dateKey);
    map[dhikrId] = count;
    await _adhkarBox.put('adhkar_daily_$dateKey', map);
  }

  // --- Tasbeeh Counter & Per-Item Lifetime ---
  String getTasbeehSwipeDirection() {
    return _settingsBox.get('tasbeeh_swipe_direction', defaultValue: 'right_to_left') as String;
  }

  Future<void> setTasbeehSwipeDirection(String direction) async {
    await _settingsBox.put('tasbeeh_swipe_direction', direction);
  }

  int getTasbeehCount(String zikrId) {
    return _tasbeehBox.get('count_$zikrId', defaultValue: 0) as int;
  }

  Future<void> setTasbeehCount(String zikrId, int count) async {
    await _tasbeehBox.put('count_$zikrId', count);
  }

  int getLifetimeTasbeehCount([String? tasbeehId]) {
    if (tasbeehId != null) {
      return _tasbeehBox.get('lifetime_count_$tasbeehId', defaultValue: 0) as int;
    }
    return _tasbeehBox.get('lifetime_count', defaultValue: 0) as int;
  }

  Future<void> incrementLifetimeTasbeeh([String? tasbeehId]) async {
    final currentTotal = getLifetimeTasbeehCount();
    await _tasbeehBox.put('lifetime_count', currentTotal + 1);

    if (tasbeehId != null) {
      final currentItem = getLifetimeTasbeehCount(tasbeehId);
      await _tasbeehBox.put('lifetime_count_$tasbeehId', currentItem + 1);
    }
  }

  List<Map<String, dynamic>>? getSavedTasbeehItems() {
    final data = _tasbeehBox.get('custom_tasbeeh_items');
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> saveTasbeehItems(List<Map<String, dynamic>> items) async {
    await _tasbeehBox.put('custom_tasbeeh_items', items);
  }

  int getDailyTasbeehCount(String dateKey, String tasbeehId) {
    final map = getDailyTasbeehCountsMap(dateKey);
    return map[tasbeehId] ?? 0;
  }

  Map<String, int> getDailyTasbeehCountsMap(String dateKey) {
    final data = _tasbeehBox.get('tasbeeh_daily_$dateKey');
    if (data != null && data is Map) {
      return Map<String, int>.from(data.map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
    }
    return {};
  }

  Future<void> setDailyTasbeehCount(String dateKey, String tasbeehId, int count) async {
    final currentMap = getDailyTasbeehCountsMap(dateKey);
    final oldCount = currentMap[tasbeehId] ?? 0;
    currentMap[tasbeehId] = count;
    await _tasbeehBox.put('tasbeeh_daily_$dateKey', currentMap);

    await setTasbeehCount(tasbeehId, count);

    if (count > oldCount) {
      final diff = count - oldCount;
      final itemLifetime = getLifetimeTasbeehCount(tasbeehId);
      final newItemLifetime = math.max(itemLifetime + diff, count);
      await _tasbeehBox.put('lifetime_count_$tasbeehId', newItemLifetime);

      final totalLifetime = getLifetimeTasbeehCount();
      await _tasbeehBox.put('lifetime_count', totalLifetime + diff);
    }
  }

  // --- Quran Bookmarks, Favorites & Reading Settings ---
  int? getLastReadSurah() {
    return _bookmarksBox.get('last_surah') as int?;
  }

  int? getLastReadAyah() {
    return _bookmarksBox.get('last_ayah') as int?;
  }

  int? getLastReadJuz() {
    return _bookmarksBox.get('last_juz') as int?;
  }

  Future<void> saveBookmark(int surah, int ayah) async {
    await _bookmarksBox.put('last_surah', surah);
    await _bookmarksBox.put('last_ayah', ayah);
  }

  Future<void> setLastRead(dynamic surah, int ayah) async {
    await _bookmarksBox.put('last_surah', surah);
    await _bookmarksBox.put('last_ayah', ayah);
  }

  Future<void> setLastReadJuz(int juz) async {
    await _bookmarksBox.put('last_juz', juz);
  }

  List<int> getFavoriteSurahs() {
    final data = _bookmarksBox.get('favorite_surahs');
    if (data != null && data is List) {
      return List<int>.from(data.map((e) => (e as num).toInt()));
    }
    return [];
  }

  Future<void> toggleFavoriteSurah(int surahNumber) async {
    final current = getFavoriteSurahs();
    if (current.contains(surahNumber)) {
      current.remove(surahNumber);
    } else {
      current.add(surahNumber);
    }
    await _bookmarksBox.put('favorite_surahs', current);
  }

  bool isSurahFavorite(int surahNumber) {
    return getFavoriteSurahs().contains(surahNumber);
  }

  List<int> getFavoriteJuz() {
    final data = _bookmarksBox.get('favorite_juz');
    if (data != null && data is List) {
      return List<int>.from(data.map((e) => (e as num).toInt()));
    }
    return [];
  }

  Future<void> toggleFavoriteJuz(int juzNumber) async {
    final current = getFavoriteJuz();
    if (current.contains(juzNumber)) {
      current.remove(juzNumber);
    } else {
      current.add(juzNumber);
    }
    await _bookmarksBox.put('favorite_juz', current);
  }

  bool isJuzFavorite(int juzNumber) {
    return getFavoriteJuz().contains(juzNumber);
  }

  // --- Quran Stop Points & Reading History ---
  List<Map<String, dynamic>> getQuranStopPoints() {
    final data = _bookmarksBox.get('quran_stop_points');
    if (data != null && data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) => ((b['timestamp'] ?? 0) as num)
            .compareTo((a['timestamp'] ?? 0) as num));
    }
    return [];
  }

  Future<void> saveQuranStopPoint({
    required int surahNumber,
    required String surahNameEnglish,
    required String surahNameArabic,
    int? juzNumber,
    required int markedAyahNumber,
    required int totalAyahs,
    int? page,
  }) async {
    final currentList = getQuranStopPoints();
    final String id = juzNumber != null
        ? 'juz_$juzNumber'
        : 'surah_$surahNumber';

    final resumeAyah = markedAyahNumber < totalAyahs
        ? markedAyahNumber + 1
        : markedAyahNumber;

    final entry = {
      'id': id,
      'surahNumber': surahNumber,
      'surahNameEnglish': surahNameEnglish,
      'surahNameArabic': surahNameArabic,
      'juzNumber': juzNumber,
      'markedAyahNumber': markedAyahNumber,
      'resumeAyahNumber': resumeAyah,
      'totalAyahs': totalAyahs,
      'page': page ?? 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    currentList.removeWhere((e) => e['id'] == id);
    currentList.insert(0, entry);
    await _bookmarksBox.put('quran_stop_points', currentList);

    // Also update classic last read
    if (juzNumber != null) {
      await setLastReadJuz(juzNumber);
    } else {
      await setLastRead(surahNumber, markedAyahNumber);
    }
  }

  Future<void> removeQuranStopPoint(String id) async {
    final currentList = getQuranStopPoints();
    currentList.removeWhere((e) => e['id'] == id);
    await _bookmarksBox.put('quran_stop_points', currentList);
  }

  Future<void> clearAllQuranStopPoints() async {
    await _bookmarksBox.put('quran_stop_points', []);
  }

  Map<String, dynamic>? getLatestStopPoint({int? surahNumber, int? juzNumber}) {
    final list = getQuranStopPoints();
    if (juzNumber != null) {
      final matches = list.where((e) => e['juzNumber'] == juzNumber);
      return matches.isNotEmpty ? matches.first : null;
    }
    if (surahNumber != null) {
      final matches = list.where((e) => e['surahNumber'] == surahNumber && e['juzNumber'] == null);
      return matches.isNotEmpty ? matches.first : null;
    }
    return list.isNotEmpty ? list.first : null;
  }

  Map<String, dynamic>? getStopPointForSurah(int surahNumber) {
    final list = getQuranStopPoints();
    final matches = list.where((e) => e['id'] == 'surah_$surahNumber' || (e['surahNumber'] == surahNumber && e['juzNumber'] == null));
    return matches.isNotEmpty ? matches.first : null;
  }

  Map<String, dynamic>? getStopPointForJuz(int juzNumber) {
    final list = getQuranStopPoints();
    final matches = list.where((e) => e['id'] == 'juz_$juzNumber' || e['juzNumber'] == juzNumber);
    return matches.isNotEmpty ? matches.first : null;
  }

  bool isAyahMarkedAsStopPoint(int surahNumber, int ayahNumber, {int? juzNumber}) {
    final sp = juzNumber != null
        ? getStopPointForJuz(juzNumber)
        : getStopPointForSurah(surahNumber);
    if (sp == null) return false;
    return sp['surahNumber'] == surahNumber && sp['markedAyahNumber'] == ayahNumber;
  }

  // --- Quran Ayah Bookmarks ---
  List<Map<String, dynamic>> getQuranAyahBookmarks() {
    final data = _bookmarksBox.get('quran_ayah_bookmarks');
    if (data != null && data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) => ((b['timestamp'] ?? 0) as num)
            .compareTo((a['timestamp'] ?? 0) as num));
    }
    return [];
  }

  Future<void> saveQuranAyahBookmark({
    required int surahNumber,
    required String surahNameEnglish,
    required String surahNameArabic,
    required int juzNumber,
    required int ayahNumber,
    required int totalAyahs,
    required int page,
    required String arabicText,
    required String translationEnglish,
  }) async {
    final currentList = getQuranAyahBookmarks();
    final id = 'bookmark_${surahNumber}_$ayahNumber';
    final entry = {
      'id': id,
      'surahNumber': surahNumber,
      'surahNameEnglish': surahNameEnglish,
      'surahNameArabic': surahNameArabic,
      'juzNumber': juzNumber,
      'ayahNumber': ayahNumber,
      'totalAyahs': totalAyahs,
      'page': page,
      'arabicText': arabicText,
      'translationEnglish': translationEnglish,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    currentList.removeWhere((e) => e['id'] == id);
    currentList.insert(0, entry);
    await _bookmarksBox.put('quran_ayah_bookmarks', currentList);
  }

  Future<void> removeQuranAyahBookmark(String id) async {
    final currentList = getQuranAyahBookmarks();
    currentList.removeWhere((e) => e['id'] == id);
    await _bookmarksBox.put('quran_ayah_bookmarks', currentList);
  }

  Future<void> clearAllQuranAyahBookmarks() async {
    await _bookmarksBox.put('quran_ayah_bookmarks', []);
  }

  bool isAyahBookmarked(int surahNumber, int ayahNumber) {
    final list = getQuranAyahBookmarks();
    final id = 'bookmark_${surahNumber}_$ayahNumber';
    return list.any((e) => e['id'] == id || (e['surahNumber'] == surahNumber && e['ayahNumber'] == ayahNumber));
  }

  double getQuranArabicFontSize() {
    return (_settingsBox.get('quran_arabic_font_size', defaultValue: 24.0) as num).toDouble();
  }

  Future<void> setQuranArabicFontSize(double size) async {
    await _settingsBox.put('quran_arabic_font_size', size);
  }

  bool? getQuranReadingDarkMode() {
    return _settingsBox.get('quran_reading_dark_mode') as bool?;
  }

  Future<void> setQuranReadingDarkMode(bool isDark) async {
    await _settingsBox.put('quran_reading_dark_mode', isDark);
  }

  String getQuranTranslationLanguage() {
    return _settingsBox.get('quran_translation_lang', defaultValue: 'none') as String;
  }

  Future<void> setQuranTranslationLanguage(String lang) async {
    await _settingsBox.put('quran_translation_lang', lang);
  }

  // --- Saved Dua Items ---
  List<Map<String, dynamic>>? getSavedDuaItems() {
    final data = _adhkarBox.get('custom_dua_items');
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> saveDuaItems(List<Map<String, dynamic>> items) async {
    await _adhkarBox.put('custom_dua_items', items);
  }

  // --- Quiet Hours Persistence ---
  Map<String, dynamic>? getQuietHours() {
    final data = _settingsBox.get('quiet_hours_config');
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveQuietHours(Map<String, dynamic> data) async {
    await _settingsBox.put('quiet_hours_config', data);
  }

  List<Map<String, dynamic>>? getQuietHoursList() {
    final data = _settingsBox.get('quiet_hours_list_v2');
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    // Backward compatibility with single quiet_hours_config
    final single = getQuietHours();
    if (single != null) {
      return [single];
    }
    return null;
  }

  Future<void> saveQuietHoursList(List<Map<String, dynamic>> items) async {
    await _settingsBox.put('quiet_hours_list_v2', items);
  }
}
