import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/typography/arabic_font.dart';
import '../../data/surah_model.dart';
import 'mushaf_pagination_engine.dart';

/// Renders a single physically paginated Mushaf page with strictly 13 lines,
/// vertically centered canvas, reduced line height, and clean verse endings without circle markers.
class MushafPageWidget extends StatelessWidget {
  final MushafPage page;
  final SurahModel currentSurah;
  final AyahModel? playingAyah;
  final bool isDark;
  final dynamic storage;
  final double arabicFontSize;
  final ArabicFont? arabicFont;
  final int? juzNumber;
  final int? highlightResumeAyahNumber;
  final int? selectedAyahIndex;
  final List<AyahModel> allAyahs;
  final List<SurahModel> allSurahs;
  final void Function(AyahModel ayah, int masterIndex) onAyahTap;

  const MushafPageWidget({
    super.key,
    required this.page,
    required this.currentSurah,
    required this.playingAyah,
    required this.isDark,
    required this.storage,
    required this.arabicFontSize,
    required this.arabicFont,
    required this.juzNumber,
    required this.highlightResumeAyahNumber,
    this.selectedAyahIndex,
    required this.allAyahs,
    required this.allSurahs,
    required this.onAyahTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212121) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF303030)
              : const Color(0xFF2A531D).withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: page.lines.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final line = entry.value;
                        final bool isLastLine = idx == page.lines.length - 1;

                        Widget child;
                        if (line.isSurahHeader) {
                          final surah = allSurahs.firstWhere(
                            (s) => s.number == line.surahNumber,
                            orElse: () => currentSurah,
                          );
                          child = _buildSurahHeader(surah);
                        } else if (line.isBismillah) {
                          child = _buildBismillah();
                        } else {
                          child = _buildAyahLine(line);
                        }

                        // Moderate spacing between lines ensuring equal top and bottom page padding
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLastLine ? 0 : 5.5),
                          child: child,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word; 
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Ornate Surah Title Frame Line
  Widget _buildSurahHeader(SurahModel surah) {
    final formattedRevelation = _toTitleCase(surah.revelationType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFF2A531D),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${surah.verseCount} Ayahs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF2A531D),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'سُوْرَةُ ${surah.nameArabic}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.arabicHeader(
                fontSize: arabicFontSize,
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1A3512),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formattedRevelation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF2A531D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Centered Bismillah Line
  Widget _buildBismillah() {
    return Text(
      "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ",
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: AppTypography.arabicBody(
        arabicFont: arabicFont,
        fontSize: 20,
        height: 1.8,
        color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF2A531D),
      ),
    );
  }

  /// Full-width Justified Line with Edge-to-Edge Word Distribution
  Widget _buildAyahLine(MushafLine line) {
    if (line.isCentered || line.words.length <= 2) {
      return SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: line.words.map((w) => _buildWordItem(w)).toList(),
        ), 
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: line.words.map((w) => _buildWordItem(w)).toList(),
      ),
    );
  }

  Widget _buildWordItem(MushafWord word) {
    final ayah = word.ayah;
    final isPlayingThis = playingAyah?.number == ayah.number;
    final bool isSajda = ayah.sajda != null && ayah.sajda != false;
    final fullIndex = word.masterAyahIndex;
    final surahNum = ayah.surahNumber ?? currentSurah.number;
    final bool isMarked = storage.isAyahMarkedAsStopPoint(
      surahNum,
      ayah.numberInSurah,
      juzNumber: juzNumber,
    );
    final bool isSelected = selectedAyahIndex != null && selectedAyahIndex == fullIndex;
    final bool isResumeHighlight = highlightResumeAyahNumber != null &&
        highlightResumeAyahNumber == ayah.numberInSurah &&
        (juzNumber == null ||
            (storage.getStopPointForJuz(
                  juzNumber!,
                )?['surahNumber'] ==
                surahNum));

    final bool isHighlighted = isPlayingThis || isSelected || isResumeHighlight;

    return GestureDetector(
      onTap: () => onAyahTap(ayah, word.masterAyahIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
        decoration: BoxDecoration(
          color: isHighlighted
              ? (isDark
                  ? const Color(0xFF27272A)
                  : const Color(0xFFFEF9C3))
              : (isSajda
                  ? (isDark
                      ? const Color(0xFF1F2937).withValues(alpha: 0.5)
                      : const Color(0xFFFEF3C7))
                  : null),
          borderRadius: BorderRadius.circular(4),
          border: isHighlighted && isDark
              ? Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            // Arabic Word Text
            Text(
              word.text,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicBody(
                arabicFont: arabicFont,
                fontSize: arabicFontSize,
                height: 1.8,
                color: isHighlighted
                    ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF854D0E))
                    : (isSajda
                        ? (isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF166534))
                        : (isDark
                            ? const Color(0xFFF4F4F5)
                            : const Color(0xFF1F2937))),
              ),
            ),

            // Stop Point Flag Badge (last word only)
            if (word.isLastWordOfAyah && isMarked)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 3.5,
                  vertical: 0.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 8,
                      color: Colors.white,
                    ),
                    SizedBox(width: 1),
                    Text(
                      'Stop',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            // Sajda Badge (last word only)
            if (word.isLastWordOfAyah && isSajda)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 3.5,
                  vertical: 0.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '۩ سَجْدَة',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 8.0,
                    color: Color(0xFF86EFAC),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Effortless, responsive Mushaf page scroll physics with sensitive fling detection
/// and a soft 18% drag threshold so gentle soft swipes flip the page smoothly.
class SmoothMushafPageScrollPhysics extends PageScrollPhysics {
  const SmoothMushafPageScrollPhysics({super.parent});

  @override
  SmoothMushafPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothMushafPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override 
  double get minFlingVelocity => 35.0;

  @override
  double get minFlingDistance => 5.0;

  @override
  double get dragStartDistanceMotionThreshold => 2.0;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = toleranceFor(position);
    final double page = position.pixels / position.viewportDimension;
    final double currentPage = page.floorToDouble();
    final double pageProgress = page - currentPage;

    double targetPage = currentPage;

    if (velocity > 35.0) {
      targetPage = currentPage + 1.0;
    } else if (velocity < -35.0) {
      targetPage = currentPage;
    } else {
      // Soft gentle swipe: if user dragged even 18%, complete the page flip
      if (pageProgress > 0.18) {
        targetPage = currentPage + 1.0;
      } else {
        targetPage = currentPage;
      }
    }

    final double targetPixels = (targetPage * position.viewportDimension).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (targetPixels != position.pixels) {
      return ScrollSpringSimulation(
        const SpringDescription(
          mass: 80,
          stiffness: 100,
          damping: 1.2,
        ),
        position.pixels,
        targetPixels,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }
}
