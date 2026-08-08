import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/aladhan_api_client.dart';
import '../../../../core/services/prayer_calculation_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/aladhan_models.dart';

/// Source flag indicating where prayer times came from.
enum PrayerTimeSource {
  apiRemote,
  localCalculated,
}

/// Container object returning both the timings and their source.
class PrayerTimeFetchResult {
  final PrayerTimeResult result;
  final PrayerTimeSource source;
  final AlAdhanTimingsData? apiRawData;

  const PrayerTimeFetchResult({
    required this.result,
    required this.source,
    this.apiRawData,
  });
}

class AlAdhanRepository {
  final AlAdhanApiClient apiClient;
  final StorageService? storageService;

  static final Map<String, PrayerTimeFetchResult> _memoryCache = {};

  AlAdhanRepository({AlAdhanApiClient? apiClient, this.storageService})
      : apiClient = apiClient ?? AlAdhanApiClient();

  /// Fetches prayer times for a specified date and location.
  /// Uses latitude and longitude directly with AlAdhan API (`/timings/{date}?latitude=...&longitude=...`).
  /// Caches results locally by date, coordinates, calculation method, and juristic school.
  Future<PrayerTimeFetchResult> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String? city,
    String? country,
    String methodName = 'KARACHI',
    String juristicAsr = 'Hanafi',
  }) async {
    final methodId = AlAdhanApiClient.mapMethodToId(methodName);
    final schoolId = AlAdhanApiClient.mapJuristicToSchool(juristicAsr);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // Build unique cache key using date, rounded coordinates, method, and school
    final cacheKey = '${dateKey}_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_${methodName}_$juristicAsr';

    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    try {
      final response = await apiClient.getTimings(
        date: date,
        latitude: latitude,
        longitude: longitude,
        method: methodId,
        school: schoolId,
      );

      if (response.isSuccess) {
        final prayerTimeResult = _convertTimingsDataToPrayerTimeResult(date, response.data.timings);

        final h = response.data.date.hijri;
        final hijriStr = h.formattedHijri;
        await storageService?.setCachedHijriDate(dateKey, hijriStr);
        await storageService?.setHijriLastFetchedMs(DateTime.now().millisecondsSinceEpoch);

        final fetchResult = PrayerTimeFetchResult(
          result: prayerTimeResult,
          source: PrayerTimeSource.apiRemote,
          apiRawData: response.data,
        );

        _memoryCache[cacheKey] = fetchResult;
        return fetchResult;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AlAdhan API request failed ($e). Falling back to local PrayerCalculationService.');
      }
    }

    // Fallback to local calculation if network fails
    final localResult = PrayerCalculationService.calculate(
      date: date,
      latitude: latitude,
      longitude: longitude,
      methodName: methodName,
      juristicAsr: juristicAsr,
    );

    final fetchResult = PrayerTimeFetchResult(
      result: localResult,
      source: PrayerTimeSource.localCalculated,
    );

    _memoryCache[cacheKey] = fetchResult;
    return fetchResult;
  }

  /// Converts API string timings ("05:15", "12:30", etc.) to [PrayerTimeResult].
  PrayerTimeResult _convertTimingsDataToPrayerTimeResult(DateTime baseDate, AlAdhanTimings timings) {
    DateTime parseTime(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      }
      return baseDate;
    }

    final fajr = parseTime(timings.fajr);
    final sunrise = parseTime(timings.sunrise);
    final dhuhr = parseTime(timings.dhuhr);
    final asr = parseTime(timings.asr);
    final maghrib = parseTime(timings.maghrib);
    final isha = parseTime(timings.isha);

    // Qiyam (last third of the night between Maghrib and next day's Fajr)
    final nextFajr = fajr.add(const Duration(days: 1));
    final nightDuration = nextFajr.difference(maghrib);
    final qiyam = maghrib.add(Duration(seconds: (nightDuration.inSeconds * (2 / 3)).round()));

    return PrayerTimeResult(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      qiyam: qiyam,
    );
  }
}
