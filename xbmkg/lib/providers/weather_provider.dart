import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../services/bmkg_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/preferences_service.dart';
import '../services/location_service.dart';

class WeatherProvider extends ChangeNotifier {
  final BmkgApiService _apiService = BmkgApiService();
  final LocalStorageService _storageService = LocalStorageService();

  WeatherModel? _currentWeather;
  bool _isLoading = false;
  String? _error;
  String _selectedLocation = 'Yogyakarta';

  double? _userLatitude;
  double? _userLongitude;

  // GETTERS
  WeatherModel? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedLocation => _selectedLocation;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;

  // ---------------------------------------------------------
  // INIT PROVIDER
  // ---------------------------------------------------------
  WeatherProvider() {
    _init();
  }

  Future<void> _init() async {
    await _detectLocation();
    await loadWeather();
  }

  // ---------------------------------------------------------
  // 📍 DETECT GPS LOCATION
  // ---------------------------------------------------------
  Future<void> _detectLocation() async {
    try {
      final useGPS = PreferencesService.getUseGPS();

      // Jika GPS dimatikan user → lokasi default
      if (!useGPS) {
        _selectedLocation = PreferencesService.getDefaultLocation();
        debugPrint("ℹ️ GPS OFF → lokasi default: $_selectedLocation");
        return;
      }

      // Ambil posisi GPS
      final position = await LocationService.getCurrentPosition();

      if (position == null) {
        debugPrint("❌ Gagal ambil GPS → pakai default");
        _selectedLocation = PreferencesService.getDefaultLocation();
        return;
      }

      _userLatitude = position.latitude;
      _userLongitude = position.longitude;

      debugPrint("📍 GPS: $_userLatitude, $_userLongitude");

      // Cari kota terdekat
      final nearestCity = LocationService.getNearestCity(
        position.latitude,
        position.longitude,
      );

      debugPrint("📌 Kota terdeteksi: $nearestCity");

      _selectedLocation = nearestCity;
      await PreferencesService.setDefaultLocation(nearestCity);

    } catch (e) {
      debugPrint("⚠️ ERROR detect location → $e");
      _selectedLocation = PreferencesService.getDefaultLocation();
    }
  }

  // ---------------------------------------------------------
  // 🌤 LOAD WEATHER
  // ---------------------------------------------------------
  Future<void> loadWeather({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gunakan cache jika masih valid
      if (!forceRefresh && !PreferencesService.isDataStale()) {
        final cached = _storageService.getWeather(_selectedLocation);
        if (cached != null) {
          _currentWeather = cached;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Ambil data BMKG API
      final weather =
          await _apiService.getWeatherForecast(_selectedLocation);

      if (weather != null) {
        _currentWeather = weather;

        await _storageService.saveWeather(_selectedLocation, weather);
        await PreferencesService.setLastUpdate(DateTime.now());
      } else {
        _error = "Failed to load weather data";
      }
    } catch (e) {
      _error = "Error loading weather: $e";

      final cached = _storageService.getWeather(_selectedLocation);
      if (cached != null) {
        _currentWeather = cached;
        _error = "Using cached data due to error.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // 🔄 REFRESH LOCATION + WEATHER
  // (ini yang membuat refresh kembali ke lokasi GPS)
  // ---------------------------------------------------------
 Future<void> refreshWithLocation() async {
  bool granted = await LocationService.isLocationPermissionGranted();
  if (!granted) {
    granted = await LocationService.requestLocationPermission();
    if (!granted) {
      // Jika tetap ditolak → jangan paksa, pakai default
      _selectedLocation = PreferencesService.getDefaultLocation();
      await loadWeather(forceRefresh: true);
      return;
    }
  }

  await _detectLocation();
  await loadWeather(forceRefresh: true);
}


  // ---------------------------------------------------------
  // 📍 CHANGE LOCATION MANUAL
  // ---------------------------------------------------------
  Future<void> changeLocation(String location) async {
    _selectedLocation = location;

    await PreferencesService.setDefaultLocation(location);
    await loadWeather(forceRefresh: true);
  }

  Future<void> refresh() async {
    await loadWeather(forceRefresh: true);
  }

  // ---------------------------------------------------------
  // 🌡 UTIL
  // ---------------------------------------------------------
  double? getTemperature(double? celsius) {
    if (celsius == null) return null;

    return PreferencesService.getTemperatureUnit() == 'F'
        ? (celsius * 9 / 5) + 32
        : celsius;
  }

  String getTemperatureUnit() {
    return PreferencesService.getTemperatureUnit();
  }

  // ---------------------------------------------------------
  // 📊 TODAY FORECAST
  // ---------------------------------------------------------
  List<WeatherData> getTodayForecast() {
    if (_currentWeather?.forecasts == null) return [];

    final now = DateTime.now();
    return _currentWeather!.forecasts!.where((f) {
      if (f.datetime == null) return false;
      return f.datetime!.year == now.year &&
          f.datetime!.month == now.month &&
          f.datetime!.day == now.day;
    }).toList();
  }

  // ---------------------------------------------------------
  // 📆 NEXT 7 DAYS
  // ---------------------------------------------------------
  List<WeatherData> getWeeklyForecast() {
    if (_currentWeather?.forecasts == null) return [];

    final Map<String, WeatherData> dailyMap = {};

    for (var f in _currentWeather!.forecasts!) {
      if (f.datetime == null) continue;

      final key =
          '${f.datetime!.year}-${f.datetime!.month}-${f.datetime!.day}';

      // Ambil jam 12 siang untuk representasi hari
      if (!dailyMap.containsKey(key) || f.datetime!.hour == 12) {
        dailyMap[key] = f;
      }
    }

    final sorted = dailyMap.keys.toList()
      ..sort();

    return sorted.take(7).map((key) => dailyMap[key]!).toList();
  }

  // ---------------------------------------------------------
  // 🌤 CURRENT
  // ---------------------------------------------------------
  double? getCurrentTemperature() {
    final today = getTodayForecast();
    return today.isNotEmpty
        ? getTemperature(today.first.temperature)
        : null;
  }

  String? getCurrentWeatherCondition() {
    final today = getTodayForecast();
    return today.isNotEmpty ? today.first.weather : null;
  }

  // ---------------------------------------------------------
  // ❌ CLEAR CACHE
  // ---------------------------------------------------------
  Future<void> clearCache() async {
    await _storageService.clearWeather();
    _currentWeather = null;
    notifyListeners();
  }
}
