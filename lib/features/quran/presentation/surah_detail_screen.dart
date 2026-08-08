import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../widgets/app_header_bar.dart';
import '../repositories/quran_repository.dart';

class SurahDetailScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen> {
  final QuranRepository _repository = QuranRepository();
  bool _showTranslation = true;
  int _selectedMode = 0; // 0: Translation Mode, 1: Continuous Reading Mode, 2: Hide Single Verse Mode

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
                    title: 'Translation Mode',
                    subtitle: 'Full Arabic verse, English translation & verse actions',
                    icon: Icons.translate_rounded,
                    modeIndex: 0,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildModeOptionTile(
                    title: 'Continuous Reading Mode',
                    subtitle: 'Flowing Mushaf text with circular verse checkpoints',
                    icon: Icons.menu_book_rounded,
                    modeIndex: 1,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildModeOptionTile(
                    title: 'Hide Single Verse Mode',
                    subtitle: 'Show verse-by-verse Arabic text without translation',
                    icon: Icons.subtitles_off_rounded,
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
          if (modeIndex == 2) {
            _showTranslation = false;
          } else if (modeIndex == 0) {
            _showTranslation = true;
          }
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF23322B) : const Color(0xFFF4FAF3))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2A531D)
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2A531D)
                    : (isDark ? const Color(0xFF23322B) : const Color(0xFFF4FAF3)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF2A531D)),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final ayahs = _repository.getAyahsForSurah(widget.surahNumber);
    final storage = ref.watch(storageServiceProvider);
    final surahs = _repository.getSurahs();
    final currentSurah = surahs.firstWhere(
      (s) => s.number == widget.surahNumber,
      orElse: () => surahs.first,
    );

    final isMeccan = currentSurah.revelationType.toLowerCase() == 'meccan';
    final revelationIcon = isMeccan
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
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Top Surah Header Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A15), const Color(0xFF0F1A0E)]
                      : [const Color(0xFF669f1d), const Color(0xFF2A531D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dynamic Revelation Icon (Mecca for Meccan, Mosque for Medinan)
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

                  // Centered Contents
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentSurah.nameEnglish,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentSurah.nameTranslation}  •  ${currentSurah.verseCount} Ayahs  •  ${currentSurah.revelationType}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFd1ffbe),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.surahNumber != 9) ...[
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

            // Mode 0: Translation Mode (Arabic + Translation + Action Buttons)
            if (_selectedMode == 0)
              ...ayahs.map((ayah) {
                final cleanArabicText = ayah.arabicText
                    .replaceAll(RegExp(r'\s*\(\d+:\d+\)\s*'), '')
                    .replaceAll(RegExp(r'\s*﴿\d+:\d+﴾\s*'), '')
                    .replaceAll(RegExp(r'\s*﴿\d+﴾\s*'), '')
                    .trim();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Verse Number & Action Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF23322B)
                                      : const Color(0xFFF4FAF3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2A531D)
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  '${widget.surahNumber}:${ayah.numberInSurah}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A531D),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Playing reciter audio for Ayah ${ayah.numberInSurah}',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 22,
                                      color: Color(0xFF2A531D),
                                    ),
                                    tooltip: 'Play Audio',
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await storage.setLastRead(
                                        widget.surahNumber,
                                        ayah.numberInSurah,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Saved bookmark for Ayah ${ayah.numberInSurah}',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.bookmark_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF2A531D),
                                    ),
                                    tooltip: 'Bookmark',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text:
                                              '$cleanArabicText\n\n"${ayah.englishTranslation}" [Quran ${widget.surahNumber}:${ayah.numberInSurah}]',
                                        ),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ayah copied to clipboard',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      size: 19,
                                      color: Colors.grey,
                                    ),
                                    tooltip: 'Share',
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Arabic Verse Text
                          SelectableText(
                            cleanArabicText,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFDE047)
                                  : const Color(0xFF1A3512),
                              height: 1.7,
                            ),
                          ),

                          // Translation Text
                          if (_showTranslation) ...[
                            const SizedBox(height: 10),
                            SelectableText(
                              ayah.englishTranslation,
                              style: GoogleFonts.lexend(
                                fontSize: 13.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Divider between Ayahs
                    Divider(
                      height: 1,
                      thickness: 1.0,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ],
                );
              })
            // Mode 1: Continuous Reading Mode (Continuous Mushaf Text with Small Inline Circular Checkpoints)
            else if (_selectedMode == 1)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF23322B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : const Color(0xFF2A531D).withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      for (final ayah in ayahs) ...[
                        TextSpan(
                          text: '${ayah.arabicText.replaceAll(RegExp(r'\s*\(\d+:\d+\)\s*'), '').replaceAll(RegExp(r'\s*﴿\d+:\d+﴾\s*'), '').replaceAll(RegExp(r'\s*﴿\d+﴾\s*'), '').trim()} ',
                          style: GoogleFonts.amiri(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFDE047)
                                : const Color(0xFF1A3512),
                            height: 2.2,
                          ),
                        ),
                        _buildAyahCircleSpan(ayah.numberInSurah, isDark),
                        const TextSpan(text: ' '),
                      ],
                    ],
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              )
            // Mode 2: Hide Single Verse Mode (Only Verse-by-Verse Arabic Text)
            else
              ...ayahs.map((ayah) {
                final cleanArabicText = ayah.arabicText
                    .replaceAll(RegExp(r'\s*\(\d+:\d+\)\s*'), '')
                    .replaceAll(RegExp(r'\s*﴿\d+:\d+﴾\s*'), '')
                    .replaceAll(RegExp(r'\s*﴿\d+﴾\s*'), '')
                    .trim();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF23322B)
                                  : const Color(0xFFF4FAF3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF2A531D)
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              '${ayah.numberInSurah}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A531D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SelectableText(
                              cleanArabicText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFFDE047)
                                    : const Color(0xFF1A3512),
                                height: 1.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1.0,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ],
                );
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String str = number.toString();
    for (int i = 0; i < 10; i++) { 
      str = str.replaceAll(englishDigits[i], arabicDigits[i]);
    }
    return str;
  }

  // Small, Customized, Beautiful & Attractive Circular Arabic Ayah End Badge
  InlineSpan _buildAyahCircleSpan(int ayahNumber, bool isDark) {
    final arabicNum = _toArabicNumerals(ayahNumber);
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E2A24) : const Color(0xFFF4FAF3),
          border: Border.all(
            color: isDark
                ? const Color(0xFFA3E635)
                : const Color(0xFF2A531D).withValues(alpha: 0.75),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A531D).withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            arabicNum,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFA3E635) : const Color(0xFF2A531D),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
