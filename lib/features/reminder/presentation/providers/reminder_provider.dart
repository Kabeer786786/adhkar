import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/reminder_model.dart';

final remindersProvider =
    StateNotifierProvider<ReminderNotifier, List<CustomReminder>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ReminderNotifier(storageService);
});

class ReminderNotifier extends StateNotifier<List<CustomReminder>> {
  final StorageService _storageService;
  static const String _storageKey = 'custom_reminders_list_v1';

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
        state = loaded;
      } else {
        // Initial Default Presets
        state = [
          CustomReminder(
            id: 'preset_morning_adhkar',
            title: 'Morning Adhkar',
            hour: 6,
            minute: 0,
            sound: true,
            vibration: true,
            notification: true,
            soundType: 'Azaan',
            selectedDays: const [1, 2, 3, 4, 5, 6, 7],
            isEnabled: true,
            createdAt: DateTime.now(),
          ),
          CustomReminder(
            id: 'preset_evening_adhkar',
            title: 'Evening Adhkar',
            hour: 17,
            minute: 30,
            sound: true,
            vibration: true,
            notification: true,
            soundType: 'Azaan',
            selectedDays: const [1, 2, 3, 4, 5, 6, 7],
            isEnabled: true,
            createdAt: DateTime.now(),
          ),
          CustomReminder(
            id: 'preset_surah_kahf',
            title: 'Read Surah Al-Kahf',
            hour: 9,
            minute: 0,
            sound: true,
            vibration: true,
            notification: true,
            soundType: 'Azaan',
            selectedDays: const [5], // Friday
            isEnabled: true,
            createdAt: DateTime.now(),
          ),
        ];
        _saveReminders();
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> _saveReminders() async {
    final jsonList = state.map((r) => r.toJson()).toList();
    await _storageService.saveGenericData(_storageKey, jsonEncode(jsonList));
  }


  Future<void> addReminder(CustomReminder reminder) async {
    state = [...state, reminder];
    await _saveReminders();
  }

  Future<void> updateReminder(CustomReminder updated) async {
    state = state.map((r) => r.id == updated.id ? updated : r).toList();
    await _saveReminders();
  }

  Future<void> deleteReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveReminders();
  }

  Future<void> toggleReminder(String id) async {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(isEnabled: !r.isEnabled);
      }
      return r;
    }).toList();
    await _saveReminders();
  }
}
