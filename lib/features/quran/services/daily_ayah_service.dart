import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/services/storage_service.dart';
import '../data/daily_ayah_model.dart';

/// Service responsible for fetching and caching the Daily Quran Ayah
/// from the Al-Quran Cloud API.
class DailyAyahService {
  static const String _storageKey = 'daily_ayah_cache_key';
  static const int totalAyahsInQuran = 6236;

  final StorageService _storage;
  final Dio _dio;

  DailyAyahService(this._storage, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.alquran.cloud/v1/ayah',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  /// Returns today's formatted date string: 'yyyy-MM-dd'
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Returns the current Daily Ayah.
  /// If [forceRefresh] is true, ignores cache and fetches a new random ayah.
  Future<DailyAyahModel> getDailyAyah({bool forceRefresh = false}) async {
    final cached = getCachedAyah();

    // 1. If we have a cached ayah for today and not forcing a refresh, return it instantly
    if (!forceRefresh && cached != null && cached.dateKey == _todayKey) {
      return cached;
    }

    // 2. Otherwise, fetch a new random ayah from the API
    try {
      final ayahNumber = _pickRandomAyahNumber();
      final freshAyah = await _fetchAyahFromApi(ayahNumber, _todayKey);
      await _cacheAyah(freshAyah);
      return freshAyah;
    } catch (e, stack) {
      debugPrint('[DailyAyahService] Network error fetching daily ayah: $e\n$stack');
      // 3. Fallback: if network fails, use existing cache if available, else default ayah
      if (cached != null) {
        return cached;
      }
      return DailyAyahModel.defaultAyah;
    }
  }

  /// Synchronously retrieves the cached Daily Ayah if present.
  DailyAyahModel? getCachedAyah() {
    try {
      final raw = _storage.getGenericData(_storageKey);
      if (raw != null && raw is String && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return DailyAyahModel.fromMap(map);
      }
    } catch (e) {
      debugPrint('[DailyAyahService] Error parsing cached ayah: $e');
    }
    return null;
  }

  /// Saves the given ayah to local storage.
  Future<void> _cacheAyah(DailyAyahModel ayah) async {
    try {
      await _storage.saveGenericData(_storageKey, ayah.toJson());
    } catch (e) {
      debugPrint('[DailyAyahService] Error caching ayah: $e');
    }
  }

  /// Generates a random Ayah index between 1 and 6236 inclusive.
  int _pickRandomAyahNumber() {
    final rng = math.Random();
    return rng.nextInt(totalAyahsInQuran) + 1;
  }

  /// Fetches the ayah from Al-Quran Cloud API for both Arabic Uthmani and English Saheeh.
  Future<DailyAyahModel> _fetchAyahFromApi(int ayahNumber, String dateKey) async {
    // Attempt 1: Combined multi-editions endpoint
    try {
      final response = await _dio.get('/$ayahNumber/editions/quran-uthmani,en.sahih');
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final dataList = body['data'];
        if (dataList is List && dataList.length >= 2) {
          Map<String, dynamic>? uthmani;
          Map<String, dynamic>? sahih;

          for (final item in dataList) {
            if (item is Map<String, dynamic>) {
              final editionId = item['edition']?['identifier'];
              if (editionId == 'quran-uthmani') {
                uthmani = item;
              } else if (editionId == 'en.sahih') {
                sahih = item;
              }
            }
          }

          if (uthmani != null && sahih != null) {
            return DailyAyahModel.fromApiData(
              uthmaniData: uthmani,
              sahihData: sahih,
              dateKey: dateKey,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[DailyAyahService] Combined endpoint failed, falling back to separate calls: $e');
    }

    // Attempt 2: Separate parallel endpoints
    final results = await Future.wait([
      _dio.get('/$ayahNumber/quran-uthmani'),
      _dio.get('/$ayahNumber/en.sahih'),
    ]);

    final resUthmani = results[0];
    final resSahih = results[1];

    if (resUthmani.statusCode == 200 && resSahih.statusCode == 200) {
      final uthmaniData = (resUthmani.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final sahihData = (resSahih.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      return DailyAyahModel.fromApiData(
        uthmaniData: uthmaniData,
        sahihData: sahihData,
        dateKey: dateKey,
      );
    }

    throw Exception('Failed to load Ayah $ayahNumber from Al-Quran Cloud API');
  }
}
