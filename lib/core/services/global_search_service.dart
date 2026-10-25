import 'package:flutter/material.dart';
import '../../features/adhkar/repositories/adhkar_repository.dart';
import '../../features/asma_ul_husna/data/asma_ul_husna_data.dart';
import '../../features/books/data/books_repository.dart';
import '../../features/dua/data/dua_repository.dart';
import '../../features/dua/domain/dua_item.dart';
import '../../features/quran/data/juz_model.dart';
import '../../features/quran/repositories/quran_repository.dart';
import '../../features/sci_islam/data/sci_islam_data.dart';
import '../../shared/models/tasbeeh_item.dart';

enum GlobalSearchCategory {
  all('All', Icons.grid_view_rounded),
  quran('Quran', Icons.menu_book_rounded),
  juz('Juz / Para', Icons.auto_stories_rounded),
  duaeen('Dua & Adhkar', Icons.favorite_rounded),
  asmaUlHusna('99 Names', Icons.stars_rounded),
  scientificIslam('Science', Icons.science_rounded),
  books('Books', Icons.library_books_rounded),
  tasbeeh('Tasbeeh', Icons.touch_app_rounded),
  features('Tools', Icons.widgets_rounded);

  final String label;
  final IconData icon;
  const GlobalSearchCategory(this.label, this.icon);
}

class GlobalSearchItem {
  final String id;
  final String title;
  final String subtitle;
  final String? arabic;
  final String category;
  final GlobalSearchCategory categoryType;
  final IconData icon;
  final String route;
  final List<String> keywords;

  const GlobalSearchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.arabic,
    required this.category,
    required this.categoryType,
    required this.icon,
    required this.route,
    this.keywords = const [],
  });
}

class GlobalSearchService {
  static final GlobalSearchService _instance = GlobalSearchService._internal();
  factory GlobalSearchService() => _instance;
  GlobalSearchService._internal();

  List<GlobalSearchItem>? _cachedCatalog;
  bool _isAsyncLoaded = false;

  /// Returns full indexed catalog of all app items synchronously,
  /// initializing from memory data sets on first call.
  List<GlobalSearchItem> getCatalog() {
    if (_cachedCatalog != null) {
      return _cachedCatalog!;
    }
    _buildInitialCatalog();
    return _cachedCatalog!;
  }

  /// Warmup async data (such as the 197 Duas from assets/data/duaeen.json) in background.
  Future<void> warmupAsync() async {
    if (_isAsyncLoaded) return;
    try {
      final allDuas = await DuaRepository()
          .loadAllDuas()
          .timeout(const Duration(seconds: 1));
      _mergeAdditionalDuas(allDuas);
      _isAsyncLoaded = true;
    } catch (_) {}
  }

  void _buildInitialCatalog() {
    final items = <GlobalSearchItem>[];

    // 1. Core App Features & Navigation
    items.addAll(_buildFeatures());

    // 2. All 114 Quran Surahs
    items.addAll(_buildSurahs());

    // 3. All 30 Juz / Paras
    items.addAll(_buildJuzList());

    // 4. Adhkar Categories
    items.addAll(_buildAdhkarCategories());

    // 5. Curated & Essential Duas
    items.addAll(_buildCuratedDuas());

    // 6. Asma ul Husna (99 Names of Allah)
    items.addAll(_buildAsmaUlHusna());

    // 7. Scientific Islam Miracles & Topics
    items.addAll(_buildScientificIslam());

    // 8. Islamic Books Library
    items.addAll(_buildBooks());

    // 9. Tasbeeh Presets & Counters
    items.addAll(_buildTasbeehs());

    _cachedCatalog = items;
  }

