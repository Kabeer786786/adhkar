import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/surah_model.dart';

class AyahVerseCard extends StatelessWidget {
  final AyahModel ayah;
  final int index;
  final List<AyahModel> allAyahs;
  final SurahModel currentSurah;
  final bool isDark;
  final dynamic arabicFont;
  final double arabicFontSize;
  final String translationLanguage;
  final bool showTranslation;
  final bool showTransliteration;
  final bool isSelected;
  final bool isPlaying;
  final bool isMarkedStopPoint;
  final bool isResumeHighlight;
  final bool isBookmarked;
  final bool isJuzMode;
  final SurahModel ayahSurah;
  final VoidCallback onPlayTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onStopPointTap;
  final VoidCallback onTafsirTap;
  final VoidCallback onQuickActionsTap;
  final Key? cardKey;

  const AyahVerseCard({
    super.key,
    required this.ayah,
    required this.index,
    required this.allAyahs,
    required this.currentSurah,
    required this.isDark,
    required this.arabicFont,
    required this.arabicFontSize,
    required this.translationLanguage,
    required this.showTranslation,
    required this.showTransliteration,
    required this.isSelected,
    required this.isPlaying,
    required this.isMarkedStopPoint,
    required this.isResumeHighlight,
    required this.isBookmarked,
    required this.isJuzMode,
    required this.ayahSurah,
    required this.onPlayTap,
    required this.onBookmarkTap,
    required this.onStopPointTap,
    required this.onTafsirTap,
    required this.onQuickActionsTap,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSajda = ayah.sajda != null && ayah.sajda != false;

    // Show Hizb badge ONLY on subsequent boundary verses where Hizb changes
    final bool isHizbChange =
        ayah.hizb > 0 && index > 0 && ayah.hizb != allAyahs[index - 1].hizb;

    // Show Rub badge ONLY on subsequent boundary verses where Rub changes
    final bool isRubChange =
        ayah.rub > 0 && index > 0 && ayah.rub != allAyahs[index - 1].rub;

    final cardBgColor = isSelected
        ? (isDark ? const Color(0xFF27272A) : const Color(0xFFE2F6DB))
        : (isResumeHighlight
            ? (isDark ? const Color(0xFF27272A) : const Color(0xFFFEF9C3))
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white));

    final borderColor = isResumeHighlight
        ? const Color(0xFFF59E0B)
        : (isMarkedStopPoint
            ? const Color(0xFFD97706)
            : (isSelected
                ? (isDark
                    ? const Color(0xFFA3E635)
                    : const Color(0xFF1E3A1A).withValues(alpha: 0.45))
                : (isDark
                    ? const Color(0xFF2E2E32)
                    : const Color(0xFF2A531D).withValues(alpha: 0.12))));

    final int resumeAyahNum = ayah.numberInSurah < allAyahs.length
        ? ayah.numberInSurah + 1
        : ayah.numberInSurah;

    return Container(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSajda ? const Color(0xFF22C55E) : borderColor,
            width: isResumeHighlight || isMarkedStopPoint
                ? 1.5
                : (isSelected ? 1.0 : 0.8),
          ),
          boxShadow: isSelected || isMarkedStopPoint || isResumeHighlight
              ? [
                  BoxShadow(
                    color: isResumeHighlight || isMarkedStopPoint
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                        : const Color(0xFF2A531D)
                            .withValues(alpha: isDark ? 0.35 : 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Number Circle, Badges Wrap (Left) and Compact Action Buttons (Right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ayah Number Circle Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isResumeHighlight || isMarkedStopPoint
                        ? const Color(0xFFD97706)
                        : (isSelected
                            ? const Color(0xFF2A531D)
                            : (isDark
                                ? const Color(0xFF1E3A2B)
                                : const Color(0xFFE8F5E9))),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isResumeHighlight || isMarkedStopPoint
                          ? const Color(0xFFF59E0B)
                          : (isSelected
                              ? const Color(0xFFA3E635)
                              : const Color(0xFF2A531D).withValues(alpha: 0.2)),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: (isSelected ||
                                isResumeHighlight ||
                                isMarkedStopPoint)
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFA3E635)
                                : const Color(0xFF2A531D)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Responsive Metadata Badges (Wraps gracefully without overflowing)
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // In Juz Screen: Surah Name & Number Pill
                      if (isJuzMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A2B)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF2A531D).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            '${ayahSurah.number}. ${ayahSurah.nameEnglish}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D),
                            ),
                          ),
                        ),

