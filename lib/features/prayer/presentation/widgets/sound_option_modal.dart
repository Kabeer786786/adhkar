import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../domain/prayer_models.dart';

class SoundOptionModal extends StatefulWidget {
  final String prayerName;
  final PrayerNotificationConfig initialConfig;
  final ValueChanged<PrayerNotificationConfig> onSave;

  const SoundOptionModal({
    super.key,
    required this.prayerName,
    required this.initialConfig,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String prayerName,
    required PrayerNotificationConfig initialConfig,
    required ValueChanged<PrayerNotificationConfig> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SoundOptionModal(
        prayerName: prayerName,
        initialConfig: initialConfig,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SoundOptionModal> createState() => _SoundOptionModalState();
}

class _SoundOptionModalState extends State<SoundOptionModal> {
  late bool _sound;
  late bool _noSound;
  late bool _vibration;
  late bool _notification;
  late String _soundType;
  late Set<int> _selectedDays;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingPreview = false;
  bool _isLoadingPreview = false;

  final List<String> _soundTypes = const [
    'Makkah Azaan',
    'Madinah Azaan',
    'Mishary Alafasy Azaan',
    'Takbeer',
    'Default Notification',
    'Ringtone',
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
    _sound = widget.initialConfig.sound;
    _noSound = widget.initialConfig.noSound;
    _vibration = widget.initialConfig.vibration;
    _notification = widget.initialConfig.notification;
    _soundType = _soundTypes.contains(widget.initialConfig.soundType)
        ? widget.initialConfig.soundType
        : 'Makkah Azaan';
    _selectedDays = Set<int>.from(widget.initialConfig.selectedDays);
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPreview() async {
    if (_isPlayingPreview) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlayingPreview = false);
      return;
    }

    final url = PrayerNotificationConfig.soundAudioUrls[_soundType];
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preview sound relies on system default audio ringtone.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isLoadingPreview = true);
      await _audioPlayer.setUrl(url);
      setState(() {
        _isLoadingPreview = false;
        _isPlayingPreview = true;
      });
      await _audioPlayer.play();
      if (mounted) {
        setState(() => _isPlayingPreview = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _isPlayingPreview = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play preview audio: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.prayerName} Notification Settings',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Customize alert modes, sound and alarm days',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE7E7E7)),
            const SizedBox(height: 16),

            Text(
              'Alert Modes (Select Multiple)',
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            // Options Checklist
            _buildOptionTile(
              title: 'Sound',
              subtitle: 'Play audio alert at prayer time',
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
              subtitle: 'Disable audio alerts for this prayer',
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
              subtitle: 'Haptic alert on device',
              icon: Icons.vibration_rounded,
              value: _vibration,
              onChanged: (val) {
                setState(() {
                  _vibration = val ?? false;
                });
              },
            ),
            _buildOptionTile(
              title: 'Notification Banner',
              subtitle: 'Display banner notification on screen',
              icon: Icons.notifications_active_rounded,
              value: _notification,
              onChanged: (val) {
                setState(() {
                  _notification = val ?? false;
                });
              },
            ),

            const SizedBox(height: 16),
            Text(
              'Repeat Days (Alarm Active Days)',
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
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
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? context.colorScheme.primary
                            : const Color(0xFFE7E7E7),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: context.colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      dayName,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isSelected
                            ? context.colorScheme.onPrimary
                            : context.colorScheme.onSurfaceVariant,
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
                  onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5, 6, 7}),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'All Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5}),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Weekdays',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _selectedDays = {6, 7}),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Weekends',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Azaan / Sound Type',
                    value: _soundTypes.contains(_soundType) ? _soundType : 'Makkah Azaan',
                    items: _soundTypes.map((type) {
                      return AppDropdownItem<String>(
                        value: type,
                        label: type,
                        icon: type.contains('Azaan') || type.contains('Takbeer')
                            ? Icons.mosque_rounded
                            : Icons.ring_volume_rounded,
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _soundType = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Audio Preview Button
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A531D).withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    tooltip: _isPlayingPreview ? 'Stop Preview' : 'Play Preview',
                    onPressed: _isLoadingPreview ? null : _toggleAudioPreview,
                    icon: _isLoadingPreview
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            _isPlayingPreview
                                ? Icons.stop_circle_rounded
                                : Icons.play_circle_fill_rounded,
                            color: const Color(0xFF2A531D),
                            size: 26,
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _audioPlayer.stop();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _audioPlayer.stop();
                      final updated = widget.initialConfig.copyWith(
                        sound: _sound,
                        noSound: _noSound,
                        vibration: _vibration,
                        notification: _notification,
                        soundType: _soundType,
                        selectedDays: (_selectedDays.toList()..sort()),
                      );
                      widget.onSave(updated);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: context.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
