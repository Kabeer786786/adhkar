import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final bool isDefault;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.isDefault = false,
  });
}

class LocationService {
  // Kaaba location coordinates in Makkah
  static const double makkahLat = 21.422487;
  static const double makkahLng = 39.826206;

  // Default location (Mecca)
  static const LocationData defaultLocation = LocationData(
    latitude: makkahLat,
    longitude: makkahLng,
    city: 'Makkah',
    country: 'Saudi Arabia',
    isDefault: true,
  );

  Future<LocationData> getCurrentLocation() async {
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
      }
      if (!status.isGranted && !status.isLimited) {
        return defaultLocation;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return defaultLocation;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return defaultLocation;
      }

      final geo = await reverseGeocode(position.latitude, position.longitude);

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        city: geo['city']!.isNotEmpty ? geo['city']! : 'Current Location',
        country: geo['country'] ?? '',
        isDefault: false,
      );
    } catch (_) {
      return defaultLocation;
    }
  }

  /// Reverse geocodes latitude and longitude to get city/region and country names
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    // Primary: Native package:geocoding (placemarkFromCoordinates)
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final city = (place.locality != null && place.locality!.isNotEmpty)
            ? place.locality!
            : (place.subAdministrativeArea != null &&
                  place.subAdministrativeArea!.isNotEmpty)
            ? place.subAdministrativeArea!
            : (place.administrativeArea != null &&
                  place.administrativeArea!.isNotEmpty)
            ? place.administrativeArea!
            : '';
        final country = place.country ?? '';

        if (city.isNotEmpty) {
          return {'city': city, 'country': country};
        }
      }
    } catch (_) {}

    // Fallback 1: BigDataCloud HTTP Reverse Geocoding
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      final response = await dio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'localityLanguage': 'en',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final city =
            (data['city'] as String?)?.trim() ??
            (data['locality'] as String?)?.trim() ??
            (data['principalSubdivision'] as String?)?.trim() ??
            '';
        final country =
            (data['countryName'] as String?)?.trim() ??
            (data['principalSubdivision'] as String?)?.trim() ??
            '';

        if (city.isNotEmpty) {
          return {'city': city, 'country': country};
        }
      }
    } catch (_) {}

    // Fallback 2: OpenStreetMap Nominatim
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          headers: {'User-Agent': 'AdhkarApp/1.0'},
        ),
      );

      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'en',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final address = response.data['address'] as Map?;
        if (address != null) {
          final city =
              (address['city'] as String?) ??
              (address['town'] as String?) ??
              (address['village'] as String?) ??
              (address['suburb'] as String?) ??
              (address['county'] as String?) ??
              (address['state'] as String?) ??
              '';
          final country = (address['country'] as String?) ?? '';
          if (city.isNotEmpty) {
            return {'city': city, 'country': country};
          }
        }
      }
    } catch (_) {}

    return {'city': 'Current Location', 'country': ''};
  }

  /// Geocodes a place name string (e.g. "Mysore, India") using [locationFromAddress]
  /// to fetch latitude and longitude coordinates.
  Future<LocationData?> getCoordinatesFromPlace(String placeName) async {
    try {
      final locations = await Geocoding().locationFromAddress(placeName);
      if (locations.isNotEmpty) {
        final place = locations.first;
        final parts = placeName.split(',');
        final city = parts[0].trim();
        final country = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

        return LocationData(
          latitude: place.latitude,
          longitude: place.longitude,
          city: city,
          country: country,
        );
      }
    } catch (e) {
      // Fall through to fallback
    }

    final parts = placeName.split(',');
    final city = parts[0].trim();
    final country = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
    return geocodeCityCountry(city, country);
  }

  /// Forward geocodes a city and country string to exact latitude and longitude coordinates.
  /// Falls back to country mean coordinates if city is not found.
  Future<LocationData?> geocodeCityCountry(String city, String country) async {
    final query = city.isNotEmpty ? '$city, $country' : country;

    // Attempt 1: Native package:geocoding locationFromAddress
    try {
      final locations = await Geocoding().locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LocationData(
          latitude: loc.latitude,
          longitude: loc.longitude,
          city: city.isNotEmpty ? city : country,
          country: country,
        );
      }
    } catch (_) {}

    // Attempt 2: OpenStreetMap Nominatim forward search
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'User-Agent': 'AdhkarApp/1.0'},
        ),
      );

      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          if (city.isNotEmpty) 'city': city,
          if (country.isNotEmpty) 'country': country,
          'format': 'json',
          'limit': '1',
          'accept-language': 'en',
        },
      );

      if (response.statusCode == 200 &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        final item = response.data[0] as Map;
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          return LocationData(
            latitude: lat,
            longitude: lon,
            city: city.isNotEmpty ? city : country,
            country: country,
          );
        }
      }
    } catch (_) {}

    // Attempt 3: Fall back to country mean/capital coordinates search
    if (country.isNotEmpty) {
      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {'User-Agent': 'AdhkarApp/1.0'},
          ),
        );

        final response = await dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'country': country,
            'format': 'json',
            'limit': '1',
            'accept-language': 'en',
          },
        );

        if (response.statusCode == 200 &&
            response.data is List &&
            (response.data as List).isNotEmpty) {
          final item = response.data[0] as Map;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return LocationData(
              latitude: lat,
              longitude: lon,
              city: city.isNotEmpty ? city : country,
              country: country,
            );
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Calculates the Qibla direction (bearing angle in degrees relative to True North)
  /// for a given latitude and longitude.
  static double calculateQiblaDirection(double lat, double lng) {
    final phi1 = lat * (math.pi / 180.0);
    final phi2 = makkahLat * (math.pi / 180.0);
    final deltaLambda = (makkahLng - lng) * (math.pi / 180.0);

    final y = math.sin(deltaLambda);
    final x =
        math.cos(phi1) * math.tan(phi2) -
        math.sin(phi1) * math.cos(deltaLambda);

    double qibla = math.atan2(y, x) * (180.0 / math.pi);
    return (qibla + 360.0) % 360.0;
  }

  /// Calculates distance in kilometers from given position to Kaaba in Makkah
  static double calculateDistanceToMakkah(double lat, double lng) {
    return Geolocator.distanceBetween(lat, lng, makkahLat, makkahLng) / 1000.0;
  }
}