                      // Hizb badge
                      if (isHizbChange)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A2B)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '۞ Hizb',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Rub badge
                      if (isRubChange)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A2B)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '۞ Rub',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Bookmarked badge (Uses Bookmark Icon 🔖)
                      if (isBookmarked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
                              SizedBox(width: 2),
                              Text(
                                'Bookmarked',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Resume highlight badge / Stop Point badge (Uses Flag Icon 🚩)
                      if (isResumeHighlight)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Resume Here',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isMarkedStopPoint)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.flag_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Resume from $resumeAyahNum',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Sajda badge
                      if (isSajda)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF166534),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '۩ Sajdah',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF86EFAC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Audio playing indicator badge
                      if (isSelected && isPlaying)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A531D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.graphic_eq_rounded,
                                size: 11,
                                color: Color(0xFFA3E635),
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Playing',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Top Right Compact Action Buttons (Bookmark, Flag, Play, 3-dots)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bookmark Action Button (🔖)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(3),
                      onPressed: onBookmarkTap,
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: isBookmarked
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white60 : const Color(0xFF2A531D)),
                        size: 20,
                      ),
                      tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Ayah',
                    ),

                    // Mark as Stop Point Action Button (🚩)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(3),
                      onPressed: onStopPointTap,
                      icon: Icon(
                        isMarkedStopPoint
                            ? Icons.flag_rounded
                            : Icons.outlined_flag_rounded,
                        color: isMarkedStopPoint
                            ? const Color(0xFFF59E0B)
                            : (isDark ? Colors.white60 : const Color(0xFF2A531D)),
                        size: 20,
                      ),
                      tooltip: isMarkedStopPoint
                          ? 'Stop Point Marked'
                          : 'Mark as Stop Point',
                    ),

                    // Play Ayah Audio Button
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: const EdgeInsets.all(2),
                      onPressed: onPlayTap,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : (isSelected
                                ? Icons.play_circle_fill_rounded
                                : Icons.play_circle_outline_rounded),
                        color: isDark
                            ? const Color(0xFFA3E635)
                            : (isSelected
                                ? const Color(0xFF15803D)
                                : const Color(0xFF2A531D)),
                        size: 26,
                      ),
                      tooltip: isPlaying ? 'Pause Audio' : 'Play Ayah Audio',
                    ),

                    // 3-dots Vertical Menu Button beside Play Button (opens Quick Actions / Tafsir / Copy modal)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                      padding: const EdgeInsets.all(2),
                      onPressed: onQuickActionsTap,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white60 : const Color(0xFF2A531D),
                        size: 20,
                      ),
                      tooltip: 'More Actions & Tafsir',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Arabic Text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SelectableText(
                ayah.displayArabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTypography.arabicBody(
                  arabicFont: arabicFont,
                  fontSize: arabicFontSize,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  height: 1.8,
                ),
              ),
            ),

            // Transliteration
            if (showTransliteration && ayah.transliteration.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ayah.transliteration,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? const Color(0xFF86EFAC).withValues(alpha: 0.8)
                      : const Color(0xFF166534),
                  height: 1.4,
                ),
              ),
            ],

            // Translations
            if (showTranslation) ...[
              if ((translationLanguage == 'en' ||
                      translationLanguage == 'both') &&
                  ayah.englishTranslation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ayah.englishTranslation,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ],
              if ((translationLanguage == 'ur' ||
                      translationLanguage == 'both') &&
                  ayah.translationUrdu.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ayah.translationUrdu,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF166534),
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
