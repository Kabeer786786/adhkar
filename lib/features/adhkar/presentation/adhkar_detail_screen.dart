import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/dhikr_item.dart';
import '../../../shared/models/tasbeeh_item.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../../shared/widgets/m3_card.dart';
import '../../../widgets/app_action_popup_menu.dart';
import '../../../widgets/app_header_bar.dart';
import '../../dua/data/dua_repository.dart';
import '../../dua/domain/dua_item.dart';
import '../../quran/repositories/quran_repository.dart';
import '../../quran/presentation/surah_detail_screen.dart';
import '../../tasbeeh/presentation/tasbeeh_detail_screen.dart';
import '../repositories/adhkar_repository.dart';

class AdhkarDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String title;

  const AdhkarDetailScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  @override
  ConsumerState<AdhkarDetailScreen> createState() => _AdhkarDetailScreenState();
}

class _AdhkarDetailScreenState extends ConsumerState<AdhkarDetailScreen>
    with WidgetsBindingObserver {
  List<DhikrItem> _allAdhkar = [];
  List<DhikrItem> _categoryAdhkar = [];
  Map<String, int> _dailyCounts = {};
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late String _todayDateKey;

  // Language state per Dhikr item (for Dua type)
  final Map<String, String> _itemLanguages = {};

  // Audio Playback state
  String? _playingDhikrId;
  StreamSubscription<AudioPlaybackState>? _playerStateSub;
  AppAudioService? _audioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audioService = ref.read(audioServiceProvider);
      _playerStateSub = _audioService?.playbackStateStream.listen((state) {
        if (!mounted) return;
        if (!state.isPlaying && _playingDhikrId != null) {
          setState(() {
            _playingDhikrId = null;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _playerStateSub?.cancel();
    _audioService?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDateAndRefresh();
    }
  }

  void _checkDateAndRefresh() {
    final nowKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (nowKey != _todayDateKey) {
      setState(() {
        _todayDateKey = nowKey;
        _dailyCounts = ref
            .read(storageServiceProvider)
            .getDailyAdhkarCounts(_todayDateKey);
      });
    }
  }

  void _loadData() {
    final storage = ref.read(storageServiceProvider);
    final repo = AdhkarRepository();

    final savedMaps = storage.getSavedAdhkarItems();
    if (savedMaps != null && savedMaps.isNotEmpty) {
      _allAdhkar = savedMaps.map((map) => DhikrItem.fromJson(map)).toList();
      // Ensure all 4 test types in default category exist if previously missing
      final defaultCategoryItems = repo.getAdhkarByCategory(widget.categoryId);
      bool hasNew = false;
      for (final defItem in defaultCategoryItems) {
        if (!_allAdhkar.any((item) => item.id == defItem.id)) {
          _allAdhkar.add(defItem);
          hasNew = true;
        }
      }
      if (hasNew) {
        _persistAdhkar();
      }
    } else {
      _allAdhkar = repo.getAllDefaultAdhkar();
      _persistAdhkar();
    }

    _dailyCounts = storage.getDailyAdhkarCounts(_todayDateKey);
    _filterCategoryItems();
  }

  void _filterCategoryItems() {
    setState(() {
      _categoryAdhkar = _allAdhkar
          .where((item) => item.category == widget.categoryId)
          .toList();
      if (_currentIndex >= _categoryAdhkar.length &&
          _categoryAdhkar.isNotEmpty) {
        _currentIndex = _categoryAdhkar.length - 1;
      }
    });
  }

  void _persistAdhkar() {
    final storage = ref.read(storageServiceProvider);
    final mapList = _allAdhkar.map((i) => i.toJson()).toList();
    storage.saveAdhkarItems(mapList);
  }

  void _incrementCount(String id, int target) {
    final storage = ref.read(storageServiceProvider);
    _checkDateAndRefresh();
    final current = _dailyCounts[id] ?? 0;

    if (current < target) {
      final newCount = current + 1;
      setState(() {
        _dailyCounts[id] = newCount;
      });
      storage.saveDailyAdhkarCount(_todayDateKey, id, newCount);

      if (newCount == target) {
        HapticFeedback.heavyImpact();
        // Smoothly scroll to next dhikr after 450ms if target reached
        if (_currentIndex < _categoryAdhkar.length - 1) {
          Future.delayed(const Duration(milliseconds: 450), () {
            if (mounted && _pageController.hasClients) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _resetCount(String id) {
    final storage = ref.read(storageServiceProvider);
    _checkDateAndRefresh();
    setState(() {
      _dailyCounts[id] = 0;
    });
    storage.saveDailyAdhkarCount(_todayDateKey, id, 0);
    HapticFeedback.mediumImpact();
    AppFloatingToast.showRemoved(context, message: 'Count reset to 0');
  }

  void _saveOrUpdateDhikr(DhikrItem item) {
    final isNew = !_allAdhkar.any((element) => element.id == item.id);
    setState(() {
      final index = _allAdhkar.indexWhere((element) => element.id == item.id);
      if (index >= 0) {
        _allAdhkar[index] = item;
      } else {
        _allAdhkar.add(item);
      }
    });
    _persistAdhkar();
    _filterCategoryItems();
    HapticFeedback.lightImpact();

    if (isNew && _categoryAdhkar.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          final targetIndex = _categoryAdhkar.length - 1;
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _deleteDhikr(String id) {
    setState(() {
      _allAdhkar.removeWhere((element) => element.id == id);
      _dailyCounts.remove(id);
      _itemLanguages.remove(id);
    });
    _persistAdhkar();
    _filterCategoryItems();
    HapticFeedback.mediumImpact();
    AppFloatingToast.showRemoved(context, message: 'Dhikr removed');
  }

  void _confirmDeleteDhikr(DhikrItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? const Color(0xFF27272A) : Colors.transparent,
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Delete Item?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${item.getTitle('en')}"? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteDhikr(item.id);
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleAudio(DhikrItem item) async {
    final audioService = _audioService ?? ref.read(audioServiceProvider);
    if (audioService == null) return;

    if (item.audioUrl == null || item.audioUrl!.isEmpty) {
      AppFloatingToast.showError(
        context,
        message: 'Audio recitation not available for this Dua',
      );
      return;
    }

    if (_playingDhikrId == item.id) {
      await audioService.stop();
      if (mounted) setState(() => _playingDhikrId = null);
    } else {
      setState(() => _playingDhikrId = item.id);
      try {
        final mediaItem = MediaItem(
          id: 'adhkar_dua_${item.id}',
          album: 'Adhkar • ${widget.title}',
          title: item.getTitle('en'),
          artist: 'Dua Recitation',
        );
        await audioService.playUrl(item.audioUrl!, mediaItem: mediaItem);
      } catch (_) {
        if (mounted) {
          setState(() => _playingDhikrId = null);
          AppFloatingToast.showError(
            context,
            message: 'Could not stream audio recitation',
          );
        }
      }
    }
  }

  InputDecoration _roundedDecoration({
    required String labelText,
    String? hintText,
    bool alignLabelWithHint = false,
    bool? isDark,
  }) {
    final dark =
        isDark ??
        (mounted ? Theme.of(context).brightness == Brightness.dark : false);
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: dark ? Colors.white70 : const Color(0xFF4B5563),
        fontSize: 14,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: dark ? Colors.white38 : Colors.grey.shade400,
        fontSize: 13,
      ),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: dark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
          width: 1.8,
        ),
      ),
    );
  }

  void _showAddEditDhikrDialog({DhikrItem? item}) {
    final isEdit = item != null;
    final storage = ref.read(storageServiceProvider);

    // Initial state values
    String selectedType =
        item?.type ?? (item?.isSurah == true ? 'quran' : 'custom');

    // Quran Data
    final surahsList = QuranRepository().getSurahs();
    int? selectedSurahNumber = item?.surahNumber;

    // Dua Data
    final savedDuaMaps = storage.getSavedDuaItems() ?? [];
    final List<DuaItem> userDuas = savedDuaMaps
        .map((m) => DuaItem.fromJson(m))
        .toList();
    final List<DuaItem> defaultDuas = DuaRepository().getDefaultDuas();
    final List<DuaItem> allAvailableDuas = [
      ...userDuas,
      ...defaultDuas.where((d) => !userDuas.any((u) => u.id == d.id)),
    ];
    DuaItem? selectedDua;
    if (item?.duaId != null) {
      try {
        selectedDua = allAvailableDuas.firstWhere((d) => d.id == item!.duaId);
      } catch (_) {}
    }

    // Tasbeeh Data
    final savedTasbeehMaps = storage.getSavedTasbeehItems() ?? [];
    final List<TasbeehItem> userTasbeehs = savedTasbeehMaps
        .map((m) => TasbeehItem.fromJson(m))
        .toList();
    final List<TasbeehItem> allAvailableTasbeehs = [
      ...userTasbeehs,
      ...TasbeehItem.defaults.where(
        (d) => !userTasbeehs.any((u) => u.id == d.id),
      ),
    ];
    TasbeehItem? selectedTasbeeh;
    if (item?.tasbeehId != null) {
      try {
        selectedTasbeeh = allAvailableTasbeehs.firstWhere(
          (t) => t.id == item!.tasbeehId,
        );
      } catch (_) {}
    }

    // Controllers
    final arabicController = TextEditingController(
      text: item?.arabicText ?? '',
    );
    final transliterationController = TextEditingController(
      text: item?.transliteration ?? '',
    );
    final translationController = TextEditingController(
      text: item?.translation ?? '',
    );
    final referenceController = TextEditingController(
      text: item?.reference ?? '',
    );
    final virtueController = TextEditingController(text: item?.virtue ?? '');
    final countController = TextEditingController(
      text: (item?.countTarget ?? 1).toString(),
    );

    // Holding maps for multi-language Duas
    Map<String, String>? duaTitles = item?.titles;
    Map<String, String>? duaTranslations = item?.translations;
    Map<String, String>? duaTransliterations = item?.transliterations;
    Map<String, String>? duaBenefitsMap = item?.benefitsMap;
    String? duaAudioUrl = item?.audioUrl;

    // Surah details holding
    String? surahNameEnglish = item?.surahName;
    String? surahNameArabic = item?.surahNameArabic;
    String? surahMeaning = item?.surahMeaning;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FIXED TOP HEADING
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEdit ? 'Edit Adhkar Item' : 'Add New Dhikr',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2A531D),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF1F5F0),
                  ),

                  // SCROLLABLE FORM BODY
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. TYPE SELECTOR DROPDOWN (Quran, Daily Duaeen, Tasbeeh, Custom Dhikr)
                          DropdownButtonFormField<String>(
                            key: ValueKey('type_selector_$selectedType'),
                            initialValue: selectedType,
                            dropdownColor: isDark
                                ? const Color(0xFF18181B)
                                : Colors.white,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            decoration: _roundedDecoration(
                              labelText: 'Select Dhikr Type *',
                              isDark: isDark,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'quran',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      color: isDark
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF2A531D),
                                      size: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Quran (Surah Recitation)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'dua',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      color: isDark
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFFD97724),
                                      size: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Daily Duaeen',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'tasbeeh',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.touch_app_rounded,
                                      color: isDark
                                          ? const Color(0xFFA78BFA)
                                          : const Color(0xFF2563EB),
                                      size: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Tasbeeh (Dhikr & Counter)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'custom',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF4B5563),
                                      size: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Custom Dhikr',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedType = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // -------------------------------------------------------------
                          // TYPE A: QURAN
                          // -------------------------------------------------------------
                          if (selectedType == 'quran') ...[
                            DropdownButtonFormField<int>(
                              key: ValueKey(
                                'surah_dropdown_$selectedSurahNumber',
                              ),
                              initialValue: selectedSurahNumber,
                              dropdownColor: isDark
                                  ? const Color(0xFF18181B)
                                  : Colors.white,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              decoration: _roundedDecoration(
                                labelText: 'Select Quran Surah *',
                                hintText: 'Choose from 114 Surahs',
                                isDark: isDark,
                              ),
                              isExpanded: true,
                              items: surahsList.map((s) {
                                return DropdownMenuItem<int>(
                                  value: s.number,
                                  child: Text(
                                    'Surah ${s.number}. ${s.nameEnglish} (${s.nameArabic})',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (numVal) {
                                if (numVal != null) {
                                  final s = surahsList.firstWhere(
                                    (element) => element.number == numVal,
                                  );
                                  setModalState(() {
                                    selectedSurahNumber = numVal;
                                    surahNameEnglish = s.nameEnglish;
                                    surahNameArabic = s.nameArabic;
                                    surahMeaning =
                                        '${s.nameTranslation} • ${s.verseCount} Verses • ${s.revelationType}';
                                    arabicController.text = s.nameArabic;
                                    translationController.text =
                                        '${s.nameTranslation} • ${s.verseCount} Verses';
                                    referenceController.text =
                                        'Holy Quran • Surah ${s.nameEnglish} (${s.number}:1-${s.verseCount})';
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // -------------------------------------------------------------
                          // TYPE B: DAILY DUAEEN
                          // -------------------------------------------------------------
                          if (selectedType == 'dua') ...[
                            DropdownButtonFormField<String>(
                              key: ValueKey('dua_dropdown_${selectedDua?.id}'),
                              initialValue: selectedDua?.id,
                              dropdownColor: isDark
                                  ? const Color(0xFF18181B)
                                  : Colors.white,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              decoration: _roundedDecoration(
                                labelText: 'Select Dua from Library *',
                                hintText: 'Choose from library & custom duas',
                                isDark: isDark,
                              ),
                              isExpanded: true,
                              items: allAvailableDuas.map((d) {
                                return DropdownMenuItem<String>(
                                  value: d.id,
                                  child: Text(
                                    d.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (duaId) {
                                if (duaId != null) {
                                  final d = allAvailableDuas.firstWhere(
                                    (element) => element.id == duaId,
                                  );
                                  setModalState(() {
                                    selectedDua = d;
                                    arabicController.text = d.arabic;
                                    transliterationController.text =
                                        d.transliteration;
                                    translationController.text = d.translation;
                                    referenceController.text = d.reference;
                                    virtueController.text = d.benefits;
                                    countController.text = d.repeatCount
                                        .toString();
                                    duaTitles = d.titles;
                                    duaTranslations = d.translations;
                                    duaTransliterations = d.transliterations;
                                    duaBenefitsMap = d.benefitsMap;
                                    duaAudioUrl = d.audioUrl;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // -------------------------------------------------------------
                          // TYPE C: TASBEEH
                          // -------------------------------------------------------------
                          if (selectedType == 'tasbeeh') ...[
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                'tasbeeh_dropdown_${selectedTasbeeh?.id}',
                              ),
                              initialValue: selectedTasbeeh?.id,
                              dropdownColor: isDark
                                  ? const Color(0xFF18181B)
                                  : Colors.white,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              decoration: _roundedDecoration(
                                labelText: 'Select Tasbeeh *',
                                hintText: 'Choose from Tasbeeh presets',
                                isDark: isDark,
                              ),
                              isExpanded: true,
                              items: allAvailableTasbeehs.map((t) {
                                return DropdownMenuItem<String>(
                                  value: t.id,
                                  child: Text(
                                    '${t.textEn} (${t.textAr})',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (tasbeehId) {
                                if (tasbeehId != null) {
                                  final t = allAvailableTasbeehs.firstWhere(
                                    (element) => element.id == tasbeehId,
                                  );
                                  setModalState(() {
                                    selectedTasbeeh = t;
                                    arabicController.text = t.textAr;
                                    translationController.text =
                                        t.effectiveTranslation;
                                    virtueController.text = t.description;
                                    referenceController.text =
                                        'Daily Dhikr & Tasbeeh';
                                    countController.text = t.targetGoal
                                        .toString();
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Arabic Text Display / Input
                          if (selectedType == 'custom') ...[
                            TextField(
                              controller: arabicController,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              maxLines: 3,
                              cursorColor: isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF2A531D),
                              style: AppTypography.arabicBody(
                                fontSize: 20,
                                height: 1.8,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              decoration: _roundedDecoration(
                                labelText: 'Arabic Text *',
                                alignLabelWithHint: true,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: transliterationController,
                              cursorColor: isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF2A531D),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              decoration: _roundedDecoration(
                                labelText: 'Transliteration (Optional)',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: translationController,
                              maxLines: 2,
                              cursorColor: isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF2A531D),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              decoration: _roundedDecoration(
                                labelText: 'Translation (Optional)',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            if (arabicController.text.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F0F12)
                                      : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF27272A)
                                        : const Color(0xFFDCFCE7),
                                  ),
                                ),
                                child: Text(
                                  arabicController.text,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: AppTypography.arabicBody(
                                    fontSize: 20,
                                    color: isDark
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFF1E3A14),
                                  ),
                                ),
                              ),
                          ],

                          // Reference field (Editable)
                          TextField(
                            controller: referenceController,
                            cursorColor: isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF2A531D),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            decoration: _roundedDecoration(
                              labelText: 'Reference (Optional)',
                              hintText: 'e.g. Sahih al-Bukhari',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Spiritual Benefits / Virtues field (Editable)
                          TextField(
                            controller: virtueController,
                            maxLines: 2,
                            cursorColor: isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF2A531D),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            decoration: _roundedDecoration(
                              labelText:
                                  'Virtues & Spiritual Benefits (Optional)',
                              hintText:
                                  'e.g. Protection, immense reward & peace',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Target Count Input
                          TextField(
                            controller: countController,
                            keyboardType: TextInputType.number,
                            cursorColor: isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF2A531D),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) {
                              setModalState(() {});
                            },
                            decoration: _roundedDecoration(
                              labelText: 'Target Recitation Count *',
                              hintText: 'e.g. 1, 3, 7, 33, 100',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Quick Count Preset Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [1, 3, 7, 10, 33, 99, 100].map((
                                presetVal,
                              ) {
                                final isSelected =
                                    countController.text.trim() ==
                                    presetVal.toString();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text('$presetVal x'),
                                    selected: isSelected,
                                    selectedColor: isDark
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFF2A531D),
                                    backgroundColor: isDark
                                        ? const Color(0xFF27272A)
                                        : const Color(0xFFF3F4F6),
                                    checkmarkColor: isDark
                                        ? const Color(0xFF0F0F12)
                                        : Colors.white,
                                    side: BorderSide(
                                      color: isSelected
                                          ? (isDark
                                                ? const Color(0xFF86EFAC)
                                                : const Color(0xFF2A531D))
                                          : (isDark
                                                ? const Color(0xFF3F3F46)
                                                : const Color(0xFFE5E7EB)),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? (isDark
                                                ? const Color(0xFF0F0F12)
                                                : Colors.white)
                                          : (isDark
                                                ? Colors.white
                                                : const Color(0xFF2A531D)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setModalState(() {
                                          countController.text = presetVal
                                              .toString();
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // FIXED BOTTOM BUTTON
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF1F5F0),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (selectedType == 'quran' &&
                              selectedSurahNumber == null) {
                            AppFloatingToast.showError(
                              context,
                              message: 'Please select a Quran Surah',
                            );
                            return;
                          }
                          if (selectedType == 'custom' &&
                              arabicController.text.trim().isEmpty) {
                            AppFloatingToast.showError(
                              context,
                              message:
                                  'Please enter Arabic text for custom Dhikr',
                            );
                            return;
                          }

                          final parsedTarget = int.tryParse(
                            countController.text.trim(),
                          );
                          final finalTarget =
                              (parsedTarget != null && parsedTarget > 0)
                              ? parsedTarget
                              : 1;

                          final newItem = DhikrItem(
                            id:
                                item?.id ??
                                'dhikr_${DateTime.now().millisecondsSinceEpoch}',
                            category: widget.categoryId,
                            arabicText: arabicController.text.trim(),
                            transliteration: transliterationController.text
                                .trim(),
                            translation: translationController.text.trim(),
                            reference: referenceController.text.trim().isEmpty
                                ? (selectedType == 'quran'
                                      ? 'Holy Quran'
                                      : 'Adhkar & Supplication')
                                : referenceController.text.trim(),
                            virtue: virtueController.text.trim(),
                            countTarget: finalTarget,
                            type: selectedType,
                            surahNumber: selectedSurahNumber,
                            surahName: surahNameEnglish,
                            surahNameArabic: surahNameArabic,
                            surahMeaning: surahMeaning,
                            duaId: selectedDua?.id,
                            titles: duaTitles,
                            translations: duaTranslations,
                            transliterations: duaTransliterations,
                            benefitsMap: duaBenefitsMap,
                            audioUrl: duaAudioUrl,
                            tasbeehId: selectedTasbeeh?.id,
                            tasbeehName: selectedTasbeeh?.textEn,
                          );

                          _saveOrUpdateDhikr(newItem);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          isEdit ? Icons.save_rounded : Icons.add_rounded,
                        ),
                        label: Text(
                          isEdit ? 'Save Changes' : 'Add to Adhkar',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF18A74C)
                              : const Color(0xFF2A531D),
                          foregroundColor: isDark
                              ? const Color(0xFF0F0F12)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
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

  Widget _buildDuaLangChip(String itemId, String langCode, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = _itemLanguages[itemId] ?? 'en';
    final isSelected = currentLang == langCode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _itemLanguages[itemId] = langCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF14532D))
              : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF14532D))
                : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? (isDark ? const Color(0xFF0F0F12) : Colors.white)
                : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F12)
          : const Color(0xFFF8FAF7),
      appBar: AppHeaderBar(
        title: widget.title,
        showBackButton: true,
        showDrawerButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 26),
            tooltip: 'Add Dua / Dhikr',
            onPressed: () => _showAddEditDhikrDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _categoryAdhkar.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF2A531D).withValues(alpha: 0.12)
                            : const Color(0xFFE8F4E5).withValues(alpha: 0.6),
                      ),
                      child: Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(
                                    0xFF2A531D,
                                  ).withValues(alpha: 0.25)
                                : const Color(
                                    0xFFD4EBD0,
                                  ).withValues(alpha: 0.8),
                          ),
                          child: Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2A531D),
                                    Color(0xFF14532D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF14532D,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.library_books_rounded,
                                size: 34,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'No Dhikrs in this Folder',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2A531D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Quran Surahs, Daily Duaeen, Tasbeehs, or custom Dhikrs to this section.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF14532D,
                            ).withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditDhikrDialog(),
                        icon: const Icon(Icons.add_rounded, size: 22),
                        label: const Text(
                          'Add Dhikr to Folder',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF18A74C)
                              : const Color(0xFF2A531D),
                          foregroundColor: isDark
                              ? const Color(0xFF0F0F12)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Main Smooth Horizontal Scrollable PageView (Single Screen Per Dhikr)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _categoryAdhkar.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                      HapticFeedback.selectionClick();
                    },
                    itemBuilder: (context, index) {
                      final item = _categoryAdhkar[index];
                      final currentCount = _dailyCounts[item.id] ?? 0;
                      final isDone = currentCount >= item.countTarget;
                      final activeLang = _itemLanguages[item.id] ?? 'en';
                      final isPlayingAudio = _playingDhikrId == item.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: M3Card(
                          color: isDark
                              ? const Color(0xFF18181B)
                              : Colors.white,
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF14532D).withValues(alpha: 0.8)
                                : (isDark
                                      ? const Color(0xFF27272A)
                                      : const Color(0xFFE5E7EB)),
                            width: isDone ? 1.6 : 1.0,
                          ),
                          margin: EdgeInsets.zero,
                          padding: EdgeInsets.zero,
                          borderRadius: 24,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                // 1. SCROLLABLE BODY CONTENT
                                Positioned.fill(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(
                                      18,
                                      item.isDua ? 110 : 70,
                                      18,
                                      80,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // -------------------------------------------------------------
                                        // BODY CONTENT BASED ON TYPE
                                        // -------------------------------------------------------------
                                        if (item.isQuran)
                                          _buildQuranCardContent(item)
                                        else if (item.isDua)
                                          _buildDuaCardContent(item, activeLang)
                                        else if (item.isTasbeeh)
                                          _buildTasbeehCardContent(item)
                                        else
                                          _buildCustomCardContent(item),
                                      ],
                                    ),
                                  ),
                                ),

                                // 2. FLOATING TOP BAR: PILLS (TYPE + RECITE) & ACTIONS (AUDIO + 3-DOTS)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  right: 12,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Left Floating Pills
                                      Row(
                                        children: [
                                          const SizedBox(width: 6),
                                          _buildTypeBadge(item),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF27272A)
                                                  : const Color(0xFFE8F4E5),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF3F3F46)
                                                    : const Color(0xFFC8E6C9),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              'Recite ${item.countTarget}x',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? const Color(0xFF86EFAC)
                                                    : const Color(0xFF2A531D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Right Floating Actions & 3-Dots
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (item.isDua &&
                                              item.audioUrl != null &&
                                              item.audioUrl!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _toggleAudio(item),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: Icon(
                                                      isPlayingAudio
                                                          ? Icons
                                                                .pause_circle_filled_rounded
                                                          : Icons
                                                                .volume_up_rounded,
                                                      color: isPlayingAudio
                                                          ? const Color(
                                                              0xFFD97724,
                                                            )
                                                          : const Color(
                                                              0xFF2A531D,
                                                            ),
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // Floating 3-Dots Popup Menu Button
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : const Color(0xFFF3F4F6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: AppActionPopupMenu<String>(
                                              items: const [
                                                AppActionMenuItem(
                                                  value: 'edit',
                                                  title: 'Edit Item',
                                                  icon: Icons.edit_outlined,
                                                ),
                                                AppActionMenuItem(
                                                  value: 'reset',
                                                  title: 'Reset Count',
                                                  icon: Icons.refresh_rounded,
                                                ),
                                                AppActionMenuItem(
                                                  value: 'delete',
                                                  title: 'Delete Item',
                                                  icon: Icons
                                                      .delete_outline_rounded,
                                                  isDestructive: true,
                                                ),
                                              ],
                                              onSelected: (val) {
                                                if (val == 'edit') {
                                                  _showAddEditDhikrDialog(
                                                    item: item,
                                                  );
                                                } else if (val == 'reset') {
                                                  _resetCount(item.id);
                                                } else if (val == 'delete') {
                                                  _confirmDeleteDhikr(item);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 2b. FLOATING LANGUAGE CHIPS (BELOW 3-DOTS FOR DAILY DUA)
                                if (item.isDua)
                                  Positioned(
                                    top: 70,
                                    right: 14,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(
                                                0xFF18181B,
                                              ).withValues(alpha: 0.94)
                                            : Colors.white.withValues(
                                                alpha: 0.94,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF27272A)
                                              : const Color(0xFFE5E7EB),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildDuaLangChip(
                                            item.id,
                                            'en',
                                            'EN',
                                          ),
                                          _buildDuaLangChip(
                                            item.id,
                                            'ur',
                                            'UR',
                                          ),
                                          _buildDuaLangChip(
                                            item.id,
                                            'hi',
                                            'HI',
                                          ),
                                          _buildDuaLangChip(
                                            item.id,
                                            'te',
                                            'TE',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // 3. FLOATING BOTTOM BUTTONS: RESET & CYLINDRICAL COUNTER
                                Positioned(
                                  bottom: 14,
                                  right: 14,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Floating Reset Button
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            _resetCount(item.id);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDark
                                                  ? const Color(0xFF18181B)
                                                  : Colors.white,
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF27272A)
                                                    : const Color(0xFFE5E7EB),
                                                width: 1.2,
                                              ),
                                              // boxShadow: [
                                              //   BoxShadow(
                                              //     color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.09),
                                              //     blurRadius: 10,
                                              //     offset: const Offset(0, 3),
                                              //   ),
                                              // ],
                                            ),
                                            child: Icon(
                                              Icons.refresh_rounded,
                                              size: 20,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF4B5563),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Floating Cylindrical Counter Button (Yellow Pending -> Green Complete)
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _incrementCount(
                                            item.id,
                                            item.countTarget,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              gradient: isDone
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF166534),
                                                        Color(0xFF14532D),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    )
                                                  : const LinearGradient(
                                                      colors: [
                                                        Color(0xFFFBBF24),
                                                        Color(0xFFEAB308),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                              border: Border.all(
                                                color: isDone
                                                    ? const Color(
                                                        0xFF15803D,
                                                      ).withValues(alpha: 0.8)
                                                    : const Color(
                                                        0xFFFDE68A,
                                                      ).withValues(alpha: 0.6),
                                                width: 1.2,
                                              ),
                                              // boxShadow: [
                                              //   BoxShadow(
                                              //     color: (isDone
                                              //             ? const Color(0xFF16A34A)
                                              //             : const Color(0xFFEAB308))
                                              //         .withValues(alpha: 0.45),
                                              //     blurRadius: 14,
                                              //     offset: const Offset(0, 4),
                                              //   ),
                                              // ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isDone
                                                      ? Icons
                                                            .check_circle_rounded
                                                      : Icons.add_rounded,
                                                  size: 21,
                                                  color: isDone
                                                      ? Colors.white
                                                      : const Color(0xFF78350F),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '$currentCount / ${item.countTarget}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDone
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF78350F,
                                                          ),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
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
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Circles / Page Indicator Dots
                if (_categoryAdhkar.length > 1)
                  Container(
                    padding: EdgeInsets.only(
                      top: 14,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_categoryAdhkar.length, (
                        dotIndex,
                      ) {
                        final isSelected = dotIndex == _currentIndex;
                        final dhikr = _categoryAdhkar[dotIndex];
                        final isCompleted =
                            (_dailyCounts[dhikr.id] ?? 0) >= dhikr.countTarget;

                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              dotIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isSelected ? 22 : 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isSelected
                                  ? (isDark
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFF2A531D))
                                  : (isCompleted
                                        ? (isDark
                                              ? const Color(0xFF166534)
                                              : const Color(0xFF14532D))
                                        : (isDark
                                              ? const Color(0xFF27272A)
                                              : Colors.grey.shade300)),
                            ),
                          ),
                        );
                      }),
                    ),
                  )
                else
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
    );
  }

  Widget _buildTypeBadge(DhikrItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (item.isQuran) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C2A44) : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(10),
          border: isDark
              ? Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 12,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
            ),
            const SizedBox(width: 4),
            Text(
              'Quran',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFF0369A1),
              ),
            ),
          ],
        ),
      );
    } else if (item.isDua) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF38230B) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: isDark
              ? Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.4),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 12,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
            ),
            const SizedBox(width: 4),
            Text(
              'Daily Dua',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    } else if (item.isTasbeeh) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(10),
          border: isDark
              ? Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 12,
              color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9),
            ),
            const SizedBox(width: 4),
            Text(
              'Tasbeeh',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFA78BFA)
                    : const Color(0xFF6D28D9),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: isDark
            ? Border.all(color: const Color(0xFF3F3F46), width: 0.8)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 12,
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
          ),
          const SizedBox(width: 4),
          Text(
            'Custom Dhikr',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  // 1. QURAN CARD CONTENT
  Widget _buildQuranCardContent(DhikrItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah Name & Meaning Header
        Text(
          'Surah ${item.surahName ?? "Surah"}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2A531D),
          ),
        ),
        if (item.surahMeaning != null && item.surahMeaning!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            item.surahMeaning!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Arabic Name / Script Display
        if (item.arabicText.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.arabicText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicHeader(
                fontSize: 26,
                color: isDark
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFF1B5E20),
                height: 1.8,
              ),
            ),
          ),
        const SizedBox(height: 14),

        // Read Surah CTA Button
        if (item.surahNumber != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahDetailScreen(
                      surahNumber: item.surahNumber!,
                      surahName: item.surahName ?? 'Surah',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: Text(
                'Read Surah ${item.surahName ?? ""} in Quran',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF166534)
                    : const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
              ),
            ),
          ),

        // Reference & Benefits
        if (item.reference.isNotEmpty) _buildReferenceBox(item.reference),
        if (item.virtue.isNotEmpty) _buildBenefitsBox(item.virtue),
      ],
    );
  }

  // 2. DAILY DUA CARD CONTENT (Same structure as DuaDetailScreen)
  Widget _buildDuaCardContent(DhikrItem item, String activeLang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Title in Selected Language
        Text(
          item.getTitle(activeLang),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2A531D),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),

        // Large Arabic Text
        Text(
          item.arabicText,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTypography.arabicHeader(
            fontSize: 25,
            height: 1.8,
            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1A3512),
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),

        // Transliteration in Selected Language
        if (item.getTransliteration(activeLang).isNotEmpty) ...[
          Text(
            item.getTransliteration(activeLang),
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Translation in Selected Language
        Text(
          item.getTranslation(activeLang),
          style: GoogleFonts.lexend(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 14),

        // Reference Section
        if (item.reference.isNotEmpty) _buildReferenceBox(item.reference),

        // Spiritual & Practical Benefits Section
        if (item.getBenefits(activeLang).isNotEmpty)
          _buildBenefitsBox(item.getBenefits(activeLang)),
      ],
    );
  }

  // 3. TASBEEH CARD CONTENT
  Widget _buildTasbeehCardContent(DhikrItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.tasbeehName ?? item.getTitle('en'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2A531D),
          ),
        ),
        const SizedBox(height: 14),

        // Arabic Script
        Text(
          item.arabicText,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTypography.arabicHeader(
            fontSize: 27,
            height: 1.8,
            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1A3512),
          ),
        ),
        const SizedBox(height: 12),

        // Translation
        if (item.translation.isNotEmpty) ...[
          Text(
            item.translation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Center CTA Button: Go to this Tasbeeh
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ElevatedButton.icon(
            onPressed: () {
              final tasbeeh = TasbeehItem(
                id: item.tasbeehId ?? item.id,
                textAr: item.arabicText,
                textEn: item.tasbeehName ?? item.getTitle('en'),
                translation: item.translation,
                description: item.virtue,
                targetGoal: item.countTarget,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TasbeehDetailScreen(item: tasbeeh),
                ),
              );
            },
            icon: const Icon(Icons.touch_app_rounded, size: 20),
            label: const Text(
              'Open in Digital Tasbeeh Counter',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF166534)
                  : const Color(0xFF14532D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF14532D).withValues(alpha: 0.4),
            ),
          ),
        ),

        if (item.reference.isNotEmpty) _buildReferenceBox(item.reference),
        if (item.virtue.isNotEmpty) _buildBenefitsBox(item.virtue),
      ],
    );
  }

  // 4. CUSTOM CARD CONTENT
  Widget _buildCustomCardContent(DhikrItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Arabic Script Display
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            item.arabicText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTypography.arabicBody(
              fontSize: 24,
              height: 2.0,
              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SizedBox(height: 12),

        // Transliteration
        if (item.transliteration.isNotEmpty) ...[
          Text(
            item.transliteration,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD1D5DB) : Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Translation
        if (item.translation.isNotEmpty) ...[
          Text(
            item.translation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (item.reference.isNotEmpty) _buildReferenceBox(item.reference),
        if (item.virtue.isNotEmpty) _buildBenefitsBox(item.virtue),
      ],
    );
  }

  Widget _buildReferenceBox(String reference) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFFEF3C7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFERENCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reference,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white : const Color(0xFF78350F),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsBox(String benefits) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3E8FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPIRITUAL & PRACTICAL BENEFITS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            benefits,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white : const Color(0xFF581C87),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
