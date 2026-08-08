import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/models/tasbeeh_item.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../widgets/app_header_bar.dart';
import 'widgets/add_tasbeeh_modal.dart';
import 'widgets/marble_beads_counter.dart';
import 'widgets/marble_style_modal.dart';
import 'widgets/tasbeeh_description_modal.dart';

class TasbeehDetailScreen extends ConsumerStatefulWidget {
  final TasbeehItem item;
  final Function(TasbeehItem updatedItem)? onUpdate;
  final Function(String selectedAsset)? onApplyToAllMarbles;
  final VoidCallback? onDelete;

  const TasbeehDetailScreen({
    super.key,
    required this.item,
    this.onUpdate,
    this.onApplyToAllMarbles,
    this.onDelete,
  });

  @override
  ConsumerState<TasbeehDetailScreen> createState() =>
      _TasbeehDetailScreenState();
}

class _TasbeehDetailScreenState extends ConsumerState<TasbeehDetailScreen> {
  final GlobalKey<MarbleBeadsCounterState> _marbleCounterKey =
      GlobalKey<MarbleBeadsCounterState>();
  late TasbeehItem _item;
  late String _todayKey;
  int _count = 0;
  late int _targetGoal;
  bool _swipeLeftToRight = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _targetGoal = _item.targetGoal;
    _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCount();
      _loadSwipeConfig();
    });
  }

  void _loadSwipeConfig() {
    final storage = ref.read(storageServiceProvider);
    final direction = storage.getTasbeehSwipeDirection();
    setState(() {
      _swipeLeftToRight = (direction == 'left_to_right');
    });
  }

  void _openSwipeConfigModal() {
    showDialog(
      context: context,
      builder: (context) {
        String tempDirection = _swipeLeftToRight
            ? 'left_to_right'
            : 'right_to_left';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFF2A531D)),
                  SizedBox(width: 10),
                  Text(
                    'Swipe Direction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose which direction to swipe the marble beads to count:',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSwipeOption(
                    context: context,
                    title: 'Swipe Right-to-Left (←)',
                    subtitle: 'Swipe finger left to increment',
                    value: 'right_to_left',
                    groupValue: tempDirection,
                    onTap: () {
                      setModalState(() {
                        tempDirection = 'right_to_left';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSwipeOption(
                    context: context,
                    title: 'Swipe Left-to-Right (→)',
                    subtitle: 'Swipe finger right to increment',
                    value: 'left_to_right',
                    groupValue: tempDirection,
                    onTap: () {
                      setModalState(() {
                        tempDirection = 'left_to_right';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A531D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final storage = ref.read(storageServiceProvider);
                    storage.setTasbeehSwipeDirection(tempDirection);
                    setState(() {
                      _swipeLeftToRight = (tempDirection == 'left_to_right');
                    });
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                  },
                  child: const Text('Save Preference'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSwipeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2A531D).withValues(alpha: 0.08)
              : (context.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2A531D)
                : (context.isDarkMode
                      ? Colors.white12
                      : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF2A531D) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadCount() {
    final storage = ref.read(storageServiceProvider);
    final savedCount = storage.getDailyTasbeehCount(_todayKey, _item.id);
    setState(() {
      _count = savedCount;
    });
  }

  void _incrementCount() {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _count++;
    });
    storage.setDailyTasbeehCount(_todayKey, _item.id, _count);
  }

  void _decrementCount() {
    if (_count <= 0) return;
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _count--;
    });
    storage.setDailyTasbeehCount(_todayKey, _item.id, _count);
  }

  void _resetCount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Color(0xFF2A531D)),
            SizedBox(width: 8),
            Text('Reset Counter?'),
          ],
        ),
        content: Text(
          'Are you sure you want to reset today\'s count for "${_item.textEn}" back to 0?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A531D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              final storage = ref.read(storageServiceProvider);
              setState(() {
                _count = 0;
              });
              storage.setDailyTasbeehCount(_todayKey, _item.id, 0);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _openMarbleStyleModal() {
    MarbleStyleModal.show(
      context,
      currentAsset: _item.marbleAsset,
      onSelect: (selectedAsset, applyToAll) {
        setState(() {
          _item = _item.copyWith(marbleAsset: selectedAsset);
        });
        widget.onUpdate?.call(_item);
        if (applyToAll) {
          widget.onApplyToAllMarbles?.call(selectedAsset);
        }
        HapticFeedback.mediumImpact();
      },
    );
  }

  void _editTasbeeh() {
    AddTasbeehModal.show(
      context,
      existingItem: _item,
      onSave: (updated) {
        setState(() {
          _item = updated;
          _targetGoal = updated.targetGoal;
        });
        widget.onUpdate?.call(updated);
      },
      onDelete: () {
        widget.onDelete?.call();
        Navigator.pop(context);
      },
    );
  }

  void _openDescriptionModal() {
    TasbeehDescriptionModal.show(context, _item);
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final rawLifetime = storage.getLifetimeTasbeehCount(_item.id);
    final lifetimeCount = math.max(rawLifetime, _count);

    final progress = _targetGoal > 0
        ? (_count / _targetGoal).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = _count >= _targetGoal;

    return Scaffold(
      // Light color theme background for detail screen
      backgroundColor: context.isDarkMode
          ? const Color(0xFF14201B)
          : const Color(0xFFF9F9F9),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppHeaderBar(
          title: _item.textEn,
          showBackButton: true,
          showDrawerButton: false,
          actions: [
            // Marble Style Selector Icon Beside Reset Icon
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Change Marble Bead Style',
              onPressed: _openMarbleStyleModal,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Today\'s Count',
              onPressed: _resetCount,
            ),
            if (_item.isCustom)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Tasbeeh',
                onPressed: _editTasbeeh,
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Tapping anywhere on the screen triggers marble counter increment!
            _marbleCounterKey.currentState?.triggerTapIncrement();
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              // Top Content: Tasbeeh Card & Target Goal Chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // 1. Top Main Tasbeeh Card with Info (i) Icon at Top Right Corner
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF1E2923)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _item.color.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ), 
                      child: Stack(
                        children: [
                          // 1. Perfectly Centered Content across the card
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 22,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _item.textAr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.amiri(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                      color: context.isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF1E3816),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Transliteration
                                  Text(
                                    _item.textEn,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _item.color,
                                    ),
                                  ),

                                  // Translation below Transliteration
                                  if (_item.effectiveTranslation.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _item.effectiveTranslation,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.lexend(
                                        fontSize: 13.5,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                        color: context.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // 2. Info (i) Icon Button positioned absolutely at Top Right Corner
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _item.color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: _item.color,
                                ),
                              ),
                              tooltip: 'Why Recite This? (Virtues & Benefits)',
                              onPressed: _openDescriptionModal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Clean Inline Target Goal Selector (No Box Container!)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target Goal:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            children: [33, 99, 100, 1000].map((goal) {
                              final isSelected = _targetGoal == goal;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _targetGoal = goal;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _item.color
                                          : (context.isDarkMode
                                                ? Colors.white10
                                                : Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: context.isDarkMode
                                                  ? Colors.white12
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                    ),
                                    child: Text(
                                      '$goal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : context.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer pushing 3D Marbles & Bottom Counter justified to the bottom
              const Spacer(),

              // 3. 3D Marbles Tasbeeh (rendered with selected marbleAsset)
              MarbleBeadsCounter(
                key: _marbleCounterKey,
                onIncrement: _incrementCount,
                onDecrement: _decrementCount,
                height: 200,
                marbleAsset: _item.marbleAsset,
                swipeLeftToRight: _swipeLeftToRight,
              ),

              // 4. Counter & Progress Section at the VERY BOTTOM (directly below 3D Marbles)
              Padding(
                padding: const EdgeInsets.only(left: 36, right: 36, bottom: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_count',
                          style: GoogleFonts.oxanium(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? _item.color
                                : (context.isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1E3816)),
                          ),
                        ),
                        Text(
                          ' / $_targetGoal',
                          style: GoogleFonts.oxanium(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Config Button at Top-Left Corner Just Above Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _openSwipeConfigModal,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _item.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _item.color.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 14,
                                  color: _item.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _swipeLeftToRight
                                      ? 'Swipe Right (→)'
                                      : 'Swipe Left (←)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _item.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Linear Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: _item.color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(_item.color),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Count Info Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Lifetime: $lifetimeCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
