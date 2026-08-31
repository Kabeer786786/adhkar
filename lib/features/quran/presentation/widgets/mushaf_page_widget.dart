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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: page.lines.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final line = entry.value;
                        final bool isLastLine = idx == page.lines.length - 1;
                        final bool isFirstLineOfJuz =
                            juzNumber != null && page.pageIndex == 0 && idx == 0;

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
                          child = _buildAyahLine(
                            line,
                            isFirstLineOfJuz: isFirstLineOfJuz,
                          );
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


  String _toArabicDigits(int number) {
    const arabicDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return number
        .toString()
        .split('')
        .map((ch) => int.tryParse(ch) != null ? arabicDigits[int.parse(ch)] : ch)
        .join('');
  }

  /// Islamic Ornamental Surah Title Frame Line (Pill Frame, Emerald Arabesque Background, Gold Cartouche & Clean Side Badges)
  Widget _buildSurahHeader(SurahModel surah) {
    final bool isMeccan = surah.revelationType.toLowerCase() == 'meccan';  
    final String cityArabic = isMeccan ? 'مكّيّة' : 'مدنيّة';
    final String ayahDigits = _toArabicDigits(surah.verseCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB18020),
            Color(0xFFCDB463),
            Color(0xFF8A5D12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF062817), const Color(0xFF02160C)]
                : [const Color(0xFF0A4625), const Color(0xFF032313)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: const Color(0xFF573A08),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Full-Spread Background Grid (Zero padding, spreads totally across the entire box)
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicArabesquePainter(isDark: isDark),
              ),
            ),

            // Foreground Content Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                // Right Badge (Place of Revelation: e.g. مكّيّة or مدنيّة)
                Container(
                  width: 64,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ 
                        Color(0xFF115C32),
                        Color(0xFF08381D),
                        Color(0xFF031E0F),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: const Color(0xFFB1801E),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFF6D6).withValues(alpha: 0.25),
                        blurRadius: 2,
                        spreadRadius: 0.5,
                      ),
                    ], 
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        cityArabic,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Noto',
                          color: Colors.white,
                          fontSize: 18.0,
                          height: 1.15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Center Cartouche: Surah Name
                Expanded(
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2B22) : const Color(0xFFFAF8F2),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isDark ? const Color(0xFFD4A036) : const Color(0xFFFAF8F2),
                        width: 1, 
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4A036).withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'سُوْرَةُ ${surah.nameArabic}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: AppTypography.arabicHeader(
                            arabicFont: arabicFont,
                            fontSize:22,
                            color: isDark ? const Color(0xFFFAE084) : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Left Badge (Ayah Count: e.g. ۲۸۶)
                Container(
                  width: 64,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF115C32),
                        Color(0xFF08381D),
                        Color(0xFF031E0F),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: const Color(0xFFB1801E),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFF6D6).withValues(alpha: 0.25),
                        blurRadius: 2,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        ayahDigits,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          color: Colors.white,
                          fontSize: 15.0,
                          height: 1.15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  Widget _buildAyahLine(MushafLine line, {bool isFirstLineOfJuz = false}) {
    final content = Row(
      mainAxisAlignment: (line.isCentered || line.words.length <= 2)
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      textDirection: TextDirection.rtl,
      children: line.words
          .map((w) => _buildWordItem(w, isFirstLineOfJuz: isFirstLineOfJuz))
          .toList(),
    );

    if (isFirstLineOfJuz) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B), // Authentic Mushaf black Juz line background
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3F3F46)
                : const Color(0xFF27272A),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: content,
    );
  }

  Widget _buildWordItem(MushafWord word, {bool isFirstLineOfJuz = false}) {
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
                  : (isFirstLineOfJuz ? const Color(0xFF3F3F46) : const Color(0xFFFEF9C3)))
              : (isSajda
                  ? (isDark || isFirstLineOfJuz
                      ? const Color(0xFF1F2937).withValues(alpha: 0.7)
                      : const Color(0xFFFEF3C7))
                  : null),
          borderRadius: BorderRadius.circular(4),
          border: isHighlighted && (isDark || isFirstLineOfJuz)
              ? Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
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
                    ? (isDark || isFirstLineOfJuz ? const Color(0xFF4ADE80) : const Color(0xFF854D0E))
                    : (isSajda
                        ? (isDark || isFirstLineOfJuz
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF166534))
                        : (isFirstLineOfJuz
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFF4F4F5)
                                : const Color(0xFF1F2937)))),
              ),
            ),

            // Stop Point Flag Badge (last word only)
            if (word.isLastWordOfAyah && isMarked)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: Color(0xFFD97706),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  size: 12,
                  color: Colors.white,
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

/// Authentic Islamic Geometric Lattice Grid Painter for Surah Header (Full-Coverage Diamond Grid Pattern)
class IslamicArabesquePainter extends CustomPainter { 
  final bool isDark;

  const IslamicArabesquePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD4A036).withValues(alpha: isDark ? 0.32 : 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final dotPaint = Paint()
      ..color = const Color(0xFFFAE084).withValues(alpha: isDark ? 0.50 : 0.65)
      ..style = PaintingStyle.fill;

    const double gridStep = 11.0;

    // 1. Full-Coverage Diagonal Criss-Cross Grid Lines (45 degrees forward & backward across entire box)
    for (double d = -size.height * 2; d < size.width + size.height * 2; d += gridStep) {
      // Forward diagonal (\)
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        gridPaint,
      );
      // Backward diagonal (/)
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        gridPaint,
      );
    }

    

    // 3. Grid Intersection Dots across the full surface
    for (double x = gridStep / 2; x < size.width; x += gridStep) {
      for (double y = gridStep / 2; y < size.height; y += gridStep) {
        canvas.drawCircle(Offset(x-2, y-1), 0.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslamicArabesquePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
 