  List<GlobalSearchItem> _buildFeatures() {
    return const [
      GlobalSearchItem(
        id: 'feat_prayer',
        title: 'Prayer Times & Timetable',
        subtitle: 'Accurate Salah timings, countdown & notifications',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.access_time_filled_rounded,
        route: '/prayer',
        keywords: ['prayer', 'salah', 'namaz', 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'tahajjud', 'time', 'timetable'],
      ),
      GlobalSearchItem(
        id: 'feat_salah_tracker',
        title: 'Salah Tracker & History',
        subtitle: 'Track daily prayers, log missed prayers & habits',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.check_circle_rounded,
        route: '/prayer',
        keywords: ['salah tracker', 'tracker', 'namaz record', 'prayer log', 'daily salah'],
      ),
      GlobalSearchItem(
        id: 'feat_qibla',
        title: 'Qibla Finder Compass',
        subtitle: 'Precision direction to Kaaba in Makkah',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.explore_rounded,
        route: '/qibla',
        keywords: ['qibla', 'compass', 'kaaba', 'direction', 'mecca', 'makkah'],
      ),
      GlobalSearchItem(
        id: 'feat_roza',
        title: 'Roza & Fasting Tracker',
        subtitle: 'Suhoor, Iftar times, Ramadan & voluntary fasts',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.nightlight_round,
        route: '/roza',
        keywords: ['roza', 'fasting', 'ramadan', 'suhoor', 'sehri', 'iftar', 'sawm', 'voluntary fast'],
      ),
      GlobalSearchItem(
        id: 'feat_sadqa',
        title: 'Sadqa & Charity Tracker',
        subtitle: 'Log and monitor charity, donations & zakat',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.volunteer_activism_rounded,
        route: '/sadqa',
        keywords: ['sadqa', 'sadaqah', 'charity', 'zakat', 'donation', 'giving'],
      ),
      GlobalSearchItem(
        id: 'feat_calendar',
        title: 'Islamic Hijri Calendar',
        subtitle: 'Hijri dates, Islamic events & holy months',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.calendar_month_rounded,
        route: '/islamic-calendar',
        keywords: ['hijri', 'calendar', 'islamic date', 'muharram', 'ramadan', 'dhul hijjah', 'events'],
      ),
      GlobalSearchItem(
        id: 'feat_what_is_islam',
        title: 'What is Islam Guide',
        subtitle: 'Introduction to Islam, Tawheed & 5 Pillars',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.menu_book_outlined,
        route: '/what-is-islam',
        keywords: ['what is islam', 'intro', 'pillars', 'faith', 'basics', 'principles'],
      ),
      GlobalSearchItem(
        id: 'feat_reminder',
        title: 'Adhkar Alarms & Reminders',
        subtitle: 'Scheduled reminders for morning, evening & prayer',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.alarm_rounded,
        route: '/reminder',
        keywords: ['alarm', 'reminder', 'schedule', 'notification', 'alert'],
      ),
      GlobalSearchItem(
        id: 'feat_quiet_hours',
        title: 'Quiet Hours (Silence in Salah)',
        subtitle: 'Auto-mute phone during prayer times in Mosque',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.do_not_disturb_on_rounded,
        route: '/quiet-hours',
        keywords: ['quiet hours', 'silent', 'dnd', 'do not disturb', 'mute', 'mosque mode'],
      ),
      GlobalSearchItem(
        id: 'feat_settings',
        title: 'Settings & Calculation Methods',
        subtitle: 'Calculation method, theme, Juristic school & audio',
        category: 'Tools',
        categoryType: GlobalSearchCategory.features,
        icon: Icons.settings_rounded,
        route: '/settings',
        keywords: ['settings', 'config', 'method', 'hanafi', 'shafi', 'theme', 'dark mode', 'language'],
      ),
    ];
  }

  List<GlobalSearchItem> _buildSurahs() {
    final surahs = QuranRepository().getSurahs();
    return surahs.map((s) {
      final numStr = s.number.toString();
      return GlobalSearchItem(
        id: 'surah_$numStr',
        title: 'Surah ${s.nameEnglish}',
        subtitle: '${s.nameTranslation} • ${s.verseCount} Verses • ${s.revelationType}',
        arabic: s.nameArabic,
        category: 'Quran',
        categoryType: GlobalSearchCategory.quran,
        icon: Icons.menu_book_rounded,
        route: '/quran/surah?num=$numStr&name=${Uri.encodeComponent(s.nameEnglish)}',
        keywords: [
          'surah',
          'chapter',
          'quran',
          s.nameEnglish,
          s.nameTranslation,
          s.revelationType,
          numStr,
          'surah $numStr',
        ],
      );
    }).toList();
  }

