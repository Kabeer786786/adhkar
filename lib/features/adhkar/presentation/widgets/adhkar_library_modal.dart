import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/models/adhkar_category.dart';
import '../../../../shared/models/dhikr_item.dart';

enum AdhkarModalView { library, details, form }

class AdhkarLibraryModal extends StatefulWidget {
  final List<AdhkarCategory> currentCategories;
  final List<DhikrItem> currentAdhkarItems;
  final List<AdhkarCategory> defaultCategories;
  final List<DhikrItem> defaultAdhkarItems;
  final Function(AdhkarCategory category, List<DhikrItem> items) onAddCategory;
  final Function(String categoryId) onRemoveCategory;
  final Function(AdhkarCategory newCategory, List<DhikrItem> newItems) onCreateCustom;

  const AdhkarLibraryModal({
    super.key,
    required this.currentCategories,
    required this.currentAdhkarItems,
    required this.defaultCategories,
    required this.defaultAdhkarItems,
    required this.onAddCategory,
    required this.onRemoveCategory,
    required this.onCreateCustom,
  });

  static void show(
    BuildContext context, {
    required List<AdhkarCategory> currentCategories,
    required List<DhikrItem> currentAdhkarItems,
    required List<AdhkarCategory> defaultCategories,
    required List<DhikrItem> defaultAdhkarItems,
    required Function(AdhkarCategory category, List<DhikrItem> items) onAddCategory,
    required Function(String categoryId) onRemoveCategory,
    required Function(AdhkarCategory newCategory, List<DhikrItem> newItems) onCreateCustom,
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
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AdhkarLibraryModal(
          currentCategories: currentCategories,
          currentAdhkarItems: currentAdhkarItems,
          defaultCategories: defaultCategories,
          defaultAdhkarItems: defaultAdhkarItems,
          onAddCategory: onAddCategory,
          onRemoveCategory: onRemoveCategory,
          onCreateCustom: onCreateCustom,
        ),
      ),
    );
  }

  @override
  State<AdhkarLibraryModal> createState() => _AdhkarLibraryModalState();
}

class _AdhkarLibraryModalState extends State<AdhkarLibraryModal> {
  final TextEditingController _searchController = TextEditingController();
  late List<AdhkarCategory> _activeCategories;

  // View state: library, details, form
  AdhkarModalView _currentView = AdhkarModalView.library;
  AdhkarCategory? _selectedCategoryForDetails;
  int _detailPageIndex = 0;
  late PageController _detailPageController;

  // Form Controllers
  final _formTitleController = TextEditingController();
  final _formSubtitleController = TextEditingController();
  final _formTitleArController = TextEditingController();
  int _formSelectedGradientIndex = 0;
  String _formSelectedImagePath = AdhkarCategory.availableImages.first;

  @override
  void initState() {
    super.initState();
    _activeCategories = List.from(widget.currentCategories);
    _detailPageController = PageController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _detailPageController.dispose();
    _formTitleController.dispose();
    _formSubtitleController.dispose();
    _formTitleArController.dispose();
    super.dispose();
  }

  bool _isCategorySelected(String categoryId) {
    return _activeCategories.any((c) => c.id == categoryId);
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

  void _toggleCategory(AdhkarCategory category) {
    final isSelected = _isCategorySelected(category.id);
    if (isSelected) {
      widget.onRemoveCategory(category.id);
      setState(() {
        _activeCategories.removeWhere((c) => c.id == category.id);
      });
      _showFloatingToast('Removed', isAdded: false);
    } else {
      final itemsForCat = widget.defaultAdhkarItems
          .where((i) => i.category == category.id)
          .toList();
      widget.onAddCategory(category, itemsForCat);
      setState(() {
        _activeCategories.add(category);
      });
      _showFloatingToast('Added', isAdded: true);
    }
  }

  void _openDetailsView(AdhkarCategory category) {
    setState(() {
      _selectedCategoryForDetails = category;
      _detailPageIndex = 0;
      _currentView = AdhkarModalView.details;
    });
    _detailPageController = PageController(initialPage: 0);
  }

  void _openFormView() {
    _formTitleController.clear();
    _formSubtitleController.clear();
    _formTitleArController.clear();
    _formSelectedGradientIndex = 0;
    _formSelectedImagePath = AdhkarCategory.availableImages.first;

    setState(() {
      _currentView = AdhkarModalView.form;
    });
  }

  void _submitForm() {
    final title = _formTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Adhkar title.')),
      );
      return;
    }

