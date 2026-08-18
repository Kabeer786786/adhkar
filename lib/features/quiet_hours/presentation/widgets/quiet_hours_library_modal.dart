import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/prayer_calculation_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/quiet_hours_model.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import '../providers/quiet_hours_provider.dart';

class QuietHoursLibraryModal extends ConsumerStatefulWidget {
  const QuietHoursLibraryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuietHoursLibraryModal(),
    );
  }

  @override
  ConsumerState<QuietHoursLibraryModal> createState() =>
      _QuietHoursLibraryModalState();
}

class _QuietHoursLibraryModalState extends ConsumerState<QuietHoursLibraryModal>
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

  TimeOfDay _addMinutes(TimeOfDay tod, int minutesToAdd) {
    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      tod.hour,
      tod.minute,
    ).add(Duration(minutes: minutesToAdd));
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
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

    final activeSchedules = ref.watch(quietHoursProvider);

    final List<Map<String, dynamic>> predefinedTemplates = [
      {
        'id': 'predefined_quiet_fajr',
        'title': 'Fajr Quiet Hours',
        'desc': 'Silence calls and alerts during Fajr prayer time',
        'startTime': TimeOfDay.fromDateTime(prayerTimes.fajr),
      },
      {
        'id': 'predefined_quiet_dhuhr',
        'title': 'Dhuhr Quiet Hours',
        'desc': 'Silence calls and alerts during Dhuhr prayer time',
        'startTime': TimeOfDay.fromDateTime(prayerTimes.dhuhr),
      },
      {
        'id': 'predefined_quiet_asr',
        'title': 'Asr Quiet Hours',
        'desc': 'Silence calls and alerts during Asr prayer time',
        'startTime': TimeOfDay.fromDateTime(prayerTimes.asr),
      },
      {
        'id': 'predefined_quiet_maghrib',
        'title': 'Maghrib Quiet Hours',
        'desc': 'Silence calls and alerts during Maghrib prayer time',
        'startTime': TimeOfDay.fromDateTime(prayerTimes.maghrib),
      },
      {
        'id': 'predefined_quiet_isha',
        'title': 'Isha Quiet Hours',
        'desc': 'Silence calls and alerts during Isha prayer time',
        'startTime': TimeOfDay.fromDateTime(prayerTimes.isha),
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
                    'Quiet Hours Timings',
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
                  // TAB 1: PREDEFINED NAMAZ TIMINGS
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

                      final rawTime = item['startTime'];
                      final TimeOfDay startTime = rawTime is TimeOfDay
                          ? rawTime
                          : (rawTime is DateTime
                                ? TimeOfDay.fromDateTime(rawTime)
                                : TimeOfDay.now());

                      final endTime = _addMinutes(startTime, 15);

                      final isAdded = activeSchedules.any(
                        (s) => s.id == id || s.title == title,
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
                                          '${_formatTimeOfDay(startTime)} – ${_formatTimeOfDay(endTime)} (15 mins)',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
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
                                    final existing = activeSchedules.firstWhere(
                                      (s) => s.id == id || s.title == title,
                                    );
                                    ref
                                        .read(quietHoursProvider.notifier)
                                        .deleteSchedule(existing.id);
                                    AppFloatingToast.showRemoved(
                                      context,
                                      message: 'Removed',
                                    );
                                  } else {
                                    final now = DateTime.now();
                                    final schedule = QuietHours(
                                      id: id,
                                      title: title,
                                      description: desc,
                                      startHour: startTime.hour,
                                      startMinute: startTime.minute,
                                      endHour: endTime.hour,
                                      endMinute: endTime.minute,
                                      enabled: true,
                                      repeatDaily: true,
                                      weekdays: const [1, 2, 3, 4, 5, 6, 7],
                                      createdAt: now,
                                      updatedAt: now,
                                    );
                                    ref
                                        .read(quietHoursProvider.notifier)
                                        .addSchedule(schedule);
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
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _CustomQuietHoursForm(
                        onSave: (schedule) {
                          ref
                              .read(quietHoursProvider.notifier)
                              .addSchedule(schedule);
                          AppFloatingToast.showAdded(context, message: 'Added');
                          Navigator.pop(context);
                        },
                      ),
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
}

class _CustomQuietHoursForm extends StatefulWidget {
  final ValueChanged<QuietHours> onSave;
  const _CustomQuietHoursForm({required this.onSave});

  @override
  State<_CustomQuietHoursForm> createState() => _CustomQuietHoursFormState();
}

class _CustomQuietHoursFormState extends State<_CustomQuietHoursForm> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Set<int> _selectedDays;
  String? _titleError;

  final Map<int, String> _daysMap = const {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _startTime = const TimeOfDay(hour: 13, minute: 15);
    _endTime = const TimeOfDay(hour: 13, minute: 40);
    _selectedDays = {1, 2, 3, 4, 5, 6, 7};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2A531D),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E2D24),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF2A531D),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF2A531D),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2A531D),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E2D24),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF2A531D),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF2A531D),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  void _save() {
    final titleText = _titleController.text.trim();
    if (titleText.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }

    final now = DateTime.now();
    final schedule = QuietHours(
      id: 'quiet_${now.millisecondsSinceEpoch}',
      title: titleText,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      enabled: true,
      repeatDaily: _selectedDays.length == 7,
      weekdays: _selectedDays.toList()..sort(),
      createdAt: now,
      updatedAt: now,
    );

    widget.onSave(schedule);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TITLE *',
          style: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.lexend(fontSize: 14, color: textColor),
          onChanged: (_) {
            if (_titleError != null) {
              setState(() => _titleError = null);
            }
          },
          decoration: InputDecoration(
            hintText: 'e.g., Afternoon Prayer, Night Sleep, Work',
            hintStyle: GoogleFonts.lexend(fontSize: 13, color: subTextColor),
            errorText: _titleError,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF16251C)
                : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'DESCRIPTION (OPTIONAL)',
          style: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: subTextColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          style: GoogleFonts.lexend(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'e.g., Silence phone during Zuhr prayer',
            hintStyle: GoogleFonts.lexend(fontSize: 13, color: subTextColor),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF16251C)
                : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickStartTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF16251C)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 15,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'START TIME',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimeOfDay(_startTime),
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _pickEndTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF16251C)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.pause_circle_outline_rounded,
                            size: 15,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'END TIME',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimeOfDay(_endTime),
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Text(
          'REPEAT DAYS',
          style: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: subTextColor,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [1, 2, 3, 4, 5, 6, 7].map((dayInt) {
            final dayName = _daysMap[dayInt]!;
            final isSelected = _selectedDays.contains(dayInt);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    if (_selectedDays.length > 1) {
                      _selectedDays.remove(dayInt);
                    }
                  } else {
                    _selectedDays.add(dayInt);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryGreen
                      : (isDark
                            ? const Color(0xFF16251C)
                            : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? primaryGreen
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  dayName,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _save,
            child: Text(
              'Save Custom Timing',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
