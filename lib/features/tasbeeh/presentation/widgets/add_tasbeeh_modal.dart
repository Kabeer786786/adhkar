import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/tasbeeh_item.dart';
import '../../../../shared/widgets/app_floating_toast.dart';

class AddTasbeehModal extends StatefulWidget {
  final TasbeehItem? existingItem;
  final Function(TasbeehItem item) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onBack;
  final bool isEmbedded;

  const AddTasbeehModal({
    super.key,
    this.existingItem,
    required this.onSave,
    this.onDelete,
    this.onBack,
    this.isEmbedded = false,
  });

  static void show(
    BuildContext context, {
    TasbeehItem? existingItem,
    required Function(TasbeehItem item) onSave,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTasbeehModal(
        existingItem: existingItem,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<AddTasbeehModal> createState() => _AddTasbeehModalState();
}

class _AddTasbeehModalState extends State<AddTasbeehModal> {
  late TextEditingController _textArController;
  late TextEditingController _textEnController;
  late TextEditingController _translationController;
  late TextEditingController _targetController;
  late TextEditingController _descController;
  late int _selectedColorValue;

  static const List<int> colorOptions = [
    0xFF0284C7, // Sky Blue
    0xFF16A34A, // Emerald Green
    0xFFEA580C, // Orange
    0xFF9333EA, // Purple
    0xFF059669, // Teal
    0xFFD97724, // Gold
    0xFFDC2626, // Crimson
    0xFF2563EB, // Royal Blue
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _textArController = TextEditingController(text: item?.textAr ?? '');
    _textEnController = TextEditingController(text: item?.textEn ?? '');
    _translationController = TextEditingController(
      text: item?.translation ?? '',
    );
    _targetController = TextEditingController(
      text: '${item?.targetGoal ?? 33}',
    );
    _descController = TextEditingController(text: item?.description ?? '');
    _selectedColorValue = item?.colorValue ?? colorOptions.first;
  }

  @override
  void dispose() {
    _textArController.dispose();
    _textEnController.dispose();
    _translationController.dispose();
    _targetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final ar = _textArController.text.trim();
    final en = _textEnController.text.trim();
    final translation = _translationController.text.trim();
    final target = int.tryParse(_targetController.text.trim()) ?? 33;
    final desc = _descController.text.trim();

    if (ar.isEmpty || en.isEmpty) {
      AppFloatingToast.showError(
        context,
        message: 'Please enter Arabic text and English title.',
      );
      return;
    }

    final id =
        widget.existingItem?.id ??
        'custom_${DateTime.now().millisecondsSinceEpoch}';

    final newItem = TasbeehItem(
      id: id,
      textAr: ar,
      textEn: en,
      translation: translation,
      description: desc,
      targetGoal: target > 0 ? target : 33,
      colorValue: _selectedColorValue,
      isCustom: true,
    );

    HapticFeedback.lightImpact();
    widget.onSave(newItem);
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
      labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
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
    final isEdit = widget.existingItem != null;
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

        // Header Row with Left Arrow, Title, and optional Delete Button
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
                  isEdit ? 'Edit Tasbeeh' : 'Create Custom Tasbeeh',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
              ),
              if (isEdit && widget.onDelete != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDelete!();
                  },
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic Text Field
                TextField(
                  controller: _textArController,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicBody(
                    fontSize: 20,
                    color: isDark ? Colors.white : null,
                  ),
                  decoration: _inputDecoration(
                    'Arabic Text *',
                    'سُبْحَانَ اللَّهِ',
                    Icons.auto_awesome_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // English Transliteration Field
                TextField(
                  controller: _textEnController,
                  style: TextStyle(color: isDark ? Colors.white : null),
                  decoration: _inputDecoration(
                    'English Transliteration / Title *',
                    'SubhanAllah',
                    Icons.text_fields_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // English Translation Field
                TextField(
                  controller: _translationController,
                  style: TextStyle(color: isDark ? Colors.white : null),
                  decoration: _inputDecoration(
                    'English Translation / Meaning',
                    'Glory be to Allah',
                    Icons.translate_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Target Goal Field
                TextField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : null),
                  decoration: _inputDecoration(
                    'Target Count (Goal)',
                    '33',
                    Icons.flag_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Description Field
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: TextStyle(color: isDark ? Colors.white : null),
                  decoration: _inputDecoration(
                    'Description / Benefits',
                    'Enter virtues or why this Tasbeeh is recited...',
                    Icons.info_outline_rounded,
                  ),
                ),
                const SizedBox(height: 16),

                // Color Selection Row
                Text(
                  'Theme Color',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white70
                        : context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colorOptions.map((cVal) {
                    final isSelected = cVal == _selectedColorValue;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorValue = cVal),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(cVal),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(cVal).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Fixed Bottom Save Button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
              child: ElevatedButton(
                onPressed: _handleSave,
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
                child: Text(
                  isEdit ? 'Save Changes' : 'Save Custom Tasbeeh',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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
