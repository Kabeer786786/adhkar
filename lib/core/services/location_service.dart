import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;
  final String fullAddress;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    this.state = '',
    required this.country,
    this.fullAddress = '',
  });

  @override
  String toString() => '$city, $country';
}

typedef UserLocationData = LocationData;

Future<List<geo.Placemark>> _fetchPlacemarks(double lat, double lng) async {
  try {
    return await geo.placemarkFromCoordinates(lat, lng);
  } catch (e) {
    return [];
  }
}

Future<List<geo.Location>> _fetchLocations(String address) async {
  try {
    return await geo.locationFromAddress(address);
  } catch (e) {
    return [];
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const double makkahLat = 21.4225;
  static const double makkahLng = 39.8262;

  static const LocationData defaultLocation = LocationData(
    latitude: 21.4225,
    longitude: 39.8262,
    city: 'Makkah',
    country: 'Saudi Arabia',
    fullAddress: 'Makkah, Saudi Arabia',
  );

  /// Check and request location permission
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user position and reverse geocode location details
  Future<LocationData> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return defaultLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String city = 'Unknown City';
      String state = '';
      String country = '';
      String fullAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';

      try {
        List<geo.Placemark> placemarks = await _fetchPlacemarks(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown City';
          state = place.administrativeArea ?? '';
          country = place.country ?? '';
          fullAddress = [
            place.street,
            place.subLocality,
            city,
            state,
            country
          ].where((element) => element != null && element.isNotEmpty).join(', ');
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        state: state,
        country: country,
        fullAddress: fullAddress.isNotEmpty ? fullAddress : '$city, $country',
      );
    } catch (e) {
      debugPrint('Error fetching location: $e');
      return defaultLocation;
    }
  }

  /// Calculate Qibla direction from latitude and longitude
  static double calculateQiblaDirection(double latitude, double longitude) {
    final double userLatRad = latitude * (math.pi / 180.0);
    final double userLngRad = longitude * (math.pi / 180.0);
    final double makkahLatRad = makkahLat * (math.pi / 180.0);
    final double makkahLngRad = makkahLng * (math.pi / 180.0);

    final double deltaLng = makkahLngRad - userLngRad;

    final double y = math.sin(deltaLng);
    final double x = math.cos(userLatRad) * math.tan(makkahLatRad) -
        math.sin(userLatRad) * math.cos(deltaLng);

    double qiblaAngle = math.atan2(y, x) * (180.0 / math.pi);
    return (qiblaAngle + 360.0) % 360.0;
  }

  /// Calculate distance in km to Makkah
  static double calculateDistanceToMakkah(double latitude, double longitude) {
    return Geolocator.distanceBetween(latitude, longitude, makkahLat, makkahLng) / 1000.0;
  }

  /// Geocode city/place name to coordinates
  Future<LocationData?> getCoordinatesFromPlace(String placeName) async {
    try {
      List<geo.Location> locations = await _fetchLocations(placeName);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        List<geo.Placemark> placemarks = await _fetchPlacemarks(loc.latitude, loc.longitude);
        String city = placeName;
        String country = '';
        if (placemarks.isNotEmpty) {
          city = placemarks.first.locality ?? placeName;
          country = placemarks.first.country ?? '';
        }
        return LocationData(
          latitude: loc.latitude,
          longitude: loc.longitude,
          city: city,
          country: country,
          fullAddress: placeName,
        );
      }
    } catch (e) {
      debugPrint('Error geocoding place $placeName: $e');
    }
    return null;
  }
}
