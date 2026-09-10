import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/models/tasbeeh_item.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../../widgets/app_header_bar.dart';
import 'tasbeeh_detail_screen.dart';
import 'widgets/tasbeeh_library_modal.dart';
import 'widgets/tasbeeh_card_tile.dart';
import 'widgets/tasbeeh_heatmap_modal.dart';

class TasbeehScreen extends ConsumerStatefulWidget {
  const TasbeehScreen({super.key});

  @override
  ConsumerState<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends ConsumerState<TasbeehScreen> {
  List<TasbeehItem> _tasbeehItems = [];
  late String _todayKey;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadItems();
  }

  void _loadItems() {
    final storage = ref.read(storageServiceProvider);
    final savedItemMaps = storage.getSavedTasbeehItems();

    if (savedItemMaps != null && savedItemMaps.isNotEmpty) {
      _tasbeehItems = savedItemMaps.map((m) => TasbeehItem.fromJson(m)).toList();
    } else {
      _tasbeehItems = List.from(TasbeehItem.defaults);
      _persistItems();
    }
  }

  void _persistItems() {
    final storage = ref.read(storageServiceProvider);
    final jsonList = _tasbeehItems.map((i) => i.toJson()).toList();
    storage.saveTasbeehItems(jsonList);
  }

  void _saveOrUpdateItem(TasbeehItem item) {
    setState(() {
      final index = _tasbeehItems.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        _tasbeehItems[index] = item;
      } else {
        _tasbeehItems.add(item);
      }
    });
    _persistItems();
  }

  void _applyMarbleToAll(String selectedAsset) {
    setState(() {
      _tasbeehItems = _tasbeehItems.map((i) => i.copyWith(marbleAsset: selectedAsset)).toList();
    });
    _persistItems();
  }

  void _deleteItem(String itemId) {
    setState(() {
      _tasbeehItems.removeWhere((i) => i.id == itemId);
    });
    _persistItems();
    HapticFeedback.mediumImpact();
    AppFloatingToast.showRemoved(context, message: 'Removed');
  }

  void _confirmDeleteSelected(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _selectedIds.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Tasbeeh${count > 1 ? 's' : ''}?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Are you sure you want to delete $count selected Tasbeeh item${count > 1 ? 's' : ''}?',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _tasbeehItems.removeWhere((i) => _selectedIds.contains(i.id));
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
                _persistItems();
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                AppFloatingToast.showRemoved(
                  context,
                  message: '$count Tasbeeh${count > 1 ? 's' : ''} deleted',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openHeatmapModal() {
    final storage = ref.read(storageServiceProvider);
    TasbeehHeatmapModal.show(
      context,
      storage: storage,
      tasbeehItems: _tasbeehItems,
    );
  }

  void _openTasbeehLibraryModal() {
    TasbeehLibraryModal.show(
      context,
      currentItems: _tasbeehItems,
      onAddItem: (item) {
        _saveOrUpdateItem(item);
      },
      onRemoveItem: (itemId) {
        _deleteItem(itemId);
      },
      onCreateCustom: (newItem) {
        _saveOrUpdateItem(newItem);
      },
    );
  }

  void _openDetailScreen(TasbeehItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TasbeehDetailScreen(
          item: item,
          onUpdate: _saveOrUpdateItem,
          onApplyToAllMarbles: _applyMarbleToAll,
          onDelete: () => _deleteItem(item.id),
        ),
      ),
    );
    setState(() {});
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color primaryGreen,
  ) {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedIds.clear();
            });
          },
        ),
        title: Text(
          '${_selectedIds.length} Selected',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
            ),
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _confirmDeleteSelected(context),
            tooltip: 'Delete Selected',
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppHeaderBar(
        title: 'Digital Tasbeeh',
        showBackButton: true,
        showDrawerButton: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF2A531D),
              size: 26,
            ),
            tooltip: 'Tasbeeh Heatmap Calendar',
            onPressed: _openHeatmapModal,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final isDark = context.isDarkMode;
    const primaryGreen = Color(0xFF2A531D);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final isAllSelected = _tasbeehItems.isNotEmpty &&
        _selectedIds.length == _tasbeehItems.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B17) : const Color(0xFFFFFFFF),
      appBar: _buildAppBar(context, isDark, textColor, primaryGreen),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (_isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECT TASBEEH',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isAllSelected) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(_tasbeehItems.map((i) => i.id));
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAllSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAllSelected ? 'Deselect All' : 'Select All',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ..._tasbeehItems.map((item) {
              final currentCount = storage.getDailyTasbeehCount(_todayKey, item.id);
              final isSelected = _selectedIds.contains(item.id);

              return TasbeehCardTile(
                item: item,
                currentCount: currentCount,
                isSelectionMode: _isSelectionMode,
                isSelected: isSelected,
                onTap: () {
                  if (_isSelectionMode) {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(item.id);
                        if (_selectedIds.isEmpty) _isSelectionMode = false;
                      } else {
                        _selectedIds.add(item.id);
                      }
                    });
                  } else {
                    _openDetailScreen(item);
                  }
                },
                onLongPress: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isSelectionMode = true;
                    if (isSelected) {
                      _selectedIds.remove(item.id);
                      if (_selectedIds.isEmpty) _isSelectionMode = false;
                    } else {
                      _selectedIds.add(item.id);
                    }
                  });
                },
              );
            }),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openTasbeehLibraryModal,
              backgroundColor: const Color(0xFF2A531D),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Tasbeeh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 4,
            ),
    );
  }
}
