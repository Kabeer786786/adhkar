import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../domain/dua_item.dart';

class AddDuaModal extends ConsumerStatefulWidget {
  final DuaItem? initialDua;
  final Function(DuaItem dua) onSave;

  const AddDuaModal({super.key, this.initialDua, required this.onSave});

  static void show(
    BuildContext context, {
    DuaItem? initialDua,
    required Function(DuaItem dua) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDuaModal(initialDua: initialDua, onSave: onSave),
    );
  }

  @override
  ConsumerState<AddDuaModal> createState() => _AddDuaModalState();
}

class _AddDuaModalState extends ConsumerState<AddDuaModal> {
  final _titleController = TextEditingController();
  final _arabicController = TextEditingController();
  final _transliterationController = TextEditingController();
  final _translationController = TextEditingController();
  final _referenceController = TextEditingController();
  final _benefitsController = TextEditingController();
  String _selectedCategory = 'Daily';

  final List<String> _categories = [
    'Daily',
    'Food',
    'Sleep',
    'Hygiene',
    'Travel',
    'Protection',
  ];

  @override
  void initState() {
    super.initState();
    final savedCats = ref
        .read(storageServiceProvider)
        .getCustomCategories('dua');
    for (final cat in savedCats) {
      if (!_categories.contains(cat)) {
        _categories.add(cat);
      }
    }

    if (widget.initialDua != null) {
      final dua = widget.initialDua!;
      _titleController.text = dua.title;
      _arabicController.text = dua.arabic;
      _transliterationController.text = dua.transliteration;
      _translationController.text = dua.translation;
      _referenceController.text = dua.reference;
      _benefitsController.text = dua.benefits;
      if (_categories.contains(dua.category)) {
        _selectedCategory = dua.category;
      } else if (dua.category.isNotEmpty) {
        _categories.add(dua.category);
        _selectedCategory = dua.category;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _arabicController.dispose();
    _transliterationController.dispose();
    _translationController.dispose();
    _referenceController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final arabic = _arabicController.text.trim();

    if (title.isEmpty || arabic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a title and Arabic text.'),
        ),
      );
      return;
    }

    final savedDua = DuaItem(
      id:
          widget.initialDua?.id ??
          'custom_dua_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _selectedCategory,
      arabic: arabic,
      transliteration: _transliterationController.text.trim().isNotEmpty
          ? _transliterationController.text.trim()
          : title,
      translation: _translationController.text.trim().isNotEmpty
          ? _translationController.text.trim()
          : title,
      repeatCount: widget.initialDua?.repeatCount ?? 1,
      reference: _referenceController.text.trim().isNotEmpty
          ? _referenceController.text.trim()
          : 'Personal Custom Supplication',
      benefits: _benefitsController.text.trim().isNotEmpty
          ? _benefitsController.text.trim()
          : 'Brings peace and reward.',
      imagePath: widget.initialDua?.imagePath ?? 'assets/images/dua.png',
      isCustom: widget.initialDua?.isCustom ?? true,
    );

    HapticFeedback.lightImpact();
    widget.onSave(savedDua);
    Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2A531D)),
      filled: true,
      fillColor: context.isDarkMode
          ? const Color(0xFF23322B)
          : const Color(0xFFF9FAFB),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialDua != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xFF192520) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Drag Handle & Title Row
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isEditing ? 'Edit Dua' : 'Create Custom Dua',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A531D),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextField(
                controller: _titleController,
                decoration: _inputDecoration(
                  'Dua Title *',
                  'e.g. Dua for Peace & Protection',
                  Icons.title_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // Category Selector
              AppDropdown<String>(
                label: 'Category',
                value: _selectedCategory,
                prefixIcon: Icons.category_rounded,
                onAddCustomCategory: () async {
                  final newCatName =
                      await AppDropdown.showAddCustomCategoryDialog(
                        context,
                        title: 'Add Custom Category',
                        hintText: 'e.g. Travel & Protection',
                        icon: Icons.menu_book_rounded,
                      );
                  if (newCatName != null && newCatName.isNotEmpty) {
                    ref
                        .read(storageServiceProvider)
                        .saveCustomCategory('dua', newCatName);
                    setState(() {
                      if (!_categories.contains(newCatName)) {
                        _categories.add(newCatName);
                      }
                      _selectedCategory = newCatName;
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
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Arabic Text
              TextField(
                controller: _arabicController,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                style: AppTypography.arabicBody(
                  fontSize: 20,
                ),
                decoration: _inputDecoration(
                  'Arabic Text *',
                  'اَللَّهُمَّ حَاسِبۡنِي حِسَاباً يَسِيراً',
                  Icons.auto_awesome_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // Transliteration
              TextField(
                controller: _transliterationController,
                decoration: _inputDecoration(
                  'Transliteration',
                  'e.g. Allahumma hasibni hisaban yasira',
                  Icons.text_fields_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // Translation
              TextField(
                controller: _translationController,
                maxLines: 2,
                decoration: _inputDecoration(
                  'English Translation',
                  'e.g. O Allah, grant me an easy accounting.',
                  Icons.translate_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // Hadith Reference
              TextField(
                controller: _referenceController,
                decoration: _inputDecoration(
                  'Hadith / Book Reference',
                  'e.g. Musnad Ahmad & Sahih Ibn Hibban',
                  Icons.menu_book_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // Benefits
              TextField(
                controller: _benefitsController,
                maxLines: 2,
                decoration: _inputDecoration(
                  'Spiritual & Practical Benefits',
                  'e.g. Grants ease on the Day of Judgment.',
                  Icons.info_outline_rounded,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Save Custom Dua',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
