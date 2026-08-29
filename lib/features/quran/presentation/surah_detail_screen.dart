import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/media_download_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/floating_download_bar.dart';
import '../../../widgets/app_header_bar.dart';
import '../data/juz_model.dart';
import '../data/surah_model.dart';
import '../repositories/quran_repository.dart';
import '../services/quran_audio_service.dart';
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
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  bool _showTranslation = true;
  int _selectedMode =
      0; // 0: Verse-by-Verse List, 1: Page-Wise Mushaf, 2: Continuous Mushaf
  int _currentPageIndex = 0;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDownloadStatus();
      final storage = ref.read(storageServiceProvider);
      if (widget.juzNumber != null) {
        storage.setLastReadJuz(widget.juzNumber!);
      } else {
        storage.setLastRead(widget.surahNumber, 1);
      }
    });
  }

  Future<void> _checkDownloadStatus() async {
    final ayahs = widget.juzNumber != null
        ? _repository.getAyahsForJuz(widget.juzNumber!)
        : _repository.getAyahsForSurah(widget.surahNumber);

    final downloaded = await MediaDownloadService.instance.isBatchDownloaded(
      ayahs.map((a) => a.localRelativePath).toList(),
    );
    if (mounted && downloaded != _isDownloaded) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
  }

  void _scrollToVerse(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || _selectedMode != 0) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      // Header card + spacing occupies ~250px; scrolling brings active verse to the top
      final target = (250.0 + (index * 215.0)).clamp(0.0, maxScroll);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _syncPageWithAyah(AyahModel ayah, List<int> sortedPages) {
    if (_selectedMode != 1 || !_pageController.hasClients) return;
    final pageIndex = sortedPages.indexOf(ayah.page);
    if (pageIndex >= 0 && pageIndex != _currentPageIndex) {
      setState(() {
        _currentPageIndex = pageIndex;
      });
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
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
                    subtitle:
                        'Full Arabic verse, transliteration, English translation & audio play',
                    icon: Icons.translate_rounded,
                    modeIndex: 0,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildModeOptionTile(
                    title: 'Page-Wise Mushaf Mode',
                    subtitle:
                        'Authentic page-by-page Mushaf view with page navigation',
                    icon: Icons.auto_stories_rounded,
                    modeIndex: 1,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildModeOptionTile(
                    title: 'Continuous Flowing Mushaf Mode',
                    subtitle:
                        'Flowing continuous Arabic Mushaf text with verse markers',
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
                    : (isDark
                          ? const Color(0xFF2D3C34)
                          : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
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
    _scrollController.dispose();
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

    final quranAudio = ref.watch(quranAudioProvider);
    final playingAyah = quranAudio.currentAyah;
    final arabicFont = ref.watch(arabicFontProvider);

    // Reactively scroll / sync page when audio changes
    ref.listen(quranAudioProvider, (previous, next) {
      if (next.currentIndex >= 0 &&
          next.currentIndex != previous?.currentIndex) {
        _scrollToVerse(next.currentIndex);
        if (next.currentAyah != null) {
          final Map<int, List<AyahModel>> pageGroups = {};
          for (final ayah in ayahs) {
            pageGroups.putIfAbsent(ayah.page, () => []).add(ayah);
          }
          final sortedPages = pageGroups.keys.toList()..sort();
          _syncPageWithAyah(next.currentAyah!, sortedPages);
        }
      }
    });

    // Group ayahs by Page for Page-Wise Mushaf Mode
    final Map<int, List<AyahModel>> pageGroups = {};
    for (final ayah in ayahs) {
      pageGroups.putIfAbsent(ayah.page, () => []).add(ayah);
    }
    final List<int> sortedPages = pageGroups.keys.toList()..sort();

    final revelationIcon = currentSurah.revelationType.toLowerCase() == 'meccan'
        ? FlutterIslamicIcons.solidKaaba
        : FlutterIslamicIcons.solidMosque;

    final isPlayerActive = quranAudio.currentIndex >= 0;

    final bool isJuzMode = widget.juzNumber != null;
    final JuzModel? currentJuz = isJuzMode
        ? juzList.firstWhere(
            (j) => j.number == widget.juzNumber,
            orElse: () => juzList.first,
          )
        : null;

    final String barTitle = isJuzMode
        ? '${currentJuz!.number}. ${currentJuz.nameArabic}'
        : '${currentSurah.number}. ${currentSurah.nameArabic}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF17241E)
                : const Color(0xFFF9F9F9),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AppHeaderBar(
                title: barTitle,
                showBackButton: true,
                centerTitle: false,
                leadingWidth: 60,
                titleSpacing: 6,
                systemOverlayStyle: isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                backgroundColor: isDark
                    ? const Color(0xFF192520)
                    : Colors.white,
                iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
                titleWidget: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        isJuzMode
                            ? '${currentJuz!.number}. '
                            : '${currentSurah.number}. ',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2A531D),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        isJuzMode
                            ? currentJuz!.nameArabic
                            : currentSurah.nameArabic,
                        style: AppTypography.arabicHeader(
                          arabicFont: arabicFont,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2A531D),
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      _triggerExplicitDownload(context, ayahs);
                    },
                    icon: Icon(
                      _isDownloaded
                          ? Icons.cloud_done_rounded
                          : Icons.download_for_offline_rounded,
                      color: _isDownloaded
                          ? const Color(0xFFA3E635)
                          : (isDark ? Colors.white : const Color(0xFF2A531D)),
                    ),
                    tooltip: _isDownloaded
                        ? 'Surah Audio Downloaded'
                        : 'Download Surah Audio',
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showTranslation = !_showTranslation;
                      });
                    },
                    icon: Icon(
                      _showTranslation
                          ? Icons.g_translate_rounded
                          : Icons.translate_rounded,
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
                          sortedPages,
                          pageGroups,
                          isDark,
                          currentSurah,
                          playingAyah,
                        )
                      : ListView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            14,
                            16,
                            isPlayerActive ? 140 : 24,
                          ),
                          children: [
                            // Top Surah Header Card
                            _buildHeaderCard(
                              currentSurah,
                              ayahs,
                              revelationIcon,
                              isDark,
                              quranAudio,
                            ),

                            const SizedBox(height: 16),

                            // Mode 0: Verse-by-Verse List Mode
                            if (_selectedMode == 0)
                              ...List.generate(ayahs.length, (index) {
                                final ayah = ayahs[index];
                                final isPlayingThis =
                                    quranAudio.currentIndex == index &&
                                    quranAudio.isPlaying;
                                final isSelectedThis =
                                    quranAudio.currentIndex == index;
                                return _buildVerseCard(
                                  ayah: ayah,
                                  index: index,
                                  isDark: isDark,
                                  allAyahs: ayahs,
                                  isPlaying: isPlayingThis,
                                  isSelected: isSelectedThis,
                                  onPlayTap: () {
                                    if (isSelectedThis) {
                                      quranAudio.togglePlayPause();
                                    } else {
                                      quranAudio.playPlaylist(
                                        ayahs,
                                        index,
                                        title: widget.surahName,
                                        surahNumber: widget.surahNumber,
                                      );
                                      _scrollToVerse(index);
                                    }
                                  },
                                );
                              }),

                            // Mode 2: Continuous Flowing Mushaf Text
                            if (_selectedMode == 2)
                              _buildContinuousMushafCard(
                                ayahs,
                                isDark,
                                playingAyah,
                              ),

                            SizedBox(height: isPlayerActive ? 140 : 24),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (isPlayerActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyAudioPlayerBar(quranAudio, isDark),
            ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: FloatingDownloadBar(),
          ),
        ],
      ),
    );
  }

  void _triggerExplicitDownload(BuildContext context, List<AyahModel> ayahs) {
    final title = widget.juzNumber != null
        ? 'Juz ${widget.juzNumber}'
        : widget.surahName;

    SurahDownloadDialog.checkAndPrompt(
      context: context,
      ref: ref,
      title: title,
      items: ayahs
          .map(
            (a) => MediaDownloadItem(
              id: 'ayah_${a.number}',
              title: 'Ayah ${a.numberInSurah}',
              remoteUrl: a.remoteUrl,
              relativePath: a.localRelativePath,
            ),
          )
          .toList(),
    );
  }

  Widget _buildHeaderCard(
    SurahModel currentSurah,
    List<AyahModel> ayahs,
    IconData revelationIcon,
    bool isDark,
    QuranAudioController quranAudio,
  ) {
    final bool isJuzMode = widget.juzNumber != null;
    final JuzModel? currentJuz = isJuzMode
        ? juzList.firstWhere(
            (j) => j.number == widget.juzNumber,
            orElse: () => juzList.first,
          )
        : null;

    final String transliteration = isJuzMode
        ? currentJuz!.nameEnglish
        : currentSurah.nameEnglish;

    final String arabicName = isJuzMode
        ? currentJuz!.nameArabic
        : currentSurah.nameArabic;

    final int startJuz = ayahs.isNotEmpty ? ayahs.first.juz : 1;
    final int endJuz = ayahs.isNotEmpty ? ayahs.last.juz : 1;

    final bool isPlayingThisPlaylist =
        quranAudio.currentIndex >= 0 && quranAudio.isPlaying;

    final bool hasBismillah = widget.surahNumber != 9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
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
                color: const Color(0xFF2A531D).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content: Transliteration (left) & Arabic (right) + Centered Bismillah
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Transliteration & Translation on Left
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transliteration,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              isJuzMode
                                  ? 'Para (Juz) : ${currentJuz!.number}'
                                  : currentSurah.nameTranslation,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Arabic on Right with right padding
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          arabicName,
                          textDirection: TextDirection.rtl,
                          style: AppTypography.arabicHeader(
                            fontSize: 28,
                            color: const Color(0xFFd1ffbe),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasBismillah) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'بِسۡمِ اللَّهِ الرَّحۡمَٰنِ الرَّحِيمِ',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTypography.arabicHeader(
                          fontSize: 20,
                          color: const Color(0xFFd1ffbe),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    const SizedBox(height: 38),
                  ],
                ],
              ),

              // Absolute Left Bottom Corner Play Button
              Positioned(
                left: 0,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isPlayingThisPlaylist) {
                        quranAudio.togglePlayPause();
                      } else {
                        quranAudio.playPlaylist(
                          ayahs,
                          0,
                          title: isJuzMode
                              ? 'Juz ${widget.juzNumber} - ${currentJuz?.nameEnglish ?? ""}'
                              : widget.surahName,
                          surahNumber: widget.surahNumber,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isPlayingThisPlaylist
                            ? const Color(0xFFA3E635)
                            : Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPlayingThisPlaylist
                              ? const Color(0xFFA3E635)
                              : Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlayingThisPlaylist
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isPlayingThisPlaylist
                            ? const Color(0xFF1A3512)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Pills Row Below Card (Centered with Header Background)
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              _buildPillBadge(
                label: isJuzMode
                    ? 'Para ${currentJuz!.number}'
                    : (startJuz == endJuz
                          ? 'Para $startJuz'
                          : 'Para $startJuz - $endJuz'),
                isDark: isDark,
              ),
              _buildPillBadge(
                label: isJuzMode
                    ? currentJuz!.surahRange
                    : 'Surah ${currentSurah.number} (${currentSurah.revelationType})',
                isDark: isDark,
              ),
              _buildPillBadge(
                label: isJuzMode
                    ? '${ayahs.length} Ayahs'
                    : '${currentSurah.verseCount} Ayahs',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillBadge({required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A15), const Color(0xFF0F1A0E)]
              : [const Color(0xFF669f1d), const Color(0xFF66914d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A531D).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Floating Bottom Audio Player Bar (Identical to Asma Ul Husna Design)
  Widget _buildStickyAudioPlayerBar(
    QuranAudioController quranAudio,
    bool isDark,
  ) {
    final ayah = quranAudio.currentAyah;
    final totalAyahs = quranAudio.playlist.length;
    final int currentAyahNumber = (quranAudio.currentIndex + 1).clamp(
      1,
      totalAyahs > 0 ? totalAyahs : 1,
    );

    final double sliderValue = currentAyahNumber.toDouble().clamp(
      1.0,
      totalAyahs > 0 ? totalAyahs.toDouble() : 1.0,
    );

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A1A), Color(0xFF0F230D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 4),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ayah?.numberInSurah ?? currentAyahNumber}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ayah != null
                                ? 'Ayah ${ayah.numberInSurah} of $totalAyahs'
                                : quranAudio.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            quranAudio.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (ayah != null && ayah.displayArabicText.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          ayah.displayArabicText,
                          textDirection: TextDirection.rtl,
                          style: AppTypography.arabicHeader(
                            color: const Color(0xFF4ADE80),
                            fontSize: 20,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                      ),
                      onPressed: quranAudio.stop,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                          activeTrackColor: const Color(0xFF4ADE80),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: sliderValue,
                          min: 1.0,
                          max: totalAyahs > 0 ? totalAyahs.toDouble() : 1.0,
                          divisions: totalAyahs > 1 ? totalAyahs - 1 : 1,
                          onChanged: (val) {
                            final targetIndex = val.toInt() - 1;
                            if (targetIndex >= 0 &&
                                targetIndex < totalAyahs &&
                                targetIndex != quranAudio.currentIndex) {
                              quranAudio.playIndex(targetIndex);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Row(
                  children: [
                    // Playback speed toggle on bottom-left
                    InkWell(
                      onTap: () {
                        final speeds = [1.0, 1.25, 1.5, 2.0];
                        final currIndex = speeds.indexOf(quranAudio.speed);
                        final nextSpeed =
                            speeds[(currIndex + 1) % speeds.length];
                        quranAudio.setSpeed(nextSpeed);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF4ADE80,
                            ).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${quranAudio.speed}x',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                      ),
                    ),

                    // Centered Playback Controls
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: quranAudio.currentIndex > 0
                                ? () => quranAudio.playPrevious()
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => quranAudio.togglePlayPause(),
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(
                                  quranAudio.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: const Color(0xFF4ADE80),
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: quranAudio.currentIndex < totalAyahs - 1
                                ? () => quranAudio.playNext()
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // Symmetrical spacer for balance
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ],
          ),
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
    AyahModel? playingAyah,
  ) {
    if (sortedPages.isEmpty) {
      return const Center(child: Text('No page data available'));
    }

    final currentPageNumber =
        sortedPages[_currentPageIndex.clamp(0, sortedPages.length - 1)];

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
                    color: isDark
                        ? const Color(0xFF202F27)
                        : const Color(0xFFFFFDF7),
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
                              style: AppTypography.arabicHeader(
                                fontSize: 16,
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
                              final cleanText = ayah.displayArabicText;

                              final isPlayingThis =
                                  playingAyah?.number == ayah.number;

                              return TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$cleanText ',
                                    style: AppTypography.arabicBody(
                                      fontSize: 23,
                                      height: 2.2,
                                      color: isPlayingThis
                                          ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF854D0E))
                                          : (isDark
                                                ? Colors.white
                                                : const Color(0xFF1F2937)),
                                    ).copyWith(
                                      backgroundColor: isPlayingThis
                                          ? (isDark
                                                ? const Color(0xFF166534)
                                                : const Color(0xFFFEF08A))
                                          : null,
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isPlayingThis
                                            ? const Color(0xFF2A531D)
                                            : Colors.transparent,
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
                                          color: isPlayingThis
                                              ? Colors.white
                                              : (isDark
                                                    ? const Color(0xFFA3E635)
                                                    : const Color(0xFF2A531D)),
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

  /// Mode 0: Verse-by-Verse Card Widget with Highlighting & Audio Action
  Widget _buildVerseCard({
    required AyahModel ayah,
    required int index,
    required bool isDark,
    required List<AyahModel> allAyahs,
    required bool isPlaying,
    required bool isSelected,
    required VoidCallback onPlayTap,
  }) {
    final cleanArabicText = ayah.displayArabicText;

    final cardBgColor = isSelected
        ? (isDark ? const Color(0xFF1C3A24) : const Color(0xFFE2F6DB))
        : (isDark ? const Color(0xFF202F27) : Colors.white);

    final borderColor = isSelected
        ? const Color(0xFF2A531D)
        : (isDark
              ? Colors.white10
              : const Color(0xFF2A531D).withValues(alpha: 0.12));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(
                        0xFF2A531D,
                      ).withValues(alpha: isDark ? 0.35 : 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFA3E635)
                          : const Color(0xFF2A531D),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${ayah.numberInSurah}',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1A3512)
                              : Colors.white,
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
                  if (isSelected && isPlaying) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A531D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 12,
                            color: Color(0xFFA3E635),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Playing',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: onPlayTap,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : (isSelected
                                ? Icons.play_circle_fill_rounded
                                : Icons.play_circle_outline_rounded),
                      color: const Color(0xFF2A531D),
                      size: 30,
                    ),
                    tooltip: isPlaying ? 'Pause Audio' : 'Play Ayah Audio',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SelectableText(
                cleanArabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTypography.arabicBody(
                  fontSize: 24,
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
  Widget _buildContinuousMushafCard(
    List<AyahModel> ayahs,
    bool isDark,
    AyahModel? playingAyah,
  ) {
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
            final cleanText = ayah.displayArabicText;

            final isPlayingThis = playingAyah?.number == ayah.number;

            return TextSpan(
              children: [
                TextSpan(
                  text: '$cleanText ',
                  style: AppTypography.arabicBody(
                    fontSize: 24,
                    height: 2.2,
                    color: isPlayingThis
                        ? (isDark ? Colors.white : const Color(0xFF854D0E))
                        : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ).copyWith(
                    backgroundColor: isPlayingThis
                        ? (isDark
                              ? const Color(0xFF166534)
                              : const Color(0xFFFEF08A))
                        : null,
                  ),
                ),
                WidgetSpan(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPlayingThis
                          ? const Color(0xFF2A531D)
                          : Colors.transparent,
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
                        color: isPlayingThis
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D)),
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
