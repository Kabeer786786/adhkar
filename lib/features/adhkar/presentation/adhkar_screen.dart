import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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

class _AdhkarScreenState extends ConsumerState<AdhkarScreen> {
  List<AdhkarCategory> _categories = [];
  List<DhikrItem> _allAdhkar = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final storage = ref.read(storageServiceProvider);
    final repo = AdhkarRepository();

    // 1. Load Saved Categories or set defaults
    final savedCatMaps = storage.getSavedAdhkarCategories();
    if (savedCatMaps != null && savedCatMaps.isNotEmpty) {
      _categories = savedCatMaps.map((map) => AdhkarCategory.fromJson(map)).toList();
    } else {
      _categories = repo.getDefaultCategories();
      _persistCategories();
    }

    // 2. Load Saved Adhkar Items or set defaults
    final savedItemMaps = storage.getSavedAdhkarItems();
    if (savedItemMaps != null && savedItemMaps.isNotEmpty) {
      _allAdhkar = savedItemMaps.map((map) => DhikrItem.fromJson(map)).toList();
    } else {
      _allAdhkar = repo.getAllDefaultAdhkar();
      _persistAdhkar();
    }
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Delete Adhkar?'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${category.title}" and all its Duas and Adhkar? This action cannot be undone.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteCategory(category.id);
              },
              child: const Text('Delete'),
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
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF2A531D)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.8),
      ),
    );
  }

  Widget _buildCategoryImageWidget(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
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
        return Image.file(
          file,
          fit: BoxFit.contain,
          alignment: Alignment.bottomRight,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.auto_awesome_rounded,
            size: 60,
            color: Colors.black12,
          ),
        );
      }
      return const Icon(
        Icons.auto_awesome_rounded,
        size: 60,
        color: Colors.black12,
      );
    }
  }

  void _showCategoryModal({AdhkarCategory? category}) {
    final isEdit = category != null;
    final titleController = TextEditingController(text: category?.title ?? '');
    final subtitleController = TextEditingController(text: category?.subtitle ?? '');
    final titleArController = TextEditingController(text: category?.titleAr ?? '');
    int selectedGradientIndex = category?.gradientIndex ?? 0;
    String selectedImagePath = category?.imagePath ?? AdhkarCategory.availableImages.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Build selectable images list (built-in assets + custom uploaded image if selected)
            final selectableImages = List<String>.from(AdhkarCategory.availableImages);
            if (!selectableImages.contains(selectedImagePath)) {
              selectableImages.insert(0, selectedImagePath);
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Adhkar' : 'Create New Adhkar',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Category Title Input
                    TextField(
                      controller: titleController,
                      decoration: _roundedInputDecoration(
                        labelText: 'Adhkar Title *',
                        hintText: 'e.g. Travel Duas',
                        prefixIcon: Icons.category_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subtitle / Description Input (max 2 lines)
                    TextField(
                      controller: subtitleController,
                      maxLines: 2,
                      maxLength: 100,
                      decoration: _roundedInputDecoration(
                        labelText: 'Subtitle / Description (max 2 lines)',
                        hintText: 'e.g. Duas for protection during journeys',
                        prefixIcon: Icons.description_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Arabic Title (optional)
                    TextField(
                      controller: titleArController,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(fontSize: 18),
                      decoration: _roundedInputDecoration(
                        labelText: 'Arabic Title (Optional)',
                        hintText: 'أدعية السفر',
                        prefixIcon: Icons.translate_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gradient Theme Picker (No Shadow!)
                    const Text(
                      'Select Light Gradient Theme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A531D),
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
                          final preset = AdhkarCategory.gradientPresets[index];
                          final isSelected = selectedGradientIndex == index;
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
                    const Text(
                      'Upload background-less image or select icon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A531D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: selectableImages.length + 1, // +1 for the Upload tile at index 0
                        itemBuilder: (context, index) {
                          // Index 0: Upload Image (+) Tile
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
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
                                  color: const Color(0xFFE8F4E5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF2A531D),
                                    width: 1.8,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_rounded,
                                      color: Color(0xFF2A531D),
                                      size: 24,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Upload',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A531D),
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
                                    ? const Color(0xFFE8F4E5)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
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
                    const SizedBox(height: 26),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final newCategory = AdhkarCategory(
                            id: category?.id ??
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
                        icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                        label: Text(
                          isEdit ? 'Save Changes' : 'Create Adhkar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const AppHeaderBar(title: 'ADHKAR'),
      body: _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_rounded,
                    size: 64,
                    color: Color(0xFF8C6D53),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Adhkar Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your first section to organize Duas & Adhkar',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openAdhkarLibraryModal(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Adhkar'),
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
                top: 14,
                bottom: 100,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final gradientPreset =
                    AdhkarCategory.getGradient(cat.gradientIndex);

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
                        height: 145,
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
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: gradientPreset.textColor
                                .withValues(alpha: 0.15),
                            width: 1.0,
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
                                    child: _buildCategoryImageWidget(cat.imagePath),
                                  ),
                                ),
                              ),
                            ),
 
                            // Absolute Positioned 3 Dots Popup Menu at Top Right Corner
                            Positioned(
                              top: 4,
                              right: 4,
                              child: AppActionPopupMenu<String>(
                                iconColor: gradientPreset.textColor,
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
                                      style: GoogleFonts.amiri(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: gradientPreset.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],

                                  // Category Title (1 line)
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.65,
                                    child: Text(
                                      cat.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: gradientPreset.textColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Category Subtitle (max 2 lines)
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.60,
                                    child: Text(
                                      cat.subtitle.isNotEmpty
                                          ? cat.subtitle
                                          : 'Tap to view Duas & Adhkar inside this category',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                        color: gradientPreset.textColor
                                            .withValues(alpha: 0.85),
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
                  ),
                );
              },
            ),

      // Beautiful Floating Add Button at Bottom Right
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_category_fab',
        onPressed: () => _openAdhkarLibraryModal(),
        backgroundColor: const Color(0xFF2A531D),
        foregroundColor: Colors.white,
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
}
