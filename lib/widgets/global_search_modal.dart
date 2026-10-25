import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/extensions/context_extensions.dart';
import '../core/services/global_search_service.dart';
import '../shared/providers/app_providers.dart';

/// Backward-compatible model
class SearchSuggestionItem {
  final String title;
  final String category;
  final IconData icon;
  final String route;

  const SearchSuggestionItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.route,
  });
}

class GlobalSearchModal extends ConsumerStatefulWidget {
  final bool autoFocus;
  const GlobalSearchModal({super.key, this.autoFocus = true});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const GlobalSearchModal(),
    );
  }

  @override
  ConsumerState<GlobalSearchModal> createState() => _GlobalSearchModalState();
}

class _GlobalSearchModalState extends ConsumerState<GlobalSearchModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalSearchService _searchService = GlobalSearchService();

  String _query = '';
  GlobalSearchCategory _selectedCategory = GlobalSearchCategory.all;

  @override
  void initState() {
    super.initState();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onItemTapped(GlobalSearchItem item) {
    final storage = ref.read(storageServiceProvider);
    // Store either query or item title in search history
    final historyEntry = _query.trim().isNotEmpty ? _query.trim() : item.title;
    storage.addSearchHistory(historyEntry);

    Navigator.of(context, rootNavigator: true).pop();
    context.push(item.route);
  }

  void _onHistoryQueryTapped(String term) {
    HapticFeedback.selectionClick();
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    setState(() {
      _query = term;
    });
  }

  void _deleteHistoryItem(String term) {
    HapticFeedback.lightImpact();
    final storage = ref.read(storageServiceProvider);
    storage.removeSearchHistoryItem(term);
    setState(() {});
  }

  void _clearAllHistory() {
    HapticFeedback.mediumImpact();
    final storage = ref.read(storageServiceProvider);
    storage.clearSearchHistory();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final recentHistory = storage.getSearchHistory();

    final hasQuery = _query.trim().isNotEmpty;
    // Always returns top 10 matches
    final results = _searchService.search(
      _query,
      filterCategory: _selectedCategory,
    );
    final quickShortcuts = _searchService.getQuickShortcuts();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 24),
      backgroundColor: context.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Field
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (val) {
                setState(() {
                  _query = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Surahs, Juz, Duas, 99 Names, Books...',
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colorScheme.primary,
                  size: 22,
                ),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            const SizedBox(height: 10),

            // Category Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: GlobalSearchCategory.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = GlobalSearchCategory.values[index];
                  final isSelected = _selectedCategory == cat;

                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected
                          ? context.colorScheme.onPrimary
                          : context.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(cat.label),
                    labelPadding: const EdgeInsets.only(right: 10, left:-2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? context.colorScheme.onPrimary
                          : context.colorScheme.onSurface,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: isDark
                        ? context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                        : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    selectedColor: context.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),

            // Search Content / Results Area (Shows results if query entered OR category pill selected)
            Expanded(
              child: (hasQuery || _selectedCategory != GlobalSearchCategory.all)
                  ? _buildSearchResults(results)
                  : _buildIdleContent(recentHistory, quickShortcuts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<GlobalSearchItem> results) {
    final isCategoryFiltered = _selectedCategory != GlobalSearchCategory.all;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                _query.trim().isNotEmpty
                    ? 'No matches found for "$_query"'
                    : 'No items in ${_selectedCategory.label}',
                textAlign: TextAlign.center,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try searching for Surah name, Juz number, Dua, Asma Ul Husna, or app feature.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isCategoryFiltered) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = GlobalSearchCategory.all;
                    });
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Show All Categories'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final titleText = isCategoryFiltered
        ? '${_selectedCategory.label} (${results.length})'
        : 'Top Matches (${results.length})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isCategoryFiltered)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = GlobalSearchCategory.all;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.close_rounded, size: 13, color: context.colorScheme.primary),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'Top 10 ranked',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final item = results[index];
              return _buildSearchResultTile(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(GlobalSearchItem item) {
    final hasArabic = item.arabic != null && item.arabic!.trim().isNotEmpty;
    // Omit Arabic in overflowing/long cases to keep tile compact with clean English ellipsis
    final isOverflowProne = item.title.length > 24 || (hasArabic && item.arabic!.trim().length > 16);
    final showArabic = hasArabic && !isOverflowProne;

    return InkWell(
      onTap: () => _onItemTapped(item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: context.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // English Title with maxLines: 1 and ellipsis
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Only include Arabic if not overflowing, wrapped in Flexible with ellipsis
                      if (showArabic) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.arabic!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 13,
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Interactive Category Pill: Tapping filters immediately to this category
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = item.categoryType;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _selectedCategory == item.categoryType
                                ? context.colorScheme.primary.withValues(alpha: 0.15)
                                : context.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _selectedCategory == item.categoryType
                                  ? context.colorScheme.primary.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _selectedCategory == item.categoryType
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Subtitle with maxLines: 1 and ellipsis
                      Expanded(
                        child: Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleContent(
    List<String> recentHistory,
    List<GlobalSearchItem> shortcuts,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Recent Searches Section (up to 25 items stored locally)
        if (recentHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Recent Searches (${recentHistory.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _clearAllHistory,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: recentHistory.map((term) {
              return InkWell(
                onTap: () => _onHistoryQueryTapped(term),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 13,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          term,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _deleteHistoryItem(term),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
        ],

        // Popular Shortcuts Section
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Popular Shortcuts',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...shortcuts.map((item) => _buildSearchResultTile(item)),
      ],
    );
  }
}
