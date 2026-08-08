import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/providers/app_providers.dart';
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

  final List<String> _categories = [
    'Food',
    'Sleep',
    'Daily',
    'Hygiene',
    'Travel',
    'Protection',
  ];

  static ({List<Color> colors, Color textColor}) _getCategoryPreset(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
        return (
          colors: const [Color(0xFFFFFDF2), Color(0xFFFFF8DE)],
          textColor: const Color(0xFFB45309),
        );
      case 'sleep':
        return (
          colors: const [Color(0xFFF3F6FF), Color(0xFFE8EEFF)],
          textColor: const Color(0xFF1E3A8A),
        );
      case 'daily':
        return (
          colors: const [Color(0xFFF4FAF3), Color(0xFFEAF5E8)],
          textColor: const Color(0xFF1B5E20),
        );
      case 'hygiene':
        return (
          colors: const [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
          textColor: const Color(0xFFDB2777),
        );
      case 'travel':
        return (
          colors: const [Color(0xFFF3FBF7), Color(0xFFE2F6EC)],
          textColor: const Color(0xFF047857),
        );
      case 'protection':
        return (
          colors: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          textColor: const Color(0xFF7E22CE),
        );
      default:
        return (
          colors: const [Color(0xFFFFF5F5), Color(0xFFFFECEC)],
          textColor: const Color(0xFFBE123C),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDuas();
    _searchController.addListener(_filterDuas);
  }

  void _loadDuas() {
    final storage = ref.read(storageServiceProvider);
    final savedItemMaps = storage.getSavedDuaItems();

    if (savedItemMaps != null && savedItemMaps.isNotEmpty) {
      _allDuas = savedItemMaps.map((m) => DuaItem.fromJson(m)).toList();
    } else {
      _allDuas = _repository.getDefaultDuas();
      _persistDuas();
    }
    _filterDuas();
  }

  void _persistDuas() {
    final storage = ref.read(storageServiceProvider);
    final maps = _allDuas.map((d) => d.toJson()).toList();
    storage.saveDuaItems(maps);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDuas() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredDuas = _allDuas.where((dua) {
        final matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(dua.category);
        final matchesQuery = query.isEmpty ||
            dua.title.toLowerCase().contains(query) ||
            dua.arabic.contains(query) ||
            dua.transliteration.toLowerCase().contains(query) ||
            dua.translation.toLowerCase().contains(query) ||
            dua.reference.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  void _openDuaLibraryModal() {
    DuaLibraryModal.show(
      context,
      currentDuas: _allDuas,
      defaultDuas: _repository.getDefaultDuas(),
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

  void _showCategoryFilterModal() {
    final tempSelected = Set<String>.from(_selectedCategories);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allSelected = tempSelected.length == _categories.length;

            return Padding(
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 10,
                    children: _categories.map((category) {
                      final isSelected = tempSelected.contains(category);
                      final preset = _getCategoryPreset(category);

                      return FilterChip(
                        label: Text(category),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? preset.textColor : const Color(0xFF334155),
                        ),
                        selected: isSelected,
                        selectedColor: preset.colors.last,
                        backgroundColor: const Color(0xFFF8FAFC),
                        checkmarkColor: preset.textColor,
                        side: BorderSide(
                          color: isSelected ? preset.textColor : const Color(0xFFE2E8F0),
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
                  const SizedBox(height: 24),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeaderBar(
        title: 'DAILY DUAS',
        showBackButton: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Filter Bar Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Dua by title, meaning, or topic...',
                      hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2A531D)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.5),
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
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DuaDetailScreen(dua: dua),
                                ),
                              );
                            },
                            child: Container(
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
                                    color: gradientPreset.textColor.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: gradientPreset.textColor.withValues(alpha: 0.15),
                                  width: 1.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Category Watermark Label
                                  Positioned(
                                    top: 10,
                                    right: 14,
                                    child: IgnorePointer(
                                      child: Text(
                                        dua.category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                          color: gradientPreset.textColor.withValues(alpha: 0.28),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Background Illustration Image
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
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
                                            errorBuilder: (context, error, stackTrace) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Card Content
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 75, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dua.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                            color: gradientPreset.textColor,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        Text(
                                          dua.arabic,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          style: GoogleFonts.amiri(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1B3512),
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        Text(
                                          dua.translation,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.lexend(
                                            fontSize: 11.5,
                                            letterSpacing: -0.1,
                                            color: Colors.black87,
                                            height: 1.35,
                                          ),
                                        ),
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

      // Add Dua Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
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
