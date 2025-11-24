import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../models/watch_point_model.dart';
import '../services/local_storage_service.dart';

class WatchPointProvider extends ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();

  List<WatchPointModel> _watchPoints = [];
  bool _isLoading = false;
  String? _error;

  // Search results
  List<Location> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  // Getters
  List<WatchPointModel> get watchPoints => _watchPoints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Location> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  // Daftar kota yang didukung BMKG untuk mapping
  static const Map<String, Map<String, double>> _supportedCities = {
    'Jakarta': {'lat': -6.2088, 'lon': 106.8456},
    'Bandung': {'lat': -6.9175, 'lon': 107.6191},
    'Surabaya': {'lat': -7.2575, 'lon': 112.7521},
    'Medan': {'lat': 3.5952, 'lon': 98.6722},
    'Semarang': {'lat': -6.9666, 'lon': 110.4196},
    'Makassar': {'lat': -5.1477, 'lon': 119.4327},
    'Palembang': {'lat': -2.9761, 'lon': 104.7754},
    'Tangerang': {'lat': -6.1783, 'lon': 106.6319},
    'Depok': {'lat': -6.4025, 'lon': 106.7942},
    'Bekasi': {'lat': -6.2349, 'lon': 106.9896},
    'Yogyakarta': {'lat': -7.7956, 'lon': 110.3695},
    'Denpasar': {'lat': -8.6705, 'lon': 115.2126},
    'Malang': {'lat': -7.9666, 'lon': 112.6326},
    'Bogor': {'lat': -6.5971, 'lon': 106.8060},
    'Batam': {'lat': 1.0456, 'lon': 104.0305},
  };

  WatchPointProvider() {
    loadWatchPoints();
  }

  // Load all watch points from storage
  void loadWatchPoints() {
    _watchPoints = _storageService.getAllWatchPoints();
    notifyListeners();
  }

  // CREATE - Add new watch point
  Future<bool> addWatchPoint({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final nearestCity = _findNearestCity(latitude, longitude);

      final watchPoint = WatchPointModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
        nearestCity: nearestCity,
        createdAt: DateTime.now(),
      );

      await _storageService.addWatchPoint(watchPoint);
      loadWatchPoints();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal menambahkan titik pantau: $e';
      notifyListeners();
      return false;
    }
  }

  // READ - Get watch point by ID
  WatchPointModel? getWatchPointById(String id) {
    return _storageService.getWatchPoint(id);
  }

  // UPDATE - Update existing watch point
  Future<bool> updateWatchPoint({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existingWatchPoint = _storageService.getWatchPoint(id);
      if (existingWatchPoint == null) {
        _error = 'Titik pantau tidak ditemukan';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final nearestCity = _findNearestCity(latitude, longitude);

      final updatedWatchPoint = existingWatchPoint.copyWith(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
        nearestCity: nearestCity,
        updatedAt: DateTime.now(),
      );

      await _storageService.updateWatchPoint(updatedWatchPoint);
      loadWatchPoints();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal mengupdate titik pantau: $e';
      notifyListeners();
      return false;
    }
  }

  // DELETE - Remove watch point
  Future<bool> deleteWatchPoint(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _storageService.deleteWatchPoint(id);
      loadWatchPoints();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal menghapus titik pantau: $e';
      notifyListeners();
      return false;
    }
  }

  // Search address using geocoding
  Future<void> searchAddress(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }

    try {
      _isSearching = true;
      _searchError = null;
      notifyListeners();

      // Tambahkan "Indonesia" ke query untuk hasil yang lebih relevan
      final searchQuery = query.contains('Indonesia') ? query : '$query, Indonesia';

      _searchResults = await locationFromAddress(searchQuery);

      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      _searchResults = [];
      _searchError = 'Alamat tidak ditemukan. Coba kata kunci lain.';
      notifyListeners();
    }
  }

  // Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  // Find nearest supported city for weather data
  String _findNearestCity(double lat, double lon) {
    String nearestCity = 'Jakarta';
    double minDistance = double.infinity;

    _supportedCities.forEach((city, coords) {
      final distance = _calculateDistance(
        lat,
        lon,
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

  // Haversine formula for distance calculation
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;
}
