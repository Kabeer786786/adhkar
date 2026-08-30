import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/typography/arabic_font.dart';
import '../../data/surah_model.dart';

/// Represents an individual Arabic word token within an Ayah.
class MushafWord {
  final String text;
  final AyahModel ayah;
  final int masterAyahIndex;
  final bool isFirstWordOfAyah;
  final bool isLastWordOfAyah;

  const MushafWord({
    required this.text,
    required this.ayah,
    required this.masterAyahIndex,
    required this.isFirstWordOfAyah,
    required this.isLastWordOfAyah,
  });
}

/// The type of line rendered on a Mushaf page.
enum MushafLineType { surahHeader, bismillah, ayahText }

/// Represents a single horizontal line of the authentic Mushaf page.
class MushafLine {
  final MushafLineType type;
  final int? surahNumber;
  final List<MushafWord> words;
  final bool isCentered;

  const MushafLine({
    required this.type,
    this.surahNumber,
    this.words = const [],
    this.isCentered = false,
  });

  bool get isSurahHeader => type == MushafLineType.surahHeader;
  bool get isBismillah => type == MushafLineType.bismillah;
  bool get isAyahText => type == MushafLineType.ayahText;
}

/// Represents a single, physically measured Mushaf page composed of strictly 13 lines.
class MushafPage {
  final int pageIndex;
  final List<MushafLine> lines;

  const MushafPage({
    required this.pageIndex,
    required this.lines,
  });

  bool containsMasterAyahIndex(int index) {
    return lines.any(
      (line) => line.words.any((w) => w.masterAyahIndex == index),
    );
  }

  bool containsAyah(int ayahGlobalNumber) {
    return lines.any(
      (line) => line.words.any((w) => w.ayah.number == ayahGlobalNumber),
    );
  }

  bool containsAyahInSurah(int surahNum, int ayahNumInSurah) {
    return lines.any(
      (line) => line.words.any(
        (w) =>
            (w.ayah.surahNumber == surahNum || w.ayah.surahNumber == null) &&
            w.ayah.numberInSurah == ayahNumInSurah,
      ),
    );
  }
}

/// High-performance text layout pagination engine for the Quran Mushaf.
class MushafPaginationEngine {
  static const int strictLinesPerPage = 13;
  static final Map<String, List<MushafPage>> _cache = {};

  /// Clears the pagination cache.
  static void clearCache() {
    _cache.clear();
  }

  static String _buildCacheKey({
    required int surahOrJuzId,
    required bool isJuz,
    required int totalAyahs,
    required double availableWidth,
    required double fontSize,
    required String fontFamily,
  }) {
    return '${isJuz ? 'juz' : 'surah'}_${surahOrJuzId}_${totalAyahs}_${availableWidth.toInt()}_${fontSize.toStringAsFixed(1)}_${fontFamily}_v3';
  }

  /// Paginates [ayahs] strictly into 13 lines per page with sub-millisecond execution.
  static List<MushafPage> paginate({
    required List<AyahModel> ayahs,
    required int surahOrJuzId,
    required bool isJuz,
    required double availableWidth,
    required double availableHeight,
    required double fontSize,
    ArabicFont? arabicFont,
    required double lineHeight,
    SurahModel? defaultSurah,
  }) {
    if (ayahs.isEmpty || availableWidth <= 60) {
      return [];
    }

    final fontFamily = arabicFont?.fontFamily ?? 'Amiri';
    final cacheKey = _buildCacheKey(
      surahOrJuzId: surahOrJuzId,
      isJuz: isJuz,
      totalAyahs: ayahs.length,
      availableWidth: availableWidth,
      fontSize: fontSize,
      fontFamily: fontFamily,
    );

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final result = _computePages(
      ayahs: ayahs,
      availableWidth: availableWidth,
      fontSize: fontSize,
      arabicFont: arabicFont,
      defaultSurah: defaultSurah,
    );

    _cache[cacheKey] = result;
    return result;
  }

