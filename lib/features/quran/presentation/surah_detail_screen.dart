import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'surah_info_screen.dart';
import 'widgets/ayah_quick_actions_sheet.dart';
import 'widgets/ayah_verse_card.dart';
import 'widgets/quran_audio_player_bar.dart';
import 'widgets/quran_reading_settings_modal.dart';
import 'widgets/stop_point_dialog.dart';
import 'widgets/surah_download_dialog.dart';
import 'widgets/surah_header_card.dart';

class SurahDetailScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? juzNumber;
  final String surahName;
  final int? initialAyahNumber;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    this.juzNumber,
    required this.surahName,
    this.initialAyahNumber,
  });

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen> {
  final QuranRepository _repository = QuranRepository();
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;

  bool _showTranslation = false;
  bool _showTransliteration = true;
  String _translationLanguage = 'none'; // 'english', 'urdu', 'both', 'none'
  int _selectedMode =
      0; // 0: Verse-by-Verse List, 1: Page-Wise Mushaf, 2: Continuous Mushaf
  int _currentPageIndex = 0;
  bool _isDownloaded = false;

  // Page slider collapse & drag states (Left-edge pill docking)
  bool _isPageSliderExpanded = false;
  Timer? _pageSliderCollapseTimer;
  bool _isDraggingPageSlider = false;
  int _pageSliderDragValue = 1;

  // Active/Resume verse index for synchronization across modes
  int _activeAyahIndex = 0;
  int? _highlightResumeAyahNumber;
  bool _isNavigatingToTargetAyah = false;
  int? _targetAyahDisplayNumber;

  // On-screen typography & dedicated reading theme controls
  double _arabicFontSize = 24.0;
  bool _isReadingDarkMode = false;
  bool _isThemeInitialized = false;
  // Global keys for exact scroll alignment in Mode 0 (Verse List Mode)
  final Map<int, GlobalKey> _ayahKeys = {};

  @override
  void initState() {
    super.initState();

    final storage = ref.read(storageServiceProvider);
    final sp = widget.juzNumber != null
        ? storage.getStopPointForJuz(widget.juzNumber!)
        : storage.getStopPointForSurah(widget.surahNumber);

    int? targetAyahNum;
    if (widget.initialAyahNumber != null) {
      targetAyahNum = widget.initialAyahNumber;
      if (sp != null && sp['resumeAyahNumber'] == targetAyahNum) {
        _highlightResumeAyahNumber = targetAyahNum;
      } else {
        _highlightResumeAyahNumber = null;
      }
    } else if (sp != null) {
      targetAyahNum = sp['resumeAyahNumber'] as int?;
      _highlightResumeAyahNumber = targetAyahNum;
    } else {
      targetAyahNum = null;
      _highlightResumeAyahNumber = null;
    }

    final ayahs = widget.juzNumber != null
        ? _repository.getAyahsForJuz(widget.juzNumber!)
        : _repository.getAyahsForSurah(widget.surahNumber);

    int targetIdx = 0;
    int? targetAyahDisplayNum;
    if (targetAyahNum != null) {
      final targetSurahNum = widget.juzNumber != null && sp != null
          ? (sp['surahNumber'] as int?)
          : widget.surahNumber;
      final found = ayahs.indexWhere(
        (a) =>
            a.numberInSurah == targetAyahNum &&
            (widget.juzNumber == null ||
                targetSurahNum == null ||
                a.surahNumber == null ||
                a.surahNumber == targetSurahNum),
      );
      if (found >= 0) {
        targetIdx = found;
        targetAyahDisplayNum = targetAyahNum;
      }
    }
    _activeAyahIndex = targetIdx;
    _targetAyahDisplayNumber = targetAyahDisplayNum;
    if (targetIdx > 0) {
      _isNavigatingToTargetAyah = true;
    }

    final mushafPages = _computeMushafPages(ayahs);
    int initialPageIndex = 0;
    if (targetIdx < ayahs.length) {
      final targetAyah = ayahs[targetIdx];
      final foundPage = mushafPages.indexWhere(
        (p) => p.any(
          (a) =>
              a.numberInSurah == targetAyah.numberInSurah &&
              (a.surahNumber == null ||
                  targetAyah.surahNumber == null ||
                  a.surahNumber == targetAyah.surahNumber),
        ),
      );
      if (foundPage >= 0) {
        initialPageIndex = foundPage;
      }
    }
    _currentPageIndex = initialPageIndex;
    _pageController = PageController(initialPage: initialPageIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDownloadStatus();
      if (widget.juzNumber != null) {
        storage.setLastReadJuz(widget.juzNumber!);
      } else {
        storage.setLastRead(widget.surahNumber, targetAyahNum ?? 1);
      }
      final savedFontSize = storage.getQuranArabicFontSize();
      final savedDarkMode = storage.getQuranReadingDarkMode();
      final savedTranslationLang = storage.getQuranTranslationLanguage();

      setState(() {
        _arabicFontSize = savedFontSize;
        _isReadingDarkMode = savedDarkMode ?? context.isDarkMode;
        _translationLanguage = savedTranslationLang;
        _showTranslation = savedTranslationLang != 'none';
        _isThemeInitialized = true;
      });

      // Scroll/jump to target position accurately with loading overlay
      if (targetIdx > 0) {
        _scrollToTargetAyahWithLoading(targetIdx, ayahs);
      }
    });
  }

  void _resetPageSliderCollapseTimer() {
    _pageSliderCollapseTimer?.cancel();
    if (_isPageSliderExpanded) {
      _pageSliderCollapseTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _isPageSliderExpanded = false;
          });
        }
      });
    }
  }

  void _expandPageSlider() {
    setState(() {
      _isPageSliderExpanded = true;
    });
    _resetPageSliderCollapseTimer();
  }

  void _collapsePageSlider() {
    _pageSliderCollapseTimer?.cancel();
    setState(() {
      _isPageSliderExpanded = false;
    });
  }

  /// Groups verses strictly by authentic standard Quran page (ayah.page)
  List<List<AyahModel>> _computeMushafPages(List<AyahModel> ayahs) {
    if (ayahs.isEmpty) return [];

    final Map<int, List<AyahModel>> pageMap = {};
    for (final ayah in ayahs) {
      final p = ayah.page > 0 ? ayah.page : 1;
      pageMap.putIfAbsent(p, () => []).add(ayah);
    }

    return pageMap.values.toList();
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

  void _scrollToActiveAyah([List<AyahModel>? ayahsList]) {
    final ayahs = ayahsList ??
        (widget.juzNumber != null
            ? _repository.getAyahsForJuz(widget.juzNumber!)
            : _repository.getAyahsForSurah(widget.surahNumber));
    if (_activeAyahIndex < 0 || _activeAyahIndex >= ayahs.length) return;

    if (_selectedMode == 0) {
      // Verse-by-Verse list mode: Smoothly position active/speaking verse at top (alignment: 0.08)
      final key = _ayahKeys[_activeAyahIndex];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      } else if (_scrollController.hasClients) {
        const double headerEstimatedHeight = 340.0;
        const double avgVerseHeight = 260.0;
        final double estimatedTarget =
            headerEstimatedHeight + (_activeAyahIndex * avgVerseHeight);
        _scrollController.animateTo(
          estimatedTarget.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    } else if (_selectedMode == 1) {
      // Page-wise Mushaf mode: Slide to page containing the active verse
      final mushafPages = _computeMushafPages(ayahs);
      final targetAyah = ayahs[_activeAyahIndex];
      final pageIdx = mushafPages.indexWhere(
        (p) => p.any(
          (a) =>
              a.numberInSurah == targetAyah.numberInSurah &&
              (a.surahNumber == null ||
                  targetAyah.surahNumber == null ||
                  a.surahNumber == targetAyah.surahNumber),
        ),
      );
      if (pageIdx >= 0 && pageIdx != _currentPageIndex) {
        _currentPageIndex = pageIdx;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            pageIdx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    } else if (_selectedMode == 2) {
      // Continuous Mushaf mode: Proportional smooth scroll
      if (_scrollController.hasClients && ayahs.isNotEmpty) {
        final double progress = _activeAyahIndex / ayahs.length;
        final double target =
            progress * _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  Future<void> _scrollToTargetAyahWithLoading(
    int targetIdx,
    List<AyahModel> ayahs,
  ) async {
    if (targetIdx < 0 || targetIdx >= ayahs.length) {
      if (mounted && _isNavigatingToTargetAyah) {
        setState(() => _isNavigatingToTargetAyah = false);
      }
      return;
    }

    if (_selectedMode == 1) {
      // Page-wise Mushaf mode
      final mushafPages = _computeMushafPages(ayahs);
      final targetAyah = ayahs[targetIdx];
      final pageIdx = mushafPages.indexWhere(
        (p) => p.any(
          (a) =>
              a.numberInSurah == targetAyah.numberInSurah &&
              (a.surahNumber == null ||
                  targetAyah.surahNumber == null ||
                  a.surahNumber == targetAyah.surahNumber),
        ),
      );
      if (pageIdx >= 0) {
        _currentPageIndex = pageIdx;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(pageIdx);
        }
      }
      if (mounted) {
        setState(() => _isNavigatingToTargetAyah = false);
      }
      return;
    }

    if (_selectedMode == 2) {
      // Continuous Mushaf mode
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients && ayahs.isNotEmpty) {
        final double progress = targetIdx / ayahs.length;
        final double target =
            progress * _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(target);
      }
      if (mounted) {
        setState(() => _isNavigatingToTargetAyah = false);
      }
      return;
    }

    // Mode 0: Verse-by-Verse list mode
    // Allow initial layout pass
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    // Iteratively advance scroll until target widget is realized and mounted
    for (int attempt = 0; attempt < 12; attempt++) {
      if (!mounted) return;

      final key = _ayahKeys[targetIdx];
      if (key?.currentContext != null) {
        // Target widget is mounted!
        await Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
        break;
      }

      // If not yet mounted, progressively advance the scroll extent
      if (_scrollController.hasClients) {
        final double maxExtent = _scrollController.position.maxScrollExtent;
        final double fraction = targetIdx / ayahs.length;
        final double estimatedOffset =
            (fraction * (maxExtent + 4000)).clamp(0.0, maxExtent);
        _scrollController.jumpTo(estimatedOffset);
      }

      await Future.delayed(const Duration(milliseconds: 60));
    }

    // Final precision alignment pass
    if (mounted) {
      final key = _ayahKeys[targetIdx];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _isNavigatingToTargetAyah = false;
        });
      }
    }
  }

  void _markStopPoint(
    AyahModel ayah,
    int totalAyahs,
    SurahModel currentSurah,
  ) async {
    final storage = ref.read(storageServiceProvider);
    final surahNum = ayah.surahNumber ?? widget.surahNumber;
    final isAlreadyMarked = storage.isAyahMarkedAsStopPoint(
      surahNum,
      ayah.numberInSurah,
      juzNumber: widget.juzNumber,
    );

    if (isAlreadyMarked) {
      final String id = widget.juzNumber != null
          ? 'juz_${widget.juzNumber}'
          : 'surah_$surahNum';
      await storage.removeQuranStopPoint(id);
      setState(() {
        _highlightResumeAyahNumber = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.outlined_flag_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stop point on Ayah ${ayah.numberInSurah} removed.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final existingSp = widget.juzNumber != null
        ? storage.getStopPointForJuz(widget.juzNumber!)
        : storage.getStopPointForSurah(surahNum);

    if (existingSp != null) {
      final int oldMarkedAyah = existingSp['markedAyahNumber'] ?? 1;
      final int newResumeAyah = ayah.numberInSurah < totalAyahs
          ? ayah.numberInSurah + 1
          : ayah.numberInSurah;
      final bool isDark = _isReadingDarkMode;

      final bool? confirmed = await StopPointDialog.show(
        context: context,
        isDark: isDark,
        surahName: currentSurah.nameEnglish,
        previousAyah: oldMarkedAyah,
        newAyah: ayah.numberInSurah,
        newResumeAyah: newResumeAyah,
        isJuz: widget.juzNumber != null,
        juzNumber: widget.juzNumber,
      );

      if (confirmed != true) return;
    }

    await storage.saveQuranStopPoint(
      surahNumber: surahNum,
      surahNameEnglish: currentSurah.nameEnglish,
      surahNameArabic: currentSurah.nameArabic,
      juzNumber: widget.juzNumber,
      markedAyahNumber: ayah.numberInSurah,
      totalAyahs: totalAyahs,
      page: ayah.page,
    );

    final resumeAyah = ayah.numberInSurah < totalAyahs
        ? ayah.numberInSurah + 1
        : ayah.numberInSurah;

    setState(() {
      _highlightResumeAyahNumber = resumeAyah;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A531D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                color: Color(0xFFA3E635),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ayah ${ayah.numberInSurah} marked as stop point! Resume will start from Ayah $resumeAyah.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleAyahBookmark(
    AyahModel ayah,
    SurahModel currentSurah,
    int totalAyahs,
  ) async {
    final storage = ref.read(storageServiceProvider);
    final surahNum = ayah.surahNumber ?? currentSurah.number;
    final isBookmarked = storage.isAyahBookmarked(surahNum, ayah.numberInSurah);

    if (isBookmarked) {
      final id = 'bookmark_${surahNum}_${ayah.numberInSurah}';
      await storage.removeQuranAyahBookmark(id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.bookmark_border_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ayah ${ayah.numberInSurah} removed from bookmarks.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await storage.saveQuranAyahBookmark(
        surahNumber: surahNum,
        surahNameEnglish: currentSurah.nameEnglish,
        surahNameArabic: currentSurah.nameArabic,
        juzNumber: ayah.juz > 0 ? ayah.juz : (widget.juzNumber ?? 1),
        ayahNumber: ayah.numberInSurah, 
        totalAyahs: totalAyahs,
        page: ayah.page,
        arabicText: ayah.arabicText,
        translationEnglish: ayah.englishTranslation,
      );
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2A531D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.bookmark_added_rounded,
                  color: Color(0xFFA3E635),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ayah ${ayah.numberInSurah} of ${currentSurah.nameEnglish} saved to bookmarks!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Ayah Quick Action Bottom Sheet for Mushaf Modes
  void _showAyahQuickActionsSheet({
    required BuildContext context,
    required AyahModel ayah,
    required int totalAyahs,
    required SurahModel currentSurah,
    required bool isDark,
    required QuranAudioController quranAudio,
    required List<AyahModel> allAyahs,
    required int ayahIndex,
  }) {
    final storage = ref.read(storageServiceProvider);
    final surahNum = ayah.surahNumber ?? widget.surahNumber;
    final isMarked = storage.isAyahMarkedAsStopPoint(
      surahNum,
      ayah.numberInSurah,
      juzNumber: widget.juzNumber,
    );
    final isBookmarked = storage.isAyahBookmarked(
      surahNum,
      ayah.numberInSurah,
    );
    final arabicFont = ref.read(arabicFontProvider);

    AyahQuickActionsSheet.show(
      context: context,
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
      surahName: widget.surahName,
      surahNumber: widget.surahNumber,
      onToggleStopPoint: () => _markStopPoint(ayah, totalAyahs, currentSurah),
      onToggleBookmark: () =>
          _toggleAyahBookmark(ayah, currentSurah, totalAyahs),
      onPlay: () {
        quranAudio.playPlaylist(
          allAyahs,
          ayahIndex,
          title: widget.surahName,
          surahNumber: widget.surahNumber,
        );
        setState(() {
          _activeAyahIndex = ayahIndex;
        });
      },
    );
  }

  /// Unified Preferences & Settings Modal
  void _showSettingsModal(
    BuildContext context,
    bool isDark,
    List<AyahModel> ayahs,
  ) {
    QuranReadingSettingsModal.show(
      context: context,
      isDark: isDark,
      ayahs: ayahs,
      selectedMode: _selectedMode,
      arabicFontSize: _arabicFontSize,
      isReadingDarkMode: _isReadingDarkMode,
      translationLanguage: _translationLanguage,
      showTransliteration: _showTransliteration,
      isDownloaded: _isDownloaded,
      onModeChanged: (newMode) {
        setState(() {
          _selectedMode = newMode;
        });
        _scrollToActiveAyah();
      },
      onFontSizeChanged: (newSize) {
        setState(() {
          _arabicFontSize = newSize;
        });
        ref.read(storageServiceProvider).setQuranArabicFontSize(newSize);
      },
      onReadingDarkModeChanged: (newDarkMode) {
        setState(() {
          _isReadingDarkMode = newDarkMode;
        });
        ref.read(storageServiceProvider).setQuranReadingDarkMode(newDarkMode);
      },
      onTranslationLanguageChanged: (newLang) {
        setState(() {
          _translationLanguage = newLang;
          _showTranslation = newLang != 'none';
        });
        ref.read(storageServiceProvider).setQuranTranslationLanguage(newLang);
      },
      onTransliterationChanged: (val) {
        setState(() {
          _showTransliteration = val;
        });
      },
      onTriggerDownload: () => _triggerExplicitDownload(context, ayahs),
    );
  }



  @override
  void dispose() {
    _pageSliderCollapseTimer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = _isThemeInitialized
        ? _isReadingDarkMode
        : context.isDarkMode;
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
    final storage = ref.watch(storageServiceProvider);

    final bool isJuzMode = widget.juzNumber != null;
    final bool isFavorited = isJuzMode
        ? storage.getFavoriteJuz().contains(widget.juzNumber)
        : storage.getFavoriteSurahs().contains(widget.surahNumber);

    // Reactively scroll / sync page when audio changes
    ref.listen(quranAudioProvider, (previous, next) {
      if (next.currentIndex >= 0 &&
          next.currentIndex != previous?.currentIndex) {
        setState(() {
          _activeAyahIndex = next.currentIndex;
        });
        _scrollToActiveAyah(ayahs);
      }
    });

    // Compute standard authentic Mushaf pages for Mode 1 (RTL screen-fit pages)
    final List<List<AyahModel>> mushafPages = _computeMushafPages(ayahs);

    final revelationIcon = currentSurah.revelationType.toLowerCase() == 'meccan'
        ? FlutterIslamicIcons.solidKaaba
        : FlutterIslamicIcons.solidMosque;

    final isPlayerActive = quranAudio.currentIndex >= 0;

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
      value: effectiveIsDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: effectiveIsDark
                ? const Color(0xFF131E18) 
                : const Color(0xFFF8FAFC),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AppHeaderBar(
                title: barTitle,
                showBackButton: true,
                centerTitle: false,
                leadingWidth: 60,
                titleSpacing: 6,
                systemOverlayStyle: effectiveIsDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                backgroundColor: effectiveIsDark
                    ? const Color(0xFF192520)
                    : Colors.white,
                iconColor: effectiveIsDark
                    ? Colors.white
                    : const Color(0xFF2A531D),
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
                          color: effectiveIsDark
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
                          color: effectiveIsDark
                              ? Colors.white
                              : const Color(0xFF2A531D),
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Surah Information Button ('i')
                  if (!isJuzMode)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SurahInfoScreen(surah: currentSurah),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: effectiveIsDark
                            ? Colors.white
                            : const Color(0xFF2A531D),
                        size: 22,
                      ),
                      tooltip: 'Surah Information & Context',
                    ),
                  // Favorite Toggle for current Surah / Juz
                  IconButton(
                    onPressed: () async {
                      if (isJuzMode) {
                        await storage.toggleFavoriteJuz(widget.juzNumber!);
                      } else {
                        await storage.toggleFavoriteSurah(widget.surahNumber);
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      isFavorited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorited
                          ? const Color(0xFFEF4444)
                          : (effectiveIsDark
                                ? Colors.white
                                : const Color(0xFF2A531D)),
                      size: 22,
                    ),
                    tooltip: isFavorited
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                  ),
                  // Dark / Light Mode Toggle Button
                  IconButton(
                    onPressed: () {
                      final newDarkMode = !effectiveIsDark;
                      setState(() {
                        _isReadingDarkMode = newDarkMode;
                      });
                      ref
                          .read(storageServiceProvider)
                          .setQuranReadingDarkMode(newDarkMode);
                    },
                    icon: Icon(
                      effectiveIsDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: effectiveIsDark
                          ? const Color(0xFFA3E635)
                          : const Color(0xFF2A531D),
                      size: 22,
                    ),
                    tooltip: effectiveIsDark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                  ),
                  // Unified Settings & Preferences Button
                  IconButton(
                    onPressed: () =>
                        _showSettingsModal(context, effectiveIsDark, ayahs),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: effectiveIsDark
                          ? Colors.white
                          : const Color(0xFF2A531D),
                      size: 22,
                    ),
                    tooltip: 'Reading Preferences & Settings',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: _selectedMode == 1
                          ? _buildPageWiseMushafView(
                              mushafPages,
                              effectiveIsDark,
                              currentSurah,
                              playingAyah,
                              isPlayerActive,
                              storage,
                              ayahs.length,
                              ayahs,
                            )
                          : ListView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                _selectedMode == 2 ? 4 : 16,
                                14,
                                _selectedMode == 2 ? 4 : 16,
                                isPlayerActive ? 140 : 24,
                              ),
                              children: [
                                // Top Surah Header Card
                                _buildHeaderCard(
                                  currentSurah,
                                  ayahs,
                                  revelationIcon,
                                  effectiveIsDark,
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
                                    final surahNum = ayah.surahNumber ?? widget.surahNumber;
                                    final isMarked = storage.isAyahMarkedAsStopPoint(
                                      surahNum,
                                      ayah.numberInSurah,
                                      juzNumber: widget.juzNumber,
                                    );
                                    final isResumeHighlight = _highlightResumeAyahNumber != null &&
                                        _highlightResumeAyahNumber == ayah.numberInSurah &&
                                        (widget.juzNumber == null ||
                                            (storage.getStopPointForJuz(widget.juzNumber!)?['surahNumber'] == surahNum));

                                    return _buildVerseCard(
                                      ayah: ayah,
                                      index: index,
                                      isDark: effectiveIsDark,
                                      allAyahs: ayahs,
                                      isPlaying: isPlayingThis,
                                      isSelected: isSelectedThis,
                                      isMarkedStopPoint: isMarked,
                                      isResumeHighlight: isResumeHighlight,
                                      currentSurah: currentSurah,
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
                                          setState(() {
                                            _activeAyahIndex = index;
                                          });
                                          _scrollToActiveAyah(ayahs);
                                        }
                                      },
                                    );
                                  }),

                                // Mode 2: Continuous Flowing Mushaf Text
                                if (_selectedMode == 2)
                                  _buildContinuousMushafCard(
                                    ayahs,
                                    effectiveIsDark,
                                    playingAyah,
                                    currentSurah,
                                    storage,
                                  ),

                                SizedBox(height: isPlayerActive ? 140 : 24),
                              ],
                            ),
                    ),
                  ],
                ),

                // Floating Left Edge Semicircular Pill / Full Expanded Horizontal Traverser (Only when more than 1 page)
                if (_selectedMode == 1 && mushafPages.length > 1)
                  _buildFloatingPageTraverser(
                    mushafPages.length,
                    effectiveIsDark,
                    isPlayerActive,
                  ),

                // Beautiful Loading Overlay while scrolling to target bookmark / stop point
                if (_isNavigatingToTargetAyah)
                  Positioned.fill(
                    child: Container(
                      color: (effectiveIsDark
                              ? const Color(0xFF131D18)
                              : Colors.white)
                          .withValues(alpha: 0.90),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: effectiveIsDark
                                ? const Color(0xFF1C2B22)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFd1ffbe)
                                  .withValues(alpha: 0.6),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2A531D).withValues(
                                  alpha: effectiveIsDark ? 0.35 : 0.2,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.2,
                                  valueColor: AlwaysStoppedAnimation(
                                    effectiveIsDark
                                        ? const Color(0xFFA3E635)
                                        : const Color(0xFF2A531D),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _targetAyahDisplayNumber != null
                                    ? 'Loading Ayah $_targetAyahDisplayNumber...'
                                    : 'Opening Ayah...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: effectiveIsDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.juzNumber != null
                                    ? 'Juz ${widget.juzNumber}'
                                    : widget.surahName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: effectiveIsDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
              child: _buildStickyAudioPlayerBar(quranAudio, effectiveIsDark),
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
    final arabicFont = ref.read(arabicFontProvider);

    return SurahHeaderCard(
      currentSurah: currentSurah,
      ayahs: ayahs,
      isDark: isDark,
      isJuzMode: isJuzMode,
      currentJuz: currentJuz,
      revelationIcon: revelationIcon,
      arabicFont: arabicFont,
      quranAudio: quranAudio,
      isDownloaded: _isDownloaded,
      onPlayPlaylist: () {
        if (quranAudio.currentIndex >= 0) {
          quranAudio.togglePlayPause();
        } else {
          quranAudio.playPlaylist(
            ayahs,
            0,
            title: widget.surahName,
            surahNumber: widget.surahNumber,
          );
          setState(() {
            _activeAyahIndex = 0;
          });
        }
      },
      onDownloadTap: () => _triggerExplicitDownload(context, ayahs),
    );
  }

  /// 3. Mode 1: Authentic RTL Page-Wise Mushaf View (Standard Quran Pages, Fully Justified, Single-Screen Fit)
  Widget _buildPageWiseMushafView(
    List<List<AyahModel>> mushafPages,
    bool isDark,
    SurahModel currentSurah,
    AyahModel? playingAyah,
    bool isPlayerActive,
    dynamic storage,
    int totalAyahs,
    List<AyahModel> allAyahs,
  ) {
    if (mushafPages.isEmpty) {
      return const Center(child: Text('No page data available'));
    }

    return PageView.builder(
      controller: _pageController,
      reverse: true, // Authentic RTL Mushaf page sliding
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
        _resetPageSliderCollapseTimer();
      },
      itemCount: mushafPages.length,
      itemBuilder: (context, pageIndex) {
        final pAyahs = mushafPages[pageIndex];
        final int pageNumber =
            pAyahs.isNotEmpty ? pAyahs.first.page : pageIndex + 1;
        final int juzNumber = pAyahs.isNotEmpty ? pAyahs.first.juz : 1;

        // Check if any surah begins on this page (numberInSurah == 1)
        final List<int> startingSurahNumbers = pAyahs
            .where((a) => a.numberInSurah == 1)
            .map((a) => a.surahNumber ?? currentSurah.number)
            .toSet()
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final double bottomSpace = mushafPages.length > 1
                ? (isPlayerActive ? 160.0 : 80.0)
                : (isPlayerActive ? 140.0 : 20.0);
            final double availableHeight = (constraints.maxHeight - bottomSpace)
                .clamp(100.0, double.infinity);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  // Top Mini Page Indicator (Page on Left, Juz on Right)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page $pageNumber',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'Juz $juzNumber',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFA3E635)
                                : const Color(0xFF2A531D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Non-scrolling Single-Screen Justified Page Content
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                          maxHeight: availableHeight,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: constraints.maxWidth - 28,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // If any surah begins on this page, render Surah Banner & Bismillah
                                if (startingSurahNumbers.isNotEmpty) ...[
                                  ...startingSurahNumbers.map((sNum) {
                                    final surah = _repository
                                        .getSurahs()
                                        .firstWhere(
                                          (s) => s.number == sNum,
                                          orElse: () => currentSurah,
                                        );
                                    final showBismillah =
                                        sNum != 1 && sNum != 9;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Column(
                                        children: [
                                          // Ornate Surah Title Frame
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E3A2B)
                                                  : const Color(0xFFE8F5E9),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFF2A531D),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${surah.verseCount} Ayahs',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white70
                                                        : const Color(
                                                            0xFF2A531D,
                                                          ),
                                                  ),
                                                ),
                                                Text(
                                                  'سُوْرَةُ ${surah.nameArabic}',
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  style:
                                                      AppTypography.arabicHeader(
                                                        fontSize: 17,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFFA3E635,
                                                              )
                                                            : const Color(
                                                                0xFF1A3512,
                                                              ),
                                                      ),
                                                ),
                                                Text(
                                                  surah.revelationType,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white70
                                                        : const Color(
                                                            0xFF2A531D,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (showBismillah) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ",
                                              textDirection: TextDirection.rtl,
                                              textAlign: TextAlign.center,
                                              style:
                                                  AppTypography.arabicHeader(
                                                    fontSize: 18,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFA3E635,
                                                          )
                                                        : const Color(
                                                            0xFF2A531D,
                                                          ),
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                // Fully Justified Page Ayahs Text
                                SelectableText.rich(
                                  TextSpan(
                                    children: pAyahs.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final ayah = entry.value;
                                      final cleanText = ayah.displayArabicText;
                                      final isPlayingThis =
                                          playingAyah?.number == ayah.number;
                                      final bool isSajda =
                                          ayah.sajda != null &&
                                          ayah.sajda != false;
                                      final fullIndex = allAyahs.indexOf(ayah);
                                      final bool isNewHizb =
                                          ayah.hizb > 0 &&
                                          fullIndex > 0 &&
                                          allAyahs[fullIndex - 1].hizb !=
                                              ayah.hizb;
                                      final bool isNewRub =
                                          ayah.rub > 0 &&
                                          fullIndex > 0 &&
                                          allAyahs[fullIndex - 1].rub !=
                                              ayah.rub;
                                      final surahNum = ayah.surahNumber ?? widget.surahNumber;
                                      final bool isMarked = storage
                                          .isAyahMarkedAsStopPoint(
                                            surahNum,
                                            ayah.numberInSurah,
                                            juzNumber: juzNumber,
                                          );
                                      final bool isResumeHighlight = _highlightResumeAyahNumber != null &&
                                          _highlightResumeAyahNumber == ayah.numberInSurah &&
                                          (widget.juzNumber == null ||
                                              (storage.getStopPointForJuz(widget.juzNumber!)?['surahNumber'] == surahNum));

                                      return TextSpan(
                                        children: [
                                          // New Hizb Marker (changes only, no number)
                                          if (isNewHizb)
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF1E3A2B)
                                                      : const Color(0xFFE8F5E9),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2A531D,
                                                    ),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  '۞ حِزْب',
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFA3E635,
                                                          )
                                                        : const Color(
                                                            0xFF2A531D,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // New Rub Marker (changes only, no number)
                                          if (isNewRub && !isNewHizb)
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF1E3A2B)
                                                      : const Color(0xFFE8F5E9),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2A531D,
                                                    ),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  '۞ رُبْع',
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFA3E635,
                                                          )
                                                        : const Color(
                                                            0xFF2A531D,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Ayah Arabic Text Span (with authentic end circle)
                                          TextSpan(
                                            text: '$cleanText ',
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () =>
                                                  _showAyahQuickActionsSheet(
                                                    context: context,
                                                    ayah: ayah,
                                                    totalAyahs: totalAyahs,
                                                    currentSurah: currentSurah,
                                                    isDark: isDark,
                                                    quranAudio: ref.read(
                                                      quranAudioProvider,
                                                    ),
                                                    allAyahs: pAyahs,
                                                    ayahIndex: index,
                                                  ),
                                            style: AppTypography.arabicBody(
                                              fontSize: _arabicFontSize,
                                              height: 2.15,
                                              color: isPlayingThis
                                                  ? (isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF854D0E,
                                                          ))
                                                  : (isResumeHighlight
                                                        ? (isDark
                                                              ? const Color(
                                                                  0xFFFDE047,
                                                                )
                                                              : const Color(
                                                                  0xFF854D0E,
                                                                ))
                                                        : (isSajda
                                                              ? (isDark
                                                                    ? const Color(
                                                                        0xFF86EFAC,
                                                                      )
                                                                    : const Color(
                                                                        0xFF166534,
                                                                      ))
                                                              : (isDark
                                                                    ? const Color(
                                                                        0xFFF1F5F2,
                                                                      )
                                                                    : const Color(
                                                                        0xFF1F2937,
                                                                      )))),
                                            ).copyWith(
                                              backgroundColor: isPlayingThis
                                                  ? (isDark
                                                        ? const Color(
                                                            0xFF166534,
                                                          )
                                                        : const Color(
                                                            0xFFFEF08A,
                                                          ))
                                                  : (isResumeHighlight
                                                        ? (isDark
                                                              ? const Color(
                                                                  0xFF78350F,
                                                                ).withValues(
                                                                  alpha: 0.45,
                                                                )
                                                              : const Color(
                                                                  0xFFFEF08A,
                                                                ))
                                                        : (isSajda
                                                              ? (isDark
                                                                    ? const Color(
                                                                        0xFF14532D,
                                                                      ).withValues(
                                                                        alpha:
                                                                            0.35,
                                                                      )
                                                                    : const Color(
                                                                        0xFFFEF3C7,
                                                                      ))
                                                              : null)),
                                            ),
                                          ),
                                          // Stop Point Marker Pin
                                          if (isMarked)
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _showAyahQuickActionsSheet(
                                                      context: context,
                                                      ayah: ayah,
                                                      totalAyahs: totalAyahs,
                                                      currentSurah:
                                                          currentSurah,
                                                      isDark: isDark,
                                                      quranAudio: ref.read(
                                                        quranAudioProvider,
                                                      ),
                                                      allAyahs: pAyahs,
                                                      ayahIndex: index,
                                                    ),
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 3,
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFD97706,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.flag_rounded,
                                                        size: 11,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        'Stop',
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Sajda Badge
                                          if (isSajda)
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF166534,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  '۩ سَجْدَة',
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF86EFAC),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const TextSpan(text: ' '),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  textAlign: TextAlign.justify,
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Floating Left Edge Semicircular Pill that smoothly extends to the right showing the slider
  Widget _buildFloatingPageTraverser(
    int totalPages,
    bool isDark,
    bool isPlayerActive,
  ) {
    final currentPageNum = (_currentPageIndex + 1).clamp(1, totalPages);
    final displayPage = _isDraggingPageSlider
        ? _pageSliderDragValue
        : currentPageNum;
    final screenWidth = MediaQuery.of(context).size.width;
    final expandedWidth = (screenWidth - 24).clamp(240.0, 370.0);

    return Positioned(
      left: 0,
      bottom: isPlayerActive ? 150 : 28,
      child: GestureDetector(
        onTap: () {
          if (!_isPageSliderExpanded) {
            _expandPageSlider();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          width: _isPageSliderExpanded ? expandedWidth : 110,
          padding: EdgeInsets.only(
            left: _isPageSliderExpanded ? 12 : 9,
            right: _isPageSliderExpanded ? 9 : 6,
            top: _isPageSliderExpanded ? 8 : 9,
            bottom: _isPageSliderExpanded ? 8 : 9,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A531D), Color(0xFF1E3A15)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            border: Border.all(
              color: const Color(0xFFd1ffbe).withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
                blurRadius: 12,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: _isPageSliderExpanded
              ? // Expanded state: Slider + Page count + Right close chevron
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              activeTrackColor: const Color(0xFFd1ffbe),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFFA3E635),
                            ),
                            child: Slider(
                              value: displayPage.toDouble(),
                              min: 1.0,
                              max: totalPages > 0 ? totalPages.toDouble() : 1.0,
                              divisions: totalPages > 1 ? totalPages - 1 : 1,
                              onChangeStart: (_) {
                                _resetPageSliderCollapseTimer();
                                setState(() {
                                  _isDraggingPageSlider = true;
                                });
                              },
                              onChanged: (val) {
                                _resetPageSliderCollapseTimer();
                                final target = val.toInt();
                                setState(() {
                                  _pageSliderDragValue = target;
                                });
                                final pageIdx = target - 1;
                                if (pageIdx >= 0 &&
                                    pageIdx < totalPages &&
                                    pageIdx != _currentPageIndex) {
                                  _pageController.jumpToPage(pageIdx);
                                }
                              },
                              onChangeEnd: (_) {
                                _resetPageSliderCollapseTimer();
                                setState(() {
                                  _isDraggingPageSlider = false;
                                });
                              },
                            ),
                          ),
                          Text(
                            'Page $currentPageNum of $totalPages (${totalPages - currentPageNum} remaining)',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFd1ffbe),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Right side chevron to collapse
                    InkWell(
                      onTap: _collapsePageSlider,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFFd1ffbe),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                )
              : // Collapsed compact pill: Quran icon + Page / Total + Right open chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      FlutterIslamicIcons.quran2,
                      color: Color(0xFFd1ffbe),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$currentPageNum / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFd1ffbe),
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
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
    required bool isMarkedStopPoint,
    required bool isResumeHighlight,
    required SurahModel currentSurah,
    required VoidCallback onPlayTap,
  }) {
    final bool isJuzMode = widget.juzNumber != null;
    final int surahNum = ayah.surahNumber ?? currentSurah.number;
    final SurahModel ayahSurah = isJuzMode
        ? _repository.getSurahs().firstWhere(
            (s) => s.number == surahNum,
            orElse: () => currentSurah,
          )
        : currentSurah;
    final storage = ref.read(storageServiceProvider);
    final bool isBookmarked =
        storage.isAyahBookmarked(surahNum, ayah.numberInSurah);
    final arabicFont = ref.read(arabicFontProvider);

    return AyahVerseCard(
      cardKey: _ayahKeys.putIfAbsent(index, () => GlobalKey()),
      ayah: ayah,
      index: index,
      allAyahs: allAyahs,
      currentSurah: currentSurah,
      isDark: isDark,
      arabicFont: arabicFont,
      arabicFontSize: _arabicFontSize,
      translationLanguage: _translationLanguage,
      showTranslation: _showTranslation,
      showTransliteration: _showTransliteration,
      isSelected: isSelected,
      isPlaying: isPlaying,
      isMarkedStopPoint: isMarkedStopPoint,
      isResumeHighlight: isResumeHighlight,
      isBookmarked: isBookmarked,
      isJuzMode: isJuzMode,
      ayahSurah: ayahSurah,
      onPlayTap: onPlayTap,
      onBookmarkTap: () =>
          _toggleAyahBookmark(ayah, ayahSurah, allAyahs.length),
      onStopPointTap: () =>
          _markStopPoint(ayah, allAyahs.length, ayahSurah),
      onTafsirTap: () => _showAyahQuickActionsSheet(
        context: context,
        ayah: ayah,
        totalAyahs: allAyahs.length,
        currentSurah: ayahSurah,
        isDark: isDark,
        quranAudio: ref.read(quranAudioProvider),
        allAyahs: allAyahs,
        ayahIndex: index,
      ),
      onQuickActionsTap: () => _showAyahQuickActionsSheet(
        context: context,
        ayah: ayah,
        totalAyahs: allAyahs.length,
        currentSurah: ayahSurah,
        isDark: isDark,
        quranAudio: ref.read(quranAudioProvider),
        allAyahs: allAyahs,
        ayahIndex: index,
      ),
    );
  }

  /// 5. Mode 2: Continuous Flowing Mushaf View with 4pt Padding, Total Sajda & Ruku Markers
  Widget _buildContinuousMushafCard(
    List<AyahModel> ayahs,
    bool isDark,
    AyahModel? playingAyah,
    SurahModel currentSurah,
    dynamic storage,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SelectableText.rich(
        TextSpan(
          children: ayahs.asMap().entries.map((entry) {
            final index = entry.key;
            final ayah = entry.value;
            final cleanText = ayah.displayArabicText;
            final isPlayingThis = playingAyah?.number == ayah.number;
            final bool isSajda = ayah.sajda != null && ayah.sajda != false;
            final bool isNewHizb =
                ayah.hizb > 0 &&
                index > 0 &&
                ayahs[index - 1].hizb != ayah.hizb;
            final bool isNewRub =
                ayah.rub > 0 &&
                index > 0 &&
                ayahs[index - 1].rub != ayah.rub;
            final surahNum = ayah.surahNumber ?? widget.surahNumber;
            final bool isMarked = storage.isAyahMarkedAsStopPoint(
              surahNum,
              ayah.numberInSurah,
              juzNumber: widget.juzNumber,
            );
            final bool isResumeHighlight = _highlightResumeAyahNumber != null &&
                _highlightResumeAyahNumber == ayah.numberInSurah &&
                (widget.juzNumber == null ||
                    (storage.getStopPointForJuz(widget.juzNumber!)?['surahNumber'] == surahNum));

            return TextSpan(
              children: [
                // New Hizb Marker (changes only, no start, no number)
                if (isNewHizb)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
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
                          color: const Color(0xFF2A531D),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '۞ حِزْب',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFA3E635)
                              : const Color(0xFF2A531D),
                        ),
                      ),
                    ),
                  ),
                // New Rub Marker (changes only, no start, no number)
                if (isNewRub && !isNewHizb)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
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
                          color: const Color(0xFF2A531D),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '۞ رُبْع',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFA3E635)
                              : const Color(0xFF2A531D),
                        ),
                      ),
                    ),
                  ),
                // Arabic text with authentic end circle & highlighting
                TextSpan(
                  text: '$cleanText ',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showAyahQuickActionsSheet(
                      context: context,
                      ayah: ayah,
                      totalAyahs: ayahs.length,
                      currentSurah: currentSurah,
                      isDark: isDark,
                      quranAudio: ref.read(quranAudioProvider),
                      allAyahs: ayahs,
                      ayahIndex: index,
                    ),
                  style:
                      AppTypography.arabicBody(
                        fontSize: _arabicFontSize,
                        height: 2.2,
                        color: isPlayingThis
                            ? (isDark ? Colors.white : const Color(0xFF854D0E))
                            : (isResumeHighlight
                                  ? (isDark
                                        ? const Color(0xFFFDE047)
                                        : const Color(0xFF854D0E))
                                  : (isSajda
                                        ? (isDark
                                              ? const Color(0xFF86EFAC)
                                              : const Color(0xFF166534))
                                        : (isDark
                                              ? const Color(0xFFF1F5F2)
                                              : const Color(0xFF1F2937)))),
                      ).copyWith(
                        backgroundColor: isPlayingThis
                            ? (isDark
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFFEF08A))
                            : (isResumeHighlight
                                  ? (isDark
                                        ? const Color(
                                            0xFF78350F,
                                          ).withValues(alpha: 0.45)
                                        : const Color(0xFFFEF08A))
                                  : (isSajda
                                        ? (isDark
                                              ? const Color(
                                                  0xFF14532D,
                                                ).withValues(alpha: 0.35)
                                              : const Color(0xFFFEF3C7))
                                        : null)),
                      ),
                ),
                // Stop Point Marker Pin on Marked Stop Ayah (appears immediately before resuming verse in reading order)
                if (isMarked)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => _showAyahQuickActionsSheet(
                        context: context,
                        ayah: ayah,
                        totalAyahs: ayahs.length,
                        currentSurah: currentSurah,
                        isDark: isDark,
                        quranAudio: ref.read(quranAudioProvider),
                        allAyahs: ayahs,
                        ayahIndex: index,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Stop',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Sajda Badge
                if (isSajda)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF166534),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '۩ سَجْدَة',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF86EFAC),
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

  /// 4. Sticky Audio Player Bar
  Widget _buildStickyAudioPlayerBar(
    QuranAudioController quranAudio,
    bool isDark,
  ) {
    return QuranAudioPlayerBar(
      quranAudio: quranAudio,
      isDark: isDark,
    );
  }
}
