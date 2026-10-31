import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/books_provider.dart';

class BookFilterModal extends ConsumerStatefulWidget {
  const BookFilterModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BookFilterModal(),
    );
  }

  @override
  ConsumerState<BookFilterModal> createState() => _BookFilterModalState();
}

class _BookFilterModalState extends ConsumerState<BookFilterModal> {
  late String _selectedCat;
  late String _selectedSort;

  static const List<String> _categories = [
    'All',
    'Hadith',
    'Seerah',
    'Fiqh',
    'Aqeedah',
    'Tazkiyah',
    'Custom',
  ];

  static const List<String> _sortOptions = [
    'Default',
    'Title (A - Z)',
    'Author (A - Z)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCat = ref.read(selectedBookCategoryProvider);
    _selectedSort = ref.read(bookSortOptionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filter & Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 1: Book Category
          Text(
            'Select Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCat == cat;
              return ChoiceChip(
                showCheckmark: true,
                checkmarkColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                label: Text(cat),
                selected: isSelected,
                selectedColor: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: isDark
                      ? (isSelected ? const Color(0xFF18A74C) : const Color(0xFF27272A))
                      : (isSelected ? const Color(0xFF2A531D) : Colors.transparent),
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (isDark ? const Color(0xFF0F0F12) : Colors.white)
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedCat = cat);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Section 2: Sort By
          Text(
            'Sort Order',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((opt) {
              final isSelected = _selectedSort == opt;
              return ChoiceChip(
                showCheckmark: true,
                checkmarkColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                label: Text(opt),
                selected: isSelected,
                selectedColor: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97724),
                backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: isDark
                      ? (isSelected ? const Color(0xFFF59E0B) : const Color(0xFF27272A))
                      : (isSelected ? const Color(0xFFD97724) : Colors.transparent),
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (isDark ? const Color(0xFF0F0F12) : Colors.white)
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedSort = opt);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ref.read(selectedBookCategoryProvider.notifier).state =
                    _selectedCat;
                ref.read(bookSortOptionProvider.notifier).state = _selectedSort;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                foregroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Apply Preferences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
