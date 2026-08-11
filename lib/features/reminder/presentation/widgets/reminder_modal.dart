import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../domain/reminder_model.dart';

class ReminderModal extends StatefulWidget {
  final CustomReminder? initialReminder;
  final ValueChanged<CustomReminder> onSave;

  const ReminderModal({
    super.key,
    this.initialReminder,
    required this.onSave,
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
      builder: (_) => ReminderModal(
        initialReminder: initialReminder,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ReminderModal> createState() => _ReminderModalState();
}

class _ReminderModalState extends State<ReminderModal> {
  late TextEditingController _titleController;
  late TimeOfDay _selectedTime;
  late bool _sound;
  late bool _noSound;
  late bool _vibration;
  late bool _notification;
  late String _soundType;
  late Set<int> _selectedDays;

  final List<String> _soundTypes = [
    'Azaan',
    'Ringtone',
    'Default Notification',
  ];

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
    _selectedTime = TimeOfDay(
      hour: rem?.hour ?? 8,
      minute: rem?.minute ?? 0,
    );
    _sound = rem?.sound ?? true;
    _noSound = rem?.noSound ?? false;
    _vibration = rem?.vibration ?? true;
    _notification = rem?.notification ?? true;
    _soundType = rem?.soundType ?? 'Azaan';
    _selectedDays = Set<int>.from(rem?.selectedDays ?? [1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for the reminder'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final reminder = CustomReminder(
      id: widget.initialReminder?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      sound: _sound && !_noSound,
      noSound: _noSound,
      vibration: _vibration,
      notification: _notification,
      soundType: _soundType,
      selectedDays: _selectedDays.toList(),
      isEnabled: widget.initialReminder?.isEnabled ?? true,
      createdAt: widget.initialReminder?.createdAt ?? DateTime.now(),
    );

    widget.onSave(reminder);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialReminder != null;
    final hour12 =
        _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minStr = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3FAF2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.alarm_add_rounded,
                    color: Color(0xFF2A531D),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Custom Reminder' : 'New Custom Reminder',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A531D),
                        ),
                      ),
                      Text(
                        'Set alarm title, time, repeat days and alert sound',
                        style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          color: const Color(0xFF6B533E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE8F4E5)),
            const SizedBox(height: 18),

            // Title Input
            Text(
              'Reminder Title',
              style: GoogleFonts.lexend(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Morning Adhkar, Read Quran, Tahajjud',
                hintStyle: GoogleFonts.lexend(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAF8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF2A531D),
                    width: 1.8,
                  ),
                ),
              ),
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 20),

            // Time Selector Card
            Text(
              'Alarm Time',
              style: GoogleFonts.lexend(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FAF2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: Color(0xFFD97724),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$hour12:$minStr $period',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A531D),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A531D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Change Time',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Repeat Days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repeat Days',
                  style: GoogleFonts.lexend(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A531D),
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5, 6, 7}),
                      child: Text(
                        'All Days',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97724),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5}),
                      child: Text(
                        'Weekdays',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97724),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                        _selectedDays.remove(dayInt);
                      } else {
                        _selectedDays.add(dayInt);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2A531D)
                          : const Color(0xFFF3FAF2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2A531D)
                            : const Color(0xFFE8F4E5),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      dayName,
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Alert Modes Options
            Text(
              'Alert Modes',
              style: GoogleFonts.lexend(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),

            _buildOptionTile(
              title: 'Sound',
              subtitle: 'Play audio alert at scheduled time',
              icon: Icons.music_note_rounded,
              value: _sound && !_noSound,
              onChanged: (val) {
                setState(() {
                  _sound = val ?? false;
                  if (_sound) _noSound = false;
                });
              },
            ),
            _buildOptionTile(
              title: 'No Sound (Mute Audio)',
              subtitle: 'Disable audio alerts for this reminder',
              icon: Icons.volume_off_rounded,
              value: _noSound,
              onChanged: (val) {
                setState(() {
                  _noSound = val ?? false;
                  if (_noSound) _sound = false;
                });
              },
            ),
            _buildOptionTile(
              title: 'Vibration',
              subtitle: 'Haptic feedback pulse on device',
              icon: Icons.vibration_rounded,
              value: _vibration,
              onChanged: (val) {
                setState(() {
                  _vibration = val ?? false;
                });
              },
            ),
            _buildOptionTile(
              title: 'Notification',
              subtitle: 'Display banner alert on screen',
              icon: Icons.notifications_active_rounded,
              value: _notification,
              onChanged: (val) {
                setState(() {
                  _notification = val ?? false;
                });
              },
            ),
            const SizedBox(height: 16),

            // Sound Type Selector Dropdown
            if (_sound && !_noSound) ...[
              Text(
                'Sound Type',
                style: GoogleFonts.lexend(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A531D),
                ),
              ),
              const SizedBox(height: 8),
              AppDropdown<String>(
                value: _soundType,
                items: _soundTypes
                    .map((st) => AppDropdownItem<String>(value: st, label: st))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _soundType = val);
                },
              ),

              const SizedBox(height: 20),
            ],

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Reminder' : 'Save Reminder',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFF2A531D).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: GoogleFonts.lexend(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2A531D),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.lexend(
            fontSize: 11.5,
            color: const Color(0xFF718096),
          ),
        ),
        secondary: Icon(
          icon,
          color: value ? const Color(0xFF2A531D) : Colors.grey,
          size: 20,
        ),
        value: value,
        activeColor: const Color(0xFF2A531D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
