import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_typography.dart';
import '../../../shared/models/adhkar_category.dart';
import '../../../shared/models/dhikr_item.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../widgets/app_action_popup_menu.dart';
import '../../../widgets/app_header_bar.dart';
import '../repositories/adhkar_repository.dart';
import 'adhkar_detail_screen.dart';
import 'widgets/adhkar_library_modal.dart';

class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({super.key});

  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen>
    with WidgetsBindingObserver {
  List<AdhkarCategory> _categories = [];
  List<DhikrItem> _allAdhkar = [];
  Map<String, int> _dailyCounts = {};
  late String _todayDateKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        _loadData();
      });
    }
  }

  void _loadData() {
    final storage = ref.read(storageServiceProvider);
    final repo = AdhkarRepository();
    _todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Load Saved Categories or set defaults
    final savedCatMaps = storage.getSavedAdhkarCategories();
    if (savedCatMaps != null && savedCatMaps.isNotEmpty) {
      _categories = savedCatMaps
          .map((map) => AdhkarCategory.fromJson(map))
          .toList();
    } else {
      _categories = repo.getDefaultCategories();
      _persistCategories();
    }

    // 2. Load Saved Adhkar Items or set defaults
    final savedItemMaps = storage.getSavedAdhkarItems();
    if (savedItemMaps != null && savedItemMaps.isNotEmpty) {
      _allAdhkar = savedItemMaps.map((map) => DhikrItem.fromJson(map)).toList();
      // Ensure all 4 test types in daily duas category exist
      final defaultDaily = repo.getAdhkarByCategory('duas');
      bool hasNew = false;
      for (final defItem in defaultDaily) {
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

    // 3. Load daily counts for today
    _dailyCounts = storage.getDailyAdhkarCounts(_todayDateKey);
  }

  void _persistCategories() {
    final storage = ref.read(storageServiceProvider);
    final maps = _categories.map((c) => c.toJson()).toList();
    storage.saveAdhkarCategories(maps);
  }

  void _persistAdhkar() {
    final storage = ref.read(storageServiceProvider);
    final maps = _allAdhkar.map((i) => i.toJson()).toList();
    storage.saveAdhkarItems(maps);
  }

  void _saveOrUpdateCategory(AdhkarCategory cat) {
    setState(() {
      final index = _categories.indexWhere((c) => c.id == cat.id);
      if (index >= 0) {
        _categories[index] = cat;
      } else {
        _categories.add(cat);
      }
    });
    _persistCategories();
    HapticFeedback.lightImpact();
  }

  void _deleteCategory(String categoryId) {
    setState(() {
      _categories.removeWhere((c) => c.id == categoryId);
      _allAdhkar.removeWhere((item) => item.category == categoryId);
    });
    _persistCategories();
    _persistAdhkar();
    HapticFeedback.mediumImpact();
  }

  void _openAdhkarLibraryModal() {
    final repo = AdhkarRepository();
    AdhkarLibraryModal.show(
      context,
      currentCategories: _categories,
      currentAdhkarItems: _allAdhkar,
      defaultCategories: repo.getDefaultCategories(),
      defaultAdhkarItems: repo.getAllDefaultAdhkar(),
      onAddCategory: (category, items) {
        setState(() {
          if (!_categories.any((c) => c.id == category.id)) {
            _categories.add(category);
          }
          for (final item in items) {
            if (!_allAdhkar.any((i) => i.id == item.id)) {
              _allAdhkar.add(item);
            }
          }
        });
        _persistCategories();
        _persistAdhkar();
      },
      onRemoveCategory: (categoryId) {
        _deleteCategory(categoryId);
      },
      onCreateCustom: (newCat, newItems) {
        _saveOrUpdateCategory(newCat);
      },
    );
  }

  void _confirmDeleteCategory(AdhkarCategory category) {
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
                'Delete Adhkar?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${category.title}" and all its Duas and Adhkar? This action cannot be undone.',
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
                _deleteCategory(category.id);
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

  InputDecoration _roundedInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isDark = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF9FAFB),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF2A531D)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.8),
      ),
    );
  }

  Widget _buildCategoryImageWidget(String imagePath, [bool isDark = false]) {
    Widget imgWidget;
    if (imagePath.startsWith('assets/')) {
      imgWidget = Image.asset(
        imagePath,
        fit: BoxFit.contain,
        cacheWidth: 300,
        cacheHeight: 300,
        alignment: Alignment.bottomRight,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.auto_awesome_rounded,
          size: 60,
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
            size: 60,
            color: Colors.black12,
          ),
        );
      } else {
        imgWidget = const Icon(
          Icons.auto_awesome_rounded,
          size: 60,
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

  void _showCategoryModal({AdhkarCategory? category}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = category != null;
    final titleController = TextEditingController(text: category?.title ?? '');
    final subtitleController = TextEditingController(
      text: category?.subtitle ?? '',
    );
    final titleArController = TextEditingController(
      text: category?.titleAr ?? '',
    );
    int selectedGradientIndex = category?.gradientIndex ?? 0;
    String selectedImagePath =
        category?.imagePath ?? AdhkarCategory.availableImages.first;

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
            // Build selectable images list (built-in assets + custom uploaded image if selected)
            final selectableImages = List<String>.from(
              AdhkarCategory.availableImages,
            );
            if (!selectableImages.contains(selectedImagePath)) {
              selectableImages.insert(0, selectedImagePath);
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed Sheet Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Adhkar' : 'Create New Adhkar',
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
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF27272A)
                        : Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),

                  // Scrollable Content
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Title Input
                          TextField(
                            controller: titleController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: _roundedInputDecoration(
                              labelText: 'Adhkar Title *',
                              hintText: 'e.g. Travel Duas',
                              prefixIcon: Icons.category_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Subtitle / Description Input (max 2 lines)
                          TextField(
                            controller: subtitleController,
                            maxLines: 2,
                            maxLength: 100,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: _roundedInputDecoration(
                              labelText: 'Subtitle / Description (max 2 lines)',
                              hintText:
                                  'e.g. Duas for protection during journeys',
                              prefixIcon: Icons.description_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Arabic Title (optional)
                          TextField(
                            controller: titleArController,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: AppTypography.arabicBody(
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: _roundedInputDecoration(
                              labelText: 'Arabic Title (Optional)',
                              hintText: 'أدعية السفر',
                              prefixIcon: Icons.translate_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Select Gradient Theme',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2A531D),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 52,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: AdhkarCategory.gradientPresets.length,
                              itemBuilder: (context, index) {
                                final preset =
                                    AdhkarCategory.gradientPresets[index];
                                final isSelected =
                                    selectedGradientIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedGradientIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 46,
                                    height: 46,
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
                                      boxShadow: null, // Removed Shadow
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: preset.textColor,
                                            size: 22,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Image Upload / Selector
                          Text(
                            'Upload background-less image or select icon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2A531D),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 72,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount:
                                  selectableImages.length +
                                  1, // +1 for the Upload tile at index 0
                              itemBuilder: (context, index) {
                                // Index 0: Upload Image (+) Tile
                                if (index == 0) {
                                  return GestureDetector(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      final XFile? image = await picker
                                          .pickImage(
                                            source: ImageSource.gallery,
                                          );
                                      if (image != null) {
                                        setModalState(() {
                                          selectedImagePath = image.path;
                                        });
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF18181B)
                                            : const Color(0xFFE8F4E5),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF27272A)
                                              : const Color(0xFF2A531D),
                                          width: 1.8,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_rounded,
                                            color: isDark
                                                ? const Color(0xFF86EFAC)
                                                : const Color(0xFF2A531D),
                                            size: 24,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Upload',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color(0xFF86EFAC)
                                                  : const Color(0xFF2A531D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Index 1..N: Predefined or uploaded image tiles
                                final imgPath = selectableImages[index - 1];
                                final isSelected = selectedImagePath == imgPath;

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedImagePath = imgPath;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(6),
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                                ? const Color(0xFF27272A)
                                                : const Color(0xFFE8F4E5))
                                          : (isDark
                                                ? const Color(0xFF18181B)
                                                : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? (isDark
                                                  ? const Color(0xFF86EFAC)
                                                  : const Color(0xFF2A531D))
                                            : (isDark
                                                  ? const Color(0xFF27272A)
                                                  : Colors.transparent),
                                        width: 2.0,
                                      ),
                                    ),
                                    child: _buildCategoryImageWidget(imgPath),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Folder info notice
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F0F12)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF27272A)
                                    : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF16A34A),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'This is only to create an Adhkar folder for you. Once it is created, you can add Dhikrs, Duas, Quran Surahs, or Tasbeeh inside it.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF166534),
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final title = titleController.text.trim();
                                if (title.isEmpty) return;

                                final newCategory = AdhkarCategory(
                                  id:
                                      category?.id ??
                                      'cat_${DateTime.now().millisecondsSinceEpoch}',
                                  title: title,
                                  subtitle: subtitleController.text.trim(),
                                  titleAr: titleArController.text.trim(),
                                  gradientIndex: selectedGradientIndex,
                                  imagePath: selectedImagePath,
                                  isDefault: category?.isDefault ?? false,
                                );

                                _saveOrUpdateCategory(newCategory);
                                Navigator.pop(context);
                              },
                              icon: Icon(
                                isEdit ? Icons.save_rounded : Icons.add_rounded,
                              ),
                              label: Text(
                                isEdit ? 'Save Changes' : 'Create Adhkar',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F12)
          : const Color(0xFFF9FAFB),
      appBar: const AppHeaderBar(title: 'ADHKAR'),
      body: _categories.isEmpty
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
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF2A531D).withValues(alpha: 0.12)
                            : const Color(0xFFE8F4E5).withValues(alpha: 0.6),
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
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
                              width: 74,
                              height: 74,
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
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Adhkar Folders Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2A531D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your daily remembrance journey. Explore our curated collections of morning, evening, and daily prayers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF14532D,
                            ).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _openAdhkarLibraryModal(),
                        icon: const Icon(Icons.add_rounded, size: 22),
                        label: const Text(
                          'Add Adhkar Collection',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF1F5F0),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF2A531D),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'POPULAR SUGGESTIONS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF2A531D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildQuickSuggestionChip(
                                'Morning Adhkar',
                                isDark,
                              ),
                              _buildQuickSuggestionChip(
                                'Evening Adhkar',
                                isDark,
                              ),
                              _buildQuickSuggestionChip(
                                'Daily Tasbeeh',
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: 100,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final gradientPreset = AdhkarCategory.getGradient(
                  cat.gradientIndex,
                );
                final cardColors = gradientPreset.getColors(isDark);
                final cardTextColor = gradientPreset.getTextColor(isDark);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        await Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => AdhkarDetailScreen(
                              categoryId: cat.id,
                              title: cat.title,
                            ),
                          ),
                        );
                        _loadData();
                      },
                      child: Container(
                        height: 154,
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
                            // Static Background Image at Absolute Position (Bottom Right, inside box)
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: IgnorePointer(
                                child: Container(
                                  width: 85,
                                  height: 85,
                                  padding: const EdgeInsets.all(4),
                                  child: Opacity(
                                    opacity: 0.85,
                                    child: _buildCategoryImageWidget(
                                      cat.imagePath,
                                      isDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Absolute Positioned 3 Dots Popup Menu at Top Right Corner
                            Positioned(
                              top: 4,
                              right: 4,
                              child: AppActionPopupMenu<String>(
                                iconColor: cardTextColor,
                                items: const [
                                  AppActionMenuItem(
                                    value: 'edit',
                                    title: 'Edit Adhkar',
                                    icon: Icons.edit_outlined,
                                  ),
                                  AppActionMenuItem(
                                    value: 'delete',
                                    title: 'Delete Category',
                                    icon: Icons.delete_outline_rounded,
                                    isDestructive: true,
                                  ),
                                ],
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showCategoryModal(category: cat);
                                  } else if (val == 'delete') {
                                    _confirmDeleteCategory(cat);
                                  }
                                },
                              ),
                            ),

                            // Main Content Overlay
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (cat.titleAr.isNotEmpty) ...[
                                    Text(
                                      cat.titleAr,
                                      textDirection: TextDirection.rtl,
                                      style: AppTypography.arabicHeader(
                                        fontSize: 16,
                                        color: cardTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                  ],

                                  // Category Title (1 line)
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.65,
                                    child: Text(
                                      cat.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: cardTextColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Category Subtitle (max 1 line for clean spacing)
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.60,
                                    child: Text(
                                      cat.subtitle.isNotEmpty
                                          ? cat.subtitle
                                          : 'Tap to view Duas & Adhkar inside this category',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.3,
                                        fontWeight: FontWeight.w500,
                                        color: cardTextColor.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Daily Progress Indicator for this folder
                                  _buildCategoryProgressBadge(
                                    cat,
                                    cardTextColor,
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

      // Floating Add Button at Bottom Right ONLY when categories exist
      floatingActionButton: _categories.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'add_category_fab',
              onPressed: () => _openAdhkarLibraryModal(),
              backgroundColor: isDark
                  ? const Color(0xFF18A74C)
                  : const Color(0xFF2A531D),
              foregroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text(
                'Add Adhkar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryProgressBadge(AdhkarCategory cat, Color textColor) {
    final catItems = _allAdhkar.where((i) => i.category == cat.id).toList();
    final totalCount = catItems.length;
    final completedCount = catItems
        .where((i) => (_dailyCounts[i.id] ?? 0) >= i.countTarget)
        .length;
    final isAllDone = totalCount > 0 && completedCount == totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isAllDone
            ? const Color(0xFF14532D)
            : textColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAllDone ? Icons.check_circle_rounded : Icons.timelapse_rounded,
            size: 12.5,
            color: isAllDone ? Colors.white : textColor,
          ),
          const SizedBox(width: 4.5),
          Text(
            totalCount == 0 
                ? 'No Dhikrs'
                : (isAllDone
                      ? 'Done for today ($completedCount/$totalCount)'
                      : '$completedCount / $totalCount done today'), 
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAllDone ? Colors.white : textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestionChip(String label, bool isDark) {
    return InkWell(
      onTap: () => _openAdhkarLibraryModal(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFD4EBD0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2A531D),
          ),
        ),
      ),
    );
  }
}
