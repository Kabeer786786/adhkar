import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/config/alarm_background_config.dart';
import '../../../../core/config/reminder_audio_config.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import '../../domain/reminder_model.dart';
import '../alarm_screen.dart';

class ReminderModal extends ConsumerStatefulWidget {
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
  ConsumerState<ReminderModal> createState() => _ReminderModalState();
}

class _ReminderModalState extends ConsumerState<ReminderModal> {
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
  late String _alarmBgType;
  late String _alarmBgValue;
  late bool _alarmShowWaves;
  String? _titleError;

  late List<String> _soundOptions;
  final Map<String, String> _customAudioNames = {};
  final List<String> _customBgImages = [];
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
    _soundEnabled = rem?.soundEnabled ?? true;
    _soundType = ReminderAudioConfig.canonicalSoundName(rem?.soundType);
    _soundOptions = List<String>.from(ReminderAudioConfig.soundOptions);
    if (!_soundOptions.contains(_soundType)) {
      _soundOptions.insert(0, _soundType);
    }
    _duration = rem?.duration ??
        (ReminderAudioConfig.isAzan(_soundType)
            ? AlarmDuration.fullRingtone
            : AlarmDuration.seconds30);
    _vibrationEnabled = rem?.vibrationEnabled ?? true;
    _notificationEnabled = rem?.notificationEnabled ?? true;
    _alarmBgType = rem?.alarmBgType ?? 'image';
    _alarmBgValue = rem?.alarmBgValue ?? 'assets/images/alarm-bgs/bg1.jpg';
    if (_alarmBgValue.isNotEmpty &&
        !AlarmBackgroundConfig.imageList.contains(_alarmBgValue) &&
        !_alarmBgValue.startsWith('assets/')) {
      _customBgImages.add(_alarmBgValue);
    }
    _alarmShowWaves = rem?.alarmShowWaves ?? false;
    _loadCustomBgImages();
    _loadCustomAudios();

