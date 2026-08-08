import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_header_bar.dart';
import '../data/sci_islam_data.dart';
import '../domain/models/sci_islam_item.dart';
import 'sci_islam_detail_screen.dart';

class SciIslamScreen extends StatefulWidget {
  const SciIslamScreen({super.key});

  @override
  State<SciIslamScreen> createState() => _SciIslamScreenState();
}

class _SciIslamScreenState extends State<SciIslamScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedCategories = {};

  final List<String> _categories = [
    'Astronomy',
    'Cosmology',
    'Oceanography',
    'Embryology',
    'Astrophysics',
    'Geology',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCategoryFilterModal() {
    final tempSelected = Set<String>.from(_selectedCategories);
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allSelected = tempSelected.length == _categories.length;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (allSelected) {
                              tempSelected.clear();
                            } else {
                              tempSelected.addAll(_categories);
                            }
                          });
                        },
                        child: Text(
                          allSelected ? 'Clear All' : 'Select All',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _categories.map((category) {
                      final isSelected = tempSelected.contains(category);

                      return FilterChip(
                        label: Text(category),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155)),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2A531D),
                        backgroundColor: isDark
                            ? const Color(0xFF23322B)
                            : const Color(0xFFF8FAFC),
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2A531D)
                              : (isDark
                                    ? Colors.white12
                                    : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempSelected.add(category);
                            } else {
                              tempSelected.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategories.clear();
                        _selectedCategories.addAll(tempSelected);
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A531D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
    final isDark = context.isDarkMode;
    final query = _searchController.text.trim().toLowerCase();

    final filteredItems = SciIslamData.items.where((item) {
      final matchesCategory =
          _selectedCategories.isEmpty ||
          _selectedCategories.contains(item.category);
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.shortDescription.toLowerCase().contains(query) ||
          item.surahReference.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF17241E)
            : const Color(0xFFF9F9F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'SCIENTIFIC ISLAM',
            showBackButton: true,
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
            iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
            titleWidget: Text(
              'SCIENTIFIC ISLAM',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2A531D),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Search & Filter Header Container
            Container(
              color: isDark ? const Color(0xFF192520) : Colors.white,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 2,
                bottom: 12,
              ),
              child: Row(
                children: [
                  // Search Input
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Search miracles by title, verse, or topic...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : Colors.grey.shade500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF2A531D),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF23322B)
                            : const Color(0xFFF9F9F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A531D),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter Button beside Search Bar
                  InkWell(
                    onTap: _showCategoryFilterModal,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF23322B)
                            : const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedCategories.isNotEmpty
                              ? const Color(0xFF2A531D)
                              : (isDark
                                    ? Colors.white12
                                    : const Color(0xFFE2E8F0)),
                          width: _selectedCategories.isNotEmpty ? 1.5 : 1.0,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF2A531D),
                            size: 22,
                          ),
                          if (_selectedCategories.isNotEmpty)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD97724),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 3),

            // Rectangle Cards List
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 56,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Scientific Miracles Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF2A531D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching for another topic or clearing your filters',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 50,
                        top: 10,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildRectangleCard(context, item, isDark);
                      }, 
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRectangleCard(
    BuildContext context,
    SciIslamItem item,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF2A531D).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF2A531D).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SciIslamDetailScreen(item: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Card Text Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 105, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.themeColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badgeText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: item.themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Short Description
                      Text(
                        item.shortDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF4B5563),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Surah Reference Tag
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 13,
                            color: item.themeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.surahReference,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.themeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Right Corner Image / Icon Container
                Positioned(
                  bottom: -10,
                  right: -10,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: item.themeColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: item.themeColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 38,
                          color: item.themeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
