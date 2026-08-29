import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/models/tasbeeh_item.dart';

class AddTasbeehModal extends StatefulWidget {
  final TasbeehItem? existingItem;
  final Function(TasbeehItem item) onSave;
  final VoidCallback? onDelete;

  const AddTasbeehModal({
    super.key,
    this.existingItem,
    required this.onSave,
    this.onDelete,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Arabic text and English title.'),
        ),
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
    final isEdit = widget.existingItem != null;

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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Tasbeeh' : 'Add Custom Tasbeeh',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A531D),
                    ),
                  ),
                  if (isEdit && widget.onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Arabic Text Field
              TextField(
                controller: _textArController,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputDecoration(
                  'Arabic Text',
                  'سُبۡحَانَ اللَّهِ',
                  Icons.auto_awesome_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // English Transliteration Field
              TextField(
                controller: _textEnController,
                decoration: _inputDecoration(
                  'English Transliteration / Title',
                  'SubhanAllah',
                  Icons.text_fields_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // English Translation Field
              TextField(
                controller: _translationController,
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
                decoration: _inputDecoration(
                  'Target Count (Goal)',
                  '33',
                  Icons.flag_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // Description Field (Why it is recited)
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Description / Benefits (Why it is recited)',
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
                  color: context.colorScheme.onSurfaceVariant,
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
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _handleSave,
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
                  isEdit ? 'Save Changes' : 'Add Tasbeeh',
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
