import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/daily_ayah_model.dart';
import '../../services/daily_ayah_service.dart';

final dailyAyahServiceProvider = Provider<DailyAyahService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DailyAyahService(storage);
});

class DailyAyahNotifier extends StateNotifier<AsyncValue<DailyAyahModel>> {
  final DailyAyahService _service;

  DailyAyahNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Check if we have a cached ayah for immediate zero-latency display
    final cached = _service.getCachedAyah();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }

    // 2. Fetch/validate today's ayah
    try {
      final ayah = await _service.getDailyAyah(forceRefresh: false);
      state = AsyncValue.data(ayah);
    } catch (e) {
      if (state.hasValue) {
        // Keep existing cached data if background refresh failed
      } else {
        state = AsyncValue.data(DailyAyahModel.defaultAyah);
      }
    }
  }

  /// Manually refreshes to pick a new random Ayah
  Future<void> refresh() async {
    // Keep showing current data while refreshing if possible
    final current = state.valueOrNull;
    try {
      final fresh = await _service.getDailyAyah(forceRefresh: true);
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      if (current != null) {
        state = AsyncValue.data(current);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final dailyAyahProvider =
    StateNotifierProvider<DailyAyahNotifier, AsyncValue<DailyAyahModel>>((ref) {
  final service = ref.watch(dailyAyahServiceProvider);
  return DailyAyahNotifier(service);
});
