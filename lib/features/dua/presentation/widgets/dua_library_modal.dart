import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../widgets/app_dropdown.dart';

import '../../domain/dua_item.dart';

enum DuaModalView { library, details, form }

class DuaLibraryModal extends StatefulWidget {
  final List<DuaItem> currentDuas;
  final List<DuaItem> defaultDuas;
  final Function(DuaItem dua) onAddDua;
  final Function(String duaId) onRemoveDua;
  final Function(DuaItem customDua) onCreateCustom;

  const DuaLibraryModal({
    super.key,
    required this.currentDuas,
    required this.defaultDuas,
    required this.onAddDua,
    required this.onRemoveDua,
    required this.onCreateCustom,
  });

  static void show(
    BuildContext context, {
    required List<DuaItem> currentDuas,
    required List<DuaItem> defaultDuas,
    required Function(DuaItem dua) onAddDua,
    required Function(String duaId) onRemoveDua,
    required Function(DuaItem customDua) onCreateCustom,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DuaLibraryModal(
          currentDuas: currentDuas,
          defaultDuas: defaultDuas,
          onAddDua: onAddDua,
          onRemoveDua: onRemoveDua,
          onCreateCustom: onCreateCustom,
        ),
      ),
    );
  }

  @override
  State<DuaLibraryModal> createState() => _DuaLibraryModalState();
}

class _DuaLibraryModalState extends State<DuaLibraryModal> {
  final TextEditingController _searchController = TextEditingController();
  late List<DuaItem> _activeDuas;

  // View switcher state
  DuaModalView _currentView = DuaModalView.library;
  DuaItem? _selectedDuaForDetails;

  // Form Controllers
  final _formTitleController = TextEditingController();
  final _formArabicController = TextEditingController();
  final _formTransliterationController = TextEditingController();
  final _formTranslationController = TextEditingController();
  final _formReferenceController = TextEditingController();
  final _formBenefitsController = TextEditingController();
  String _formSelectedCategory = 'Daily';

  final List<String> _categories = [
    'Daily',
    'Food',
    'Sleep',
    'Hygiene',
    'Travel',
    'Protection',
  ];

  static ({List<Color> colors, Color textColor}) _getCategoryPreset(
    String category,
  ) {
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
    _activeDuas = List.from(widget.currentDuas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _formTitleController.dispose();
    _formArabicController.dispose();
    _formTransliterationController.dispose();
    _formTranslationController.dispose();
    _formReferenceController.dispose();
    _formBenefitsController.dispose();
    super.dispose();
  }

  bool _isDuaSelected(String duaId) {
    return _activeDuas.any((d) => d.id == duaId);
  }

  OverlayEntry? _activeToastOverlay;

  void _showFloatingToast(String text, {required bool isAdded}) {
    _activeToastOverlay?.remove();
    _activeToastOverlay = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 70,
        left: 30,
        right: 30,
        child: Material( 
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 180),
              builder: (context, val, child) => Transform.scale(
                scale: 0.9 + (0.1 * val),
                child: Opacity(opacity: val, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isAdded ? const Color(0xFF2A531D) : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdded ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _activeToastOverlay = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      if (_activeToastOverlay == entry) {
        entry.remove();
        _activeToastOverlay = null;
      }
    });
  }

  void _toggleDua(DuaItem dua) {
    final isSelected = _isDuaSelected(dua.id);
    if (isSelected) {
      widget.onRemoveDua(dua.id);
      setState(() {
        _activeDuas.removeWhere((d) => d.id == dua.id);
      });
      _showFloatingToast('Removed', isAdded: false);
    } else {
      widget.onAddDua(dua);
      setState(() {
        _activeDuas.add(dua);
      });
      _showFloatingToast('Added', isAdded: true);
    }
  }

  void _openFormView() {
    _formTitleController.clear();
    _formArabicController.clear();
    _formTransliterationController.clear();
    _formTranslationController.clear();
    _formReferenceController.clear();
    _formBenefitsController.clear();
    _formSelectedCategory = 'Daily';

    setState(() {
      _currentView = DuaModalView.form;
    });
  }

  void _openDetailsView(DuaItem dua) {
    setState(() {
      _selectedDuaForDetails = dua;
      _currentView = DuaModalView.details;
    });
  }

  void _submitForm() {
    final title = _formTitleController.text.trim();
    final arabic = _formArabicController.text.trim();

    if (title.isEmpty || arabic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a title and Arabic text.'),
        ),
      );
      return;
    }