    _previewSubscription = _previewPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _isPreviewPlaying = false);
      } else if (!state.playing &&
          state.processingState != ProcessingState.loading &&
          state.processingState != ProcessingState.buffering) {
        if (mounted && _isPreviewPlaying) {
          setState(() => _isPreviewPlaying = false);
        }
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
      final isCustom = ReminderAudioConfig.isCustomFile(_soundType);
      final displayName = ReminderAudioConfig.getDisplayName(_soundType);
      final mediaItem = MediaItem(
        id: 'reminder_preview_${_soundType.replaceAll(" ", "_")}',
        title: displayName,
        album: 'Adhkar Preview',
      );

      await _previewPlayer.stop();
      await _previewPlayer.setVolume(1.0);
      if (isCustom) {
        await _previewPlayer.setAudioSource(
          AudioSource.file(_soundType, tag: mediaItem),
        );
      } else {
        final path = ReminderAudioConfig.getAssetPath(_soundType);
        await _previewPlayer.setAudioSource(
          AudioSource.asset(path, tag: mediaItem),
        );
      }
      if (mounted) setState(() => _isPreviewPlaying = true);
      await _previewPlayer.play();
    } catch (e) {
      debugPrint('[ReminderModal] Error loading preview audio: $e');
      if (mounted) setState(() => _isPreviewPlaying = false); 
    }
  }

  Future<void> _loadCustomAudios() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final stored = storage.getCustomAlarmAudios();
      for (final item in stored) {
        final path = item['path'];
        final name = item['name'];
        if (path != null && name != null) {
          if (File(path).existsSync()) {
            _customAudioNames[path] = name;
            if (!_soundOptions.contains(path)) {
              _soundOptions.insert(0, path);
            }
          }
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final audiosDir = Directory('${appDir.path}/alarm_audios');
      if (await audiosDir.exists()) {
        final files = audiosDir.listSync().whereType<File>().toList();
        for (final f in files) {
          if (!_soundOptions.contains(f.path)) {
            final fileName = f.path.split(RegExp(r'[/\\]')).last;
            final raw = fileName.contains('.')
                ? fileName.substring(0, fileName.lastIndexOf('.'))
                : fileName;
            final trunc = raw.length > 30 ? raw.substring(0, 30) : raw;
            final name = trunc.isEmpty ? 'Custom Audio' : trunc;
            _customAudioNames[f.path] = name;
            _soundOptions.insert(0, f.path);
            await storage.addCustomAlarmAudio(name, f.path);
          }
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[ReminderModal] Load custom audios error: $e');
    }
  }

  Future<void> _pickCustomAudioFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final appDir = await getApplicationDocumentsDirectory();
        final audiosDir = Directory('${appDir.path}/alarm_audios');
        if (!await audiosDir.exists()) await audiosDir.create(recursive: true);

        // Name truncated to max 30 characters
        final originalName = file.name;
        final rawBaseName = originalName.contains('.')
            ? originalName.substring(0, originalName.lastIndexOf('.'))
            : originalName;
        String truncatedName = rawBaseName.trim();
        if (truncatedName.length > 30) {
          truncatedName = truncatedName.substring(0, 30).trim();
        }
        if (truncatedName.isEmpty) truncatedName = 'Custom Audio';

        final ext = file.name.contains('.')
            ? '.${file.name.split('.').last}'
            : '.mp3';
        final targetPath =
            '${audiosDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}$ext';
        await File(file.path!).copy(targetPath);

        final storage = ref.read(storageServiceProvider);
        await storage.addCustomAlarmAudio(truncatedName, targetPath);

        setState(() {
          _customAudioNames[targetPath] = truncatedName;
          if (!_soundOptions.contains(targetPath)) {
            _soundOptions.insert(0, targetPath);
          }
          _soundType = targetPath;
        });

        if (_isPreviewPlaying) {
          _playAudioPreview();
        }
      }
    } catch (e) {
      debugPrint('[ReminderModal] Pick audio error: $e');
    }
  }

  void _showEditAudioDialog([String? specificPath]) {
    final audioPath = specificPath ??
        (ReminderAudioConfig.isCustomFile(_soundType)
            ? _soundType
            : _soundOptions.firstWhere(
                (s) => ReminderAudioConfig.isCustomFile(s),
                orElse: () => '',
              ));

    if (audioPath.isEmpty) return;

    final currentTitle = _customAudioNames[audioPath] ??
        ReminderAudioConfig.getDisplayName(audioPath, _customAudioNames);
    final editController = TextEditingController(text: currentTitle);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: primaryGreen, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit Custom Audio',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audio Name (max 30 characters)',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: editController,
                maxLength: 30,
                autofocus: true,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. My Morning Azan',
                  hintStyle: GoogleFonts.lexend(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF142018)
                      : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          actions: [
            Row(
              children: [
                TextButton( 
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDeleteCustomAudio(audioPath);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lexend(
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () async {
                    final newName = editController.text.trim();
                    if (newName.isEmpty) return;
                    Navigator.pop(ctx);
                    final truncated = newName.length > 30
                        ? newName.substring(0, 30).trim()
                        : newName;
                    final storage = ref.read(storageServiceProvider);
                    await storage.updateCustomAlarmAudioName(
                      audioPath,
                      truncated,
                    );
                    if (!mounted) return;
                    setState(() {
                      _customAudioNames[audioPath] = truncated;
                    });
                    AppFloatingToast.showEnabled(
                      context,
                      message: 'Audio name updated',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCustomAudio(String audioPath) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audioName = _customAudioNames[audioPath] ??
        ReminderAudioConfig.getDisplayName(audioPath, _customAudioNames);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Audio File?',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$audioName"? This will permanently remove the audio file.',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.lexend(
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (_isPreviewPlaying) {
                  await _stopAudioPreview();
                }

                final storage = ref.read(storageServiceProvider);
                await storage.deleteCustomAlarmAudio(audioPath);

                try {
                  final f = File(audioPath);
                  if (await f.exists()) {
                    await f.delete();
                  }
                } catch (e) {
                  debugPrint('[ReminderModal] Delete audio file error: $e');
                }

                if (mounted) {
                  setState(() {
                    _customAudioNames.remove(audioPath);
                    _soundOptions.remove(audioPath);
                    if (_soundType == audioPath) {
                      _soundType = ReminderAudioConfig.defaultRingtone;
                    }
                  });
                  AppFloatingToast.showRemoved(
                    context,
                    message: 'Audio file deleted',
                  );
                }
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
                style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCustomBgImages() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final stored = storage.getCustomAlarmImages();
      for (final p in stored) {
        if (File(p).existsSync() && !_customBgImages.contains(p)) {
          _customBgImages.add(p);
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final bgsDir = Directory('${appDir.path}/alarm_bgs');
      if (await bgsDir.exists()) {
        final files = bgsDir.listSync().whereType<File>().toList();
        final paths = files.map((f) => f.path).toList();
        for (final p in paths) {
          if (!_customBgImages.contains(p)) {
            _customBgImages.add(p);
            await storage.addCustomAlarmImage(p);
          }
        }
      }
      if (mounted) {
        setState(() {});
        for (final p in _customBgImages) {
          if (File(p).existsSync()) {
            precacheImage(ResizeImage(FileImage(File(p)), width: 250), context);
            precacheImage(ResizeImage(FileImage(File(p)), width: 1080), context); 
          }
        }
      }
    } catch (e) {
      debugPrint('[ReminderModal] Load custom backgrounds error: $e');
    }
  }

  Future<void> _pickCustomBackgroundImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final bgsDir = Directory('${appDir.path}/alarm_bgs');
        if (!await bgsDir.exists()) await bgsDir.create(recursive: true);

        final ext = picked.path.contains('.')
            ? '.${picked.path.split('.').last}'
            : '.jpg';
        final targetPath =
            '${bgsDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}$ext';
        await File(picked.path).copy(targetPath);

        final storage = ref.read(storageServiceProvider);
        await storage.addCustomAlarmImage(targetPath);

        if (mounted) {
          precacheImage(ResizeImage(FileImage(File(targetPath)), width: 250), context);
          precacheImage(ResizeImage(FileImage(File(targetPath)), width: 1080), context);
          setState(() {
            if (!_customBgImages.contains(targetPath)) {
              _customBgImages.insert(0, targetPath);
            }
            _alarmBgType = 'image';
            _alarmBgValue = targetPath;
          });
        }
      }
    } catch (e) {
      debugPrint('[ReminderModal] Pick custom background error: $e');
    }
  }

  void _confirmDeleteCustomBackground(String imgPath) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Background Image?',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this custom background? It will be removed permanently.',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.lexend(
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);

                // Evict from Flutter image cache for instant memory cleanup
                FileImage(File(imgPath)).evict();

                final storage = ref.read(storageServiceProvider);
                await storage.deleteCustomAlarmImage(imgPath);

                try {
                  final f = File(imgPath);
                  if (await f.exists()) {
                    await f.delete();
                  }
                } catch (e) {
                  debugPrint('[ReminderModal] Delete bg file error: $e');
                }

                if (mounted) {
                  setState(() {
                    _customBgImages.remove(imgPath);
                    if (_alarmBgValue == imgPath) {
                      _alarmBgType = 'image';
                      _alarmBgValue = AlarmBackgroundConfig.imageList.first;
                    }
                  });
                  AppFloatingToast.showRemoved(
                    context,
                    message: 'Background removed',
                  );
                }
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
                style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
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
      soundType: ReminderAudioConfig.canonicalSoundName(_soundType),
      vibrationEnabled: _vibrationEnabled,
      notificationEnabled: _notificationEnabled,
      isEnabled: widget.initialReminder?.isEnabled ?? true,
      turnedOffDate: widget.initialReminder?.turnedOffDate,
      alarmBgType: _alarmBgType,
      alarmBgValue: _alarmBgValue,
      alarmShowWaves: _alarmShowWaves,
      createdAt: widget.initialReminder?.createdAt ?? now,
      updatedAt: now,
      timezone: now.timeZoneName,
    );

    _stopAudioPreview();
    widget.onSave(rem);
    Navigator.pop(context);
  }

  Future<void> _previewAlarm() async {
    if (_alarmBgType == 'image') {
      final isCustom = (_alarmBgValue.contains('/') ||
              _alarmBgValue.contains('\\')) &&
          !_alarmBgValue.startsWith('assets/');
      try {
        if (isCustom && File(_alarmBgValue).existsSync()) {
          await precacheImage(
            ResizeImage(FileImage(File(_alarmBgValue)), width: 1080),
            context,
          );
        } else if (!isCustom) {
          await precacheImage(AssetImage(_alarmBgValue), context);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) => AlarmScreen(
          title: _titleController.text.trim().isEmpty
              ? 'Reminder Preview'
              : _titleController.text.trim(),
          soundType: 'preview_silent',
          initialBgType: _alarmBgType,
          initialBgValue: _alarmBgValue,
          initialShowWaves: _alarmShowWaves,
          isPreview: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    const secondaryGreen = Color(0xFF458830);
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
            key: ValueKey(_duration),
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
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16251C) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ), 
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _soundEnabled = !_soundEnabled),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text( 
                          'Sound',
                          style: GoogleFonts.lexend(fontSize: 15, color: textColor),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _soundEnabled,
                            activeTrackColor: primaryGreen,
                            activeThumbColor: Colors.white,
                            onChanged: (val) => setState(() => _soundEnabled = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_soundEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _soundType,
                            dropdownColor: cardBg,
                            isExpanded: true,
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
                            selectedItemBuilder: (context) {
                              return _soundOptions.map((opt) {
                                final isCustom =
                                    ReminderAudioConfig.isCustomFile(opt);
                                final displayName = _customAudioNames[opt] ??
                                    ReminderAudioConfig.getDisplayName(
                                      opt,
                                      _customAudioNames,
                                    );
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: GoogleFonts.lexend(
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCustom)
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _showEditAudioDialog(opt);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          margin: const EdgeInsets.only(left: 6),
                                          decoration: BoxDecoration(
                                            color: primaryGreen
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: primaryGreen,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }).toList();
                            },
                            items: _soundOptions.map((opt) {
                              final isCustom =
                                  ReminderAudioConfig.isCustomFile(opt);
                              final displayName = _customAudioNames[opt] ??
                                  ReminderAudioConfig.getDisplayName(
                                    opt,
                                    _customAudioNames,
                                  );
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: GoogleFonts.lexend(
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCustom)
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                          _showEditAudioDialog(opt);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          margin:
                                              const EdgeInsets.only(left: 6),
                                          decoration: BoxDecoration(
                                            color: primaryGreen
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: primaryGreen,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _soundType = val;
                                  if (ReminderAudioConfig.isAzan(val)) {
                                    _duration = AlarmDuration.fullRingtone;
                                  }
                                });
                                if (_isPreviewPlaying) {
                                  _playAudioPreview();
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: _pickCustomAudioFile,
                          tooltip: 'Upload Audio File from Phone',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                primaryGreen.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(8),
                          ),
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            color: primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 6),
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
                            padding: const EdgeInsets.all(8),
                          ),
                          icon: Icon(
                            _isPreviewPlaying
                                ? Icons.stop_circle_rounded
                                : Icons.play_circle_filled_rounded,
                            color: _isPreviewPlaying
                                ? const Color(0xFFEF4444)
                                : primaryGreen,
                            size: 24,
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
                InkWell(
                  onTap: () => setState(() => _vibrationEnabled = !_vibrationEnabled),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vibration',
                          style: GoogleFonts.lexend(fontSize: 15, color: textColor),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _vibrationEnabled,
                            activeTrackColor: primaryGreen,
                            activeThumbColor: Colors.white,
                            onChanged: (val) => setState(() => _vibrationEnabled = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                InkWell(
                  onTap: () => setState(() => _notificationEnabled = !_notificationEnabled),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notification Alert',
                          style: GoogleFonts.lexend(fontSize: 15, color: textColor),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _notificationEnabled,
                            activeTrackColor: primaryGreen,
                            activeThumbColor: Colors.white,
                            onChanged: (val) =>
                                setState(() => _notificationEnabled = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                // ALARM SCREEN THEME SECTION
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alarm Screen Theme',
                            style: GoogleFonts.lexend(
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _previewAlarm,
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text('Preview'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGreen,
                          side: BorderSide(
                            color: primaryGreen.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: GoogleFonts.lexend(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Horizontally Scrollable Wallpapers & Gradients
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // 0. Add Custom Background Button (Rectangular, exact same dimensions 95x150)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: _pickCustomBackgroundImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 95,
                              height: 150,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1B2E23)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryGreen.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: primaryGreen,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      'Add Custom\nBackground',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.lexend(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : primaryGreen,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Custom Uploaded Backgrounds
                        ..._customBgImages.map((customImg) {
                          final isSelected =
                              _alarmBgType == 'image' && _alarmBgValue == customImg;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _alarmBgType = 'image';
                                  _alarmBgValue = customImg;
                                });
                                precacheImage(
                                  ResizeImage(FileImage(File(customImg)), width: 1080),
                                  context,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 95,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? secondaryGreen
                                        : (isDark
                                              ? Colors.white12
                                              : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(customImg),
                                        fit: BoxFit.cover,
                                        cacheWidth: 250,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: isDark
                                                ? const Color(0xFF1E2D24)
                                                : Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                      if (isSelected)
                                        Container(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              margin: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(
                                                color: secondaryGreen,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Bin icon at bottom left corner
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () =>
                                                _confirmDeleteCustomBackground(
                                              customImg,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.65,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(
                                                    alpha: 0.35,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // 1. Image Wallpapers
                        ...AlarmBackgroundConfig.imageList.map((img) {
                          final isSelected =
                              _alarmBgType == 'image' && _alarmBgValue == img;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _alarmBgType = 'image';
                                  _alarmBgValue = img;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 95,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? secondaryGreen
                                        : (isDark
                                              ? Colors.white12
                                              : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(img, fit: BoxFit.cover),
                                      if (isSelected)
                                        Container(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              margin: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(
                                                color: secondaryGreen,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // 2. Gradient Wallpapers (Identical rectangle dimensions at the end)
                        ...AlarmBackgroundConfig.gradientList.map((g) {
                          final id = g['id'] as String;
                          final colors = (g['colors'] as List).cast<Color>();
                          final name = g['name'] as String;
                          final isSelected =
                              _alarmBgType == 'gradient' && _alarmBgValue == id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _alarmBgType = 'gradient';
                                  _alarmBgValue = id;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 95,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryGreen
                                        : (isDark
                                              ? Colors.white12
                                              : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  gradient: LinearGradient(
                                    colors: colors,
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (isSelected)
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 6,
                                      left: 4,
                                      right: 4,
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.lexend(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ), 
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _alarmShowWaves = !_alarmShowWaves),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ambient Wave Motion',
                                style: GoogleFonts.lexend(
                                  fontSize: 14.5,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Subtle flowing motion over wallpaper',
                                style: GoogleFonts.lexend(
                                  fontSize: 11,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _alarmShowWaves,
                            activeTrackColor: primaryGreen,
                            activeThumbColor: Colors.white,
                            onChanged: (val) => setState(() => _alarmShowWaves = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4)
              ],
            ),
          ),
        ],
      ),
    );

    final stickySaveButton = Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
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
      ),
    );

    if (widget.isEmbedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: formContent),
          stickySaveButton,
        ],
      );
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

            // Sticky Bottom Save Changes Button
            stickySaveButton,
          ],
        ),
      ),
    );
  }
}
