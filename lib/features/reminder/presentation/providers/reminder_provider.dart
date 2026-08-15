import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/reminder_model.dart';
import '../../services/reminder_scheduler.dart';

final remindersProvider =
    StateNotifierProvider<ReminderNotifier, List<CustomReminder>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ReminderNotifier(storageService);
});

class ReminderNotifier extends StateNotifier<List<CustomReminder>> {
  final StorageService _storageService;
  final ReminderScheduler _scheduler = ReminderScheduler();
  static const String _storageKey = 'custom_reminders_list_v2';

  ReminderNotifier(this._storageService) : super([]) {
    _loadReminders();
  }

  void _loadReminders() {
    try {
      final rawData = _storageService.getGenericData(_storageKey);
      if (rawData != null && rawData is String && rawData.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(rawData);
        final loaded = jsonList
            .map((item) => CustomReminder.fromJson(item as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty) {
          state = loaded;
        } else {
          _loadDefaults();
        }
      } else {
        _loadDefaults();
      }
    } catch (_) {
      _loadDefaults();
    }

    _scheduler.rescheduleAll(state);
  }

  void _loadDefaults() {
    final now = DateTime.now();
    final timezone = now.timeZoneName;

    state = [
      CustomReminder(
        id: 'predefined_rem_fajr',
        title: 'Fajr Prayer Reminder',
        description: 'Daily prayer reminder at Fajr start time',
        hour: 5,
        minute: 15,
        frequency: ReminderFrequency.daily,
        customDays: const [1, 2, 3, 4, 5, 6, 7],
        duration: AlarmDuration.seconds30,
        soundEnabled: true,
        soundType: 'Makkah Azaan',
        vibrationEnabled: true,
        notificationEnabled: true,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
        timezone: timezone,
      ),
      CustomReminder(
        id: 'predefined_rem_dhuhr',
        title: 'Dhuhr Prayer Reminder',
        description: 'Daily prayer reminder at Dhuhr start time',
        hour: 12,
        minute: 30,
        frequency: ReminderFrequency.daily,
        customDays: const [1, 2, 3, 4, 5, 6, 7],
        duration: AlarmDuration.seconds30,
        soundEnabled: true,
        soundType: 'Makkah Azaan',
        vibrationEnabled: true,
        notificationEnabled: true,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
        timezone: timezone,
      ),
      CustomReminder(
        id: 'predefined_rem_asr',
        title: 'Asr Prayer Reminder',
        description: 'Daily prayer reminder at Asr start time',
        hour: 15,
        minute: 45,
        frequency: ReminderFrequency.daily,
        customDays: const [1, 2, 3, 4, 5, 6, 7],
        duration: AlarmDuration.seconds30,
        soundEnabled: true,
        soundType: 'Makkah Azaan',
        vibrationEnabled: true,
        notificationEnabled: true,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
        timezone: timezone,
      ),
      CustomReminder(
        id: 'predefined_rem_maghrib',
        title: 'Maghrib Prayer Reminder',
        description: 'Daily prayer reminder at Maghrib start time',
        hour: 18,
        minute: 15,
        frequency: ReminderFrequency.daily,
        customDays: const [1, 2, 3, 4, 5, 6, 7],
        duration: AlarmDuration.seconds30,
        soundEnabled: true,
        soundType: 'Makkah Azaan',
        vibrationEnabled: true,
        notificationEnabled: true,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
        timezone: timezone,
      ),
      CustomReminder(
        id: 'predefined_rem_isha',
        title: 'Isha Prayer Reminder',
        description: 'Daily prayer reminder at Isha start time',
        hour: 19,
        minute: 45,
        frequency: ReminderFrequency.daily,
        customDays: const [1, 2, 3, 4, 5, 6, 7],
        duration: AlarmDuration.seconds30,
        soundEnabled: true,
        soundType: 'Makkah Azaan',
        vibrationEnabled: true,
        notificationEnabled: true,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
        timezone: timezone,
      ),
    ];
    _saveReminders();
  }

  Future<void> _saveReminders() async {
    final jsonList = state.map((r) => r.toJson()).toList();
    await _storageService.saveGenericData(_storageKey, jsonEncode(jsonList));
  }

  Future<void> addReminder(CustomReminder reminder) async {
    state = [...state, reminder];
    await _saveReminders();
    await _scheduler.scheduleReminder(reminder);
  }

  Future<void> updateReminder(CustomReminder updated) async {
    state = state.map((r) => r.id == updated.id ? updated : r).toList();
    await _saveReminders();
    await _scheduler.scheduleReminder(updated);
  }

  Future<void> deleteReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveReminders();
    await _scheduler.cancelReminder(id);
  }

  Future<void> toggleEnable(String id) async {
    final target = state.firstWhere((r) => r.id == id);
    final updated = target.copyWith(
      isEnabled: !target.isEnabled,
      clearTurnedOffDate: target.isEnabled, // clear skip if re-enabling
    );
    await updateReminder(updated);
  }

  Future<void> turnOffToday(String id) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final target = state.firstWhere((r) => r.id == id);
    final updated = target.copyWith(turnedOffDate: todayStr);
    await updateReminder(updated);
  }

  Future<void> reactivateToday(String id) async {
    final target = state.firstWhere((r) => r.id == id);
    final updated = target.copyWith(clearTurnedOffDate: true);
    await updateReminder(updated);
  }
}
