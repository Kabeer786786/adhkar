import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/prayer_calculation_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/reminder_model.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import '../providers/reminder_provider.dart';
import 'reminder_modal.dart';

class ReminderLibraryModal extends ConsumerStatefulWidget {
  const ReminderLibraryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReminderLibraryModal(),
    );
  }

  @override
  ConsumerState<ReminderLibraryModal> createState() =>
      _ReminderLibraryModalState();
}

class _ReminderLibraryModalState extends ConsumerState<ReminderLibraryModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final locationAsync = ref.watch(currentLocationProvider);
    final method = ref.watch(calculationMethodProvider);
    final juristic = ref.watch(asrJuristicProvider);
    final location = locationAsync.value ?? LocationService.defaultLocation;

    final prayerTimes = PrayerCalculationService.calculate(
      date: DateTime.now(),
      latitude: location.latitude,
      longitude: location.longitude,
      methodName: method,
      juristicAsr: juristic,
    );

    final activeReminders = ref.watch(remindersProvider);

    final List<Map<String, dynamic>> predefinedTemplates = [
      {
        'id': 'predefined_rem_fajr',
        'title': 'Fajr Prayer Reminder',
        'desc': 'Daily prayer reminder at Fajr start time',
        'time': TimeOfDay.fromDateTime(prayerTimes.fajr),
      },
      {
        'id': 'predefined_rem_dhuhr',
        'title': 'Dhuhr Prayer Reminder',
        'desc': 'Daily prayer reminder at Dhuhr start time',
        'time': TimeOfDay.fromDateTime(prayerTimes.dhuhr),
      },
      {
        'id': 'predefined_rem_asr',
        'title': 'Asr Prayer Reminder',
        'desc': 'Daily prayer reminder at Asr start time',
        'time': TimeOfDay.fromDateTime(prayerTimes.asr),
      },
      {
        'id': 'predefined_rem_maghrib',
        'title': 'Maghrib Prayer Reminder',
        'desc': 'Daily prayer reminder at Maghrib start time',
        'time': TimeOfDay.fromDateTime(prayerTimes.maghrib),
      },
      {
        'id': 'predefined_rem_isha',
        'title': 'Isha Prayer Reminder',
        'desc': 'Daily prayer reminder at Isha start time',
        'time': TimeOfDay.fromDateTime(prayerTimes.isha),
      },
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Grab handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reminder Timings',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            // 2-Tab Segment
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16251C)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: subTextColor,
                labelStyle: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                unselectedLabelStyle: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Predefined Timings'),
                  Tab(text: 'Create Custom'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: PREDEFINED NAMAZ REMINDERS
                  ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: predefinedTemplates.length,
                    itemBuilder: (context, index) {
                      final item = predefinedTemplates[index];
                      final id = item['id'] as String;
                      final title = item['title'] as String;
                      final desc = item['desc'] as String;

                      final rawTime = item['time'];
                      final TimeOfDay time = rawTime is TimeOfDay
                          ? rawTime
                          : (rawTime is DateTime
                                ? TimeOfDay.fromDateTime(rawTime)
                                : TimeOfDay.now());

                      final isAdded = activeReminders.any(
                        (r) => r.id == id || r.title == title,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF16251C)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAdded
                                ? primaryGreen
                                : (isDark
                                      ? Colors.white12
                                      : const Color(0xFFE2E8F0)),
                            width: isAdded ? 1.5 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                top: 16,
                                bottom: 16,
                                right: 48,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    desc,
                                    style: GoogleFonts.lexend(
                                      fontSize: 12.5,
                                      color: subTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_filled_rounded,
                                          size: 15,
                                          color: primaryGreen,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatTimeOfDay(time),
                                          style: GoogleFonts.outfit(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Circle Add / Checked Button Top Right
                            Positioned(
                              right: 4,
                              top: 4,
                              child: IconButton(
                                icon: Icon(
                                  isAdded
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 28,
                                  color: isAdded
                                      ? primaryGreen
                                      : (isDark
                                            ? Colors.white54
                                            : Colors.grey.shade400),
                                ),
                                onPressed: () {
                                  if (isAdded) {
                                    final existing = activeReminders.firstWhere(
                                      (r) => r.id == id || r.title == title,
                                    );
                                    ref
                                        .read(remindersProvider.notifier)
                                        .deleteReminder(existing.id);
                                    AppFloatingToast.showRemoved(
                                      context,
                                      message: 'Removed',
                                    );
                                  } else {
                                    final now = DateTime.now();
                                    final reminder = CustomReminder(
                                      id: id,
                                      title: title,
                                      description: desc,
                                      hour: time.hour,
                                      minute: time.minute,
                                      frequency: ReminderFrequency.daily,
                                      customDays: const [1, 2, 3, 4, 5, 6, 7],
                                      duration: AlarmDuration.seconds30,
                                      soundEnabled: true,
                                      soundType: 'Makkah Azaan',
                                      vibrationEnabled: true,
                                      notificationEnabled: true,
                                      isEnabled: true,
                                      createdAt: now,
                                      updatedAt: now,
                                      timezone: now.timeZoneName,
                                    );
                                    ref
                                        .read(remindersProvider.notifier)
                                        .addReminder(reminder);
                                    AppFloatingToast.showAdded(
                                      context,
                                      message: 'Added',
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // TAB 2: CREATE CUSTOM FORM
                  ReminderModal(
                    isEmbedded: true,
                    onSave: (newRem) {
                      ref
                          .read(remindersProvider.notifier)
                          .addReminder(newRem);
                      AppFloatingToast.showAdded(context, message: 'Added');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ), 
            ),
          ],
        ),
      ),
    );
  }
}
