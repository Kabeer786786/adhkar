import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import '../../domain/dua_item.dart';

class AddDuaModal extends ConsumerStatefulWidget {
  final DuaItem? initialDua;
  final Function(DuaItem dua) onSave;
  final VoidCallback? onBack;
  final bool isEmbedded;

  const AddDuaModal({
    super.key,
    this.initialDua,
    required this.onSave,
    this.onBack,
    this.isEmbedded = false,
  });

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
      AppFloatingToast.showError(
        context,
        message: 'Please enter at least a title and Arabic text.',
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
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    final isDark = context.isDarkMode;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : const Color(0xFF64748B),
        fontSize: 14,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.grey.shade400,
        fontSize: 13.5,
      ),
      prefixIcon: Icon(
        icon,
        color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFB),
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
          color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
          width: 1.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialDua != null;
    final isDark = context.isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF18A74C)
        : const Color(0xFF2A531D);

    final formContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Drag Handle
        if (!widget.isEmbedded)
          Center(
            child: Container(
              width: 60,
              height: 4.5,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

        // Top Header Row with only Left Arrow and Plain Text Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                color: primaryColor,
                onPressed: widget.onBack ?? () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isEditing ? 'Edit Dua' : 'Create Custom Dua',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),

        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
        ),

        // Scrollable Form Fields
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14.5,
                  ),
                  decoration: _inputDecoration(
                    'Dua Title *',
                    'e.g. Dua for Peace & Protection',
                    Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Category Selector (No icons for categories)
                AppDropdown<String>(
                  label: 'Category',
                  value: _selectedCategory,
                  prefixIcon: null,
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
                    return AppDropdownItem<String>(value: cat, label: cat);
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
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  ),
                  decoration: _inputDecoration(
                    'Arabic Text *',
                    'اَللَّهُمَّ حَاسِبْنِي حِسَاباً يَسِيراً',
                    Icons.auto_awesome_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Transliteration
                TextField(
                  controller: _transliterationController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    'Spiritual & Practical Benefits',
                    'e.g. Grants ease on the Day of Judgment.',
                    Icons.info_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Actions Bar (Only Save Button with decreased bottom padding)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(
                  isEditing
                      ? Icons.check_circle_rounded
                      : Icons.bookmark_added_rounded,
                  size: 19,
                ),
                label: Text(
                  isEditing ? 'Save Changes' : 'Save Custom Dua',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark
                      ? const Color(0xFF0F0F12)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return formContent;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: formContent,
      ),
    );
  }
}
