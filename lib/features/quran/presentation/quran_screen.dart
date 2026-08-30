import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/floating_download_bar.dart';
import '../../../widgets/app_header_bar.dart';
import '../data/juz_model.dart';
import '../data/surah_model.dart';
import '../repositories/quran_repository.dart';
import 'widgets/floating_draggable_scrollbar.dart';

// Comprehensive mapping of each Surah's Start Juz and End Juz
const Map<int, List<int>> surahJuzRange = {
  1: [1, 1], // Al-Fatihah
  2: [1, 3], // Al-Baqarah (Juz 1:1 - 3:253)
  3: [3, 4], // Ali 'Imran (Juz 3:253 - 4:92)
  4: [4, 6], // An-Nisa (Juz 4:93 - 6:147)
  5: [6, 7], // Al-Ma'idah (Juz 6:148 - 7:81)
  6: [7, 8], // Al-An'am (Juz 7:82 - 8:110)
  7: [8, 9], // Al-A'raf (Juz 8:111 - 9:87)
  8: [9, 10], // Al-Anfal (Juz 9:88 - 10:40)
  9: [10, 11], // At-Tawbah (Juz 10:41 - 11:92)
  10: [11, 11], // Yunus (Juz 11)
  11: [11, 12], // Hud (Juz 11:123 - 12:5)
  12: [12, 13], // Yusuf (Juz 12:6 - 13:52)
  13: [13, 13], // Ar-Ra'd (Juz 13)
  14: [13, 13], // Ibrahim (Juz 13)
  15: [14, 14], // Al-Hijr (Juz 14)
  16: [14, 14], // An-Nahl (Juz 14)
  17: [15, 15], // Al-Isra (Juz 15)
  18: [15, 16], // Al-Kahf (Juz 15:1 - 16:74)
  19: [16, 16], // Maryam (Juz 16)
  20: [16, 16], // Ta-Ha (Juz 16)
  21: [17, 17], // Al-Anbiya (Juz 17)
  22: [17, 17], // Al-Hajj (Juz 17)
  23: [18, 18], // Al-Mu'minun (Juz 18)
  24: [18, 18], // An-Nur (Juz 18)
  25: [18, 19], // Al-Furqan (Juz 18:1 - 19:20)
  26: [19, 19], // Ash-Shu'ara (Juz 19)
  27: [19, 20], // An-Naml (Juz 19:1 - 20:55)
  28: [20, 20], // Al-Qasas (Juz 20)
  29: [20, 21], // Al-'Ankabut (Juz 20:1 - 21:45)
  30: [21, 21], // Ar-Rum (Juz 21)
  31: [21, 21], // Luqman (Juz 21)
  32: [21, 21], // As-Sajdah (Juz 21)
  33: [21, 22], // Al-Ahzab (Juz 21:1 - 22:30)
  34: [22, 22], // Saba (Juz 22)
  35: [22, 22], // Fatir (Juz 22)
  36: [22, 23], // Ya-Sin (Juz 22:1 - 23:27)
  37: [23, 23], // As-Saffat (Juz 23)
  38: [23, 23], // Sad (Juz 23)
  39: [23, 24], // Az-Zumar (Juz 23:1 - 24:31)
  40: [24, 24], // Ghafir (Juz 24)
  41: [24, 25], // Fussilat (Juz 24:1 - 25:46)
  42: [25, 25], // Ash-Shura (Juz 25)
  43: [25, 25], // Az-Zukhruf (Juz 25)
  44: [25, 25], // Ad-Dukhan (Juz 25)
  45: [25, 25], // Al-Jathiyah (Juz 25)
  46: [26, 26], // Al-Ahqaf (Juz 26)
  47: [26, 26], // Muhammad (Juz 26)
  48: [26, 26], // Al-Fath (Juz 26)
  49: [26, 26], // Al-Hujurat (Juz 26)
  50: [26, 26], // Qaf (Juz 26)
  51: [26, 27], // Adh-Dhariyat (Juz 26:1 - 27:30)
  52: [27, 27], // At-Tur (Juz 27)
  53: [27, 27], // An-Najm (Juz 27)
  54: [27, 27], // Al-Qamar (Juz 27)
  55: [27, 27], // Ar-Rahman (Juz 27)
  56: [27, 27], // Al-Waqi'ah (Juz 27)
  57: [27, 27], // Al-Hadid (Juz 27)
  // Juz 28: Surahs 58 to 66
  58: [28, 28], 59: [28, 28], 60: [28, 28], 61: [28, 28], 62: [28, 28],
  63: [28, 28], 64: [28, 28], 65: [28, 28], 66: [28, 28],
  // Juz 29: Surahs 67 to 77
  67: [29, 29], 68: [29, 29], 69: [29, 29], 70: [29, 29], 71: [29, 29],
  72: [29, 29], 73: [29, 29], 74: [29, 29], 75: [29, 29], 76: [29, 29],
  77: [29, 29],
  // Juz 30: Surahs 78 to 114
  78: [30, 30], 79: [30, 30], 80: [30, 30], 81: [30, 30], 82: [30, 30],
  83: [30, 30], 84: [30, 30], 85: [30, 30], 86: [30, 30], 87: [30, 30],
  88: [30, 30], 89: [30, 30], 90: [30, 30], 91: [30, 30], 92: [30, 30],
  93: [30, 30], 94: [30, 30], 95: [30, 30], 96: [30, 30], 97: [30, 30],
  98: [30, 30], 99: [30, 30], 100: [30, 30], 101: [30, 30], 102: [30, 30],
  103: [30, 30], 104: [30, 30], 105: [30, 30], 106: [30, 30], 107: [30, 30],
  108: [30, 30], 109: [30, 30], 110: [30, 30], 111: [30, 30], 112: [30, 30],
  113: [30, 30], 114: [30, 30],
};