    final newDua = DuaItem(
      id: 'custom_dua_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _formSelectedCategory,
      arabic: arabic,
      transliteration: _formTransliterationController.text.trim().isNotEmpty
          ? _formTransliterationController.text.trim()
          : title,
      translation: _formTranslationController.text.trim().isNotEmpty
          ? _formTranslationController.text.trim()
          : title,
      repeatCount: 1,
      reference: _formReferenceController.text.trim().isNotEmpty
          ? _formReferenceController.text.trim()
          : 'Personal Custom Supplication',
      benefits: _formBenefitsController.text.trim().isNotEmpty
          ? _formBenefitsController.text.trim()
          : 'Brings peace and reward.',
      imagePath: 'assets/images/dua.png',
      isCustom: true,
    );

    widget.onCreateCustom(newDua);
    setState(() {
      _activeDuas.add(newDua);
      _currentView = DuaModalView.library;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Drag Handle
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
          const SizedBox(height: 10),

          // Content View Switcher
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildCurrentViewContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case DuaModalView.library:
        return _buildLibraryView();
      case DuaModalView.details:
        return _buildDetailsView();
      case DuaModalView.form:
        return _buildFormView();
    }
  }

  // --- 1. LIBRARY VIEW ---
  Widget _buildLibraryView() {
    final query = _searchController.text.trim().toLowerCase();
    final filteredLibrary = widget.defaultDuas.where((dua) {
      return query.isEmpty ||
          dua.title.toLowerCase().contains(query) ||
          dua.arabic.contains(query) ||
          dua.translation.toLowerCase().contains(query) ||
          dua.category.toLowerCase().contains(query);
    }).toList();

    return Padding(
      key: const ValueKey('library_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dua Library',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A531D),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openFormView,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Dua'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search Dua library...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF2A531D),
              ),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform Duas List (Identical to Main Screen Dua Cards with Light Border)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: filteredLibrary.length,
              itemBuilder: (context, index) {
                final dua = filteredLibrary[index];
                final isSelected = _isDuaSelected(dua.id);
                final gradientPreset = _getCategoryPreset(dua.category);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openDetailsView(dua),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: gradientPreset.colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: gradientPreset.textColor.withValues(
                              alpha: 0.15,
                            ),
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Category Watermark Label
                            Positioned(
                              top: 10,
                              right: 44,
                              child: IgnorePointer(
                                child: Text(
                                  dua.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: gradientPreset.textColor.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Top Right Circle Checkbox (No text button)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _toggleDua(dua),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 24,
                                    color: isSelected
                                        ? gradientPreset.textColor
                                        : gradientPreset.textColor.withValues(
                                            alpha: 0.45,
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            // Minimized Background Illustration Image
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: IgnorePointer(
                                child: Container(
                                  width: 55,
                                  height: 55,
                                  padding: const EdgeInsets.all(2),
                                  child: Opacity(
                                    opacity: 0.85,
                                    child: Image.asset(
                                      dua.imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Card Content
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                60,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    dua.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                      color: gradientPreset.textColor,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Text(
                                    dua.arabic,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiri(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1B3512),
                                      height: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  Text(
                                    dua.translation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      letterSpacing: -0.1,
                                      color: Colors.black87,
                                      height: 1.4,
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
    );
  }

  // --- 2. DETAILS VIEW ---
  Widget _buildDetailsView() {
    final dua = _selectedDuaForDetails!;
    final isSelected = _isDuaSelected(dua.id);

    return SingleChildScrollView(
      key: const ValueKey('details_view'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2A531D),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentView = DuaModalView.library;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    dua.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dua.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Arabic Text
                  Text(
                    dua.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      height: 1.8,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Transliteration
                  Text(
                    dua.transliteration,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Translation
                  Text(
                    '"${dua.translation}"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reference & Benefits Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reference',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97724),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dua.reference,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Virtues & Benefits',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7E22CE),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dua.benefits,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selection Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _toggleDua(dua);
                        setState(() {
                          _currentView = DuaModalView.library;
                        });
                      },
                      icon: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_rounded,
                      ),
                      label: Text(
                        isSelected ? 'Remove from My Duas' : 'Add to My Duas',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.red.shade700
                            : const Color(0xFF2A531D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _formInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2A531D)),
      filled: true,
      fillColor: context.isDarkMode ? const Color(0xFF23322B) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.isDarkMode ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.isDarkMode ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.8),
      ),
    );
  }

  // --- 3. FORM VIEW ---
  Widget _buildFormView() {
    return SingleChildScrollView(
      key: const ValueKey('form_view'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2A531D),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentView = DuaModalView.library;
                    });
                  },
                ),
                Text(
                  'Create Custom Dua',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A531D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _formTitleController,
              decoration: _formInputDecoration('Dua Title *', 'e.g. Dua for Peace & Protection', Icons.title_rounded),
            ),
            const SizedBox(height: 14),

            // Category Selector
            AppDropdown<String>(
              label: 'Category',
              value: _formSelectedCategory,
              prefixIcon: Icons.category_rounded,
              onAddCustomCategory: () async {
                final newCatName = await AppDropdown.showAddCustomCategoryDialog(
                  context,
                  title: 'Add Custom Category',
                  hintText: 'e.g. Travel & Protection',
                  icon: Icons.menu_book_rounded,
                );
                if (newCatName != null && newCatName.isNotEmpty) {
                  setState(() {
                    if (!_categories.contains(newCatName)) {
                      _categories.add(newCatName);
                    }
                    _formSelectedCategory = newCatName;
                  });
                }
                return newCatName;
              },
              items: _categories.map((cat) {
                return AppDropdownItem<String>(
                  value: cat,
                  label: cat,
                  icon: Icons.folder_outlined,
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _formSelectedCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // Arabic Text
            TextField(
              controller: _formArabicController,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: _formInputDecoration('Arabic Text *', 'اَللَّهُمَّ حَاسِبْنِي حِسَاباً يَسِيراً', Icons.auto_awesome_rounded),
            ),
            const SizedBox(height: 14),

            // Transliteration
            TextField(
              controller: _formTransliterationController,
              decoration: _formInputDecoration('Transliteration', 'e.g. Allahumma hasibni hisaban yasira', Icons.text_fields_rounded),
            ),
            const SizedBox(height: 14),

            // Translation
            TextField(
              controller: _formTranslationController,
              maxLines: 2,
              decoration: _formInputDecoration('English Translation', 'e.g. O Allah, grant me an easy accounting.', Icons.translate_rounded),
            ),
            const SizedBox(height: 14),

            // Hadith Reference
            TextField(
              controller: _formReferenceController,
              decoration: _formInputDecoration('Hadith / Book Reference', 'e.g. Musnad Ahmad & Sahih Ibn Hibban', Icons.menu_book_rounded),
            ),
            const SizedBox(height: 14),

            // Benefits
            TextField(
              controller: _formBenefitsController,
              maxLines: 2,
              decoration: _formInputDecoration('Spiritual & Practical Benefits', 'e.g. Grants ease on the Day of Judgment.', Icons.info_outline_rounded),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Save Custom Dua',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
