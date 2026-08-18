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

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CustomReminder reminder,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Reminder?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'This reminder "${reminder.title}" and its scheduled alarms will be removed.',
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
                    .deleteReminder(reminder.id);
                Navigator.pop(context);
                _showDeleteToast(context, 'Reminder deleted');
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawReminders = ref.watch(remindersProvider);
    final reminders = List<CustomReminder>.from(rawReminders)
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
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
      appBar: const AppHeaderBar(title: 'REMINDERS', showBackButton: true),
      body: reminders.isEmpty
          ? _buildEmptyState(context, ref, primaryGreen, isDark, subTextColor)
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
                      ref,
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
                      ref,
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
      floatingActionButton: reminders.isEmpty
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

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
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
    WidgetRef ref,
    CustomReminder reminder,
    Color primaryGreen,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    final isSkippedToday = reminder.isTurnedOffFor(DateTime.now());
    final gridBg = isDark ? const Color(0xFF16251C) : const Color(0xFFF8FAFC);
    final gridBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final tod = reminder.timeOfDay;
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minuteStr = tod.minute.toString().padLeft(2, '0');
    final periodStr = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final timeDigits = '$hour12:$minuteStr';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          if (!isDark)
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
            ReminderModal.show(
              context: context,
              initialReminder: reminder,
              onSave: (updated) {
                ref.read(remindersProvider.notifier).updateReminder(updated);
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1st ROW: Title, Subtitle, and right-side small Switch
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            reminder.title,
                            style: GoogleFonts.outfit(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w500,
                              color: reminder.isEnabled
                                  ? textColor
                                  : (isDark ? Colors.white38 : Colors.grey),
                            ),
                          ),

                          if (reminder.description != null &&
                              reminder.description!.isNotEmpty) ...[
                            const SizedBox(height: 1.5),
                            Text(
                              reminder.description!,
                              style: GoogleFonts.lexend(
                                fontSize: 12.5,
                                color: subTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Somewhat small switch
                    Transform.scale(
                      scale: 0.82,
                      child: Switch(
                        value: reminder.isEnabled,
                        activeTrackColor: primaryGreen,
                        activeColor: Colors.white,
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

                // 2nd ROW: 2 Grids (Columns)
                Row(
                  children: [
                    // GRID 1: Left Grid (Centered Time & Day frequency below time)
                    Expanded(
                      child: Container(
                        height: 90,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: gridBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: gridBorder, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Centered Time (Big Digits + Small AM/PM)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                const SizedBox(width: 3),
                                Text(
                                  periodStr,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: reminder.isEnabled
                                        ? primaryGreen
                                        : subTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Below Time: Day frequency badge with icon (e.g. Everyday / Mon-Fri / Particular Day)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: reminder.isEnabled
                                    ? (isDark
                                          ? const Color(0xFF23352B)
                                          : const Color(0xFFE8F5E9))
                                    : (isDark
                                          ? Colors.white10
                                          : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (isDark
                                      ? const Color(0xFF23352B)
                                      : const Color(0xFFD3E8DA)),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    reminder.frequency == ReminderFrequency.once
                                        ? Icons.calendar_month_rounded
                                        : Icons.repeat_rounded,
                                    size: 12,
                                    color: reminder.isEnabled
                                        ? primaryGreen
                                        : subTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    reminder.formattedDays,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lexend(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: reminder.isEnabled
                                          ? primaryGreen
                                          : subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // if (isSkippedToday && reminder.isEnabled) ...[
                            //   const SizedBox(height: 4),
                            //   Text(
                            //     'Skipped Today',
                            //     style: GoogleFonts.lexend(
                            //       fontSize: 10.5,
                            //       fontWeight: FontWeight.w600,
                            //       color: const Color(0xFFD97724),
                            //     ),
                            //   ),
                            // ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // GRID 2: Right Grid (Centered Actions: Edit, Delete & Turn Off Today)
                    Expanded(
                      child: Container(
                        height: 90,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: gridBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: gridBorder, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Edit Button
                                InkWell(
                                  onTap: () {
                                    ReminderModal.show(
                                      context: context,
                                      initialReminder: reminder,
                                      onSave: (updated) {
                                        ref
                                            .read(remindersProvider.notifier)
                                            .updateReminder(updated);
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFE0F2FE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                // Delete Button
                                InkWell(
                                  onTap: () =>
                                      _confirmDelete(context, ref, reminder),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF3B1E1E)
                                          : const Color(0xFFFEE2E2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (reminder.isEnabled) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  if (isSkippedToday) {
                                    ref
                                        .read(remindersProvider.notifier)
                                        .reactivateToday(reminder.id);
                                    _showToast(
                                      context,
                                      'Activated',
                                      true,
                                      isDark,
                                    );
                                  } else {
                                    ref
                                        .read(remindersProvider.notifier)
                                        .turnOffToday(reminder.id);
                                    _showToast(
                                      context,
                                      'Disabled for Today',
                                      false,
                                      isDark,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSkippedToday
                                        ? (isDark
                                              ? const Color(0xFF243029)
                                              : const Color(0xFFF1F5F9))
                                        : (isDark
                                              ? const Color(0xFF38260A)
                                              : const Color(0xFFFEF3C7)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSkippedToday
                                          ? (isDark
                                                ? Colors.white12
                                                : const Color(0xFFCBD5E1))
                                          : (isDark
                                                ? const Color(0xFF52360E)
                                                : const Color(0xFFFDE68A)),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSkippedToday
                                            ? Icons.event_available_rounded
                                            : Icons.do_not_disturb_on_outlined,
                                        size: 13,
                                        color: isSkippedToday
                                            ? (isDark
                                                  ? Colors.white60
                                                  : const Color(0xFF64748B))
                                            : (isDark
                                                  ? const Color(0xFFFBBF24)
                                                  : const Color(0xFFD97706)),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isSkippedToday
                                            ? 'Skipped Today'
                                            : 'Turn Off Today',
                                        style: GoogleFonts.lexend(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSkippedToday
                                              ? (isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B))
                                              : (isDark
                                                    ? const Color(0xFFFBBF24)
                                                    : const Color(0xFFD97706)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
}
