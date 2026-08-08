import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/aladhan_api_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/aladhan_models.dart';
import '../../data/repositories/aladhan_repository.dart';

/// Provider for [AlAdhanApiClient].
final aladhanApiClientProvider = Provider<AlAdhanApiClient>((ref) {
  return AlAdhanApiClient();
});

/// Provider for [AlAdhanRepository].
final aladhanRepositoryProvider = Provider<AlAdhanRepository>((ref) {
  final client = ref.watch(aladhanApiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AlAdhanRepository(apiClient: client, storageService: storage);
});

/// Provider fetching prayer timings from AlAdhan API with fallback to local calculations.
final aladhanPrayerTimesProvider = FutureProvider.family<PrayerTimeFetchResult, DateTime>((ref, rawDate) async {
  final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
  final repository = ref.watch(aladhanRepositoryProvider);
  final locationAsync = ref.watch(currentLocationProvider);
  final method = ref.watch(calculationMethodProvider);
  final juristic = ref.watch(asrJuristicProvider);

  final location = locationAsync.value ?? LocationService.defaultLocation;

  return repository.getPrayerTimes(
    date: date,
    latitude: location.latitude,
    longitude: location.longitude,
    methodName: method,
    juristicAsr: juristic,
  );
});

/// Provider fetching monthly calendar from AlAdhan API for given year & month.
final aladhanMonthlyCalendarProvider = FutureProvider.family<List<AlAdhanTimingsData>, ({int year, int month})>((ref, arg) async {
  final apiClient = ref.watch(aladhanApiClientProvider);
  final locationAsync = ref.watch(currentLocationProvider);
  final method = ref.watch(calculationMethodProvider);
  final juristic = ref.watch(asrJuristicProvider);

  final location = locationAsync.value ?? LocationService.defaultLocation;
  final methodId = AlAdhanApiClient.mapMethodToId(method);
  final schoolId = AlAdhanApiClient.mapJuristicToSchool(juristic);

  try {
    final response = await apiClient.getCalendar(
      year: arg.year,
      month: arg.month,
      latitude: location.latitude,
      longitude: location.longitude,
      method: methodId,
      school: schoolId,
    );
    if (response.isSuccess) {
      return response.data;
    }
  } catch (_) {
    // Return empty list on failure
  }

  return [];
});

/// Provider fetching Qibla direction (degrees from North) from AlAdhan API with local fallback.
final qiblaDirectionProvider = FutureProvider.family<double, ({double latitude, double longitude})>((ref, arg) async {
  final client = ref.watch(aladhanApiClientProvider);
  try {
    final apiDirection = await client.getQiblaDirection(arg.latitude, arg.longitude);
    if (apiDirection != null) {
      return apiDirection;
    }
  } catch (_) {}
  return LocationService.calculateQiblaDirection(arg.latitude, arg.longitude);
});