    final newCat = AdhkarCategory(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: _formSubtitleController.text.trim().isNotEmpty
          ? _formSubtitleController.text.trim()
          : 'Custom user adhkar collection',
      titleAr: _formTitleArController.text.trim().isNotEmpty
          ? _formTitleArController.text.trim()
          : title,
      imagePath: _formSelectedImagePath,
      gradientIndex: _formSelectedGradientIndex,
      isDefault: false,
    );

    widget.onCreateCustom(newCat, []);
    setState(() {
      _activeCategories.add(newCat);
      _currentView = AdhkarModalView.library;
    });
  }

  Widget _buildCategoryImageWidget(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        alignment: Alignment.bottomRight,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.auto_awesome_rounded,
          size: 40,
          color: Colors.black12,
        ),
      );
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          alignment: Alignment.bottomRight,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.auto_awesome_rounded,
            size: 40,
            color: Colors.black12,
          ),
        );
      }
      return const Icon(
        Icons.auto_awesome_rounded,
        size: 40,
        color: Colors.black12,
      );
    }
  }

  InputDecoration _roundedInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF2A531D)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.8),
      ),
    );
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
      case AdhkarModalView.library:
        return _buildLibraryView();
      case AdhkarModalView.details:
        return _buildDetailsView();
      case AdhkarModalView.form:
        return _buildFormView();
    }
  }

  // --- 1. LIBRARY VIEW ---
  Widget _buildLibraryView() {
    final query = _searchController.text.trim().toLowerCase();
    final filteredCategories = widget.defaultCategories.where((cat) {
      return query.isEmpty ||
          cat.title.toLowerCase().contains(query) ||
          cat.subtitle.toLowerCase().contains(query) ||
          cat.titleAr.contains(query);
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
                'Adhkar Library',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A531D),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openFormView,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Adhkar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search Adhkar categories...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2A531D)),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              // border: OutlineInputBorder(
              //   borderRadius: BorderRadius.circular(16),
              //   borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              // ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform Categories List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                final isSelected = _isCategorySelected(cat.id);
                final gradientPreset = AdhkarCategory.getGradient(cat.gradientIndex);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openDetailsView(cat),
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
                            color: gradientPreset.textColor.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Minimized Bottom Right Image to prevent overflow
                            Positioned(
                              bottom: 8,
                              right: 8,
                              width: 54,
                              height: 54,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.85,
                                  child: _buildCategoryImageWidget(cat.imagePath),
                                ),
                              ),
                            ),

                            // Top-Right Circle Checkbox (No text button)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => _toggleCategory(cat),
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
                                        : gradientPreset.textColor.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ),

                            // Card Text Content
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 54, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.titleAr,
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.amiri(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: gradientPreset.textColor,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cat.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: gradientPreset.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cat.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: gradientPreset.textColor.withValues(alpha: 0.85),
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
    );
  }

  // --- 2. DETAILS VIEW ---
  Widget _buildDetailsView() {
    final cat = _selectedCategoryForDetails!;
    final itemsForCat = widget.defaultAdhkarItems
        .where((i) => i.category == cat.id)
        .toList();
    final isSelected = _isCategorySelected(cat.id);
    final gradientPreset = AdhkarCategory.getGradient(cat.gradientIndex);

    return Column(
      key: const ValueKey('details_view'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Modal Header Row with Back Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2A531D)),
                onPressed: () {
                  setState(() {
                    _currentView = AdhkarModalView.library;
                  });
                },
              ),
              Expanded(
                child: Text(
                  cat.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A531D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradientPreset.textColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cat.titleAr,
                  style: GoogleFonts.amiri(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: gradientPreset.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Horizontal PageView of Dhikr Items
        SizedBox(
          height: 320,
          child: itemsForCat.isEmpty
              ? const Center(
                  child: Text('No Dhikr items in this section yet.'),
                )
              : PageView.builder(
                  controller: _detailPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _detailPageIndex = index;
                    });
                  },
                  itemCount: itemsForCat.length,
                  itemBuilder: (context, index) {
                    final item = itemsForCat[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: const Color(0xFFF4FAF3),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  item.arabicText,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.amiri(
                                    fontSize: 22,
                                    height: 1.8,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (item.transliteration.isNotEmpty) ...[
                                  Text(
                                    item.transliteration,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Text(
                                  '"${item.translation}"',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (item.reference.isNotEmpty)
                                  Text(
                                    'Reference: ${item.reference}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFFD97724),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (item.virtue.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Virtue: ${item.virtue}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF7E22CE),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bottom Page Indicator Circles (Dots)
        if (itemsForCat.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(itemsForCat.length, (index) {
                final isCurrent = index == _detailPageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isCurrent ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFF2A531D) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

        // Selection Action Button
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _toggleCategory(cat);
                setState(() {
                  _currentView = AdhkarModalView.library;
                });
              },
              icon: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.add_circle_rounded,
              ),
              label: Text(
                isSelected ? 'Remove from Main Screen' : 'Add to Main Screen',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.red.shade700 : const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. FORM VIEW ---
  Widget _buildFormView() {
    final selectableImages = List<String>.from(AdhkarCategory.availableImages);
    if (!selectableImages.contains(_formSelectedImagePath)) {
      selectableImages.insert(0, _formSelectedImagePath);
    }

    return Padding(
      key: const ValueKey('form_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2A531D)),
                  onPressed: () {
                    setState(() {
                      _currentView = AdhkarModalView.library;
                    });
                  },
                ),
                const Text(
                  'Create Custom Adhkar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A531D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category Title Input
            TextField(
              controller: _formTitleController,
              decoration: _roundedInputDecoration(
                labelText: 'Adhkar Title *',
                hintText: 'e.g. Travel Duas',
                prefixIcon: Icons.category_rounded,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle / Description Input
            TextField(
              controller: _formSubtitleController,
              maxLines: 2,
              maxLength: 100,
              decoration: _roundedInputDecoration(
                labelText: 'Subtitle / Description (max 2 lines)',
                hintText: 'e.g. Duas for protection during journeys',
                prefixIcon: Icons.description_rounded,
              ),
            ),
            const SizedBox(height: 12),

            // Arabic Title (optional)
            TextField(
              controller: _formTitleArController,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(fontSize: 18),
              decoration: _roundedInputDecoration(
                labelText: 'Arabic Title (Optional)',
                hintText: 'أدعية السفر',
                prefixIcon: Icons.translate_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // Gradient Theme Picker
            const Text(
              'Select Light Gradient Theme',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: AdhkarCategory.gradientPresets.length,
                itemBuilder: (context, index) {
                  final preset = AdhkarCategory.gradientPresets[index];
                  final isSelected = _formSelectedGradientIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _formSelectedGradientIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: preset.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? preset.textColor
                              : Colors.grey.shade300,
                          width: isSelected ? 3.0 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: preset.textColor,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Image Selector
            const Text(
              'Upload background-less image or select icon',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: selectableImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() {
                            _formSelectedImagePath = image.path;
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4E5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2A531D),
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              color: Color(0xFF2A531D),
                              size: 20,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Upload',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A531D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final imgPath = selectableImages[index - 1];
                  final isSelected = _formSelectedImagePath == imgPath;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _formSelectedImagePath = imgPath;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(4),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8F4E5)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2A531D)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: _buildCategoryImageWidget(imgPath),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create Adhkar Section',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
