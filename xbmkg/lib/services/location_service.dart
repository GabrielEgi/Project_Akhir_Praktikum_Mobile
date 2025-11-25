import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  /// Check if location service is enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services are disabled', name: 'LocationService');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log('Location permission denied', name: 'LocationService');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      developer.log('Error getting location: $e', name: 'LocationService');
      return null;
    }
  }

  /// Get last known position
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      developer.log('Error getting last known position: $e', name: 'LocationService');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Get nearest city name from coordinates
  static String getNearestCity(double latitude, double longitude) {
    final cities = {
      'Jakarta': {'lat': -6.2088, 'lon': 106.8456},
      'Surabaya': {'lat': -7.2575, 'lon': 112.7521},
      'Bandung': {'lat': -6.9175, 'lon': 107.6191},
      'Medan': {'lat': 3.5952, 'lon': 98.6722},
      'Semarang': {'lat': -6.9667, 'lon': 110.4167},
      'Makassar': {'lat': -5.1477, 'lon': 119.4327},
      'Palembang': {'lat': -2.9761, 'lon': 104.7754},
      'Yogyakarta': {'lat': -7.7956, 'lon': 110.3695},
      'Malang': {'lat': -7.9797, 'lon': 112.6304},
      'Denpasar': {'lat': -8.6705, 'lon': 115.2126},
      'Padang': {'lat': -0.9471, 'lon': 100.4172},
      'Banjarmasin': {'lat': -3.3194, 'lon': 114.5900},
      'Pekanbaru': {'lat': 0.5071, 'lon': 101.4478},
      'Manado': {'lat': 1.4748, 'lon': 124.8421},
      'Balikpapan': {'lat': -1.2379, 'lon': 116.8529},
    };

    String nearestCity = 'Yogyakarta';
    double minDistance = double.infinity;

    cities.forEach((city, coords) {
      final distance = calculateDistance(
        latitude,
        longitude,
        coords['lat']!,
        coords['lon']!,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = city;
      }
    });

    return nearestCity;
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