class SurahJuzGroup {
  final int startJuz;
  final int endJuz;
  final List<SurahModel> surahs;

  const SurahJuzGroup({
    required this.startJuz,
    required this.endJuz,
    required this.surahs,
  });

  String get label => 'Juz $startJuz';
}

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final QuranRepository _repository = QuranRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedTab = 0; // 0: Surahs, 1: Juz (Paras)
  bool _isSearching = false;
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showDeleteStopPointConfirmation(
    BuildContext context,
    Map<String, dynamic> stopPoint,
    bool isDark, {
    VoidCallback? onDeleted,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D25) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Stop Point?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove the marked stop point for ${stopPoint['surahNameEnglish']} (Ayah ${stopPoint['markedAyahNumber']})?',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () async {
                final storage = ref.read(storageServiceProvider);
                await storage.removeQuranStopPoint(stopPoint['id']);
                if (context.mounted) {
                  Navigator.pop(context);
                  onDeleted?.call();
                  setState(() {});
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReadingHistoryModal(BuildContext context, bool isDark) {
    final storage = ref.read(storageServiceProvider);
    final allSurahs = _repository.getSurahs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeStopPoints = storage.getQuranStopPoints();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      // Grabber
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Row
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF2A531D),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reading History & Stop Points',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (activeStopPoints.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                await storage.clearAllQuranStopPoints();
                                setModalState(() {});
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (activeStopPoints.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No marked stop points yet.\nMark verses while reading to resume easily.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: activeStopPoints.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final sp = activeStopPoints[idx];
                              final isJuz = sp['juzNumber'] != null;

                              final String arabicName =
                                  (sp['surahNameArabic'] as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? sp['surahNameArabic']
                                  : (isJuz
                                        ? juzList
                                              .firstWhere(
                                                (j) =>
                                                    j.number == sp['juzNumber'],
                                                orElse: () => juzList.first,
                                              )
                                              .nameArabic
                                        : allSurahs
                                              .firstWhere(
                                                (s) =>
                                                    s.number ==
                                                    sp['surahNumber'],
                                                orElse: () => allSurahs.first,
                                              )
                                              .nameArabic);

                              final String englishTitle = isJuz
                                  ? 'Juz ${sp['juzNumber']} - ${sp['surahNameEnglish'] ?? ''}'
                                  : '${sp['surahNameEnglish'] ?? ''}';

                              return Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF23322B)
                                          : const Color(0xFFF4FAF3),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white10
                                            : const Color(
                                                0xFF2A531D,
                                              ).withValues(alpha: 0.15),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Top Row: Number Badge + English Name & Arabic Name
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF2A531D),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  isJuz
                                                      ? '${sp['juzNumber']}'
                                                      : '${sp['surahNumber']}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 28,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        englishTitle,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF1F2937,
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      arabicName,
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF86EFAC,
                                                              )
                                                            : const Color(
                                                                0xFF2A531D,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Divider(
                                          color: Colors.black12,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 8),

                                        // Bottom Row: Resume Info + Action Button
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Resume from Ayah ${sp['resumeAyahNumber']}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF2A531D),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Marked Ayah ${sp['markedAyahNumber']} of ${sp['totalAyahs'] ?? 0} Ayahs',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: isDark
                                                          ? Colors.white60
                                                          : Colors
                                                                .grey
                                                                .shade600,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),

                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF2A531D,
                                                ),
                                                foregroundColor: Colors.white,
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                if (isJuz) {
                                                  context.push(
                                                    '/quran/surah?juz=${sp['juzNumber']}&name=${Uri.encodeComponent("Juz ${sp['juzNumber']} - ${sp['surahNameEnglish']}")}&startAyah=${sp['resumeAyahNumber']}',
                                                  );
                                                } else {
                                                  context.push(
                                                    '/quran/surah?num=${sp['surahNumber']}&name=${Uri.encodeComponent(sp['surahNameEnglish'])}&startAyah=${sp['resumeAyahNumber']}',
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 18,
                                                color: Color(0xFFd1ffbe),
                                              ),
                                              label: const Text(
                                                'Resume',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Absolute Top-Right Close / Delete Button
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          _showDeleteStopPointConfirmation(
                                            context,
                                            sp,
                                            isDark,
                                            onDeleted: () {
                                              setModalState(() {});
                                              setState(() {});
                                            },
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showBookmarksModal(BuildContext context, bool isDark) {
    final storage = ref.read(storageServiceProvider);
    final arabicFont = ref.read(arabicFontProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bookmarks = storage.getQuranAyahBookmarks();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      // Grabber
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Row
                      Row(
                        children: [
                          const Icon(
                            Icons.bookmark_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Saved Verse Bookmarks',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (bookmarks.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${bookmarks.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (bookmarks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                await storage.clearAllQuranAyahBookmarks();
                                setModalState(() {});
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (bookmarks.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No saved bookmarks yet.\nBookmark verses while reading to easily revisit them here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: bookmarks.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final bm = bookmarks[idx];
                              final int surahNum = bm['surahNumber'] ?? 1;
                              final String surahEnglish =
                                  bm['surahNameEnglish'] ?? '';
                              final String surahArabic =
                                  bm['surahNameArabic'] ?? '';
                              final int ayahNum = bm['ayahNumber'] ?? 1;
                              final int totalAyahs = bm['totalAyahs'] ?? 0;
                              final int juzNum = bm['juzNumber'] ?? 1;
                              final String arabicText = bm['arabicText'] ?? '';
                              final String transText =
                                  bm['translationEnglish'] ?? '';

                              return InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  // Always open in Surah mode at that specific Ayah!
                                  context.push(
                                    '/quran/surah?num=$surahNum&name=${Uri.encodeComponent(surahEnglish)}&startAyah=$ayahNum',
                                  );
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF23322B)
                                        : const Color(0xFFF4FAF3),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(
                                              0xFF2A531D,
                                            ).withValues(alpha: 0.15),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Badge + Surah & Ayah details + Delete button
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$ayahNum',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        '$surahNum. $surahEnglish',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF1F2937,
                                                                ),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '• Juz $juzNum',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDark
                                                            ? Colors.white60
                                                            : Colors
                                                                  .grey
                                                                  .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  'Ayah $ayahNum of $totalAyahs',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF10B981),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            surahArabic,
                                            textDirection: TextDirection.rtl,
                                            style: AppTypography.arabicHeader(
                                              arabicFont: arabicFont,
                                              fontSize: 18,
                                              color: const Color(0xFF2A531D),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Color(0xFFEF4444),
                                            ),
                                            onPressed: () async {
                                              await storage
                                                  .removeQuranAyahBookmark(
                                                    bm['id'],
                                                  );
                                              setModalState(() {});
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      if (arabicText.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          arabicText,
                                          textDirection: TextDirection.rtl,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.arabicBody(
                                            fontSize: 17,
                                            height: 1.6,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : const Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                      if (transText.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          transText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF4B5563),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final arabicFont = ref.watch(arabicFontProvider);
    final allSurahs = _repository.getSurahs();
    final storage = ref.watch(storageServiceProvider);

    final lastSurahNum = storage.getLastReadSurah() ?? 1;
    final lastJuzNum = storage.getLastReadJuz() ?? 1;
    final lastSurah = allSurahs.firstWhere(
      (s) => s.number == lastSurahNum,
      orElse: () => allSurahs.first,
    );
    final lastJuz = juzList.firstWhere(
      (j) => j.number == lastJuzNum,
      orElse: () => juzList.first,
    );

    final favoriteSurahs = storage.getFavoriteSurahs();
    final favoriteJuzList = storage.getFavoriteJuz();

    final query = _searchController.text.trim().toLowerCase();
    final filteredSurahs = allSurahs.where((s) {
      if (_showOnlyFavorites && !favoriteSurahs.contains(s.number)) {
        return false;
      }
      return query.isEmpty ||
          s.nameEnglish.toLowerCase().contains(query) ||
          s.nameTranslation.toLowerCase().contains(query) ||
          s.number.toString().contains(query);
    }).toList();

    final filteredJuz = juzList.where((j) {
      if (_showOnlyFavorites && !favoriteJuzList.contains(j.number)) {
        return false;
      }
      return query.isEmpty ||
          j.nameEnglish.toLowerCase().contains(query) ||
          j.nameArabic.contains(query) ||
          j.number.toString().contains(query);
    }).toList();

    final surahGroups = _groupSurahsByJuz(filteredSurahs);
    final activeItems = _selectedTab == 0 ? surahGroups : filteredJuz;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF17241E)
                : const Color(0xFFFFFFFF),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AppHeaderBar(
                title: 'QURAN',
                showBackButton: false,
                showDrawerButton: true,
                centerTitle: false,
                titleSpacing: 0,
                systemOverlayStyle: isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                backgroundColor: isDark
                    ? const Color(0xFF192520)
                    : Colors.white,
                iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
                titleWidget: Text(
                  'AL QURAN',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2A531D),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.8,
                  ),
                ),
                actions: [
                  // 1. Search Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(4),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) _searchController.clear();
                      });
                    },
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                      color: isDark ? Colors.white : const Color(0xFF2A531D),
                    ),
                    tooltip: 'Search Quran',
                  ),
                  // 2. Saved Bookmarks Button (Right of search button)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => _showBookmarksModal(context, isDark),
                    icon: Icon(
                      Icons.bookmark_outline_rounded,
                      color: isDark ? Colors.white : const Color(0xFF2A531D),
                    ),
                    tooltip: 'Saved Verse Bookmarks',
                  ),
                  // 3. Filter Favorites Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(4),
                    onPressed: () {
                      setState(() {
                        _showOnlyFavorites = !_showOnlyFavorites;
                      });
                    },
                    icon: Icon(
                      _showOnlyFavorites
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _showOnlyFavorites
                          ? const Color(0xFFEF4444)
                          : (isDark ? Colors.white : const Color(0xFF2A531D)),
                      size: 22,
                    ),
                    tooltip: _showOnlyFavorites
                        ? 'Show All'
                        : 'Filter Favorites Only',
                  ),
                  // 4. Reading History & Stop Points Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => _showReadingHistoryModal(context, isDark),
                    icon: Icon(
                      Icons.history_rounded,
                      color: isDark ? Colors.white : const Color(0xFF2A531D),
                    ),
                    tooltip: 'Reading History & Stop Points',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            body: Column(
              children: [
                if (_isSearching)
                  Container(
                    color: isDark ? const Color(0xFF192520) : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: _selectedTab == 0
                            ? 'Search Surah by name or number...'
                            : 'Search Juz by name or number...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF2A531D),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF23322B)
                            : const Color(0xFFF9F9F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                // 1. Fixed Recent Read Card (Always visible at top)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: _buildRecentReadSection(
                    isDark: isDark,
                    selectedTab: _selectedTab,
                    lastSurah: lastSurah,
                    lastJuz: lastJuz,
                    arabicFont: arabicFont,
                  ),
                ),

                // 2. Fixed Tabs & Header Row (Always sticky below recent card)
                _buildFixedTabsHeader(
                  isDark: isDark,
                  selectedTab: _selectedTab,
                  showOnlyFavorites: _showOnlyFavorites,
                  surahCount: _showOnlyFavorites
                      ? filteredSurahs.length
                      : allSurahs.length,
                  juzCount: _showOnlyFavorites ? filteredJuz.length : 30,
                  onTabChanged: (index) => setState(() => _selectedTab = index),
                ), // 3. Scrollable List ONLY below the fixed header with Absolute Positioned 4x Expandable Floating Scrollbar
                Expanded(
                  child: Stack(
                    children: [
                      if (_selectedTab == 0 && filteredSurahs.isEmpty)
                        _buildEmptyFavoritesPlaceholder(
                          isDark,
                          'No favorite surahs saved yet',
                        )
                      else if (_selectedTab == 1 && filteredJuz.isEmpty)
                        _buildEmptyFavoritesPlaceholder(
                          isDark,
                          'No favorite juz saved yet',
                        )
                      else
                        ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(top: 0, bottom: 100),
                          itemCount: activeItems.length,
                          itemBuilder: (context, index) {
                            if (_selectedTab == 0) {
                              final group = surahGroups[index];
                              return _buildSurahGroupCard(
                                group: group,
                                isDark: isDark,
                                arabicFont: arabicFont,
                                lastSurahNum: lastSurahNum,
                                isFirstGroup: index == 0,
                                isLastGroup: index == surahGroups.length - 1,
                              );
                            } else {
                              final juz = filteredJuz[index];
                              final isLastRead = juz.number == lastJuzNum;
                              return _buildJuzListItem(
                                juz: juz,
                                isDark: isDark,
                                arabicFont: arabicFont,
                                isLastRead: isLastRead,
                                isLastItem: index == filteredJuz.length - 1,
                              ); 
                            }
                          },
                        ),

                      // Absolute Positioned Draggable Floating Scrollbar Tab (Right docked, rounded left)
                      if (activeItems.length > 2)
                        Positioned(
                          right: 0,
                          top: 4,
                          bottom: 16,
                          child: FloatingDraggableScrollbar(
                            scrollController: _scrollController,
                            itemCount: activeItems.length,
                            isDark: isDark,
                            items: activeItems,
                            selectedTab: _selectedTab,
                            arabicFont: arabicFont,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: FloatingDownloadBar(),
          ),
        ],
      ),
    );
  }

  /// 1. Persistent Recent Read Card (Shows last opened Surah / Juz)
  Widget _buildRecentReadSection({
    required bool isDark,
    required int selectedTab,
    required dynamic lastSurah,
    required dynamic lastJuz,
    required dynamic arabicFont,
  }) {
    final storage = ref.read(storageServiceProvider);
    final sp = selectedTab == 1
        ? storage.getStopPointForJuz(lastJuz.number)
        : storage.getStopPointForSurah(lastSurah.number);
    final int? resumeAyahNum = sp != null
        ? (sp['resumeAyahNumber'] as int?)
        : null;

    final int itemNumber = selectedTab == 1 ? lastJuz.number : lastSurah.number;
    final String englishTitle = selectedTab == 1
        ? lastJuz.nameEnglish
        : lastSurah.nameEnglish;
    final String arabicTitle = selectedTab == 1
        ? lastJuz.nameArabic
        : lastSurah.nameArabic;
    final String translationSubtitle = selectedTab == 1
        ? lastJuz.surahRange
        : lastSurah.nameTranslation;

    return GestureDetector(
      onTap: () {
        if (selectedTab == 1) {
          context.push(
            '/quran/surah?juz=${lastJuz.number}&name=${Uri.encodeComponent("Juz ${lastJuz.number} - ${lastJuz.nameEnglish}")}${resumeAyahNum != null ? '&startAyah=$resumeAyahNum' : ''}',
          );
        } else {
          context.push(
            '/quran/surah?num=${lastSurah.number}&name=${Uri.encodeComponent(lastSurah.nameEnglish)}${resumeAyahNum != null ? '&startAyah=$resumeAyahNum' : ''}',
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E3A15), const Color(0xFF0F1A0E)]
                : [const Color(0xFF669f1d), const Color(0xFF2A531D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFd1ffbe).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Tag
            Row(
              children: [
                const Icon(
                  FlutterIslamicIcons.quran2,
                  size: 14,
                  color: Color(0xFFd1ffbe),
                ),
                const SizedBox(width: 6),
                Text(
                  selectedTab == 1 ? 'RECENT READ JUZ' : 'RECENT READ SURAH',
                  style: const TextStyle(
                    color: Color(0xFFd1ffbe),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 1: Left column & Right (Arabic Name)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Item Transliteration + Translation Meaning
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedTab == 1
                            ? 'Juz $itemNumber. $englishTitle'
                            : '$itemNumber. $englishTitle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        translationSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right Side: Arabic Name Only
                Text(
                  arabicTitle,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicHeader(
                    arabicFont: arabicFont,
                    fontSize: 28,
                    color: const Color(0xFFd1ffbe),
                    height: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),

            // Row 2: Resume details / Ayah info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sp != null
                      ? 'Resume from Ayah $resumeAyahNum'
                      : (selectedTab == 1
                            ? 'Juz No. $itemNumber'
                            : 'Surah No. $itemNumber'),
                  style: const TextStyle(
                    color: Color(0xFFd1ffbe),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedTab == 1
                      ? '30 Total Juz (Paras)'
                      : '${lastSurah.verseCount} Total Ayahs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Fixed Header & Surahs / Juz Segmented Pill Tabs
  Widget _buildFixedTabsHeader({
    required bool isDark,
    required int selectedTab,
    required bool showOnlyFavorites,
    required int surahCount,
    required int juzCount,
    required ValueChanged<int> onTabChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17241E) : const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white10
                : const Color(0xFF2A531D).withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Al Quran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              if (showOnlyFavorites) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Favorites',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF23322B) : const Color(0xFFF4FAF3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPillTab(
                  label: 'Surahs ($surahCount)',
                  index: 0,
                  isSelected: selectedTab == 0,
                  isDark: isDark,
                  onTap: () => onTabChanged(0),
                ),
                _buildPillTab(
                  label: 'Juz ($juzCount)',
                  index: 1,
                  isSelected: selectedTab == 1,
                  isDark: isDark,
                  onTap: () => onTabChanged(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String label,
    required int index,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A531D) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavoritesPlaceholder(bool isDark, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic grouping of Surahs based on contiguous starting & ending Juz
  List<SurahJuzGroup> _groupSurahsByJuz(List<SurahModel> surahs) {
    if (surahs.isEmpty) return [];

    final List<SurahJuzGroup> groups = [];
    int i = 0;
    while (i < surahs.length) {
      final currentSurah = surahs[i];
      final currentRange = surahJuzRange[currentSurah.number] ?? [1, 1];
      final startJuz = currentRange[0];
      int maxEndJuz = currentRange[1];

      final groupSurahs = <SurahModel>[currentSurah];
      int next = i + 1;

      while (next < surahs.length) {
        final nextSurah = surahs[next];
        final nextRange =
            surahJuzRange[nextSurah.number] ?? [startJuz, startJuz];
        if (nextRange[0] == startJuz) {
          groupSurahs.add(nextSurah);
          if (nextRange[1] > maxEndJuz) {
            maxEndJuz = nextRange[1];
          }
          next++;
        } else {
          break;
        }
      }

      groups.add(
        SurahJuzGroup(
          startJuz: startJuz,
          endJuz: maxEndJuz,
          surahs: groupSurahs,
        ),
      );

      i = next;
    }

    return groups;
  }

  /// Grouped Surah view with Left Juz Bar touching the edge and 6px _SectionDivider between groups
  Widget _buildSurahGroupCard({
    required SurahJuzGroup group,
    required bool isDark,
    required dynamic arabicFont,
    required int? lastSurahNum,
    bool isFirstGroup = false,
    required bool isLastGroup,
  }) {
    final sideBg = isDark ? const Color(0xFF16251C) : const Color(0xFFEFF3F8);
    final labelColor = isDark
        ? const Color(0xFFA3E635)
        : const Color(0xFF2A531D);
    // final borderRightColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirstGroup) const _SectionDivider(),
        IntrinsicHeight( 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Vertical Juz Tag touching the screen's left edge flush
              Container(
                width: 28,
                decoration: BoxDecoration(color: sideBg),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      group.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Right Column: Surahs in this Group without inner borders or dividers
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final surah in group.surahs)
                      _buildSurahListItem(
                        surah: surah,
                        isDark: isDark,
                        arabicFont: arabicFont,
                        isLastRead: surah.number == lastSurahNum,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 6px light/dark gray divider box between groups
        const _SectionDivider(),
      ],
    );
  }

  Widget _buildSurahListItem({
    required SurahModel surah, 
    required bool isDark,
    required dynamic arabicFont,
    required bool isLastRead,
  }) { 
    final storage = ref.read(storageServiceProvider);
    final sp = storage.getStopPointForSurah(surah.number);
    final int? resumeAyah = sp != null
        ? (sp['resumeAyahNumber'] as int?)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          '/quran/surah?num=${surah.number}&name=${Uri.encodeComponent(surah.nameEnglish)}${resumeAyah != null ? '&startAyah=$resumeAyah' : ''}',
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 24,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            children: [
              // Number Badge at Start
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isLastRead
                      ? const Color(0xFF2A531D)
                      : (isDark
                            ? const Color(0xFF23322B)
                            : const Color(0xFFF4FAF3)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLastRead
                        ? const Color(0xFF2A531D)
                        : (isDark
                              ? Colors.white12
                              : const Color(
                                  0xFF2A531D,
                                ).withValues(alpha: 0.15)),
                  ),
                ),
                child: Center(
                  child: Text(
                    surah.number < 10 ? '0${surah.number}' : '${surah.number}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLastRead
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF2A531D)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Transliteration & Details on Left
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            surah.nameEnglish,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (sp != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD97706,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(
                                  0xFFD97706,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'Ayah $resumeAyah',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          surah.revelationType.toLowerCase() == 'meccan'
                              ? FlutterIslamicIcons.solidKaaba
                              : FlutterIslamicIcons.solidMosque,
                          size: 12,
                          color: const Color(0xFF2A531D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${surah.revelationType.toTitleCase()} • ${surah.verseCount} Ayahs',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arabic Name on Right Side
              Text(
                surah.nameArabic,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabicHeader(
                  arabicFont: arabicFont,
                  fontSize: 22,
                  color: isDark
                      ? const Color(0xFFA3E635)
                      : const Color(0xFF2A531D),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJuzListItem({
    required JuzModel juz,
    required bool isDark,
    required dynamic arabicFont,
    required bool isLastRead,
    required bool isLastItem,
  }) {
    final storage = ref.read(storageServiceProvider);
    final sp = storage.getStopPointForJuz(juz.number);
    final int? resumeAyah = sp != null
        ? (sp['resumeAyahNumber'] as int?)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(
              '/quran/surah?juz=${juz.number}&name=${Uri.encodeComponent("Juz ${juz.number} - ${juz.nameEnglish}")}${resumeAyah != null ? '&startAyah=$resumeAyah' : ''}',
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 22,
                right: 28,
                top: 10,
                bottom: 10,
              ),
              child: Row(
                children: [
                  // Number Badge at Start
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isLastRead
                          ? const Color(0xFF2A531D)
                          : (isDark
                                ? const Color(0xFF23322B)
                                : const Color(0xFFF4FAF3)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLastRead
                            ? const Color(0xFF2A531D)
                            : (isDark
                                  ? Colors.white12
                                  : const Color(
                                      0xFF2A531D,
                                    ).withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        juz.number < 10 ? '0${juz.number}' : '${juz.number}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isLastRead
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF2A531D)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Transliteration & Details on Left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                juz.nameEnglish,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            if (sp != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD97706,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFD97706,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  'Ayah $resumeAyah',
                                  style: const TextStyle(
                                    color: Color(0xFFD97706),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          juz.surahRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Arabic Name on Right Side
                  Text(
                    juz.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: AppTypography.arabicHeader(
                      arabicFont: arabicFont,
                      fontSize: 22,
                      color: isDark
                          ? const Color(0xFFA3E635)
                          : const Color(0xFF2A531D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 6px light/dark gray divider box between sections/groups
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 6,
      width: double.infinity,
      color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEFF3F8),
    );
  }
}