  static List<MushafPage> _computePages({
    required List<AyahModel> ayahs,
    required double availableWidth,
    required double fontSize,
    ArabicFont? arabicFont,
    SurahModel? defaultSurah,
  }) {
    final textStyle = AppTypography.arabicBody(
      arabicFont: arabicFont,
      fontSize: fontSize,
      height: 1.8,
      color: Colors.black,
    );

    // 1. Extract all word tokens sequentially
    final List<MushafWord> allWords = [];
    for (int i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      final cleanText = ayah.displayArabicText.trim();
      final words = cleanText.isEmpty
          ? <String>[]
          : cleanText.split(RegExp(r'\s+'));

      for (int w = 0; w < words.length; w++) {
        allWords.add(
          MushafWord(
            text: words[w],
            ayah: ayah,
            masterAyahIndex: i,
            isFirstWordOfAyah: w == 0,
            isLastWordOfAyah: w == words.length - 1,
          ),
        );
      }
    }

    if (allWords.isEmpty) return [];

    // 2. High-performance single-pass word width measurement
    final painter = TextPainter(textDirection: TextDirection.rtl);
    final double spaceWidth = _measureTextWidth(' ', textStyle, painter);

    final List<double> wordWidths = List<double>.filled(allWords.length, 0.0);
    for (int i = 0; i < allWords.length; i++) {
      final w = allWords[i];
      String textToMeasure = w.text;
      if (w.isLastWordOfAyah && w.ayah.sajda != null && w.ayah.sajda != false) {
        textToMeasure = '$textToMeasure ۩';
      }
      wordWidths[i] = _measureTextWidth(textToMeasure, textStyle, painter);
    }

    // 3. Fast O(N) line-by-line builder with float addition (sub-millisecond)
    final List<MushafPage> pages = [];
    List<MushafLine> currentLines = [];
    int wordIdx = 0;

    while (wordIdx < allWords.length) {
      final currentWord = allWords[wordIdx];

      // Check if starting a new Surah
      if (currentWord.isFirstWordOfAyah && currentWord.ayah.numberInSurah == 1) {
        final surahNum =
            currentWord.ayah.surahNumber ?? defaultSurah?.number ?? 1;
        final bool hasBismillah = surahNum != 1 && surahNum != 9;
        final int headerLineCost = hasBismillah ? 2 : 1;

        // If not enough lines left on this page for header + at least 1 verse line, start a new page
        if (currentLines.length + headerLineCost + 1 > strictLinesPerPage &&
            currentLines.isNotEmpty) {
          pages.add(MushafPage(pageIndex: pages.length, lines: currentLines));
          currentLines = [];
        }

        currentLines.add(
          MushafLine(
            type: MushafLineType.surahHeader,
            surahNumber: surahNum,
            isCentered: true,
          ),
        );

        if (hasBismillah) {
          currentLines.add(
            const MushafLine(
              type: MushafLineType.bismillah,
              isCentered: true,
            ),
          );
        }

        if (currentLines.length >= strictLinesPerPage) {
          pages.add(MushafPage(pageIndex: pages.length, lines: currentLines));
          currentLines = [];
        }
      }

      // Build one line of ayah words that fits availableWidth in O(1) per word
      final List<MushafWord> lineWords = [];
      double currentLineWidth = 0.0;

      while (wordIdx < allWords.length) {
        final nextWord = allWords[wordIdx];

        // If next word starts a new Surah and we already have words on this line, break the line
        if (lineWords.isNotEmpty &&
            nextWord.isFirstWordOfAyah &&
            nextWord.ayah.numberInSurah == 1) {
          break;
        }

        final double wordCost =
            (lineWords.isEmpty ? 0.0 : spaceWidth) + wordWidths[wordIdx];

        if (currentLineWidth + wordCost > availableWidth &&
            lineWords.isNotEmpty) {
          break; // Line is complete!
        }

        currentLineWidth += wordCost;
        lineWords.add(nextWord);
        wordIdx++;
      }

      if (lineWords.isNotEmpty) {
        final bool isLastLineOfSurah = lineWords.last.isLastWordOfAyah &&
            (wordIdx == allWords.length ||
                allWords[wordIdx].ayah.numberInSurah == 1);
        final bool isShortLine = lineWords.length <= 3;

        currentLines.add(
          MushafLine(
            type: MushafLineType.ayahText,
            words: lineWords,
            isCentered: isLastLineOfSurah && isShortLine,
          ),
        );

        if (currentLines.length >= strictLinesPerPage) {
          pages.add(MushafPage(pageIndex: pages.length, lines: currentLines));
          currentLines = [];
        }
      }
    }

    if (currentLines.isNotEmpty) {
      pages.add(MushafPage(pageIndex: pages.length, lines: currentLines));
    }

    return pages;
  }

  /// Fast single-string measurement using a reusable [TextPainter].
  static double _measureTextWidth(
    String text,
    TextStyle style,
    TextPainter painter,
  ) {
    painter.text = TextSpan(text: text, style: style);
    painter.layout();
    return painter.width;
  }
}
