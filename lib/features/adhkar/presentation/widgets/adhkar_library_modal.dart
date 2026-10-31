import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/adhkar_category.dart';
import '../../../../shared/models/dhikr_item.dart';
import '../../../../shared/widgets/app_floating_toast.dart';

enum AdhkarModalView { library, details, form }

class AdhkarLibraryModal extends StatefulWidget {
  final List<AdhkarCategory> currentCategories;
  final List<DhikrItem> currentAdhkarItems;
  final List<AdhkarCategory> defaultCategories;
  final List<DhikrItem> defaultAdhkarItems;
  final Function(AdhkarCategory category, List<DhikrItem> items) onAddCategory;
  final Function(String categoryId) onRemoveCategory;
  final Function(AdhkarCategory newCategory, List<DhikrItem> newItems)
  onCreateCustom;

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
    required Function(AdhkarCategory category, List<DhikrItem> items)
    onAddCategory,
    required Function(String categoryId) onRemoveCategory,
    required Function(AdhkarCategory newCategory, List<DhikrItem> newItems)
    onCreateCustom,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
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

  void _toggleCategory(AdhkarCategory category) {
    final isSelected = _isCategorySelected(category.id);
    if (isSelected) {
      widget.onRemoveCategory(category.id);
      setState(() {
        _activeCategories.removeWhere((c) => c.id == category.id);
      });
      AppFloatingToast.showRemoved(context, message: 'Removed');
    } else {
      final itemsForCat = widget.defaultAdhkarItems
          .where((i) => i.category == category.id)
          .toList();
      widget.onAddCategory(category, itemsForCat);
      setState(() {
        _activeCategories.add(category);
      });
      AppFloatingToast.showAdded(context, message: 'Added');
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
      AppFloatingToast.showError(
        context,
        message: 'Please enter an Adhkar title.',
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
    AppFloatingToast.showAdded(
      context,
      message: 'Adhkar section created',
    );
    Navigator.of(context).pop();
  }

  Widget _buildCategoryImageWidget(String imagePath, [bool isDark = false]) {
    Widget imgWidget;
    if (imagePath.startsWith('assets/')) {
      imgWidget = Image.asset(
        imagePath,
        fit: BoxFit.contain,
        cacheWidth: 200,
        cacheHeight: 200,
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
        imgWidget = Image.file(
          file,
          fit: BoxFit.contain,
          alignment: Alignment.bottomRight,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.auto_awesome_rounded,
            size: 40,
            color: Colors.black12,
          ),
        );
      } else {
        imgWidget = const Icon(
          Icons.auto_awesome_rounded,
          size: 40,
          color: Colors.black12,
        );
      }
    }

    if (isDark) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.15),
          BlendMode.srcATop,
        ),
        child: imgWidget,
      );
    }
    return imgWidget;
  }

  InputDecoration _roundedInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isDark = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.grey.shade500,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFB),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
          width: 1.8,
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Text(
                'Adhkar Library',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openFormView,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Adhkar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF22C55E) : const Color(0xFF2A531D),
                  foregroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
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

          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search Adhkar categories...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: isDark ? const BorderSide(color: Color(0xFF27272A)) : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: isDark ? const BorderSide(color: Color(0xFF27272A)) : BorderSide.none,
              ),
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
                final gradientPreset = AdhkarCategory.getGradient(
                  cat.gradientIndex,
                );
                final cardColors = gradientPreset.getColors(isDark);
                final cardTextColor = gradientPreset.getTextColor(isDark);

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
                            colors: cardColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                                  child: _buildCategoryImageWidget(
                                    cat.imagePath,
                                    isDark,
                                  ),
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
                                        ? cardTextColor
                                        : cardTextColor.withValues(
                                            alpha: 0.45,
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            // Card Text Content
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                54,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.titleAr,
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.arabicHeader(
                                      fontSize: 18,
                                      color: cardTextColor,
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
                                      color: cardTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cat.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cardTextColor
                                          .withValues(alpha: 0.85),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
                ),
                onPressed: () {
                  setState(() {
                    _currentView = AdhkarModalView.library;
                  });
                },
              ),
              Expanded(
                child: Text(
                  cat.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2A531D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradientPreset.getTextColor(isDark).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cat.titleAr,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicHeader(
                    fontSize: 15,
                    color: gradientPreset.getTextColor(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF27272A) : Colors.grey.shade300,
        ),

        // Horizontal PageView of Dhikr Items
        SizedBox(
          height: 420,
          child: itemsForCat.isEmpty
              ? const Center(child: Text('No Dhikr items in this section yet.'))
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: isDark ? const Color(0xFF0f0f12) : const Color(0xFFF4FAF3),
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
                                  style: AppTypography.arabicBody(
                                    fontSize: 22,
                                    height: 1.8,
                                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1B5E20),
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
                                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade800,
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
                                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (item.reference.isNotEmpty)
                                  Text(
                                    'Reference: ${item.reference}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFD97724),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (item.virtue.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Virtue: ${item.virtue}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFAC5BED),
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
                    color: isCurrent
                        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                        : (isDark ? const Color(0xFF27272A) : Colors.grey.shade300),
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
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_rounded,
              ),
              label: Text(
                isSelected ? 'Remove from Main Screen' : 'Add to Main Screen',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? Colors.red.shade700
                    : (isDark ? const Color(0xFF22C55E) : const Color(0xFF2A531D)),
                foregroundColor: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF0F0F12) : Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. FORM VIEW ---
  Widget _buildFormView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectableImages = List<String>.from(AdhkarCategory.availableImages);
    if (!selectableImages.contains(_formSelectedImagePath)) {
      selectableImages.insert(0, _formSelectedImagePath);
    }

    return Padding(
      key: const ValueKey('form_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Header with Back Button
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
                ),
                onPressed: () {
                  setState(() {
                    _currentView = AdhkarModalView.library;
                  });
                },
              ),
              Text(
                'Create Custom Adhkar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                ),
              ),
            ],
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF27272A) : Colors.grey.shade200,
          ),
          const SizedBox(height: 8),

          // Scrollable Form Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [

            // Category Title Input
            TextField(
              controller: _formTitleController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              cursorColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
              decoration: _roundedInputDecoration(
                labelText: 'Adhkar Title *',
                hintText: 'e.g. Travel Duas',
                prefixIcon: Icons.category_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle / Description Input
            TextField(
              controller: _formSubtitleController,
              maxLines: 2,
              maxLength: 100,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              cursorColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
              decoration: _roundedInputDecoration(
                labelText: 'Subtitle / Description (max 2 lines)',
                hintText: 'e.g. Duas for protection during journeys',
                prefixIcon: Icons.description_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),

            // Arabic Title (optional)
            TextField(
              controller: _formTitleArController,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicBody(
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
              cursorColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
              decoration: _roundedInputDecoration(
                labelText: 'Arabic Title (Optional)',
                hintText: 'أدعية السفر',
                prefixIcon: Icons.translate_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),

            // Gradient Theme Picker
            Text(
              'Select Gradient Theme',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2A531D),
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
                  final colors = preset.getColors(isDark);
                  final textColor = preset.getTextColor(isDark);
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
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? const Color(0xFF86EFAC) : textColor)
                              : (isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300),
                          width: isSelected ? 3.0 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: textColor,
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
            Text(
              'Upload background-less image or select icon',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2A531D),
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
                          color: isDark ? const Color(0xFF18181B) : const Color(0xFFE8F4E5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFF2A531D),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Upload',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
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
                            ? (isDark ? const Color(0xFF27272A) : const Color(0xFFE8F4E5))
                            : (isDark ? const Color(0xFF18181B) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                              : (isDark ? const Color(0xFF27272A) : Colors.transparent),
                          width: 2.0,
                        ),
                      ),
                      child: _buildCategoryImageWidget(imgPath, isDark),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Folder info notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is only to create an Adhkar folder for you. Once it is created, you can add Dhikrs, Duas, Quran Surahs, or Tasbeeh inside it.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF166534),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF22C55E) : const Color(0xFF2A531D),
                  foregroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
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
    ),
  ],
),
);
  }
}
