import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/media_download_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/typography/arabic_font.dart';
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
import 'widgets/floating_draggable_page_slider.dart';
import 'widgets/floating_draggable_scrollbar.dart';
import 'widgets/mushaf_page_widget.dart';
import 'widgets/mushaf_pagination_engine.dart';
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
  final bool fromBookmark;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    this.juzNumber,
    required this.surahName,
    this.initialAyahNumber,
    this.fromBookmark = false,
  });

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen> {
  final QuranRepository _repository = QuranRepository();
  late final ScrollController _scrollController;
  late final PageController _pageController;

  bool _showTranslation = false;
  bool _showTransliteration = true;
  String _translationLanguage = 'none'; // 'english', 'urdu', 'both', 'none'
  int _selectedMode =
      0; // 0: Verse-by-Verse List, 1: Page-Wise Mushaf, 2: Continuous Mushaf
  int _currentPageIndex = 0;
  bool _isDownloaded = false;

  // Active/Resume verse index for synchronization across modes
  int _activeAyahIndex = 0;
  int? _highlightResumeAyahNumber;
  int? _selectedAyahForHighlight;
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
      _highlightResumeAyahNumber = targetAyahNum;
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

    final savedFontSize = storage.getQuranArabicFontSize();
    final savedDarkMode = storage.getQuranReadingDarkMode();
    final savedTranslationLang = storage.getQuranTranslationLanguage();
    final savedMode = storage.getQuranReadingMode();
 
    _arabicFontSize = savedFontSize;
    _isReadingDarkMode = savedDarkMode ?? false;
    _translationLanguage = savedTranslationLang;
    _showTranslation = savedTranslationLang != 'none';
    _isThemeInitialized = true;

    _selectedMode = (widget.juzNumber != null && savedMode == 2)
        ? 0
        : savedMode;

    _scrollController = ScrollController();
    _currentPageIndex = 0;
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDownloadStatus();
      if (!mounted) return;
      if (widget.juzNumber != null) {
        storage.setLastReadJuz(widget.juzNumber!);
      } else {
        storage.setLastRead(widget.surahNumber, targetAyahNum ?? 1);
      }

      // Scroll/jump to target position accurately with loading overlay
      if (targetIdx > 0) {
        _scrollToTargetAyahWithLoading(targetIdx, ayahs);
      }
    });
  }

  List<MushafPage>? _lastComputedMushafPages;

  /// Dynamic layout-aware pagination using Flutter TextPainter
  List<MushafPage> _paginateCurrentMushaf(
    BuildContext context,
    List<AyahModel> ayahs, {
    SurahModel? currentSurah,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isPlayerActive = ref.read(quranAudioProvider).currentIndex >= 0;
    final double bottomInset = mediaQuery.padding.bottom;
    final double bottomSpace = isPlayerActive
        ? (bottomInset + 100.0)
        : (bottomInset + 8.0);
    final double cardWidth = (mediaQuery.size.width - 16.0).clamp(
      100.0,
      1200.0,
    );
    final double cardHeight = (mediaQuery.size.height - 8.0 - bottomSpace)
        .clamp(100.0, 3000.0);
    final double availableWidth = (cardWidth - 32.0).clamp(80.0, 1160.0);
    final double availableHeight = (cardHeight - 24.0).clamp(80.0, 2960.0);
    final arabicFont = ref.read(arabicFontProvider);

    final pages = MushafPaginationEngine.paginate(
      ayahs: ayahs,
      surahOrJuzId: widget.juzNumber ?? widget.surahNumber,
      isJuz: widget.juzNumber != null,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      fontSize: 24.0,
      arabicFont: arabicFont,
      lineHeight: 1.8,
      defaultSurah: currentSurah,
    );

    _lastComputedMushafPages = pages;
    return pages;
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
    final ayahs =
        ayahsList ??
        (widget.juzNumber != null
            ? _repository.getAyahsForJuz(widget.juzNumber!)
            : _repository.getAyahsForSurah(widget.surahNumber));
    if (_activeAyahIndex < 0 || _activeAyahIndex >= ayahs.length) return;

    if (_selectedMode == 0) {
      // Verse-by-Verse list mode: Position active verse card exactly at top of viewport
      if (!_scrollController.hasClients) return;
      final key = _ayahKeys[_activeAyahIndex];
      final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null && renderBox.hasSize) {
        final viewport = RenderAbstractViewport.of(renderBox);
        final revealedOffset = viewport.getOffsetToReveal(renderBox, 0.0);
        _scrollController.animateTo(
          revealedOffset.offset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      } else {
        const double headerEstimatedHeight = 360.0;
        const double avgVerseHeight = 220.0;
        final double estimatedTarget =
            headerEstimatedHeight + (_activeAyahIndex * avgVerseHeight);
        final maxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(estimatedTarget.clamp(0.0, maxExtent));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final k = _ayahKeys[_activeAyahIndex];
          final rb = k?.currentContext?.findRenderObject() as RenderBox?;
          if (rb != null && rb.hasSize) {
            final vp = RenderAbstractViewport.of(rb);
            final ro = vp.getOffsetToReveal(rb, 0.0);
            _scrollController.animateTo(
              ro.offset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    } else if (_selectedMode == 1) {
      // Page-wise Mushaf mode: Slide to page containing the active verse segment
      final mushafPages =
          _lastComputedMushafPages ?? _paginateCurrentMushaf(context, ayahs);
      final pageIdx = mushafPages.indexWhere(
        (p) => p.containsMasterAyahIndex(_activeAyahIndex),
      );
      if (pageIdx >= 0) {
        _currentPageIndex = pageIdx;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            pageIdx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(pageIdx);
            }
          });
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
          duration: const Duration(milliseconds: 400),
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
      // Page-wise Mushaf mode: calculate pages with screen dimensions and jump to target page
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      final mushafPages =
          _lastComputedMushafPages ?? _paginateCurrentMushaf(context, ayahs);
      final pageIdx = mushafPages.indexWhere(
        (p) => p.containsMasterAyahIndex(targetIdx),
      );
      if (pageIdx >= 0) {
        _currentPageIndex = pageIdx;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(pageIdx);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(pageIdx);
            }
          });
        }
      }
      await Future.delayed(const Duration(milliseconds: 80));
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
    const double headerEstimatedHeight = 320.0;
    const double avgVerseEstimatedHeight = 250.0;
    final double initialTargetOffset =
        headerEstimatedHeight + (targetIdx * avgVerseEstimatedHeight);

    if (_scrollController.hasClients) {
      final double maxExt = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(initialTargetOffset.clamp(0.0, maxExt));
    }

    // Progressively converge onto targetIdx based on mounted keys
    for (int step = 0; step < 18; step++) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (!mounted) return;

      final key = _ayahKeys[targetIdx];
      final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final viewport = RenderAbstractViewport.of(renderBox);
        final revealedOffset = viewport.getOffsetToReveal(renderBox, 0.05);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            revealedOffset.offset.clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            ),
          );
        }
        break;
      }

      // Steer scroll position towards target index based on what is mounted
      if (_scrollController.hasClients) {
        final mountedEntries = _ayahKeys.entries
            .where((e) => e.value.currentContext != null)
            .map((e) => e.key)
            .toList();

        if (mountedEntries.isNotEmpty) {
          final maxMounted = mountedEntries.reduce(math.max);
          final minMounted = mountedEntries.reduce(math.min);
          final curPixels = _scrollController.position.pixels;
          final maxExtent = _scrollController.position.maxScrollExtent;

          if (targetIdx > maxMounted) {
            final double delta = (targetIdx - maxMounted) * 230.0;
            _scrollController.jumpTo(
              (curPixels + delta).clamp(0.0, maxExtent),
            );
          } else if (targetIdx < minMounted) {
            final double delta = (minMounted - targetIdx) * 230.0;
            _scrollController.jumpTo(
              (curPixels - delta).clamp(0.0, maxExtent),
            );
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isNavigatingToTargetAyah = false;
      });
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
  Future<void> _showAyahQuickActionsSheet({
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
    final isBookmarked = storage.isAyahBookmarked(surahNum, ayah.numberInSurah);
    final arabicFont = ref.read(arabicFontProvider);

    return AyahQuickActionsSheet.show(
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
      translationLanguage: _translationLanguage,
      showTransliteration: _showTransliteration,
      isDownloaded: _isDownloaded,
      isJuzMode: widget.juzNumber != null,
      onModeChanged: (newMode) {
        setState(() {
          _selectedMode = newMode;
        });
        ref.read(storageServiceProvider).setQuranReadingMode(newMode);
        _scrollToActiveAyah();
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

  /// Updates font size, persists it, and seamlessly preserves reading anchor in Mode 1
  void _applyFontSizeChange(double newSize, List<AyahModel> ayahs) {
    int anchorAyahIndex = _activeAyahIndex >= 0 ? _activeAyahIndex : 0;
    if (_lastComputedMushafPages != null &&
        _currentPageIndex < _lastComputedMushafPages!.length) {
      final curPage = _lastComputedMushafPages![_currentPageIndex];
      for (final line in curPage.lines) {
        if (line.words.isNotEmpty) {
          anchorAyahIndex = line.words.first.masterAyahIndex;
          break;
        }
      }
    }

    setState(() {
      _arabicFontSize = newSize;
    });
    ref.read(storageServiceProvider).setQuranArabicFontSize(newSize);

    if (_selectedMode == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final newPages = _paginateCurrentMushaf(context, ayahs);
        final newPageIdx = newPages.indexWhere(
          (p) => p.containsMasterAyahIndex(anchorAyahIndex),
        );
        if (newPageIdx >= 0 && newPageIdx != _currentPageIndex) {
          _currentPageIndex = newPageIdx;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(newPageIdx);
          }
        }
      });
    }
  }

  /// Dedicated Live Arabic Text Resize Bottom Sheet
  void _showFontSizeModal(
    BuildContext context,
    bool isDark,
    List<AyahModel> ayahs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF212121) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grabber
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

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.format_size_rounded,
                              color: isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Arabic Text Size',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(
                                    0xFF2A531D,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_arabicFontSize.toInt()} pt',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Live Slider with Stepper Buttons
                    Row(
                      children: [
                        // Decrease A-
                        IconButton(
                          onPressed: _arabicFontSize > 18.0
                              ? () {
                                  final newSize = (_arabicFontSize - 2.0).clamp(
                                    18.0,
                                    42.0,
                                  );
                                  _applyFontSizeChange(newSize, ayahs);
                                  setModalState(() {});
                                }
                              : null,
                          icon: Text(
                            'A-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFE8F5E9),
                            foregroundColor: isDark
                                ? const Color(0xFFA3E635)
                                : const Color(0xFF2A531D),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Slider
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              activeTrackColor: isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D),
                              inactiveTrackColor: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                              thumbColor: isDark
                                  ? const Color(0xFFA3E635)
                                  : const Color(0xFF2A531D),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                            ),
                            child: Slider(
                              value: _arabicFontSize,
                              min: 18.0,
                              max: 42.0,
                              divisions: 12,
                              onChanged: (val) {
                                _applyFontSizeChange(val, ayahs);
                                setModalState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Increase A+
                        IconButton(
                          onPressed: _arabicFontSize < 42.0
                              ? () {
                                  final newSize = (_arabicFontSize + 2.0).clamp(
                                    18.0,
                                    42.0,
                                  );
                                  _applyFontSizeChange(newSize, ayahs);
                                  setModalState(() {});
                                }
                              : null,
                          icon: Text(
                            'A+',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFE8F5E9),
                            foregroundColor: isDark
                                ? const Color(0xFFA3E635)
                                : const Color(0xFF2A531D),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToActiveAyah(ayahs);
          }
        });
      }
    });

    // Compute standard authentic Mushaf pages for Mode 1 only when Mode 1 is active
    final List<MushafPage> mushafPages = _selectedMode == 1
        ? (_lastComputedMushafPages ??
              _paginateCurrentMushaf(
                context,
                ayahs,
                currentSurah: currentSurah,
              ))
        : const [];

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

    final sp = isJuzMode
        ? storage.getStopPointForJuz(widget.juzNumber!)
        : storage.getStopPointForSurah(widget.surahNumber);
    final int? spAyahNum = sp?['resumeAyahNumber'] as int?;
    final int spTargetIdx = (spAyahNum != null && sp != null)
        ? ayahs.indexWhere(
            (a) =>
                a.numberInSurah == spAyahNum &&
                (!isJuzMode ||
                    sp['surahNumber'] == null ||
                    a.surahNumber == null ||
                    a.surahNumber == sp['surahNumber']),
          )
        : -1;

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
                ? const Color(0xFF0F0F12)
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
                    ? const Color(0xFF18181B)
                    : Colors.white,
                iconColor: effectiveIsDark
                    ? const Color(0xFFF4F4F5)
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
                  // Favorite Toggle for current Surah / Juz
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
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
                                ? const Color(0xFFF4F4F5)
                                : const Color(0xFF2A531D)),
                      size: 20,
                    ),
                    tooltip: isFavorited
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                  ),
                  // Stop Point Flag Button (Shown in Mode 0 & Mode 1, hidden in Continuous Mode 2)
                  if (_selectedMode != 2 && spAyahNum != null && spTargetIdx >= 0)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => _navigateToStopPoint(
                        spAyahNum,
                        spTargetIdx,
                        ayahs,
                      ),
                      icon: const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      tooltip: 'Go to Stop Point (Ayah $spAyahNum)',
                    ),
                  // Surah / Juz Information Button (Shown specifically in Page View Mode 1)
                  if (_selectedMode == 1)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        if (!isJuzMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SurahInfoScreen(surah: currentSurah),
                            ),
                          );
                        } else if (currentJuz != null) {
                          _showJuzInfoModal(
                            context,
                            currentJuz,
                            ayahs,
                            effectiveIsDark,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: effectiveIsDark
                            ? const Color(0xFFF4F4F5)
                            : const Color(0xFF2A531D),
                        size: 20,
                      ),
                      tooltip: isJuzMode
                          ? 'Juz Information'
                          : 'Surah Information & Context',
                    ),
                  // Live Text Resize / Font Size Button (Available only in Mode 0 & Mode 2)
                  if (_selectedMode != 1)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () =>
                          _showFontSizeModal(context, effectiveIsDark, ayahs),
                      icon: Icon(
                        Icons.format_size_rounded,
                        color: effectiveIsDark
                            ? const Color(0xFFF4F4F5)
                            : const Color(0xFF2A531D),
                        size: 20,
                      ),
                      tooltip: 'Arabic Text Size',
                    ),
                  // Dark / Light Mode Toggle Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
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
                      size: 20,
                    ),
                    tooltip: effectiveIsDark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                  ),
                  // Unified Settings & Preferences Button (Includes Display Modes, Translations)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () =>
                        _showSettingsModal(context, effectiveIsDark, ayahs),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: effectiveIsDark
                          ? const Color(0xFFF4F4F5)
                          : const Color(0xFF2A531D),
                      size: 20,
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
                              ayahs,
                              allSurahs,
                              arabicFont,
                            )
                          : _selectedMode == 2
                          ? ListView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                isPlayerActive ? 140 : 24,
                              ),
                              children: [
                                _buildHeaderCard(
                                  currentSurah,
                                  ayahs,
                                  revelationIcon,
                                  effectiveIsDark,
                                  quranAudio,
                                ),
                                const SizedBox(height: 16),
                                _buildContinuousMushafCard(
                                  ayahs,
                                  effectiveIsDark,
                                  playingAyah,
                                  currentSurah,
                                  storage,
                                ),
                                SizedBox(height: isPlayerActive ? 140 : 24),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              cacheExtent: 2000.0,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                isPlayerActive ? 140 : 24,
                              ),
                              itemCount: ayahs.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildHeaderCard(
                                      currentSurah,
                                      ayahs,
                                      revelationIcon,
                                      effectiveIsDark,
                                      quranAudio,
                                    ),
                                  );
                                }
                                final ayahIndex = index - 1;
                                final ayah = ayahs[ayahIndex];
                                final isPlayingThis =
                                    quranAudio.currentIndex == ayahIndex &&
                                    quranAudio.isPlaying;
                                final isSelectedThis =
                                    quranAudio.currentIndex == ayahIndex;
                                final surahNum =
                                    ayah.surahNumber ?? widget.surahNumber;
                                final isMarked = storage
                                    .isAyahMarkedAsStopPoint(
                                      surahNum,
                                      ayah.numberInSurah,
                                      juzNumber: widget.juzNumber,
                                    );
                                final isResumeHighlight =
                                    _highlightResumeAyahNumber != null &&
                                    _highlightResumeAyahNumber ==
                                        ayah.numberInSurah &&
                                    (widget.juzNumber == null ||
                                        (storage.getStopPointForJuz(
                                              widget.juzNumber!,
                                            )?['surahNumber'] ==
                                            surahNum));

                                return _buildVerseCard(
                                  ayah: ayah,
                                  index: ayahIndex,
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
                                        ayahIndex,
                                        title: widget.surahName,
                                        surahNumber: widget.surahNumber,
                                      );
                                      setState(() {
                                        _activeAyahIndex = ayahIndex;
                                      });
                                      _scrollToActiveAyah(ayahs);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // Absolute Positioned Draggable Floating Scrollbar Tab (Right docked, rounded left) for Mode 0 & Mode 2
                if (_selectedMode != 1 && ayahs.length > 2)
                  Positioned(
                    right: 0,
                    top: 4,
                    bottom: isPlayerActive ? 140 : 16,
                    child: FloatingDraggableScrollbar(
                      scrollController: _scrollController,
                      itemCount: ayahs.length,
                      isDark: effectiveIsDark,
                    ),
                  ),

                // Bottom-attached Horizontal Floating Draggable Page Slider for Mode 1 (RTL direction, 10s auto-hide)
                if (_selectedMode == 1 && mushafPages.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: isPlayerActive
                        ? 120
                        : (MediaQuery.of(context).padding.bottom > 0
                              ? MediaQuery.of(context).padding.bottom + 2
                              : 8),
                    child: FloatingDraggablePageSlider(
                      pageController: _pageController,
                      totalPages: mushafPages.length,
                      currentPage: _currentPageIndex,
                      isDark: effectiveIsDark,
                      onPageChanged: (newPage) {
                        setState(() {
                          _currentPageIndex = newPage;
                        });
                      },
                    ),
                  ),

                // Beautiful Loading Overlay while scrolling to target bookmark / stop point
                if (_isNavigatingToTargetAyah)
                  Positioned.fill(
                    child: Container(
                      color:
                          (effectiveIsDark
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
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1C2B22).withValues(
                                  alpha: effectiveIsDark ? 0.15 : 0.1,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 2),
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
      onInfoTap: () {
        if (!isJuzMode) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahInfoScreen(surah: currentSurah),
            ),
          );
        } else if (currentJuz != null) {
          _showJuzInfoModal(context, currentJuz, ayahs, isDark);
        }
      },
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

  void _showJuzInfoModal(
    BuildContext context,
    JuzModel juz,
    List<AyahModel> ayahs,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A531D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FlutterIslamicIcons.quran2,
                      color: Color(0xFF2A531D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Juz ${juz.number} - ${juz.nameEnglish}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          juz.nameArabic,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : const Color(0xFF2A531D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildJuzInfoRow('Surah Range', juz.surahRange, isDark),
                    const Divider(height: 16),
                    _buildJuzInfoRow('Total Verses in Juz', '${ayahs.length} Ayahs', isDark),
                    const Divider(height: 16),
                    _buildJuzInfoRow('Mushaf Page Range', 'Page ${juz.startPage} - ${juz.endPage}', isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJuzInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  /// 3. Mode 1: Authentic Adobe-Style Floating Mushaf Page View (Container-Height Relative True Dynamic Pagination)
  Widget _buildPageWiseMushafView(
    List<MushafPage> initialMushafPages,
    bool isDark,
    SurahModel currentSurah,
    AyahModel? playingAyah,
    bool isPlayerActive,
    dynamic storage,
    List<AyahModel> allAyahs,
    List<SurahModel> allSurahs,
    ArabicFont? arabicFont,
  ) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomSpace = isPlayerActive
        ? (bottomInset + 100.0)
        : (bottomInset + 8.0);

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFE9ECEF),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate exact physical text canvas bounds available inside the card container
          final double cardWidth = (constraints.maxWidth - 16.0).clamp(
            100.0,
            1200.0,
          );
          final double cardHeight = (constraints.maxHeight - 8.0 - bottomSpace)
              .clamp(100.0, 3000.0);

          // Minus card internal padding (16px horizontal, 12px vertical on top & bottom)
          final double textWidth = (cardWidth - 32.0).clamp(80.0, 1160.0);
          final double textHeight = (cardHeight - 24.0).clamp(80.0, 2960.0);

          final mushafPages = MushafPaginationEngine.paginate(
            ayahs: allAyahs,
            surahOrJuzId: widget.juzNumber ?? widget.surahNumber,
            isJuz: widget.juzNumber != null,
            availableWidth: textWidth,
            availableHeight: textHeight,
            fontSize: 24.0,
            arabicFont: arabicFont,
            lineHeight: 1.8,
            defaultSurah: currentSurah,
          );

          _lastComputedMushafPages = mushafPages;

          if (mushafPages.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFFA3E635) : const Color(0xFF2A531D),
                ),
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            reverse: true, // Authentic RTL Mushaf page sliding
            physics: const SmoothMushafPageScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemCount: mushafPages.length,
            itemBuilder: (context, pageIndex) {
              final page = mushafPages[pageIndex];

              return Padding(
                padding: EdgeInsets.fromLTRB(6, 6, 6, bottomSpace),
                child: MushafPageWidget(
                  page: page,
                  currentSurah: currentSurah,
                  playingAyah: playingAyah,
                  isDark: isDark,
                  storage: storage,
                  arabicFontSize: 24.0,
                  arabicFont: arabicFont,
                  juzNumber: widget.juzNumber,
                  highlightResumeAyahNumber: _highlightResumeAyahNumber,
                  selectedAyahIndex: _selectedAyahForHighlight,
                  allAyahs: allAyahs,
                  allSurahs: allSurahs,
                  onAyahTap: (ayah, masterIndex) {
                    setState(() {
                      _selectedAyahForHighlight = masterIndex;
                    });
                    _showAyahQuickActionsSheet(
                      context: context,
                      ayah: ayah,
                      totalAyahs: allAyahs.length,
                      currentSurah: currentSurah,
                      isDark: isDark,
                      quranAudio: ref.read(quranAudioProvider),
                      allAyahs: allAyahs,
                      ayahIndex: masterIndex,
                    ).then((_) {
                      if (mounted) {
                        setState(() {
                          _selectedAyahForHighlight = null;
                        });
                      }
                    });
                  },
                ),
              );
            },
          );
        },
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
    final bool isBookmarked = storage.isAyahBookmarked(
      surahNum,
      ayah.numberInSurah,
    );
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
      onStopPointTap: () => _markStopPoint(ayah, allAyahs.length, ayahSurah),
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

  /// 5. Mode 2: Continuous Flowing Mushaf View with Chunked Performance & Verse Highlighting
  Widget _buildContinuousMushafCard(
    List<AyahModel> ayahs,
    bool isDark,
    AyahModel? playingAyah,
    SurahModel currentSurah,
    dynamic storage,
  ) {
    // Chunk ayahs into smaller blocks of 15 for 60fps smooth scrolling
    final List<List<MapEntry<int, AyahModel>>> chunks = [];
    final allEntries = ayahs.asMap().entries.toList();
    for (int i = 0; i < allEntries.length; i += 15) {
      chunks.add(
        allEntries.sublist(
          i,
          (i + 15 > allEntries.length) ? allEntries.length : i + 15,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: chunks.map((chunk) {
          return SelectableText.rich(
            TextSpan(
              children: chunk.map((entry) {
                final index = entry.key;
                final ayah = entry.value;
                final cleanText = ayah.displayArabicText;
                final isPlayingThis = playingAyah?.number == ayah.number;
                final bool isSajda = ayah.sajda != null && ayah.sajda != false;
                final surahNum = ayah.surahNumber ?? widget.surahNumber;
                final bool isMarked = storage.isAyahMarkedAsStopPoint(
                  surahNum,
                  ayah.numberInSurah,
                  juzNumber: widget.juzNumber,
                );
                final bool isResumeHighlight =
                    _highlightResumeAyahNumber != null &&
                    _highlightResumeAyahNumber == ayah.numberInSurah &&
                    (widget.juzNumber == null ||
                        (storage.getStopPointForJuz(
                              widget.juzNumber!,
                            )?['surahNumber'] ==
                            surahNum));
                final bool isSelected = _selectedAyahForHighlight == index;
                final bool isHighlighted =
                    isPlayingThis || isResumeHighlight || isSelected;

                return TextSpan(
                  children: [
                    // Arabic text with whole-verse highlight & tap
                    TextSpan(
                      text: '$cleanText ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          setState(() {
                            _selectedAyahForHighlight = index;
                          });
                          _showAyahQuickActionsSheet(
                            context: context,
                            ayah: ayah,
                            totalAyahs: ayahs.length,
                            currentSurah: currentSurah,
                            isDark: isDark,
                            quranAudio: ref.read(quranAudioProvider),
                            allAyahs: ayahs,
                            ayahIndex: index,
                          ).then((_) {
                            if (mounted) {
                              setState(() {
                                _selectedAyahForHighlight = null;
                              });
                            }
                          });
                        },
                      style:
                          AppTypography.arabicBody(
                            fontSize: _arabicFontSize,
                            height: 1.97,
                            color: isHighlighted
                                ? (isDark
                                      ? const Color(0xFFA3E635)
                                      : const Color(0xFF854D0E))
                                : (isSajda
                                      ? (isDark
                                            ? const Color(0xFF86EFAC)
                                            : const Color(0xFF166534))
                                      : (isDark
                                            ? const Color(0xFFF1F5F2)
                                            : const Color(0xFF1F2937))),
                          ).copyWith(
                            backgroundColor: isHighlighted
                                ? (isDark
                                      ? const Color(0xFF1E3A2B)
                                      : const Color(0xFFFEF9C3))
                                : (isSajda
                                      ? (isDark
                                            ? const Color(
                                                0xFF14532D,
                                              ).withValues(alpha: 0.35)
                                            : const Color(0xFFFEF3C7))
                                      : null),
                          ),
                    ),
                    // Stop Point Marker Pin on Marked Stop Ayah
                    if (isMarked)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAyahForHighlight = index;
                            });
                            _showAyahQuickActionsSheet(
                              context: context,
                              ayah: ayah,
                              totalAyahs: ayahs.length,
                              currentSurah: currentSurah,
                              isDark: isDark,
                              quranAudio: ref.read(quranAudioProvider),
                              allAyahs: ayahs,
                              ayahIndex: index,
                            ).then((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedAyahForHighlight = null;
                                });
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.all(3),
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
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
          );
        }).toList(),
      ),
    );
  }

  /// 4. Sticky Audio Player Bar
  Widget _buildStickyAudioPlayerBar(
    QuranAudioController quranAudio,
    bool isDark,
  ) {
    return QuranAudioPlayerBar(quranAudio: quranAudio, isDark: isDark);
  }

  /// 5. Navigate directly to marked Stop Point in the current reading mode
  void _navigateToStopPoint(
    int spAyahNum,
    int spTargetIdx,
    List<AyahModel> ayahs,
  ) {
    setState(() {
      _highlightResumeAyahNumber = spAyahNum;
      _activeAyahIndex = spTargetIdx;
    });

    if (_selectedMode == 0) {
      // Verse-by-verse list mode
      _scrollToTargetAyahWithLoading(spTargetIdx, ayahs);
    } else if (_selectedMode == 1) {
      // Page-wise Mushaf mode
      final mushafPages =
          _lastComputedMushafPages ?? _paginateCurrentMushaf(context, ayahs);
      final pageIdx = mushafPages.indexWhere(
        (p) => p.containsMasterAyahIndex(spTargetIdx),
      );
      if (pageIdx >= 0) {
        _currentPageIndex = pageIdx;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            pageIdx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      }
    } else if (_selectedMode == 2) {
      // Continuous Mushaf mode
      _scrollToActiveAyah(ayahs);
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Jumped to Stop Point • Ayah $spAyahNum',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFD97706),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
