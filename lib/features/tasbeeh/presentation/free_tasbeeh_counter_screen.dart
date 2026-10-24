import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../widgets/app_header_bar.dart';
import 'widgets/marble_beads_counter.dart';
import 'widgets/marble_style_modal.dart';

class FreeTasbeehCounterScreen extends ConsumerStatefulWidget {
  const FreeTasbeehCounterScreen({super.key});

  @override
  ConsumerState<FreeTasbeehCounterScreen> createState() =>
      _FreeTasbeehCounterScreenState();
}

class _FreeTasbeehCounterScreenState
    extends ConsumerState<FreeTasbeehCounterScreen> {
  final GlobalKey<MarbleBeadsCounterState> _marbleCounterKey =
      GlobalKey<MarbleBeadsCounterState>();

  late String _todayKey;
  int _count = 0; 
  int _targetGoal = 33;
  bool _swipeLeftToRight = false;
  String _marbleAsset = 'assets/images/marble1.png';

  static const Color _primaryColor = Color(0xFF2A531D);

  @override
  void initState() {
    super.initState();
    _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCount();
      _loadPreferences();
    });
  }

  void _loadPreferences() {
    final storage = ref.read(storageServiceProvider);
    final direction = storage.getTasbeehSwipeDirection();
    final savedAsset = storage.getFreeTasbeehMarbleAsset();
    setState(() {
      _swipeLeftToRight = (direction == 'left_to_right');
      _marbleAsset = savedAsset;
    });
  }

  void _loadCount() {
    final storage = ref.read(storageServiceProvider);
    final savedCount =
        storage.getDailyTasbeehCount(_todayKey, 'free_tasbeeh_counter');
    setState(() {
      _count = savedCount;
    });
  }

  void _incrementCount() {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _count++;
    });
    storage.setDailyTasbeehCount(_todayKey, 'free_tasbeeh_counter', _count);
    storage.incrementLifetimeTasbeeh('free_tasbeeh_counter');
  }

  void _decrementCount() {
    if (_count <= 0) return;
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _count--;
    });
    storage.setDailyTasbeehCount(_todayKey, 'free_tasbeeh_counter', _count);
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
                  Icon(Icons.tune_rounded, color: _primaryColor),
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
                    backgroundColor: _primaryColor,
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
              ? _primaryColor.withValues(alpha: 0.08)
              : (context.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _primaryColor
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
              color: isSelected ? _primaryColor : Colors.grey,
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

  void _openMarbleStyleModal() {
    MarbleStyleModal.show(
      context,
      currentAsset: _marbleAsset,
      onSelect: (selectedAsset, _) {
        setState(() {
          _marbleAsset = selectedAsset;
        });
        ref
            .read(storageServiceProvider)
            .setFreeTasbeehMarbleAsset(selectedAsset);
        HapticFeedback.mediumImpact();
      },
    );
  }

  void _resetCount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Count'),
        content: const Text(
          'Are you sure you want to reset today\'s count for the Tasbeeh counter to 0?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
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
              storage.setDailyTasbeehCount(
                _todayKey,
                'free_tasbeeh_counter',
                0,
              );
              HapticFeedback.mediumImpact();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final rawLifetime =
        storage.getLifetimeTasbeehCount('free_tasbeeh_counter');
    final lifetimeCount = math.max(rawLifetime, _count);

    final progress = _targetGoal > 0
        ? (_count / _targetGoal).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = _count >= _targetGoal;

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF14201B)
          : const Color(0xFFF9F9F9),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppHeaderBar(
          title: 'Tasbeeh Counter',
          showBackButton: true,
          showDrawerButton: false,
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Tapping anywhere on the screen triggers marble counter increment & slide!
            _marbleCounterKey.currentState?.triggerTapIncrement();
          },
          child: SizedBox.expand(
            child: Column(
            children: [
              // 1. Target Goal Selector at Top (Without any Dua)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                              HapticFeedback.selectionClick();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _primaryColor
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

              // Spacer pushing 3D Marbles & Bottom Counter justified to the bottom
              const Spacer(),

              // 2. 3D Marbles Tasbeeh (rendered with selected marbleAsset)
              MarbleBeadsCounter(
                key: _marbleCounterKey,
                onIncrement: _incrementCount,
                onDecrement: _decrementCount,
                height: 240,
                marbleAsset: _marbleAsset,
                swipeLeftToRight: _swipeLeftToRight,
              ),

              // 3. Counter & Progress Section at the VERY BOTTOM (directly below 3D Marbles)
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
                                ? _primaryColor
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

                    // Config Row: Swipe direction on Left, Reset & Color Icons on Right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _openSwipeConfigModal,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _primaryColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.tune_rounded,
                                  size: 14,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _swipeLeftToRight
                                      ? 'Swipe Right (→)'
                                      : 'Swipe Left (←)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Corner: Marble Color Style & Reset Counter Icons
                        Row(
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              icon: const Icon(
                                Icons.palette_outlined,
                                size: 20,
                                color: _primaryColor,
                              ),
                              tooltip: 'Change Marble Bead Style',
                              onPressed: _openMarbleStyleModal,
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: _primaryColor,
                              ),
                              tooltip: 'Reset Today\'s Count',
                              onPressed: _resetCount,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Linear Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: _primaryColor.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
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
    ),
  );
  }
}
