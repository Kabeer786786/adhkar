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
import 'widgets/add_tasbeeh_modal.dart';
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

  void _openAddModal({TasbeehItem? existing}) {
    AddTasbeehModal.show(
      context,
      existingItem: existing,
      onSave: _saveOrUpdateItem,
      onDelete: existing != null ? () => _deleteItem(existing.id) : null,
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

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);

    return Scaffold(
      backgroundColor: context.isDarkMode ? const Color(0xFF121B17) : const Color(0xFFFFFFFF),

      appBar: PreferredSize(
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
      ),

      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            ..._tasbeehItems.map((item) {
              final currentCount = storage.getDailyTasbeehCount(_todayKey, item.id);
              return TasbeehCardTile(
                item: item,
                currentCount: currentCount,
                onTap: () => _openDetailScreen(item),
                onLongPress: () => _openAddModal(existing: item), 
              );
            }),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
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
