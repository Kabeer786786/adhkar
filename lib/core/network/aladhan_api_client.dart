import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../features/prayer/data/models/aladhan_models.dart';

/// Client to interact with the AlAdhan Prayer Times API (OpenAPI v1).
class AlAdhanApiClient {
  static const String defaultBaseUrl = 'https://api.aladhan.com/v1';
  static const String mirrorBaseUrl = 'https://aladhan.api.islamic.network/v1';

  final Dio _dio;

  AlAdhanApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: defaultBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Accept': 'application/json'},
            ),
          );

  /// Helper to format DateTime into DD-MM-YYYY expected by API endpoints.
  static String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Maps calculation method names to AlAdhan method integer IDs.
  static int mapMethodToId(String methodName) {
    switch (methodName.toUpperCase()) {
      case 'MWL':
        return 3;
      case 'ISNA':
        return 2;
      case 'EGYPT':
        return 5;
      case 'MAKKAH':
        return 4;
      case 'KARACHI':
        return 1;
      case 'TEHRAN':
        return 7;
      case 'GULF':
        return 8;
      case 'MOON SIGHTING':
      case 'MOONSIGHTING':
        return 15;
      default:
        return 1; // Default Karachi
    }
  }

  /// Maps juristic Asr rule name to AlAdhan school parameter (0 = Shafi/Standard, 1 = Hanafi).
  static int mapJuristicToSchool(String juristic) {
    return juristic.toUpperCase() == 'HANAFI' ? 1 : 0;
  }

  Future<Response<dynamic>> _getWithFallback(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (_) {
      // Retry once using mirror URL if default host fails or times out
      final options = Options(headers: {'Accept': 'application/json'});
      final mirrorPath = '$mirrorBaseUrl$path';
      return await _dio.get(
        mirrorPath,
        queryParameters: queryParameters,
        options: options,
      );
    }
  }

  /// GET /timings/{date}
  /// Returns prayer times for a specific date using latitude and longitude.
  Future<AlAdhanApiResponse<AlAdhanTimingsData>> getTimings({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? method,
    int? school,
    String? shafaq,
    String? tune,
    String? midnightMode,
    String? timeZoneString,
    String? latitudeAdjustmentMethod,
    int? calendarMethod,
    int? adjustment,
    bool iso8601 = false,
  }) async {
    final formattedDate = formatDate(date);
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
      if (shafaq != null) 'shafaq': shafaq,
      if (tune != null) 'tune': tune,
      if (midnightMode != null) 'midnightMode': midnightMode,
      if (timeZoneString != null) 'timezonestring': timeZoneString,
      if (latitudeAdjustmentMethod != null)
        'latitudeAdjustmentMethod': latitudeAdjustmentMethod,
      if (calendarMethod != null) 'calendarMethod': calendarMethod,
      if (adjustment != null) 'adjustment': adjustment,
      if (iso8601) 'iso8601': true,
    };

    final response = await _getWithFallback(
      '/timings/$formattedDate',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<AlAdhanTimingsData>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AlAdhanTimingsData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /timingsByAddress/{date}
  /// Returns prayer times for an address on a specific date.
  Future<AlAdhanApiResponse<AlAdhanTimingsData>> getTimingsByAddress({
    required DateTime date,
    required String address,
    int? method,
    int? school,
    int adjustment = -1,
  }) async {
    final formattedDate = formatDate(date);
    final queryParams = <String, dynamic>{
      'address': address,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
      'adjustment': adjustment,
    };

    final response = await _getWithFallback(
      '/timingsByAddress/$formattedDate',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<AlAdhanTimingsData>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AlAdhanTimingsData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /timingsByCity/{date}
  /// Returns prayer times for a city and country on a specific date.
  Future<AlAdhanApiResponse<AlAdhanTimingsData>> getTimingsByCity({
    required DateTime date,
    required String city,
    required String country,
    String? state,
    int? method,
    int? school,
    int adjustment = -1,
  }) async {
    final formattedDate = formatDate(date);
    final queryParams = <String, dynamic>{
      'city': city,
      'country': country,
      if (state != null) 'state': state,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
      'adjustment': adjustment,
    };

    final response = await _getWithFallback(
      '/timingsByCity/$formattedDate',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<AlAdhanTimingsData>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AlAdhanTimingsData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /nextPrayer/{date}
  /// Returns next prayer time for a date by lat & long.
  Future<AlAdhanApiResponse<AlAdhanNextPrayerData>> getNextPrayer({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? method,
    int? school,
  }) async {
    final formattedDate = formatDate(date);
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/nextPrayer/$formattedDate',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<AlAdhanNextPrayerData>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AlAdhanNextPrayerData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /nextPrayerByAddress/{date}
  /// Returns next prayer time for an address on a specific date.
  Future<AlAdhanApiResponse<AlAdhanNextPrayerData>> getNextPrayerByAddress({
    required DateTime date,
    required String address,
    int? method,
    int? school,
  }) async {
    final formattedDate = formatDate(date);
    final queryParams = <String, dynamic>{
      'address': address,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/nextPrayerByAddress/$formattedDate',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<AlAdhanNextPrayerData>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AlAdhanNextPrayerData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /calendar/{year}/{month}
  /// Returns monthly prayer times calendar for a Gregorian year & month by lat & long.
  Future<AlAdhanApiResponse<List<AlAdhanTimingsData>>> getCalendar({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    int? method,
    int? school,
  }) async {
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/calendar/$year/$month',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<List<AlAdhanTimingsData>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => AlAdhanTimingsData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// GET /calendarByCity/{year}/{month}
  /// Returns monthly prayer times calendar for a city and country.
  Future<AlAdhanApiResponse<List<AlAdhanTimingsData>>> getCalendarByCity({
    required int year,
    required int month,
    required String city,
    required String country,
    String? state,
    int? method,
    int? school,
  }) async {
    final queryParams = <String, dynamic>{
      'city': city,
      'country': country,
      if (state != null) 'state': state,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/calendarByCity/$year/$month',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<List<AlAdhanTimingsData>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => AlAdhanTimingsData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// GET /calendarByAddress/{year}/{month}
  /// Returns monthly prayer times calendar for an address.
  Future<AlAdhanApiResponse<List<AlAdhanTimingsData>>> getCalendarByAddress({
    required int year,
    required int month,
    required String address,
    int? method,
    int? school,
  }) async {
    final queryParams = <String, dynamic>{
      'address': address,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/calendarByAddress/$year/$month',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<List<AlAdhanTimingsData>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => AlAdhanTimingsData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// GET /calendar/from/{start}/to/{end}
  /// Returns prayer times between two dates (formatted DD-MM-YYYY).
  Future<AlAdhanApiResponse<List<AlAdhanTimingsData>>> getCalendarDateRange({
    required DateTime start,
    required DateTime end,
    required double latitude,
    required double longitude,
    int? method,
    int? school,
  }) async {
    final startStr = formatDate(start);
    final endStr = formatDate(end);
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/calendar/from/$startStr/to/$endStr',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<List<AlAdhanTimingsData>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => AlAdhanTimingsData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// GET /hijriCalendar/{year}/{month}
  /// Returns prayer times calendar for a Hijri year & month.
  Future<AlAdhanApiResponse<List<AlAdhanTimingsData>>> getHijriCalendar({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    int? method,
    int? school,
  }) async {
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/hijriCalendar/$year/$month',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<List<AlAdhanTimingsData>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => AlAdhanTimingsData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// GET /hijriCalendarByCity/{year}/{month}
  /// Returns prayer times calendar for a Hijri year & month for a city.
  Future<AlAdhanApiResponse<List<AlAdhanTimingsData>>> getHijriCalendarByCity({
    required int year,
    required int month,
    required String city,
    required String country,
    String? state,
    int? method,
    int? school,
  }) async {
    final queryParams = <String, dynamic>{
      'city': city,
      'country': country,
      if (state != null) 'state': state,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/hijriCalendarByCity/$year/$month',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<List<AlAdhanTimingsData>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => AlAdhanTimingsData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// GET /hijriCalendarByAddress/{year}/{month}
  /// Returns prayer times calendar for a Hijri year & month for an address.
  Future<AlAdhanApiResponse<List<AlAdhanTimingsData>>>
  getHijriCalendarByAddress({
    required int year,
    required int month,
    required String address,
    int? method,
    int? school,
  }) async {
    final queryParams = <String, dynamic>{
      'address': address,
      if (method != null) 'method': method,
      if (school != null) 'school': school,
    };

    final response = await _getWithFallback(
      '/hijriCalendarByAddress/$year/$month',
      queryParameters: queryParams,
    );
    return AlAdhanApiResponse<List<AlAdhanTimingsData>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => AlAdhanTimingsData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// GET /qibla/{latitude}/{longitude}
  /// Returns Qibla direction (degrees from North) for given latitude and longitude.
  Future<double?> getQiblaDirection(double latitude, double longitude) async {
    try {
      final response = await _getWithFallback('/qibla/$latitude/$longitude');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data != null && data['direction'] != null) {
          return (data['direction'] as num).toDouble();
        }
      }
    } catch (_) {}
    return null;
  }
}
