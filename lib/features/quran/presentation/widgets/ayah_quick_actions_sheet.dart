import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/surah_model.dart';
import '../../services/quran_audio_service.dart';

class AyahQuickActionsSheet extends StatelessWidget {
  final AyahModel ayah;
  final int totalAyahs;
  final SurahModel currentSurah;
  final bool isDark;
  final bool isMarked;
  final bool isBookmarked;
  final dynamic arabicFont;
  final QuranAudioController quranAudio;
  final List<AyahModel> allAyahs;
  final int ayahIndex;
  final String surahName;
  final int surahNumber;
  final VoidCallback onToggleStopPoint;
  final VoidCallback onToggleBookmark;
  final VoidCallback onPlay;

  const AyahQuickActionsSheet({
    super.key,
    required this.ayah,
    required this.totalAyahs,
    required this.currentSurah,
    required this.isDark,
    required this.isMarked,
    required this.isBookmarked,
    required this.arabicFont,
    required this.quranAudio,
    required this.allAyahs,
    required this.ayahIndex,
    required this.surahName,
    required this.surahNumber,
    required this.onToggleStopPoint,
    required this.onToggleBookmark,
    required this.onPlay,
  });

  static Future<void> show({
    required BuildContext context,
    required AyahModel ayah,
    required int totalAyahs,
    required SurahModel currentSurah,
    required bool isDark,
    required bool isMarked,
    required bool isBookmarked,
    required dynamic arabicFont,
    required QuranAudioController quranAudio,
    required List<AyahModel> allAyahs,
    required int ayahIndex,
    required String surahName,
    required int surahNumber,
    required VoidCallback onToggleStopPoint,
    required VoidCallback onToggleBookmark,
    required VoidCallback onPlay,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF212121) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return AyahQuickActionsSheet(
          ayah: ayah,
          totalAyahs: totalAyahs,
          currentSurah: currentSurah,
          isDark: isDark,
          isMarked: isMarked,
          isBookmarked: isBookmarked,
          arabicFont: arabicFont,
          quranAudio: quranAudio,
          allAyahs: allAyahs,
          ayahIndex: ayahIndex,
          surahName: surahName,
          surahNumber: surahNumber,
          onToggleStopPoint: onToggleStopPoint,
          onToggleBookmark: onToggleBookmark,
          onPlay: onPlay,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.88;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. FIXED TOP: Grabber handle & Header Row with badges and Close button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A531D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Ayah ${ayah.numberInSurah}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Juz ${ayah.juz} • Rub ${ayah.rub} • Ruku ${ayah.ruku}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFA3E635)
                                    : const Color(0xFF2A531D),
                              ),
                            ),
                          ),
                          if (ayah.sajda != null && ayah.sajda != false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF166534),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '۩ Sajdah',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF86EFAC),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isBookmarked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bookmark_rounded,
                                    size: 11,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Bookmarked',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),

          // 2. SCROLLABLE MIDDLE CONTENT (Dynamically adapts to content height)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Arabic Text Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF9FAF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF383838)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: SelectableText(
                      ayah.displayArabicText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTypography.arabicBody(
                        arabicFont: arabicFont,
                        fontSize: 21,
                        height: 1.9,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),

                  // English Translation
                  if (ayah.englishTranslation.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'English Translation (Sahih International):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFA3E635)
                            : const Color(0xFF2A531D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ayah.englishTranslation,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF4B5563),
                        height: 1.45,
                      ),
                    ),
                  ],

                  // Urdu Translation
                  if (ayah.translationUrdu.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'اردو ترجمہ (فتح محمد جالندھری):',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFA3E635)
                            : const Color(0xFF2A531D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ayah.translationUrdu,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF166534),
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),

          // 3. FIXED BOTTOM ACTIONS
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF192520) : Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Play Audio & Copy Ayah
                Row(
                  children: [
                    // Play Audio Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA3E635),
                          foregroundColor: const Color(0xFF1A3512),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onPlay();
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text(
                          'Play Audio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Copy Ayah Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final textToCopy =
                              '${ayah.displayArabicText}\n\n[English]: ${ayah.englishTranslation}\n\n[Urdu]: ${ayah.translationUrdu}';
                          Clipboard.setData(ClipboardData(text: textToCopy));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ayah ${ayah.numberInSurah} copied to clipboard!',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text(
                          'Copy Ayah',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 2: Set/Remove Stop Point & Bookmark
                Row(
                  children: [
                    // Stop Point Button (🚩)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMarked
                              ? const Color(0xFFD97706)
                              : const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onToggleStopPoint();
                        },
                        icon: Icon(
                          isMarked
                              ? Icons.flag_rounded
                              : Icons.outlined_flag_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isMarked ? 'Remove Stop Point' : 'Set Stop Point',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Bookmark Button (🔖)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          backgroundColor: isBookmarked
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.transparent,
                          side: BorderSide(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onToggleBookmark();
                        },
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isBookmarked ? 'Bookmarked' : 'Bookmark',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
