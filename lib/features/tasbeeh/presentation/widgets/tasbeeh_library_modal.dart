import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/tasbeeh_item.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import 'add_tasbeeh_modal.dart';

enum TasbeehModalView { library, details, form }

class TasbeehLibraryModal extends StatefulWidget {
  final List<TasbeehItem> currentItems;
  final Function(TasbeehItem item) onAddItem;
  final Function(String itemId) onRemoveItem;
  final Function(TasbeehItem newItem) onCreateCustom;

  const TasbeehLibraryModal({
    super.key,
    required this.currentItems,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onCreateCustom,
  });

  static void show(
    BuildContext context, {
    required List<TasbeehItem> currentItems,
    required Function(TasbeehItem item) onAddItem,
    required Function(String itemId) onRemoveItem,
    required Function(TasbeehItem newItem) onCreateCustom,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: TasbeehLibraryModal(
          currentItems: currentItems,
          onAddItem: onAddItem,
          onRemoveItem: onRemoveItem,
          onCreateCustom: onCreateCustom,
        ),
      ),
    );
  }

  @override
  State<TasbeehLibraryModal> createState() => _TasbeehLibraryModalState();
}

class _TasbeehLibraryModalState extends State<TasbeehLibraryModal> {
  final TextEditingController _searchController = TextEditingController();
  late List<TasbeehItem> _activeItems;

  // View state: library, details, form
  TasbeehModalView _currentView = TasbeehModalView.library;
  TasbeehItem? _selectedItemForDetails;

  @override
  void initState() {
    super.initState();
    _activeItems = List.from(widget.currentItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isItemPinned(String itemId) {
    return _activeItems.any((i) => i.id == itemId);
  }

  void _toggleItem(TasbeehItem item) {
    final isPinned = _isItemPinned(item.id);
    if (isPinned) {
      widget.onRemoveItem(item.id);
      setState(() {
        _activeItems.removeWhere((i) => i.id == item.id);
      });
      AppFloatingToast.showRemoved(context, message: 'Removed');
    } else {
      widget.onAddItem(item);
      setState(() {
        _activeItems.add(item);
      });
      AppFloatingToast.showAdded(context, message: 'Added');
    }
  }

  void _openFormView() {
    setState(() {
      _currentView = TasbeehModalView.form;
    });
  }

  void _openDetailsView(TasbeehItem item) {
    setState(() {
      _selectedItemForDetails = item;
      _currentView = TasbeehModalView.details;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Drag Handle
        Center(
          child: Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF3F3F46)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Content View Switcher
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.topCenter,
                    children: <Widget>[...previousChildren, ?currentChild],
                  );
                },
            child: _buildCurrentViewContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case TasbeehModalView.library:
        return _buildLibraryView();
      case TasbeehModalView.details:
        return _buildDetailsView();
      case TasbeehModalView.form:
        return AddTasbeehModal(
          isEmbedded: true,
          onBack: () {
            setState(() {
              _currentView = TasbeehModalView.library;
            });
          },
          onSave: (newItem) {
            widget.onCreateCustom(newItem);
            setState(() {
              _activeItems.add(newItem);
              _currentView = TasbeehModalView.library;
            });
            AppFloatingToast.showAdded(
              context,
              message: 'Custom Tasbeeh created successfully',
            );
          },
        );
    }
  }

  // --- 1. LIBRARY VIEW ---
  Widget _buildLibraryView() {
    final isDark = context.isDarkMode;
    final query = _searchController.text.trim().toLowerCase();
    final allLibraryItems = TasbeehItem.defaults;
    final filteredItems = allLibraryItems.where((item) {
      return query.isEmpty ||
          item.textEn.toLowerCase().contains(query) ||
          item.textAr.contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();

    return Padding(
      key: const ValueKey('library_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasbeeh Library',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openFormView,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Tasbeeh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF18A74C)
                      : const Color(0xFF2A531D),
                  foregroundColor: isDark
                      ? const Color(0xFF0F0F12)
                      : Colors.white,
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

          // Search Field
          TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : null),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search Tasbeeh counters...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark
                    ? const Color(0xFF18A74C)
                    : const Color(0xFF2A531D),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F0F12)
                  : const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF18A74C)
                      : const Color(0xFF2A531D),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform Tasbeeh Cards List or Empty State
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptySearchState(query, isDark)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isPinned = _isItemPinned(item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openDetailsView(item),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F0F12)
                                    : item.color.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF27272A)
                                      : item.color.withValues(alpha: 0.15),
                                  width: 1.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Top Right Circle Checkbox
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _toggleItem(item),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(
                                          isPinned
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          size: 24,
                                          color: isPinned
                                              ? item.color
                                              : item.color.withValues(
                                                  alpha: 0.45,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Card Text Content
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 66.0,
                                      bottom: 14.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.textAr,
                                          textDirection: TextDirection.rtl,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.arabicBody(
                                            fontSize: 20,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1B5E20),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.textEn,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: item.color,
                                          ),
                                        ),
                                        if (item
                                            .effectiveTranslation
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            item.effectiveTranslation,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                        if (item.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey.shade700,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Right Bottom Corner Target Goal Badge
                                  Positioned(
                                    bottom: 12,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF18181B)
                                            : item.color.withValues(
                                                alpha: 0.12,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF27272A)
                                              : item.color.withValues(
                                                  alpha: 0.2,
                                                ),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flag_rounded,
                                            size: 13,
                                            color: item.color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item.targetGoal}x',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: item.color,
                                            ),
                                          ),
                                        ],
                                      ),
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

  Widget _buildEmptySearchState(String query, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF2A531D).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Tasbeeh Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'We couldn\'t find any Tasbeeh matching "$query".\nTry checking the spelling or create your own custom Tasbeeh.'
                  : 'No Tasbeeh available in the library.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openFormView,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Custom Tasbeeh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF18A74C)
                    : const Color(0xFF2A531D),
                foregroundColor: isDark
                    ? const Color(0xFF0F0F12)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. DETAILS VIEW ---
  Widget _buildDetailsView() {
    final item = _selectedItemForDetails!;
    final isPinned = _isItemPinned(item.id);
    final isDark = context.isDarkMode;

    return Column(
      key: const ValueKey('details_view'),
      children: [
        // Header with Back Button
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark
                      ? const Color(0xFF18A74C)
                      : const Color(0xFF2A531D),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _currentView = TasbeehModalView.library;
                  });
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.textEn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : item.color,
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

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Large Arabic Text
                Text(
                  item.textAr,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicBody(
                    fontSize: 26,
                    height: 1.7,
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 14),

                if (item.effectiveTranslation.isNotEmpty) ...[
                  Text(
                    item.effectiveTranslation,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Description / Virtues
                if (item.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F0F12)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Virtues & Benefits',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7E22CE),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Target Goal Badge
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(
                        Icons.flag_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      label: Text('Target Goal: ${item.targetGoal}x'),
                      backgroundColor: item.color,
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Fixed Footer Button
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
              child: ElevatedButton.icon(
                onPressed: () {
                  _toggleItem(item);
                  setState(() {
                    _currentView = TasbeehModalView.library;
                  });
                },
                icon: Icon(
                  isPinned
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_rounded,
                  size: 20,
                ),
                label: Text(
                  isPinned ? 'Remove from Main Screen' : 'Add to Main Screen',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPinned
                      ? Colors.red.shade700
                      : (isDark
                            ? const Color(0xFF18A74C)
                            : const Color(0xFF2A531D)),
                  foregroundColor: isPinned
                      ? Colors.white
                      : (isDark ? const Color(0xFF0F0F12) : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 13),
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
  }
}
