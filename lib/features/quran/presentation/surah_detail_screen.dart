import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/media_download_service.dart';
import '../../../widgets/app_header_bar.dart';
import '../data/surah_model.dart';
import '../repositories/quran_repository.dart';
import 'widgets/surah_download_dialog.dart';

class SurahDetailScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? juzNumber;
  final String surahName;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    this.juzNumber,
    required this.surahName,
  });

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen> {
  final QuranRepository _repository = QuranRepository();
  bool _showTranslation = true;
  int _selectedMode = 0; // 0: Verse-by-Verse List, 1: Page-Wise Mushaf, 2: Continuous Mushaf
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  void _showSettingsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Display & Reading Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModeOptionTile(
                    title: 'Verse-by-Verse List Mode',
                    subtitle: 'Full Arabic verse, transliteration, English translation & audio play',
                    icon: Icons.translate_rounded,
                    modeIndex: 0,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildModeOptionTile(
                    title: 'Page-Wise Mushaf Mode',
                    subtitle: 'Authentic page-by-page Mushaf view with page navigation',
                    icon: Icons.auto_stories_rounded,
                    modeIndex: 1,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildModeOptionTile(
                    title: 'Continuous Flowing Mushaf Mode',
                    subtitle: 'Flowing continuous Arabic Mushaf text with verse markers',
                    icon: Icons.menu_book_rounded,
                    modeIndex: 2,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required int modeIndex,
    required bool isDark,
  }) {
    final isSelected = _selectedMode == modeIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = modeIndex;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF23322B) : const Color(0xFFF4FAF3))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A531D) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2A531D)
                    : (isDark ? const Color(0xFF2D3C34) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2A531D),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final allSurahs = _repository.getSurahs();

    late final SurahModel currentSurah;
    late final List<AyahModel> ayahs;

    if (widget.juzNumber != null) {
      ayahs = _repository.getAyahsForJuz(widget.juzNumber!);
      currentSurah = allSurahs.firstWhere(
        (s) => s.number == widget.surahNumber,
        orElse: () => allSurahs.first,
      );
    } else {
      currentSurah = allSurahs.firstWhere(
        (s) => s.number == widget.surahNumber,
        orElse: () => allSurahs.first,
      );
      ayahs = _repository.getAyahsForSurah(widget.surahNumber);
    }

    // Group ayahs by Page for Page-Wise Mushaf Mode
    final Map<int, List<AyahModel>> pageGroups = {};
    for (final ayah in ayahs) {
      pageGroups.putIfAbsent(ayah.page, () => []).add(ayah);
    }
    final List<int> sortedPages = pageGroups.keys.toList()..sort();

    final revelationIcon = currentSurah.revelationType.toLowerCase() == 'meccan'
        ? FlutterIslamicIcons.solidKaaba
        : FlutterIslamicIcons.solidMosque;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF17241E) : const Color(0xFFF9F9F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: widget.surahName.toUpperCase(),
            showBackButton: true,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
            iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
            titleWidget: Text(
              widget.surahName.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2A531D),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showTranslation = !_showTranslation;
                  });
                },
                icon: Icon(
                  _showTranslation ? Icons.g_translate_rounded : Icons.translate_rounded,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                ),
                tooltip: 'Toggle Translation',
              ),
              IconButton(
                onPressed: () => _showSettingsModal(context, isDark),
                icon: Icon(
                  Icons.tune_rounded,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                ),
                tooltip: 'Reading Settings & Modes',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _selectedMode == 1
                  ? _buildPageWiseMushafView(
                      sortedPages, pageGroups, isDark, currentSurah)
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      children: [
                        // Top Surah Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF1E3A15),
                                      const Color(0xFF0F1A0E)
                                    ]
                                  : [
                                      const Color(0xFF669f1d),
                                      const Color(0xFF2A531D)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2A531D)
                                    .withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                right: 10,
                                bottom: 0,
                                child: Opacity(
                                  opacity: 0.20,
                                  child: Icon(
                                    revelationIcon,
                                    size: 56,
                                    color: const Color(0xFFA3E635),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.juzNumber != null
                                          ? 'Juz ${widget.juzNumber}'
                                          : currentSurah.nameEnglish,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.juzNumber != null
                                          ? 'Para ${widget.juzNumber}  •  ${ayahs.length} Ayahs'
                                          : '${currentSurah.nameTranslation}  •  ${currentSurah.verseCount} Ayahs  •  ${currentSurah.revelationType}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFd1ffbe),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (widget.surahNumber != 9 &&
                                        widget.juzNumber == null) ...[
                                      const SizedBox(height: 14),
                                      Text(
                                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: GoogleFonts.amiri(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFd1ffbe),
                                          height: 1.7,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Mode 0: Verse-by-Verse List Mode
                        if (_selectedMode == 0)
                          ...ayahs.map((ayah) {
                            return _buildVerseCard(ayah, isDark, ayahs);
                          }),

                        // Mode 2: Continuous Flowing Mushaf Text
                        if (_selectedMode == 2)
                          _buildContinuousMushafCard(ayahs, isDark),

                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mode 1: Authentic Page-Wise Mushaf View
  Widget _buildPageWiseMushafView(
    List<int> sortedPages,
    Map<int, List<AyahModel>> pageGroups,
    bool isDark,
    SurahModel currentSurah,
  ) {
    if (sortedPages.isEmpty) {
      return const Center(child: Text('No page data available'));
    }

    final currentPageNumber = sortedPages[_currentPageIndex.clamp(0, sortedPages.length - 1)];

    return Column(
      children: [
        // Page Navigation Top Controller Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? const Color(0xFF192520) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _currentPageIndex > 0
                    ? () {
                        setState(() {
                          _currentPageIndex--;
                          _pageController.animateToPage(
                            _currentPageIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                tooltip: 'Previous Page',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A531D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page $currentPageNumber  (${_currentPageIndex + 1}/${sortedPages.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPageIndex < sortedPages.length - 1
                    ? () {
                        setState(() {
                          _currentPageIndex++;
                          _pageController.animateToPage(
                            _currentPageIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                tooltip: 'Next Page',
              ),
            ],
          ),
        ),

        // Page Contents
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemCount: sortedPages.length,
            itemBuilder: (context, pageIndex) {
              final pNum = sortedPages[pageIndex];
              final pAyahs = pageGroups[pNum] ?? [];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF202F27) : const Color(0xFFFFFDF7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Juz ${pAyahs.isNotEmpty ? pAyahs.first.juz : 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                            Text(
                              currentSurah.nameArabic,
                              style: GoogleFonts.amiri(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2A531D),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFFD4AF37), thickness: 0.8),
                        const SizedBox(height: 12),

                        SelectableText.rich(
                          TextSpan(
                            children: pAyahs.map((ayah) {
                              final cleanText = ayah.arabicText
                                  .replaceAll(RegExp(r'\s*\(\d+:\d+\)\s*'), '')
                                  .replaceAll(RegExp(r'\s*﴿\d+:\d+﴾\s*'), '')
                                  .replaceAll(RegExp(r'\s*﴿\d+﴾\s*'), '')
                                  .trim();

                              return TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$cleanText ',
                                    style: GoogleFonts.amiri(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w600,
                                      height: 2.2,
                                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF2A531D),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        '${ayah.numberInSurah}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFFA3E635) : const Color(0xFF2A531D),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' '),
                                ],
                              );
                            }).toList(),
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Mode 0: Verse-by-Verse Card Widget
  Widget _buildVerseCard(AyahModel ayah, bool isDark, List<AyahModel> allAyahs) {
    final cleanArabicText = ayah.arabicText
        .replaceAll(RegExp(r'\s*\(\d+:\d+\)\s*'), '')
        .replaceAll(RegExp(r'\s*﴿\d+:\d+﴾\s*'), '')
        .replaceAll(RegExp(r'\s*﴿\d+﴾\s*'), '')
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202F27) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : const Color(0xFF2A531D).withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A531D),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${ayah.numberInSurah}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Page ${ayah.page}  •  Juz ${ayah.juz}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      SurahDownloadDialog.checkAndPrompt(
                        context: context,
                        ref: ref,
                        title: widget.surahName,
                        items: allAyahs
                            .map((a) => MediaDownloadItem(
                                  id: a.audioFileName,
                                  title: 'Ayah ${a.numberInSurah}',
                                  remoteUrl: a.remoteUrl,
                                  relativePath: a.localRelativePath,
                                ))
                            .toList(),
                      );
                    },
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Color(0xFF2A531D),
                      size: 26,
                    ),
                    tooltip: 'Play Verse Audio',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SelectableText(
                cleanArabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 2.0,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),

              if (ayah.transliteration.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(
                  ayah.transliteration,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFFA3E635)
                        : const Color(0xFF2A531D),
                    height: 1.4,
                  ),
                ),
              ],

              if (_showTranslation && ayah.englishTranslation.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(
                  ayah.englishTranslation,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Mode 2: Continuous Flowing Mushaf View Card
  Widget _buildContinuousMushafCard(List<AyahModel> ayahs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202F27) : const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: SelectableText.rich(
        TextSpan(
          children: ayahs.map((ayah) {
            final cleanText = ayah.arabicText
                .replaceAll(RegExp(r'\s*\(\d+:\d+\)\s*'), '')
                .replaceAll(RegExp(r'\s*﴿\d+:\d+﴾\s*'), '')
                .replaceAll(RegExp(r'\s*﴿\d+﴾\s*'), '')
                .trim();

            return TextSpan(
              children: [
                TextSpan(
                  text: '$cleanText ',
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 2.2,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                WidgetSpan(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2A531D),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFA3E635) : const Color(0xFF2A531D),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' '),
              ],
            );
          }).toList(),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      ),
    );
  }
}
