import 'package:flutter/material.dart';
import '../core/extensions/context_extensions.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;
  final FormFieldValidator<T>? validator;
  final bool isExpanded;
  final double? width;
  final Future<String?> Function()? onAddCustomCategory;
  final String? customCategoryOptionLabel;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.validator,
    this.isExpanded = true,
    this.width,
    this.onAddCustomCategory,
    this.customCategoryOptionLabel = '+ Add Custom Category',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = const Color(0xFF2A531D);

    final effectiveItemsList = List<AppDropdownItem<T>>.from(items);
    if (value != null && T == String && value.toString().isNotEmpty && !effectiveItemsList.any((item) => item.value == value)) {
      effectiveItemsList.add(
        AppDropdownItem<T>(
          value: value as T,
          label: value.toString(),
          icon: Icons.folder_outlined,
        ),
      );
    }

    final bool hasMatchingItem = value != null && effectiveItemsList.any((item) => item.value == value);
    final T? effectiveValue = hasMatchingItem ? value : (effectiveItemsList.isNotEmpty ? effectiveItemsList.first.value : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<T>(
            key: ValueKey(effectiveValue),
            value: effectiveValue,
            isExpanded: isExpanded,
            validator: validator,
            padding: const EdgeInsets.symmetric(vertical: 1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            dropdownColor: isDark ? const Color(0xFF192520) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white60 : primaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint ?? 'Select option',
              hintStyle: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 20,
                      color: isDark ? Colors.white60 : primaryColor,
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF23322B) : const Color(0xFFF4FAF3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
            ),
          items: [
            ...effectiveItemsList.map((item) {
              return DropdownMenuItem<T>(
                value: item.value,
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 18,
                        color: isDark ? const Color(0xFFA3E635) : primaryColor,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (onAddCustomCategory != null)
              DropdownMenuItem<T>(
                value: null,
                onTap: () async {
                  final newCategory = await onAddCustomCategory!();
                  if (newCategory != null && newCategory.isNotEmpty) {
                    // Handled by parent callback
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        customCategoryOptionLabel!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
        ), 
      ),
    ],
  );
}

  /// Helper dialog function to prompt the user to add a custom category
  static Future<String?> showAddCustomCategoryDialog(
    BuildContext context, {
    required String title,
    required String hintText,
    IconData icon = Icons.category_outlined,
  }) async {
    final isDark = context.isDarkMode;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF2A531D),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              filled: true,
              fillColor: isDark ? const Color(0xFF23322B) : const Color(0xFFF4FAF3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context, text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