  List<GlobalSearchItem> _buildJuzList() {
    return juzList.map((j) {
      return GlobalSearchItem(
        id: 'juz_${j.number}',
        title: 'Juz ${j.number} (${j.nameEnglish})',
        subtitle: '${j.surahRange} • Pages ${j.startPage}-${j.endPage}',
        arabic: j.nameArabic,
        category: 'Juz / Para',
        categoryType: GlobalSearchCategory.juz,
        icon: Icons.auto_stories_rounded,
        route: '/quran/surah?num=1&juz=${j.number}&name=${Uri.encodeComponent(j.nameEnglish)}',
        keywords: [
          'juz',
          'para',
          'siparah',
          'part',
          'juz ${j.number}',
          'para ${j.number}',
          j.nameEnglish,
          j.surahRange,
          '${j.number}',
        ],
      );
    }).toList();
  }

  List<GlobalSearchItem> _buildAdhkarCategories() {
    final categories = AdhkarRepository().getDefaultCategories();
    return categories.map((cat) {
      return GlobalSearchItem(
        id: 'adhkar_cat_${cat.id}',
        title: cat.title,
        subtitle: cat.subtitle,
        arabic: cat.titleAr,
        category: 'Adhkar',
        categoryType: GlobalSearchCategory.duaeen,
        icon: cat.id == 'morning'
            ? Icons.wb_sunny_rounded
            : cat.id == 'evening'
                ? Icons.nights_stay_rounded
                : cat.id == 'salah'
                    ? Icons.mosque_rounded
                    : cat.id == 'sleep'
                        ? Icons.bedtime_rounded
                        : Icons.favorite_rounded,
        route: cat.id == 'duas'
            ? '/dua'
            : '/adhkar/detail?id=${cat.id}&title=${Uri.encodeComponent(cat.title)}',
        keywords: [
          'adhkar',
          'dhikr',
          'azkar',
          cat.title,
          cat.titleAr,
          cat.id,
          'morning',
          'evening',
          'salah',
          'sleep',
          'daily',
        ],
      );
    }).toList();
  }

  List<GlobalSearchItem> _buildCuratedDuas() {
    final duas = DuaRepository().getDefaultDuas();
    return duas.map((d) {
      return GlobalSearchItem(
        id: 'dua_${d.id}',
        title: d.title,
        subtitle: '${d.category} • ${d.reference}',
        arabic: d.arabic,
        category: 'Dua',
        categoryType: GlobalSearchCategory.duaeen,
        icon: Icons.volunteer_activism_outlined,
        route: '/dua/detail?id=${Uri.encodeComponent(d.id)}&lang=en',
        keywords: [
          'dua',
          'supplication',
          d.title,
          d.category,
          d.reference,
          d.transliteration,
          d.translation,
        ],
      );
    }).toList();
  }

  void _mergeAdditionalDuas(List<DuaItem> allDuas) {
    if (_cachedCatalog == null) return;
    final existingIds = _cachedCatalog!.map((e) => e.id).toSet();
    final newItems = <GlobalSearchItem>[];

    for (final d in allDuas) {
      final id = 'dua_${d.id}';
      if (!existingIds.contains(id)) {
        newItems.add(
          GlobalSearchItem(
            id: id,
            title: d.title,
            subtitle: '${d.category} • ${d.reference}',
            arabic: d.arabic,
            category: 'Dua',
            categoryType: GlobalSearchCategory.duaeen,
            icon: Icons.volunteer_activism_outlined,
            route: '/dua/detail?id=${Uri.encodeComponent(d.id)}&lang=en',
            keywords: [
              'dua',
              'supplication',
              d.title,
              d.category,
              d.reference,
              d.transliteration,
              d.translation,
            ],
          ),
        );
      }
    }
    _cachedCatalog!.addAll(newItems);
  }

