import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_typography.dart';
import '../../../shared/models/dhikr_item.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/m3_card.dart';
import '../../../widgets/app_action_popup_menu.dart';
import '../repositories/adhkar_repository.dart';

class AdhkarDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String title;

  const AdhkarDetailScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  @override
  ConsumerState<AdhkarDetailScreen> createState() => _AdhkarDetailScreenState();
}

class _AdhkarDetailScreenState extends ConsumerState<AdhkarDetailScreen> {
  List<DhikrItem> _allAdhkar = [];
  List<DhikrItem> _categoryAdhkar = [];
  Map<String, int> _dailyCounts = {};
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late String _todayDateKey;

  @override
  void initState() {
    super.initState();
    _todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  void _loadData() {
    final storage = ref.read(storageServiceProvider);
    final repo = AdhkarRepository();

    final savedMaps = storage.getSavedAdhkarItems();
    if (savedMaps != null && savedMaps.isNotEmpty) {
      _allAdhkar = savedMaps.map((map) => DhikrItem.fromJson(map)).toList();
    } else {
      _allAdhkar = repo.getAllDefaultAdhkar();
      _persistAdhkar();
    }

    _dailyCounts = storage.getDailyAdhkarCounts(_todayDateKey);
    _filterCategoryItems();
  }

  void _filterCategoryItems() {
    setState(() {
      _categoryAdhkar = _allAdhkar
          .where((item) => item.category == widget.categoryId)
          .toList();
      if (_currentIndex >= _categoryAdhkar.length &&
          _categoryAdhkar.isNotEmpty) {
        _currentIndex = _categoryAdhkar.length - 1;
      }
    });
  }

  void _persistAdhkar() {
    final storage = ref.read(storageServiceProvider);
    final mapList = _allAdhkar.map((i) => i.toJson()).toList();
    storage.saveAdhkarItems(mapList);
  }

  void _incrementCount(String id, int target) {
    final storage = ref.read(storageServiceProvider);
    final current = _dailyCounts[id] ?? 0;

    if (current < target) {
      final newCount = current + 1;
      setState(() {
        _dailyCounts[id] = newCount;
      });
      storage.saveDailyAdhkarCount(_todayDateKey, id, newCount);

      if (newCount == target) {
        HapticFeedback.mediumImpact();
        // Smoothly scroll to next dhikr after 450ms if target reached
        if (_currentIndex < _categoryAdhkar.length - 1) {
          Future.delayed(const Duration(milliseconds: 450), () {
            if (mounted && _pageController.hasClients) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _resetCount(String id) {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _dailyCounts[id] = 0;
    });
    storage.saveDailyAdhkarCount(_todayDateKey, id, 0);
    HapticFeedback.selectionClick();
  }

  void _saveOrUpdateDhikr(DhikrItem item) {
    setState(() {
      final index = _allAdhkar.indexWhere((element) => element.id == item.id);
      if (index >= 0) {
        _allAdhkar[index] = item;
      } else {
        _allAdhkar.insert(0, item);
      }
    });
    _persistAdhkar();
    _filterCategoryItems();
    HapticFeedback.lightImpact();
  }

  void _deleteDhikr(String id) {
    setState(() {
      _allAdhkar.removeWhere((element) => element.id == id);
      _dailyCounts.remove(id);
    });
    _persistAdhkar();
    _filterCategoryItems();
    HapticFeedback.mediumImpact();
  }

  void _confirmDeleteDhikr(DhikrItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Delete Dua / Dhikr?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this Dhikr item? This action cannot be undone.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteDhikr(item.id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _roundedDecoration({
    required String labelText, 
    String? hintText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.8),
      ),
    );
  }

  void _showAddEditDhikrDialog({DhikrItem? item}) {
    final isEdit = item != null;
    final arabicController = TextEditingController(
      text: item?.arabicText ?? '',
    );
    final transliterationController = TextEditingController(
      text: item?.transliteration ?? '',
    );
    final translationController = TextEditingController(
      text: item?.translation ?? '',
    );
    final referenceController = TextEditingController(
      text: item?.reference ?? '',
    );
    final virtueController = TextEditingController(text: item?.virtue ?? '');
    final countController = TextEditingController(
      text: (item?.countTarget ?? 1).toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Dua / Dhikr' : 'Add New Dua / Dhikr',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: arabicController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      style: AppTypography.arabicBody(fontSize: 20, height: 1.8),
                      decoration: _roundedDecoration(
                        labelText: 'Arabic Text *',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: transliterationController,
                      decoration: _roundedDecoration(
                        labelText: 'Transliteration (Optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: translationController,
                      maxLines: 2,
                      decoration: _roundedDecoration(
                        labelText: 'Translation (Optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: referenceController,
                      decoration: _roundedDecoration(
                        labelText: 'Reference (e.g. Muslim 1/414)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: virtueController,
                      decoration: _roundedDecoration(
                        labelText: 'Virtue / Benefit (Optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) {
                        setModalState(() {});
                      },
                      decoration: _roundedDecoration(
                        labelText: 'Target Recitation Count (Custom)',
                        hintText: 'Enter custom count (e.g. 33)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [1, 3, 7, 10, 33, 99, 100].map((presetVal) {
                          final isSelected =
                              countController.text.trim() == presetVal.toString();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('$presetVal x'),
                              selected: isSelected,
                              selectedColor: const Color(0xFF2A531D),
                              backgroundColor: const Color(0xFFF3F4F6),
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2A531D)
                                    : const Color(0xFFE5E7EB),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? Colors.white
                                    : const Color(0xFF2A531D),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    countController.text = presetVal.toString();
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (arabicController.text.trim().isEmpty) return;
                          final parsedTarget =
                              int.tryParse(countController.text.trim());
                          final finalTarget =
                              (parsedTarget != null && parsedTarget > 0)
                                  ? parsedTarget
                                  : 1;

                          final newItem = DhikrItem(
                            id:
                                item?.id ??
                                'dhikr_${DateTime.now().millisecondsSinceEpoch}',
                            category: widget.categoryId,
                            arabicText: arabicController.text.trim(),
                            transliteration: transliterationController.text
                                .trim(),
                            translation: translationController.text.trim(),
                            reference: referenceController.text.trim().isEmpty
                                ? 'Custom Dua / Dhikr'
                                : referenceController.text.trim(),
                            virtue: virtueController.text.trim(),
                            countTarget: finalTarget,
                          );

                          _saveOrUpdateDhikr(newItem);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          isEdit ? Icons.save_rounded : Icons.add_rounded,
                        ),
                        label: Text(
                          isEdit ? 'Save Changes' : 'Add Dua / Dhikr',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DhikrItem? activeItem;
    if (_categoryAdhkar.isNotEmpty && _currentIndex < _categoryAdhkar.length) {
      activeItem = _categoryAdhkar[_currentIndex];
    }
    final activeCount = activeItem != null
        ? (_dailyCounts[activeItem.id] ?? 0)
        : 0;
    final isActiveDone =
        activeItem != null && activeCount >= activeItem.countTarget;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF2A531D),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddEditDhikrDialog(),
            icon: const Icon(Icons.add_rounded, color: Color(0xFF2A531D)),
            tooltip: 'Add Dua / Dhikr',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _categoryAdhkar.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    size: 64,
                    color: Color(0xFF8C6D53),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Duas or Adhkar found inside',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap the button below to add your first Dhikr',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDhikrDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Dua / Dhikr'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A531D),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top Progress & Counter Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4E5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          '${_currentIndex + 1} of ${_categoryAdhkar.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          if (_categoryAdhkar.isNotEmpty) {
                            final currentItem = _categoryAdhkar[_currentIndex];
                            _resetCount(currentItem.id);
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Reset Count',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2A531D),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Smooth Horizontal Scrollable PageView (Single Screen Per Dhikr)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categoryAdhkar.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _categoryAdhkar[index];
                      final count = _dailyCounts[item.id] ?? 0;
                      final isDone = count >= item.countTarget;

                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 0,
                          bottom: 14,
                        ),
                        child: M3Card(
                          color: Colors.white,
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFFD9A925)
                                : Colors.grey.shade200,
                            width: isDone ? 1.5 : 1.0,
                          ),
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Card Top Row: Options Menu
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isDone)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2A531D),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Completed',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    AppActionPopupMenu<String>(
                                      items: const [
                                        AppActionMenuItem(
                                          value: 'edit',
                                          title: 'Edit Dua / Dhikr',
                                          icon: Icons.edit_outlined,
                                        ),
                                        AppActionMenuItem(
                                          value: 'reset',
                                          title: 'Reset Count',
                                          icon: Icons.refresh_rounded,
                                        ),
                                        AppActionMenuItem(
                                          value: 'delete',
                                          title: 'Delete Item',
                                          icon: Icons.delete_outline_rounded,
                                          isDestructive: true,
                                        ),
                                      ],
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showAddEditDhikrDialog(item: item);
                                        } else if (val == 'reset') {
                                          _resetCount(item.id);
                                        } else if (val == 'delete') {
                                          _confirmDeleteDhikr(item);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Arabic Script Display
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    item.arabicText,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: AppTypography.arabicBody(
                                      fontSize: 24,
                                      height: 2.1,
                                      color: const Color(0xFF2A531D),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),
                                const SizedBox(height: 14),

                                // Transliteration
                                if (item.transliteration.isNotEmpty) ...[
                                  Text(
                                    item.transliteration,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // Translation
                                if (item.translation.isNotEmpty) ...[
                                  Text(
                                    item.translation,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // Reference & Virtue
                                if (item.reference.isNotEmpty ||
                                    item.virtue.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (item.reference.isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.bookmark_rounded,
                                                size: 15,
                                                color: Color(0xFF8C6D53),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                item.reference,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8C6D53),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (item.reference.isNotEmpty &&
                                            item.virtue.isNotEmpty)
                                          const SizedBox(height: 6),
                                        if (item.virtue.isNotEmpty)
                                          Text(
                                            item.virtue,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.35,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ), 
                ),

                // Bottom Circles / Page Indicator Dots
                if (_categoryAdhkar.length > 1)
                  Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_categoryAdhkar.length, (
                        dotIndex,
                      ) {
                        final isSelected = dotIndex == _currentIndex;
                        final dhikr = _categoryAdhkar[dotIndex];
                        final isCompleted =
                            (_dailyCounts[dhikr.id] ?? 0) >= dhikr.countTarget;

                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              dotIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 10,
                            width: isSelected ? 24 : 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: isSelected
                                  ? const Color(0xFF2A531D)
                                  : (isCompleted
                                        ? const Color(0xFFD9A925)
                                        : Colors.grey.shade300),
                            ),
                          ),
                        );
                      }),
                    ),
                  )
                else
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
              ],
            ),

      // Positioned Count Button & Reset Button at Bottom Right Corner
      floatingActionButton: activeItem != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Small Reset FAB
                FloatingActionButton.small(
                  heroTag: 'detail_reset_fab',
                  onPressed: () => _resetCount(activeItem!.id),
                  backgroundColor: const Color(0xFFE8F4E5),
                  foregroundColor: const Color(0xFF2A531D),
                  elevation: 3,
                  tooltip: 'Reset Count',
                  child: const Icon(Icons.refresh_rounded, size: 20),
                ),
                const SizedBox(height: 10),

                // Main Interactive Counter FAB (+1 / Target)
                FloatingActionButton.large(
                  heroTag: 'detail_count_fab',
                  onPressed: () =>
                      _incrementCount(activeItem!.id, activeItem.countTarget),
                  backgroundColor: isActiveDone
                      ? const Color(0xFFD9A925)
                      : const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isActiveDone)
                        const Icon(
                          Icons.check_rounded,
                          size: 36,
                          color: Colors.white,
                        )
                      else ...[
                        Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '/ ${activeItem.countTarget}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
