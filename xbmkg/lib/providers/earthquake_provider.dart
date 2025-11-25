import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/earthquake_model.dart';
import '../services/local_storage_service.dart';
import '../services/location_service.dart';
import '../services/usgs_api_service.dart';

class EarthquakeProvider extends ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final UsgsApiService _usgsApiService = UsgsApiService();

  // State
  List<EarthquakeModel> _latestEarthquakes = [];
  List<EarthquakeModel> _recentEarthquakes = [];
  List<EarthquakeModel> _feltEarthquakes = [];
  List<EarthquakeModel> _usgsEarthquakes = [];
  bool _isLoading = false;
  String? _error;
  String _selectedTab = 'latest';
  bool _useUsgsData = false;

  double? _userLatitude;
  double? _userLongitude;

  // Getters
  List<EarthquakeModel> get latestEarthquakes => _latestEarthquakes;
  List<EarthquakeModel> get recentEarthquakes => _recentEarthquakes;
  List<EarthquakeModel> get feltEarthquakes => _feltEarthquakes;
  List<EarthquakeModel> get usgsEarthquakes => _usgsEarthquakes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTab => _selectedTab;
  bool get useUsgsData => _useUsgsData;

  List<EarthquakeModel> get currentList {
    switch (_selectedTab) {
      case 'recent':
        return _recentEarthquakes;
      case 'felt':
        return _feltEarthquakes;
      case 'usgs':
        return _usgsEarthquakes;
      default:
        return _latestEarthquakes;
    }
  }

  EarthquakeProvider() {
    _init();
  }

  // Init
  Future<void> _init() async {
    await _detectLocation();
    await loadEarthquakes();
  }

  /// Detect user location
  Future<void> _detectLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
      }
    } catch (_) {}
  }

  // Load
  Future<void> loadEarthquakes({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!forceRefresh) {
        final cached = _storageService.getEarthquakesSorted();
        if (cached.isNotEmpty) {
          _latestEarthquakes = cached;
          _isLoading = false;
          notifyListeners();
          _loadFromApi(); // background update
          return;
        }
      }

      await _loadFromApi();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// BMKG API (Versi Baru)
  Future<void> _loadFromApi() async {
    try {
      // MAIN API - BMKG
      final latestRes = await http.get(Uri.parse(
          "https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json"));
      final recentRes = await http.get(Uri.parse(
          "https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json"));
      final feltRes = await http.get(Uri.parse(
          "https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json"));

      if (latestRes.statusCode == 200) {
        final data = jsonDecode(latestRes.body);
        final g = data["Infogempa"]["gempa"];
        _latestEarthquakes = [EarthquakeModel.fromJson(g)];
        _storageService.saveEarthquakes(_latestEarthquakes);
      }

      if (recentRes.statusCode == 200) {
        final data = jsonDecode(recentRes.body);
        final list = data["Infogempa"]["gempa"] as List;
        _recentEarthquakes =
            list.map((e) => EarthquakeModel.fromJson(e)).toList();
      }

      if (feltRes.statusCode == 200) {
        final data = jsonDecode(feltRes.body);
        final list = data["Infogempa"]["gempa"] as List;
        _feltEarthquakes =
            list.map((e) => EarthquakeModel.fromJson(e)).toList();
      }

      // Load USGS data (Indonesia region, last 7 days)
      if (_useUsgsData) {
        await _loadUsgsData();
      }

      notifyListeners();
    } catch (e) {
      _error = "Gagal memuat data dari BMKG: $e";
    }
  }

  /// Load USGS API data
  Future<void> _loadUsgsData() async {
    try {
      _usgsEarthquakes = await _usgsApiService.getIndonesiaEarthquakes(
        days: 7,
        minMagnitude: 2.5,
      );
    } catch (e) {
      _error = "Gagal memuat data dari USGS: $e";
    }
  }

  /// Toggle USGS data source
  Future<void> toggleUsgsData(bool value) async {
    _useUsgsData = value;
    notifyListeners();

    if (value && _usgsEarthquakes.isEmpty) {
      await _loadUsgsData();
      notifyListeners();
    }
  }

  /// Load USGS data by region
  Future<void> loadUsgsDataByRegion({
    int days = 7,
    double minMagnitude = 2.5,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _usgsEarthquakes = await _usgsApiService.getIndonesiaEarthquakes(
        days: days,
        minMagnitude: minMagnitude,
      );
    } catch (e) {
      _error = "Gagal memuat data dari USGS: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load USGS recent significant earthquakes
  Future<void> loadUsgsRecentSignificant() async {
    _isLoading = true;
    notifyListeners();

    try {
      _usgsEarthquakes = await _usgsApiService.getRecentSignificantEarthquakes();
    } catch (e) {
      _error = "Gagal memuat data dari USGS: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load USGS major earthquakes
  Future<void> loadUsgsMajorEarthquakes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _usgsEarthquakes = await _usgsApiService.getMajorEarthquakes();
    } catch (e) {
      _error = "Gagal memuat data dari USGS: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  // Change Tab
  void changeTab(String tab) {
    if (tab == _selectedTab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  // Refresh
  Future<void> refresh() async {
    await loadEarthquakes(forceRefresh: true);
  }

  // Distance
  double? getDistanceFromUser(EarthquakeModel eq) {
    if (_userLatitude == null ||
        _userLongitude == null ||
        eq.latitude == null ||
        eq.longitude == null) {
      return null;
    }

    return LocationService.calculateDistance(
      _userLatitude!,
      _userLongitude!,
      eq.latitude!,
      eq.longitude!,
    );
  }

  List<EarthquakeModel> getEarthquakesSortedByDistance() {
    final sorted = List<EarthquakeModel>.from(currentList);
    sorted.sort((a, b) {
      final da = getDistanceFromUser(a);
      final db = getDistanceFromUser(b);
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return sorted;
  }

  // Filters
  List<EarthquakeModel> filterByMagnitude(double minMag) {
    return currentList
        .where((e) => e.magnitude != null && e.magnitude! >= minMag)
        .toList();
  }

  List<EarthquakeModel> filterByRegion(String region) {
    return currentList
        .where((e) =>
            e.region != null &&
            e.region!.toLowerCase().contains(region.toLowerCase()))
        .toList();
  }

  // Cache clear
  Future<void> clearCache() async {
    await _storageService.clearEarthquakes();
    _latestEarthquakes.clear();
    _recentEarthquakes.clear();
    _feltEarthquakes.clear();
    notifyListeners();
  }
}
