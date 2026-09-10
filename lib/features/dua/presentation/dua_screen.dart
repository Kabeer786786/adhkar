import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../../widgets/app_header_bar.dart';
import '../data/dua_repository.dart';
import '../domain/dua_item.dart';
import 'dua_detail_screen.dart';
import 'widgets/dua_library_modal.dart';

class DuaScreen extends ConsumerStatefulWidget {
  const DuaScreen({super.key});

  @override
  ConsumerState<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends ConsumerState<DuaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DuaRepository _repository = DuaRepository();
  List<DuaItem> _allDuas = [];
  List<DuaItem> _filteredDuas = [];
  final Set<String> _selectedCategories = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};

  // Language Preferences
  String _primaryLanguage = 'en';
  Set<String> _selectedLanguages = {'en'};

  final List<String> _categories = [
    'Morning',
    'Sleep',
    'Food',
    'Travel',
    'Protection',
    'Hygiene',
    'Prayer',
    'Forgiveness',
    'General',
  ];

  static ({List<Color> colors, Color textColor}) _getCategoryPreset(
      String category) {
    switch (category.trim().toLowerCase()) {
      case 'morning':
      case 'food':
        return (
          colors: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          textColor: const Color(0xFFB45309),
        );
      case 'sleep':
        return (
          colors: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          textColor: const Color(0xFF1E3A8A),
        );
      case 'hygiene':
        return (
          colors: const [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
          textColor: const Color(0xFFDB2777),
        );
      case 'travel':
        return (
          colors: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          textColor: const Color(0xFF047857),
        );
      case 'protection':
        return (
          colors: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          textColor: const Color(0xFF7E22CE),
        );
      case 'prayer':
      case 'adhan':
      case 'mosque':
        return (
          colors: const [Color(0xFFF4FAF3), Color(0xFFEAF5E8)],
          textColor: const Color(0xFF1B5E20),
        );
      case 'forgiveness':
        return (
          colors: const [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
          textColor: const Color(0xFF0F766E),
        );
      case 'healing':
        return (
          colors: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          textColor: const Color(0xFF065F46),
        );
      case 'guidance':
        return (
          colors: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          textColor: const Color(0xFF4338CA),
        );
      case 'family':
      case 'marriage':
        return (
          colors: const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          textColor: const Color(0xFFBE123C),
        );
      case 'distress':
        return (
          colors: const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          textColor: const Color(0xFF475569),
        );
      case 'sustenance':
        return (
          colors: const [Color(0xFFFEFCE8), Color(0xFFFEF08A)],
          textColor: const Color(0xFF854D0E),
        );
      case 'hajj':
        return (
          colors: const [Color(0xFFFAF6F0), Color(0xFFF3EAD8)],
          textColor: const Color(0xFF78350F),
        );
      case 'dhikr':
        return (
          colors: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
          textColor: const Color(0xFF6D28D9),
        );
      default:
        return (
          colors: const [Color(0xFFF4FAF3), Color(0xFFEAF5E8)],
          textColor: const Color(0xFF1B5E20),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _initDuasSynchronously();
    _loadDuas();
    _searchController.addListener(_filterDuas);
  }

  void _initDuasSynchronously() {
    final storage = ref.read(storageServiceProvider);

    // 1. Synchronously load saved language
    final savedLangs = storage.getGenericData('dua_selected_languages');
    if (savedLangs is List && savedLangs.isNotEmpty) {
      _selectedLanguages =
          Set<String>.from(savedLangs.map((e) => e.toString()));
      _primaryLanguage = _selectedLanguages.first;
    } else {
      final savedPrimary = storage.getGenericData('dua_primary_language');
      if (savedPrimary is String && savedPrimary.isNotEmpty) {
        _primaryLanguage = savedPrimary;
        _selectedLanguages = {savedPrimary};
      }
    }

    // 2. Synchronously load cached Duas (Zero-latency, zero-flicker)
    final savedItemMaps = storage.getSavedDuaItems();
    if (savedItemMaps != null && savedItemMaps.isNotEmpty) {
      _allDuas = savedItemMaps.map((m) => DuaItem.fromJson(m)).toList();
    } else {
      // First time user: show top 10 important Duas immediately
      _allDuas = _repository.getDefaultDuas().take(10).toList();
      _persistDuas();
    }
    _filterDuas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDuas() async {
    final storage = ref.read(storageServiceProvider);

    // 1. SharedPreferences backup for language
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefLang = prefs.getString('dua_primary_language');
      if (prefLang != null &&
          prefLang.isNotEmpty &&
          prefLang != _primaryLanguage) {
        if (mounted) {
          setState(() {
            _primaryLanguage = prefLang;
            _selectedLanguages = {prefLang};
          });
          _filterDuas();
        }
      }
    } catch (_) {}

    // 2. Pre-cache all 197 Duas in memory for the Dua Library modal
    final allJsonDuas = await _repository.loadAllDuas();

    // 3. If storage was empty, initialize with top 10 important Duas
    final savedItemMaps = storage.getSavedDuaItems();
    if (savedItemMaps == null || savedItemMaps.isEmpty) {
      if (mounted) {
        setState(() {
          _allDuas = allJsonDuas.take(10).toList();
        });
        _persistDuas();
        _filterDuas();
      }
    }
  }

  void _persistDuas() {
    final storage = ref.read(storageServiceProvider);
    final maps = _allDuas.map((d) => d.toJson()).toList();
    storage.saveDuaItems(maps);
  }


  void _confirmDeleteSelected(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _selectedIds.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Dua${count > 1 ? 's' : ''}?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Are you sure you want to delete $count selected Dua${count > 1 ? 's' : ''}?',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.lexend(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _allDuas.removeWhere((d) => _selectedIds.contains(d.id));
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
                _persistDuas();
                _filterDuas();
                Navigator.pop(context);
                AppFloatingToast.showRemoved(
                  context,
                  message: '$count Dua${count > 1 ? 's' : ''} deleted',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _filterDuas() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredDuas = _allDuas.where((dua) {
        final matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(dua.category);
        final matchesQuery = query.isEmpty ||
            dua.getTitle(_primaryLanguage).toLowerCase().contains(query) ||
            dua.arabic.contains(query) ||
            dua
                .getTransliteration(_primaryLanguage)
                .toLowerCase()
                .contains(query) ||
            dua
                .getTranslation(_primaryLanguage)
                .toLowerCase()
                .contains(query) ||
            dua.reference.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  Future<void> _openDuaLibraryModal() async {
    final allDuas = await _repository.loadAllDuas();
    if (!mounted) return;

    DuaLibraryModal.show(
      context,
      currentDuas: _allDuas,
      defaultDuas: allDuas,
      onAddDua: (dua) {
        setState(() {
          if (!_allDuas.any((d) => d.id == dua.id)) {
            _allDuas.add(dua);
          }
        });
        _persistDuas();
        _filterDuas();
      },
      onRemoveDua: (duaId) {
        setState(() {
          _allDuas.removeWhere((d) => d.id == duaId);
        });
        _persistDuas();
        _filterDuas();
      },
      onCreateCustom: (customDua) {
        setState(() {
          _allDuas.add(customDua);
        });
        _persistDuas();
        _filterDuas();
      },
    );
  }

  void _showLanguagePreferenceModal() {
    final availableLanguages = [
      {'code': 'en', 'name': 'English', 'native': 'English'},
      {'code': 'ur', 'name': 'Urdu', 'native': 'اردو'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.88,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Language Preferences',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A531D),
                          ),
                        ),
                        const Icon(
                          Icons.translate_rounded,
                          color: Color(0xFF2A531D),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select your preferred language. All titles and translations will be displayed in the chosen language.',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: availableLanguages.length,
                        itemBuilder: (context, index) {
                          final lang = availableLanguages[index];
                          final code = lang['code']!;
                          final isSelected = _primaryLanguage == code;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2A531D)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onTap: () async {
                                setSheetState(() {
                                  _primaryLanguage = code;
                                  _selectedLanguages = {code};
                                });
                                setState(() {});
                                final storage =
                                    ref.read(storageServiceProvider);
                                await storage.saveGenericData(
                                  'dua_selected_languages',
                                  _selectedLanguages.toList(),
                                );
                                await storage.saveGenericData(
                                  'dua_primary_language',
                                  code,
                                );
                                try {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                      'dua_primary_language', code);
                                } catch (_) {}
                                _filterDuas();
                              },
                              title: Text(
                                lang['name']!,
                                style: GoogleFonts.lexend(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF2A531D)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text(
                                lang['native']!,
                                style: GoogleFonts.lexend(
                                  fontSize: 12.5,
                                  color: isSelected
                                      ? const Color(0xFF2A531D)
                                          .withValues(alpha: 0.8)
                                      : Colors.grey.shade600,
                                ),
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? const Color(0xFF2A531D)
                                    : Colors.grey.shade400,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A531D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                      ),
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

  void _showCategoryFilterModal() {
    final tempSelected = Set<String>.from(_selectedCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allSelected = tempSelected.length == _categories.length;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              if (allSelected) {
                                tempSelected.clear();
                              } else {
                                tempSelected.addAll(_categories);
                              }
                            });
                          },
                          child: Text(
                            allSelected ? 'Clear All' : 'Select All',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A531D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _categories.map((category) {
                            final isSelected = tempSelected.contains(category);
                            final preset = _getCategoryPreset(category);

                            return FilterChip(
                              label: Text(category),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? preset.textColor
                                    : const Color(0xFF334155),
                              ),
                              selected: isSelected,
                              selectedColor: preset.colors.last,
                              backgroundColor: const Color(0xFFF8FAFC),
                              checkmarkColor: preset.textColor,
                              side: BorderSide(
                                color: isSelected
                                    ? preset.textColor
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempSelected.add(category);
                                  } else {
                                    tempSelected.remove(category);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories.clear();
                          _selectedCategories.addAll(tempSelected);
                        });
                        _filterDuas();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A531D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color primaryGreen,
  ) {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedIds.clear();
            });
          },
        ),
        title: Text(
          '${_selectedIds.length} Selected',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
            ),
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _confirmDeleteSelected(context),
            tooltip: 'Delete Selected',
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    return AppHeaderBar(
      title: 'DAILY DUAS',
      showBackButton: true,
      centerTitle: true,
      titleSpacing: 0,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.translate_rounded,
            color: Color(0xFF2A531D),
            size: 22,
          ),
          tooltip: 'Language Preferences',
          onPressed: _showLanguagePreferenceModal,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  String _getLanguageShortLabel(String lang) {
    switch (lang) {
      case 'ur':
        return 'UR';
      case 'hi':
        return 'HI';
      case 'te':
        return 'TE';
      case 'en':
      default:
        return 'EN';
    }
  }

  List<Widget> _buildCardTranslations(DuaItem dua) {
    if (_selectedLanguages.length <= 1) {
      final trans = dua.getTranslation(_primaryLanguage);
      if (trans.isEmpty) return const [];
      return [
        Text(
          trans,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lexend(
            fontSize: 11.5,
            letterSpacing: -0.1,
            color: Colors.black87,
            height: 1.35,
          ),
        ),
      ];
    }

    // Multiple languages selected
    return _selectedLanguages.map((lang) {
      final trans = dua.getTranslation(lang);
      if (trans.isEmpty) return const SizedBox.shrink();
      final langLabel = _getLanguageShortLabel(lang);

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF2A531D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Text(
                langLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFF2A531D),
                ),
              ),
            ),
            Expanded(
              child: Text(
                trans,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexend(
                  fontSize: 11.5,
                  letterSpacing: -0.1,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final isAllSelected = _filteredDuas.isNotEmpty &&
        _selectedIds.length == _filteredDuas.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, isDark, textColor, primaryGreen),
      body: Column(
        children: [
          // Search & Filter Bar Container (hidden in selection mode)
          if (!_isSelectionMode)
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search Dua by title, meaning, or topic...',
                        hintStyle: TextStyle(
                            fontSize: 13.5, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF2A531D)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 20, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF2A531D), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Filter Button beside Search Bar
                  InkWell(
                    onTap: _showCategoryFilterModal,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _selectedCategories.isNotEmpty
                            ? const Color(0xFF2A531D)
                            : const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedCategories.isNotEmpty
                              ? const Color(0xFF2A531D)
                              : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 22,
                            color: _selectedCategories.isNotEmpty
                                ? Colors.white
                                : const Color(0xFF2A531D),
                          ),
                          if (_selectedCategories.isNotEmpty)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD97724),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${_selectedCategories.length}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Select All Toggle Bar (shown when selection mode is active)
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color:
                  isDark ? const Color(0xFF1B2A20) : const Color(0xFFF1F5F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT DUAS',
                    style: GoogleFonts.lexend(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isAllSelected) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds.addAll(_filteredDuas.map((d) => d.id));
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAllSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAllSelected ? 'Deselect All' : 'Select All',
                            style: GoogleFonts.lexend(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Duas List
          Expanded(
            child: _filteredDuas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Duas Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + Add Dua to browse library or create custom Dua',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openDuaLibraryModal,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Dua'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A531D),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 6,
                      bottom: 80,
                    ),
                    itemCount: _filteredDuas.length,
                    itemBuilder: (context, index) {
                      final dua = _filteredDuas[index];
                      final gradientPreset = _getCategoryPreset(dua.category);
                      final isSelected = _selectedIds.contains(dua.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              if (_isSelectionMode) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(dua.id);
                                    if (_selectedIds.isEmpty) {
                                      _isSelectionMode = false;
                                    }
                                  } else {
                                    _selectedIds.add(dua.id);
                                  }
                                });
                              } else {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DuaDetailScreen(
                                      dua: dua,
                                      selectedLanguage: _primaryLanguage,
                                      onDelete: () {
                                        setState(() {
                                          _allDuas.removeWhere(
                                              (d) => d.id == dua.id);
                                        });
                                        _persistDuas();
                                        _filterDuas();
                                      },
                                      onSave: (updatedDua) {
                                        setState(() {
                                          final idx = _allDuas.indexWhere(
                                              (d) => d.id == updatedDua.id);
                                          if (idx != -1) {
                                            _allDuas[idx] = updatedDua;
                                          } else {
                                            _allDuas.add(updatedDua);
                                          }
                                        });
                                        _persistDuas();
                                        _filterDuas();
                                      },
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  final storage =
                                      ref.read(storageServiceProvider);
                                  final savedLangs = storage.getGenericData(
                                      'dua_selected_languages');
                                  if (savedLangs is List &&
                                      savedLangs.isNotEmpty) {
                                    final newLang =
                                        savedLangs.first.toString();
                                    if (newLang != _primaryLanguage) {
                                      setState(() {
                                        _primaryLanguage = newLang;
                                        _selectedLanguages = {newLang};
                                      });
                                      _filterDuas();
                                    }
                                  }
                                }
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                _isSelectionMode = true;
                                if (isSelected) {
                                  _selectedIds.remove(dua.id);
                                  if (_selectedIds.isEmpty) {
                                    _isSelectionMode = false;
                                  }
                                } else {
                                  _selectedIds.add(dua.id);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: gradientPreset.colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientPreset.textColor
                                        .withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: isSelected
                                      ? primaryGreen
                                      : gradientPreset.textColor
                                          .withValues(alpha: 0.15),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Category Pill
                                  Positioned(
                                    top: 12,
                                    left: _isSelectionMode ? 44 : 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: gradientPreset.textColor
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dua.category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                          color: gradientPreset.textColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Background Illustration Image
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: IgnorePointer(
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        padding: const EdgeInsets.all(4),
                                        child: Opacity(
                                          opacity: 0.85,
                                          child: Image.asset(
                                            dua.imagePath,
                                            fit: BoxFit.contain,
                                            cacheWidth: 240,
                                            cacheHeight: 240,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Selection Checkbox Indicator (Animated)
                                  if (_isSelectionMode)
                                    Positioned(
                                      top: 14,
                                      left: 14,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryGreen
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryGreen
                                                : Colors.grey.shade400,
                                            width: 1.8,
                                          ),
                                         
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),

                                  // Card Content Column
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      _isSelectionMode ? 44 : 16,
                                      36,
                                      82,
                                      14,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dua.getTitle(_primaryLanguage),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                            color: gradientPreset.textColor,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        Text(
                                          dua.arabic,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          style: AppTypography.arabicHeader(
                                            fontSize: 18,
                                            color: const Color(0xFF1B3512),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Translations according to language preferences
                                        ..._buildCardTranslations(dua),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Add Dua Floating Action Button (hidden in selection mode)
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openDuaLibraryModal,
              backgroundColor: const Color(0xFF2A531D),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Dua',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 3,
            ),
    );
  }
}
