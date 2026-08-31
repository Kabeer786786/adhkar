import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/config/reminder_audio_config.dart';
import '../../domain/reminder_model.dart';

class ReminderModal extends StatefulWidget {
  final CustomReminder? initialReminder;
  final ValueChanged<CustomReminder> onSave;
  final bool isEmbedded;

  const ReminderModal({
    super.key,
    this.initialReminder,
    required this.onSave,
    this.isEmbedded = false,
  });

  static Future<void> show({
    required BuildContext context,
    CustomReminder? initialReminder,
    required ValueChanged<CustomReminder> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReminderModal(initialReminder: initialReminder, onSave: onSave),
    );
  }

  @override
  State<ReminderModal> createState() => _ReminderModalState();
}

class _ReminderModalState extends State<ReminderModal> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  late ReminderFrequency _frequency;
  late Set<int> _selectedDays;
  late AlarmDuration _duration;
  late bool _soundEnabled;
  late String _soundType;
  late bool _vibrationEnabled;
  late bool _notificationEnabled;
  String? _titleError;

  final List<String> _soundOptions = ReminderAudioConfig.soundOptions;
  final AudioPlayer _previewPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _previewSubscription;
  bool _isPreviewPlaying = false;

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
    final rem = widget.initialReminder;
    _titleController = TextEditingController(text: rem?.title ?? '');
    _descController = TextEditingController(text: rem?.description ?? '');
    _selectedTime = TimeOfDay(hour: rem?.hour ?? 8, minute: rem?.minute ?? 0);
    _selectedDate = rem?.startDate ?? DateTime.now();
    _frequency = rem?.frequency ?? ReminderFrequency.daily;
    _selectedDays = Set<int>.from(rem?.customDays ?? [1, 2, 3, 4, 5, 6, 7]);
    _duration = rem?.duration ?? AlarmDuration.seconds30;
    _soundEnabled = rem?.soundEnabled ?? true;
    _soundType = rem?.soundType ?? ReminderAudioConfig.defaultRingtone;
    _vibrationEnabled = rem?.vibrationEnabled ?? true;
    _notificationEnabled = rem?.notificationEnabled ?? true;

    _previewSubscription = _previewPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _isPreviewPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _previewSubscription?.cancel();
    _previewPlayer.stop();
    _previewPlayer.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _playAudioPreview() async {
    try {
      final path = ReminderAudioConfig.getAssetPath(_soundType);
      await _previewPlayer.stop();
      await _previewPlayer.setAsset(path);
      if (mounted) setState(() => _isPreviewPlaying = true);
      _previewPlayer.play().catchError((e) {
        debugPrint('[ReminderModal] Error during audio playback: $e');
        if (mounted) setState(() => _isPreviewPlaying = false);
      });
    } catch (e) {
      debugPrint('[ReminderModal] Error loading preview audio: $e');
      if (mounted) setState(() => _isPreviewPlaying = false);
    }
  }

  Future<void> _stopAudioPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    if (mounted) setState(() => _isPreviewPlaying = false);
  }

  Future<void> _toggleAudioPreview() async {
    if (_isPreviewPlaying) {
      await _stopAudioPreview();
    } else {
      await _playAudioPreview();
    }
  }

  Future<void> _pickTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Ensure initialDate is at or after today so Flutter showDatePicker never asserts on past dates
    final initialDate = _selectedDate.isBefore(today) ? today : _selectedDate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
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
                    onSurface: Color(0xFF1E293B),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showExpiredDateWarning() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFEF4444),
          size: 38,
        ),
        title: Text(
          'Reminder Date Expired',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'The selected date and time has already passed. Please select a future date and time before saving this reminder.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
            height: 1.45,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Change Date / Time',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final titleText = _titleController.text.trim();
    if (titleText.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }
    if (titleText.length > 60) {
      setState(() => _titleError = 'Title cannot exceed 60 characters');
      return;
    }

    final now = DateTime.now();

    // Check if one-time reminder date & time is in the past
    if (_frequency == ReminderFrequency.once) {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (scheduledDateTime.isBefore(now)) {
        _showExpiredDateWarning();
        return;
      }
    }

    final rem = CustomReminder(
      id: widget.initialReminder?.id ?? 'rem_${now.millisecondsSinceEpoch}',
      title: titleText,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      startDate: _selectedDate,
      frequency: _frequency,
      customDays: _selectedDays.toList()..sort(),
      duration: _duration,
      soundEnabled: _soundEnabled,
      soundType: _soundType,
      vibrationEnabled: _vibrationEnabled,
      notificationEnabled: _notificationEnabled,
      isEnabled: widget.initialReminder?.isEnabled ?? true,
      turnedOffDate: widget.initialReminder?.turnedOffDate,
      createdAt: widget.initialReminder?.createdAt ?? now,
      updatedAt: now,
      timezone: now.timeZoneName,
    );

    widget.onSave(rem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final hour12 = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedTime = '$hour12:$minuteStr $period';

    final formContent = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Input
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
              hintText: 'e.g., Read Morning Adhkar, Meeting, Medicine',
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

          // Description Input
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
              hintText: 'e.g., Read Ayatul Kursi and 3 Quls',
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

          // Time Picker Tile
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16251C)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        color: primaryGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Reminder Time',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formattedTime,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Reminder Type Header
          Text(
            'REMINDER TYPE',
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 8),

          // Toggle Tabs: Repeat Days vs Particular Day
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _frequency = _selectedDays.length == 7
                          ? ReminderFrequency.daily
                          : ReminderFrequency.custom;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _frequency != ReminderFrequency.once
                          ? primaryGreen
                          : (isDark
                                ? const Color(0xFF16251C)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _frequency != ReminderFrequency.once
                            ? primaryGreen
                            : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 15,
                          color: _frequency != ReminderFrequency.once
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Repeat Days',
                          style: GoogleFonts.lexend(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _frequency != ReminderFrequency.once
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _frequency = ReminderFrequency.once;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _frequency == ReminderFrequency.once
                          ? primaryGreen
                          : (isDark
                                ? const Color(0xFF16251C)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _frequency == ReminderFrequency.once
                            ? primaryGreen
                            : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: _frequency == ReminderFrequency.once
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Particular Day',
                          style: GoogleFonts.lexend(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _frequency == ReminderFrequency.once
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // IF REPEAT DAYS: Show Week Circles Row
          if (_frequency != ReminderFrequency.once) ...[
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
                      if (_selectedDays.length == 7) {
                        _frequency = ReminderFrequency.daily;
                      } else {
                        _frequency = ReminderFrequency.custom;
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
                            : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      dayName,
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _selectedDays = {1, 2, 3, 4, 5, 6, 7};
                    _frequency = ReminderFrequency.daily;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      'All Days',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() {
                    _selectedDays = {1, 2, 3, 4, 5};
                    _frequency = ReminderFrequency.custom;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      'Weekdays',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() {
                    _selectedDays = {6, 7};
                    _frequency = ReminderFrequency.custom;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      'Weekends',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // IF PARTICULAR DAY: Show Date Picker Card
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF16251C)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          color: primaryGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Select Date',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Alarm Duration Selector
          Text(
            'ALARM RING DURATION',
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AlarmDuration>(
            initialValue: _duration,
            dropdownColor: cardBg,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF16251C)
                  : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            items: AlarmDuration.values.map((dur) {
              return DropdownMenuItem<AlarmDuration>(
                value: dur,
                child: Text(
                  dur.displayName,
                  style: GoogleFonts.lexend(fontSize: 13, color: textColor),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _duration = val);
            },
          ),

          const SizedBox(height: 18),

          // Toggles: Sound, Vibration, Notification
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16251C) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    'Sound',
                    style: GoogleFonts.lexend(fontSize: 15, color: textColor),
                  ),
                  value: _soundEnabled,
                  activeTrackColor: primaryGreen,
                  onChanged: (val) => setState(() => _soundEnabled = val),
                ),
                if (_soundEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _soundOptions.contains(_soundType)
                                ? _soundType
                                : _soundOptions.first,
                            dropdownColor: cardBg,
                            decoration: InputDecoration(
                              labelText: 'ALARM AUDIO / SOUND',
                              labelStyle: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E2D24)
                                  : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            items: _soundOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Text(
                                  opt,
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _soundType = val);
                                if (_isPreviewPlaying) {
                                  _playAudioPreview();
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _toggleAudioPreview,
                          tooltip: _isPreviewPlaying
                              ? 'Stop Audio'
                              : 'Play Audio',
                          style: IconButton.styleFrom(
                            backgroundColor: _isPreviewPlaying
                                ? const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.15)
                                : primaryGreen.withValues(alpha: 0.15),
                          ),
                          icon: Icon(
                            _isPreviewPlaying
                                ? Icons.stop_circle_rounded
                                : Icons.play_circle_filled_rounded,
                            color: _isPreviewPlaying
                                ? const Color(0xFFEF4444)
                                : primaryGreen,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    'Vibration',
                    style: GoogleFonts.lexend(fontSize: 15, color: textColor),
                  ),
                  value: _vibrationEnabled,
                  activeTrackColor: primaryGreen,
                  onChanged: (val) => setState(() => _vibrationEnabled = val),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    'Notification Alert',
                    style: GoogleFonts.lexend(fontSize: 15, color: textColor),
                  ),
                  value: _notificationEnabled,
                  activeTrackColor: primaryGreen,
                  onChanged: (val) =>
                      setState(() => _notificationEnabled = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Button: Save Reminder
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                widget.initialReminder == null
                    ? 'Create Reminder'
                    : 'Save Changes',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return formContent;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Title Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialReminder == null
                        ? 'Add Reminder'
                        : 'Edit Reminder',
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),

            Flexible(child: formContent),
          ],
        ),
      ),
    );
  }
}
