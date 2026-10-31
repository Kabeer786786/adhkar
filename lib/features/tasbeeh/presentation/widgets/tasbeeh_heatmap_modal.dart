import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/models/tasbeeh_item.dart';

class TasbeehHeatmapModal extends StatefulWidget {
  final StorageService storage;
  final List<TasbeehItem> tasbeehItems;

  const TasbeehHeatmapModal({
    super.key,
    required this.storage,
    required this.tasbeehItems,
  });

  static void show(
    BuildContext context, {
    required StorageService storage,
    required List<TasbeehItem> tasbeehItems,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TasbeehHeatmapModal(storage: storage, tasbeehItems: tasbeehItems),
    );
  }

  @override
  State<TasbeehHeatmapModal> createState() => _TasbeehHeatmapModalState();
}

class _TasbeehHeatmapModalState extends State<TasbeehHeatmapModal> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
  }

  void _showDayDetails(DateTime date, Map<String, int> countsMap) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(date);
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: isDark
                    ? const Color(0xFF18A74C)
                    : const Color(0xFF2A531D),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.tasbeehItems.map((item) {
              final count = countsMap[item.id] ?? 0;
              final isDone = count >= item.targetGoal;
              final itemColor = (isDark && item.color.value == 0xFF2A531D)
                  ? const Color(0xFF18A74C)
                  : item.color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: itemColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.textEn,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '$count / ${item.targetGoal}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDone
                            ? const Color(0xFF16A34A)
                            : (isDark ? Colors.white60 : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isDone
                          ? const Color(0xFF16A34A)
                          : (isDark ? Colors.white38 : Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF18A74C)
                      : const Color(0xFF2A531D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF18A74C)
        : const Color(0xFF2A531D);
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    ).weekday; // 1 = Mon, 7 = Sun

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);
    final today = DateTime.now();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height:
            MediaQuery.of(context).size.height * 0.65, // Fitted modal height
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3F3F46)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Line 1: Header Title & Close Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFD97724),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tasbeeh Heatmap',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2A531D),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Line 2 (Dedicated New Line): Month Selector Controls (< Month Year >)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F0F12)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: isDark
                      ? Border.all(color: const Color(0xFF27272A))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _changeMonth(-1),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: isDark ? primaryColor : Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        monthTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _changeMonth(1),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: isDark ? primaryColor : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tasbeeh Legend Colors Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: widget.tasbeehItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.textEn,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Weekday Labels Header (M, T, W, T, F, S, S)
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),

            // Horizontal Swipeable Calendar Grid for Month Navigation
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -100) {
                      _changeMonth(1); // Swiped left -> Next Month
                    } else if (details.primaryVelocity! > 100) {
                      _changeMonth(-1); // Swiped right -> Prev Month
                    }
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayOffset = index - (firstWeekday - 1);
                    if (dayOffset < 0 || dayOffset >= daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final dayNumber = dayOffset + 1;
                    final date = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month,
                      dayNumber,
                    );
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final isToday =
                        date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;
                    final isFuture = date.isAfter(today);

                    final dailyCounts = widget.storage.getDailyTasbeehCountsMap(
                      dateKey,
                    );

                    return GestureDetector(
                      onTap: isFuture
                          ? null
                          : () => _showDayDetails(date, dailyCounts),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F0F12)
                              : const Color(0xFFF3FAF2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday
                                ? (isDark
                                      ? const Color(0xFF18A74C)
                                      : const Color(0xFF2A531D))
                                : (isDark
                                      ? const Color(0xFF27272A)
                                      : Colors.black.withValues(alpha: 0.05)),
                            width: isToday ? 2.0 : 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '$dayNumber',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                color: isToday
                                    ? (isDark
                                          ? const Color(0xFF18A74C)
                                          : const Color(0xFF2A531D))
                                    : (isDark
                                          ? Colors.white
                                          : context.colorScheme.onSurface),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Column(
                                  children: widget.tasbeehItems.map((item) {
                                    final count = dailyCounts[item.id] ?? 0;
                                    final isDone = count >= item.targetGoal;
                                    final hasProgress = count > 0;

                                    Color sliceColor;
                                    if (isDone) {
                                      sliceColor = item.color;
                                    } else if (hasProgress) {
                                      sliceColor = item.color.withValues(
                                        alpha: 0.45,
                                      );
                                    } else {
                                      sliceColor = context.isDarkMode
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.grey.withValues(alpha: 0.18);
                                    }

                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 1.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isFuture
                                              ? Colors.transparent
                                              : sliceColor,
                                          borderRadius: BorderRadius.circular(
                                            1.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