  List<GlobalSearchItem> _buildAsmaUlHusna() {
    return asmaUlHusnaList.map((name) {
      return GlobalSearchItem(
        id: 'asma_${name.number}',
        title: '${name.number}. ${name.transliteration}',
        subtitle: name.shortMeaning,
        arabic: name.name,
        category: '99 Names',
        categoryType: GlobalSearchCategory.asmaUlHusna,
        icon: Icons.stars_rounded,
        route: '/asma-ul-husna',
        keywords: [
          'asma ul husna',
          '99 names',
          'allah',
          'name of allah',
          name.transliteration,
          name.name,
          name.shortMeaning,
          name.longMeaning,
          '${name.number}',
        ],
      );
    }).toList();
  }

  List<GlobalSearchItem> _buildScientificIslam() {
    return SciIslamData.items.map((sci) {
      return GlobalSearchItem(
        id: 'sci_${sci.id}',
        title: sci.title,
        subtitle: '${sci.category} • ${sci.surahReference}',
        arabic: sci.arabicVerse,
        category: 'Scientific Islam',
        categoryType: GlobalSearchCategory.scientificIslam,
        icon: sci.icon,
        route: '/sci-islam',
        keywords: [
          'scientific islam',
          'science',
          'miracle',
          'quran miracle',
          sci.title,
          sci.category,
          sci.badgeText,
          sci.surahReference,
          sci.shortDescription,
        ],
      );
    }).toList();
  }

  List<GlobalSearchItem> _buildBooks() {
    return BooksRepository.prebuiltLibrary.map((b) {
      return GlobalSearchItem(
        id: 'book_${b.id}',
        title: b.title,
        subtitle: '${b.author} • ${b.category}',
        category: 'Books',
        categoryType: GlobalSearchCategory.books,
        icon: Icons.library_books_rounded,
        route: '/books',
        keywords: [
          'book',
          'library',
          'reading',
          b.title,
          b.author,
          b.category,
          b.description,
        ],
      );
    }).toList();
  }

  List<GlobalSearchItem> _buildTasbeehs() {
    final list = <GlobalSearchItem>[
      const GlobalSearchItem(
        id: 'tasbeeh_hub',
        title: 'Digital Tasbeeh Counter',
        subtitle: 'Preset Dhikr, customizable target & marble beads',
        category: 'Tasbeeh',
        categoryType: GlobalSearchCategory.tasbeeh,
        icon: Icons.touch_app_rounded,
        route: '/tasbeeh',
        keywords: ['tasbeeh', 'dhikr', 'counter', 'beads', 'digital counter'],
      ),
      const GlobalSearchItem(
        id: 'tasbeeh_free_counter',
        title: 'Free Tasbeeh Counter',
        subtitle: 'Fullscreen tap counter with haptics & sound',
        category: 'Tasbeeh',
        categoryType: GlobalSearchCategory.tasbeeh,
        icon: Icons.radio_button_checked_rounded,
        route: '/tasbeeh/counter',
        keywords: ['free counter', 'tasbeeh counter', 'tap counter', 'haptic'],
      ),
    ];

    for (final t in TasbeehItem.defaults) {
      list.add(
        GlobalSearchItem(
          id: 'tasbeeh_preset_${t.id}',
          title: t.textEn,
          subtitle: '${t.effectiveTranslation.isNotEmpty ? t.effectiveTranslation : t.description} (Target: ${t.targetGoal})',
          arabic: t.textAr,
          category: 'Tasbeeh',
          categoryType: GlobalSearchCategory.tasbeeh,
          icon: Icons.flare_rounded,
          route: '/tasbeeh',
          keywords: [
            'tasbeeh',
            'dhikr',
            t.textEn,
            t.textAr,
            t.translation,
            t.description,
          ],
        ),
      );
    }

    return list;
  }

