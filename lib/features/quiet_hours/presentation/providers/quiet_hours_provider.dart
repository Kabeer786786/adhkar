import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/quiet_hours_model.dart';
import '../../services/quiet_hours_service.dart';

final quietHoursServiceProvider = Provider<QuietHoursService>((ref) {
  return QuietHoursService();
});

final quietHoursProvider =
    StateNotifierProvider<QuietHoursNotifier, List<QuietHours>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final quietHoursService = ref.watch(quietHoursServiceProvider);
  return QuietHoursNotifier(storageService, quietHoursService);
});

class QuietHoursNotifier extends StateNotifier<List<QuietHours>> {
  final StorageService _storageService;
  final QuietHoursService _quietHoursService;

  QuietHoursNotifier(this._storageService, this._quietHoursService)
      : super(const []) {
    _loadAndSync();
  }

  Future<void> _loadAndSync() async {
    final dataList = _storageService.getQuietHoursList();
    List<QuietHours> loaded = [];
    if (dataList != null && dataList.isNotEmpty) {
      loaded = dataList.map((e) => QuietHours.fromJson(e)).toList();
    } else {
      loaded = QuietHours.defaultSchedules();
    }

    _sortSchedules(loaded);
    state = loaded;
    final synced = await _quietHoursService.syncQuietHoursList(
      loaded,
      _storageService,
    );
    _sortSchedules(synced);
    state = synced;
  }

  void _sortSchedules(List<QuietHours> list) {
    list.sort((a, b) {
      final timeA = a.startHour * 60 + a.startMinute;
      final timeB = b.startHour * 60 + b.startMinute;
      return timeA.compareTo(timeB);
    });
  }

  Future<void> addSchedule(QuietHours schedule) async {
    final updatedList = [...state, schedule];
    _sortSchedules(updatedList);
    await _saveAndSync(updatedList);
  }

  Future<void> updateSchedule(QuietHours schedule) async {
    final updatedList = state.map((s) => s.id == schedule.id ? schedule : s).toList();
    _sortSchedules(updatedList);
    await _saveAndSync(updatedList);
  }

  Future<void> deleteSchedule(String id) async {
    final updatedList = state.where((s) => s.id != id).toList();
    _sortSchedules(updatedList);
    await _saveAndSync(updatedList);
  }

  Future<void> toggleScheduleEnabled(String id, bool enabled) async {
    final updatedList = state.map((s) {
      if (s.id == id) {
        return s.copyWith(enabled: enabled, updatedAt: DateTime.now());
      }
      return s;
    }).toList();
    _sortSchedules(updatedList);
    await _saveAndSync(updatedList);
  }

  Future<void> syncDndState() async {
    final synced = await _quietHoursService.syncQuietHoursList(
      state,
      _storageService,
    );
    _sortSchedules(synced);
    state = synced;
  }

  Future<void> _saveAndSync(List<QuietHours> list) async {
    _sortSchedules(list);
    state = list;
    await _storageService.saveQuietHoursList(list.map((s) => s.toJson()).toList());
    final synced = await _quietHoursService.syncQuietHoursList(
      list,
      _storageService,
    );
    _sortSchedules(synced);
    state = synced;
  }
}
