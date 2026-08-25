import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_header_bar.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../domain/reminder_model.dart';
import 'providers/reminder_provider.dart';
import 'widgets/reminder_library_modal.dart';
import 'widgets/reminder_modal.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};

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
            'Delete Reminder${count > 1 ? 's' : ''}?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Are you sure you want to delete $count selected reminder${count > 1 ? 's' : ''}? Scheduled alarms will be removed.',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.lexend(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(remindersProvider.notifier)
                    .deleteMultipleReminders(_selectedIds);
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
                Navigator.pop(context);
                _showDeleteToast(
                  context,
                  '$count reminder${count > 1 ? 's' : ''} deleted',
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
              child: Text(
                'Delete',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showToast(
    BuildContext context,
    String message,
    bool isActivated,
    bool isDark,
  ) {
    final toastBg = isActivated
        ? const Color(0xFF2A531D)
        : (isDark ? const Color(0xFF1E2D24) : const Color(0xFF1E293B));
    final borderColor = isActivated
        ? const Color(0xFF4ADE80).withValues(alpha: 0.6)
        : const Color(0xFF2A531D).withValues(alpha: 0.4);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: const Duration(milliseconds: 1400),
        margin: const EdgeInsets.only(bottom: 20, left: 100, right: 100),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: toastBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteToast(BuildContext context, [String message = 'Removed']) {
    AppFloatingToast.showRemoved(context, message: message);
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
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
          style: GoogleFonts.outfit(
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

    return const AppHeaderBar(title: 'REMINDERS', showBackButton: true);
  }

  @override
  Widget build(BuildContext context) {
    final rawReminders = ref.watch(remindersProvider);
    final reminders = List<CustomReminder>.from(rawReminders)
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final bgColor = isDark ? const Color(0xFF121B16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF2B3F33)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final todayReminders = reminders.where((r) {
      if (!r.isEnabled) return false;
      if (r.isTurnedOffFor(DateTime.now())) return false;
      if (r.frequency != ReminderFrequency.once) return false;

      final next = r.calculateNextOccurrence(DateTime.now());
      if (next == null) return false;
      final nextStr = DateFormat('yyyy-MM-dd').format(next);
      return nextStr == todayStr;
    }).toList();

    final otherReminders = reminders
        .where((r) => !todayReminders.contains(r))
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, isDark, textColor),
      body: reminders.isEmpty
          ? _buildEmptyState(context, primaryGreen, isDark, subTextColor)
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 90, top: 5),
              children: [
                if (todayReminders.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Text(
                      'TODAY\'S REMINDERS',
                      style: GoogleFonts.lexend(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  ...todayReminders.map(
                    (r) => _buildReminderCard(
                      context,
                      r,
                      primaryGreen,
                      cardBg,
                      cardBorder,
                      textColor,
                      subTextColor,
                      isDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (otherReminders.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Text(
                      'ALL REMINDERS',
                      style: GoogleFonts.lexend(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: subTextColor,
                      ),
                    ),
                  ),
                  ...otherReminders.map(
                    (r) => _buildReminderCard(
                      context,
                      r,
                      primaryGreen,
                      cardBg,
                      cardBorder,
                      textColor,
                      subTextColor,
                      isDark,
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: reminders.isEmpty || _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                ReminderLibraryModal.show(context);
              },
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Reminder',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color primaryGreen,
    bool isDark,
    Color subTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2D24)
                    : const Color(0xFFFFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 44,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Reminders Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create reminders for Adhkar, Namaz, Quran, meetings, medicine, or anything important.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: subTextColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ReminderLibraryModal.show(context);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.lexend(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    CustomReminder reminder,
    Color primaryGreen,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    final isSelected = _selectedIds.contains(reminder.id);
    final tod = reminder.timeOfDay;
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minuteStr = tod.minute.toString().padLeft(2, '0');
    final periodStr = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final timeDigits = '$hour12:$minuteStr';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF243B2C) : const Color(0xFFF0FDF4))
            : cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? primaryGreen : cardBorder,
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          if (!isDark && !isSelected)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(reminder.id);
                  if (_selectedIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedIds.add(reminder.id);
                }
              });
            } else {
              ReminderModal.show(
                context: context,
                initialReminder: reminder,
                onSave: (updated) {
                  ref.read(remindersProvider.notifier).updateReminder(updated);
                },
              );
            }
          },
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              if (isSelected) {
                _selectedIds.remove(reminder.id);
                if (_selectedIds.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedIds.add(reminder.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP ROW: Selection Radio (if in selection mode), Title/Description, Switch
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isSelectionMode) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 12),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? primaryGreen : subTextColor,
                          size: 24,
                        ),
                      ),
                    ],

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: reminder.isEnabled
                                  ? textColor
                                  : (isDark ? Colors.white38 : Colors.grey),
                            ),
                          ),
                          if (reminder.description != null &&
                              reminder.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              reminder.description!,
                              style: GoogleFonts.lexend(
                                fontSize: 12.5,
                                color: subTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    if (!_isSelectionMode)
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: reminder.isEnabled,
                          activeTrackColor: primaryGreen,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            ref
                                .read(remindersProvider.notifier)
                                .toggleEnable(reminder.id);
                            _showToast(
                              context,
                              val ? 'Activated' : 'Deactivated',
                              val,
                              isDark,
                            );
                          },
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // BOTTOM ROW: Time on left corner, Days / Date tag on right side
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time (Left Corner)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          timeDigits,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            color: reminder.isEnabled
                                ? primaryGreen
                                : subTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          periodStr,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: reminder.isEnabled
                                ? primaryGreen
                                : subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Right Side: Everyday / Date / Day Chips
                    _buildRightTag(
                      reminder,
                      primaryGreen,
                      subTextColor,
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightTag(
    CustomReminder reminder,
    Color primaryGreen,
    Color subTextColor,
    bool isDark,
  ) {
    if (reminder.frequency == ReminderFrequency.once) {
      final formattedDate = DateFormat(
        'E, d MMM',
      ).format(reminder.startDate ?? DateTime.now());

      return Text(
        formattedDate,
        style: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: reminder.isEnabled ? primaryGreen : subTextColor,
        ),
      );
    }

    final isEveryday =
        reminder.frequency == ReminderFrequency.daily ||
        reminder.customDays.length == 7;

    if (isEveryday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: reminder.isEnabled
              ? (isDark ? const Color(0xFF23352B) : const Color(0xFFE8F5E9))
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: reminder.isEnabled
                ? (isDark ? const Color(0xFF23352B) : const Color(0xFFD3E8DA))
                : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 13,
              color: reminder.isEnabled ? primaryGreen : subTextColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Every day',
              style: GoogleFonts.lexend(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: reminder.isEnabled ? primaryGreen : subTextColor,
              ),
            ),
          ],
        ),
      );
    }

    // Custom or Weekly selected days: M T W T F S S
    return _buildDayLettersRow(
      reminder.customDays,
      primaryGreen,
      reminder.isEnabled,
      isDark,
    );
  }

  Widget _buildDayLettersRow(
    List<int> customDays,
    Color primaryGreen,
    bool isEnabled,
    bool isDark,
  ) {
    final days = const [
      {'day': 1, 'label': 'M'},
      {'day': 2, 'label': 'T'},
      {'day': 3, 'label': 'W'},
      {'day': 4, 'label': 'T'},
      {'day': 5, 'label': 'F'},
      {'day': 6, 'label': 'S'},
      {'day': 7, 'label': 'S'},
    ];

    final activeColor = isEnabled
        ? primaryGreen
        : (isDark ? Colors.white70 : const Color(0xFF475569));
    final inactiveColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: days.map((d) {
        final dayInt = d['day'] as int;
        final label = d['label'] as String;
        final isSelected = customDays.contains(dayInt);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),

              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isSelected && isEnabled)
                      ? activeColor
                      : (isSelected ? inactiveColor : Colors.transparent),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