  /// Searches catalog with high-speed multi-factor relevance ranking.
  /// Always returns strictly the top 10 matches.
  List<GlobalSearchItem> search(
    String query, {
    GlobalSearchCategory filterCategory = GlobalSearchCategory.all,
  }) {
    final catalog = getCatalog();
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) {
      // If query is empty and a specific category is chosen, return category items immediately.
      if (filterCategory != GlobalSearchCategory.all) {
        return catalog
            .where((item) => item.categoryType == filterCategory)
            .take(30)
            .toList();
      }
      return const [];
    }

    final queryTokens = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final scoredItems = <_ScoredSearchItem>[];

    for (final item in catalog) {
      if (filterCategory != GlobalSearchCategory.all &&
          item.categoryType != filterCategory) {
        continue;
      }

      final score = _scoreItem(item, cleanQuery, queryTokens);
      if (score > 0) {
        scoredItems.add(_ScoredSearchItem(item, score));
      }
    }

    // Sort descending by relevance score
    scoredItems.sort((a, b) => b.score.compareTo(a.score));

    // Strictly return top 10 ranked matches for queries
    return scoredItems.map((e) => e.item).take(10).toList();
  }

  int _scoreItem(
    GlobalSearchItem item,
    String cleanQuery,
    List<String> queryTokens,
  ) {
    final titleLower = item.title.toLowerCase();
    final subtitleLower = item.subtitle.toLowerCase();
    final arabicText = item.arabic ?? '';
    final categoryLower = item.category.toLowerCase();

    int score = 0;

    // 1. Exact title match
    if (titleLower == cleanQuery) {
      return 1000;
    }

    // 2. Starts with query on title
    if (titleLower.startsWith(cleanQuery)) {
      score += 500;
    } else if (titleLower.contains(' $cleanQuery') ||
        titleLower.contains('-$cleanQuery') ||
        titleLower.contains('. $cleanQuery')) {
      score += 400;
    } else if (titleLower.contains(cleanQuery)) {
      score += 250;
    }

    // 3. Match on Arabic text
    if (arabicText.isNotEmpty && arabicText.contains(cleanQuery)) {
      score += 350;
    }

    // 4. Subtitle / meaning / translation match
    if (subtitleLower.startsWith(cleanQuery)) {
      score += 200;
    } else if (subtitleLower.contains(cleanQuery)) {
      score += 150;
    }

    // 5. Category match
    if (categoryLower.startsWith(cleanQuery)) {
      score += 100;
    }

    // 6. Keywords match
    for (final kw in item.keywords) {
      final kwLower = kw.toLowerCase();
      if (kwLower == cleanQuery) {
        score += 120;
        break;
      } else if (kwLower.startsWith(cleanQuery)) {
        score += 80;
        break;
      } else if (kwLower.contains(cleanQuery)) {
        score += 40;
        break;
      }
    }

    // 7. Multi-token match bonus
    if (queryTokens.length > 1) {
      bool allTokensMatch = true;
      for (final token in queryTokens) {
        final inTitle = titleLower.contains(token);
        final inSub = subtitleLower.contains(token);
        final inKw = item.keywords.any((k) => k.toLowerCase().contains(token));
        final inCat = categoryLower.contains(token);
        final inAr = arabicText.contains(token);
        if (!(inTitle || inSub || inKw || inCat || inAr)) {
          allTokensMatch = false;
          break;
        }
      }
      if (allTokensMatch) {
        score += 300;
      }
    }

    return score;
  }

  /// Popular quick shortcuts to display when search input is empty
  List<GlobalSearchItem> getQuickShortcuts() {
    final catalog = getCatalog();
    const shortcutIds = [
      'feat_prayer',
      'feat_qibla',
      'adhkar_cat_morning',
      'surah_1',
      'surah_36',
      'surah_18',
      'tasbeeh_hub',
      'asma_1',
      'feat_roza',
      'feat_sadqa',
    ];
    final map = {for (final item in catalog) item.id: item};
    return shortcutIds.map((id) => map[id]).whereType<GlobalSearchItem>().toList();
  }
}

class _ScoredSearchItem {
  final GlobalSearchItem item;
  final int score;

  const _ScoredSearchItem(this.item, this.score);
}
