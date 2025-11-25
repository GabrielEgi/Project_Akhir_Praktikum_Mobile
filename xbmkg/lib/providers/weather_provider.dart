import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../models/open_meteo_model.dart';
import '../services/bmkg_api_service.dart';
import '../services/open_meteo_service.dart';
import '../services/local_storage_service.dart';
import '../services/preferences_service.dart';
import '../services/location_service.dart';

class WeatherProvider extends ChangeNotifier {
  final BmkgApiService _apiService = BmkgApiService();
  final OpenMeteoService _openMeteoService = OpenMeteoService();
  final LocalStorageService _storageService = LocalStorageService();

  WeatherModel? _currentWeather;
  OpenMeteoWeather? _openMeteoWeather;
  bool _isLoading = false;
  String? _error;
  String _selectedLocation = 'Yogyakarta';

  double? _userLatitude;
  double? _userLongitude;

  // City coordinates for major Indonesian cities
  static const Map<String, Map<String, double>> cityCoordinates = {
    'Jakarta': {'lat': -6.2088, 'lon': 106.8456},
    'Yogyakarta': {'lat': -7.7956, 'lon': 110.3695},
    'Bandung': {'lat': -6.9175, 'lon': 107.6191},
    'Surabaya': {'lat': -7.2575, 'lon': 112.7521},
    'Semarang': {'lat': -6.9667, 'lon': 110.4167},
    'Medan': {'lat': 3.5952, 'lon': 98.6722},
    'Palembang': {'lat': -2.9761, 'lon': 104.7754},
    'Makassar': {'lat': -5.1477, 'lon': 119.4327},
    'Denpasar': {'lat': -8.6705, 'lon': 115.2126},
    'Malang': {'lat': -7.9666, 'lon': 112.6326},
  };

  // GETTERS
  WeatherModel? get currentWeather => _currentWeather;
  OpenMeteoWeather? get openMeteoWeather => _openMeteoWeather;
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

      // Get coordinates for selected city
      final coords = cityCoordinates[_selectedLocation] ?? cityCoordinates['Yogyakarta']!;
      final lat = coords['lat']!;
      final lon = coords['lon']!;

      // Ambil data dari Open-Meteo API (prioritas)
      _openMeteoWeather = await _openMeteoService.getWeather(
        latitude: lat,
        longitude: lon,
      );

      // Fallback ke BMKG jika Open-Meteo gagal
      if (_openMeteoWeather == null) {
        debugPrint("⚠️ Open-Meteo gagal, fallback ke BMKG API");
        final weather = await _apiService.getWeatherForecast(_selectedLocation);
        if (weather != null) {
          _currentWeather = weather;
          await _storageService.saveWeather(_selectedLocation, weather);
          await PreferencesService.setLastUpdate(DateTime.now());
        } else {
          _error = "Failed to load weather data from both sources";
        }
      } else {
        await PreferencesService.setLastUpdate(DateTime.now());
      }
    } catch (e) {
      _error = "Error loading weather: $e";
      debugPrint("⚠️ Error loading weather: $e");

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
  // 📊 TODAY FORECAST (using OpenMeteo data if available)
  // ---------------------------------------------------------
  List<WeatherData> getTodayForecast() {
    // Try OpenMeteo first
    if (_openMeteoWeather != null) {
      return [];
    }

    // Fallback to old BMKG data
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
  // 📆 NEXT 7 DAYS (using OpenMeteo data if available)
  // ---------------------------------------------------------
  List<WeatherData> getWeeklyForecast() {
    // Try OpenMeteo first
    if (_openMeteoWeather != null) {
      return [];
    }

    // Fallback to old BMKG data
    if (_currentWeather?.forecasts == null) return [];

    final Map<String, WeatherData> dailyMap = {};

    for (var f in _currentWeather!.forecasts!) {
      if (f.datetime == null) continue;

      final key =
          '${f.datetime!.year}-${f.datetime!.month.toString().padLeft(2, '0')}-${f.datetime!.day.toString().padLeft(2, '0')}';

      // Prioritas: ambil data jam 12 siang, kalau tidak ada ambil data terdekat
      if (!dailyMap.containsKey(key)) {
        dailyMap[key] = f;
      } else if (f.datetime!.hour == 12) {
        // Ganti dengan data jam 12 jika ada
        dailyMap[key] = f;
      } else if (dailyMap[key]!.datetime!.hour != 12 &&
                 (f.datetime!.hour - 12).abs() < (dailyMap[key]!.datetime!.hour - 12).abs()) {
        // Ambil data yang lebih dekat ke jam 12
        dailyMap[key] = f;
      }
    }

    // Sort by date
    final sorted = dailyMap.keys.toList()..sort();

    // Take 7 days
    return sorted.take(7).map((key) => dailyMap[key]!).toList();
  }

  // ---------------------------------------------------------
  // 🌤 CURRENT
  // ---------------------------------------------------------
  double? getCurrentTemperature() {
    if (_openMeteoWeather != null) {
      return getTemperature(_openMeteoWeather!.current.temperature);
    }

    final today = getTodayForecast();
    return today.isNotEmpty
        ? getTemperature(today.first.temperature)
        : null;
  }

  String? getCurrentWeatherCondition() {
    if (_openMeteoWeather != null) {
      return _openMeteoWeather!.current.weatherDescription;
    }

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
