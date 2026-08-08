import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/prayer_calculation_service.dart';
import '../../core/services/storage_service.dart';
import '../../features/prayer/presentation/providers/aladhan_providers.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main');
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final audioServiceProvider = Provider<AppAudioService>((ref) {
  final service = AppAudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

class UserLocationNotifier extends StateNotifier<AsyncValue<LocationData>> {
  final StorageService _storage;
  final LocationService _locationService;

  UserLocationNotifier(this._storage, this._locationService)
      : super(const AsyncValue.loading()) {
    loadLocation();
  }

  Future<LocationData> loadLocation() async {
    try {
      final saved = _storage.getSavedLocation();
      if (saved != null) {
        final savedLoc = LocationData(
          latitude: (saved['lat'] as num).toDouble(),
          longitude: (saved['lng'] as num).toDouble(),
          city: saved['city'] as String? ?? 'Makkah',
          country: saved['country'] as String? ?? '',
        );
        state = AsyncValue.data(savedLoc);
        return savedLoc;
      }

      // Auto-fetch fresh user location from GPS if no custom location saved
      final current = await _locationService.getCurrentLocation();
      await _storage.setSavedLocation(
        current.latitude,
        current.longitude,
        current.city,
        current.country,
      );
      state = AsyncValue.data(current);
      return current;
    } catch (e, stack) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
      return LocationService.defaultLocation;
    }
  }

  Future<void> setCustomLocation({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) async {
    await _storage.setSavedLocation(latitude, longitude, city, country);
    state = AsyncValue.data(LocationData(
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
    ));
  }

  Future<void> refreshFromGps() async {
    state = const AsyncValue.loading();
    final current = await _locationService.getCurrentLocation();
    await _storage.setSavedLocation(
      current.latitude,
      current.longitude,
      current.city,
      current.country,
    );
    state = AsyncValue.data(current);
  }
}

final userLocationProvider = StateNotifierProvider<UserLocationNotifier, AsyncValue<LocationData>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  return UserLocationNotifier(storage, locationService);
});

final currentLocationProvider = Provider<AsyncValue<LocationData>>((ref) {
  return ref.watch(userLocationProvider);
});

final calculationMethodProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getCalculationMethod();
});

final asrJuristicProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getAsrJuristic();
});

final themeModeProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getThemeMode();
});

/// Provides current prayer times. Watches AlAdhan API provider and falls back to local math calculation.
final prayerTimesProvider = Provider<PrayerTimeResult?>((ref) {
  final now = DateTime.now();
  final dateOnly = DateTime(now.year, now.month, now.day);
  final aladhanAsync = ref.watch(aladhanPrayerTimesProvider(dateOnly));
  final locationAsync = ref.watch(currentLocationProvider);
  final method = ref.watch(calculationMethodProvider);
  final juristic = ref.watch(asrJuristicProvider);

  if (aladhanAsync.hasValue && aladhanAsync.value != null) {
    return aladhanAsync.value!.result;
  }

  final location = locationAsync.value ?? LocationService.defaultLocation;
  return PrayerCalculationService.calculate(
    date: now,
    latitude: location.latitude,
    longitude: location.longitude,
    methodName: method,
    juristicAsr: juristic,
  );
});

class NextPrayerInfo {
  final String name;
  final DateTime time;
  final Duration remaining;

  const NextPrayerInfo({
    required this.name,
    required this.time,
    required this.remaining,
  });

  /// Computes live remaining duration against [DateTime.now()] dynamically.
  Duration get currentRemaining {
    final diff = time.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

final nextPrayerProvider = Provider<NextPrayerInfo?>((ref) {
  final result = ref.watch(prayerTimesProvider);
  if (result == null) return null;

  final now = DateTime.now();
  final times = result.toMap();

  for (final entry in times.entries) {
    if (entry.key == 'Qiyam') continue;
    if (entry.value.isAfter(now)) {
      return NextPrayerInfo(
        name: entry.key,
        time: entry.value,
        remaining: entry.value.difference(now),
      );
    }
  }

  // If past Isha, next prayer is Fajr tomorrow
  final location = ref.watch(currentLocationProvider).value ?? LocationService.defaultLocation;
  final method = ref.watch(calculationMethodProvider);
  final juristic = ref.watch(asrJuristicProvider);

  final tomorrowResult = PrayerCalculationService.calculate(
    date: now.add(const Duration(days: 1)),
    latitude: location.latitude,
    longitude: location.longitude,
    methodName: method,
    juristicAsr: juristic,
  );

  return NextPrayerInfo(
    name: 'Fajr',
    time: tomorrowResult.fajr,
    remaining: tomorrowResult.fajr.difference(now),
  );
});

final currentPrayerProvider = Provider<NextPrayerInfo?>((ref) {
  final result = ref.watch(prayerTimesProvider);
  if (result == null) return null;

  final now = DateTime.now();

  if (now.isBefore(result.fajr)) {
    return NextPrayerInfo(
      name: 'Isha',
      time: result.fajr,
      remaining: result.fajr.difference(now),
    );
  } else if (now.isBefore(result.dhuhr)) {
    return NextPrayerInfo(
      name: 'Fajr',
      time: result.dhuhr,
      remaining: result.dhuhr.difference(now),
    );
  } else if (now.isBefore(result.asr)) {
    return NextPrayerInfo(
      name: 'Dhuhr',
      time: result.asr,
      remaining: result.asr.difference(now),
    );
  } else if (now.isBefore(result.maghrib)) {
    return NextPrayerInfo(
      name: 'Asr',
      time: result.maghrib,
      remaining: result.maghrib.difference(now),
    );
  } else if (now.isBefore(result.isha)) {
    return NextPrayerInfo(
      name: 'Maghrib',
      time: result.isha,
      remaining: result.isha.difference(now),
    );
  } else {
    final location = ref.watch(currentLocationProvider).value ?? LocationService.defaultLocation;
    final method = ref.watch(calculationMethodProvider);
    final juristic = ref.watch(asrJuristicProvider);

    final tomorrowResult = PrayerCalculationService.calculate(
      date: now.add(const Duration(days: 1)),
      latitude: location.latitude,
      longitude: location.longitude,
      methodName: method,
      juristicAsr: juristic,
    );

    return NextPrayerInfo(
      name: 'Isha',
      time: tomorrowResult.fajr,
      remaining: tomorrowResult.fajr.difference(now),
    );
  }
});
