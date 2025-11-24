import 'package:hive_flutter/hive_flutter.dart';
import '../models/weather_model.dart';
import '../models/earthquake_model.dart';
import '../models/weather_warning_model.dart';
import '../models/watch_point_model.dart';

class LocalStorageService {
  // Box names
  static const String weatherBox = 'weather_box';
  static const String earthquakeBox = 'earthquake_box';
  static const String warningBox = 'warning_box';
  static const String favoritesBox = 'favorites_box';
  static const String watchPointBox = 'watch_point_box';

  // Helper method to safely get box (opens if not already open)
  Future<Box<T>> _getBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  // Sync version - returns null if box is not open
  Box<T>? _getBoxSync<T>(String boxName) {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return null;
  }

  // ============ Weather Operations ============

  /// Save weather data
  Future<void> saveWeather(String key, WeatherModel weather) async {
    final box = await _getBox<WeatherModel>(weatherBox);
    await box.put(key, weather);
  }

  /// Get weather data
  WeatherModel? getWeather(String key) {
    final box = _getBoxSync<WeatherModel>(weatherBox);
    return box?.get(key);
  }

  /// Get all weather data
  List<WeatherModel> getAllWeather() {
    final box = _getBoxSync<WeatherModel>(weatherBox);
    return box?.values.toList() ?? [];
  }

  /// Delete weather data
  Future<void> deleteWeather(String key) async {
    final box = await _getBox<WeatherModel>(weatherBox);
    await box.delete(key);
  }

  /// Clear all weather data
  Future<void> clearWeather() async {
    final box = await _getBox<WeatherModel>(weatherBox);
    await box.clear();
  }

  // ============ Earthquake Operations ============

  /// Save earthquake
  Future<void> saveEarthquake(EarthquakeModel earthquake) async {
    final box = await _getBox<EarthquakeModel>(earthquakeBox);
    final key = '${earthquake.date}_${earthquake.time}';
    await box.put(key, earthquake);
  }

  /// Save multiple earthquakes
  Future<void> saveEarthquakes(List<EarthquakeModel> earthquakes) async {
    final box = await _getBox<EarthquakeModel>(earthquakeBox);
    final Map<String, EarthquakeModel> dataMap = {};

    for (var eq in earthquakes) {
      final key = '${eq.date}_${eq.time}';
      dataMap[key] = eq;
    }

    await box.putAll(dataMap);
  }

  /// Get all earthquakes
  List<EarthquakeModel> getAllEarthquakes() {
    final box = _getBoxSync<EarthquakeModel>(earthquakeBox);
    return box?.values.toList() ?? [];
  }

  /// Get earthquakes sorted by date
  List<EarthquakeModel> getEarthquakesSorted() {
    final earthquakes = getAllEarthquakes();
    earthquakes.sort((a, b) {
      if (a.datetime == null || b.datetime == null) return 0;
      return b.datetime!.compareTo(a.datetime!);
    });
    return earthquakes;
  }

  /// Delete earthquake
  Future<void> deleteEarthquake(String key) async {
    final box = await _getBox<EarthquakeModel>(earthquakeBox);
    await box.delete(key);
  }

  /// Clear all earthquakes
  Future<void> clearEarthquakes() async {
    final box = await _getBox<EarthquakeModel>(earthquakeBox);
    await box.clear();
  }

  // ============ Warning Operations ============

  /// Save warning
  Future<void> saveWarning(WeatherWarningModel warning) async {
    final box = await _getBox<WeatherWarningModel>(warningBox);
    await box.put(warning.id, warning);
  }

  /// Save multiple warnings
  Future<void> saveWarnings(List<WeatherWarningModel> warnings) async {
    final box = await _getBox<WeatherWarningModel>(warningBox);
    final Map<String, WeatherWarningModel> dataMap = {};

    for (var warning in warnings) {
      if (warning.id != null) {
        dataMap[warning.id!] = warning;
      }
    }

    await box.putAll(dataMap);
  }

  /// Get all warnings
  List<WeatherWarningModel> getAllWarnings() {
    final box = _getBoxSync<WeatherWarningModel>(warningBox);
    return box?.values.toList() ?? [];
  }

  /// Get active warnings only
  List<WeatherWarningModel> getActiveWarnings() {
    final warnings = getAllWarnings();
    return warnings.where((w) => w.isActive).toList();
  }

  /// Delete warning
  Future<void> deleteWarning(String id) async {
    final box = await _getBox<WeatherWarningModel>(warningBox);
    await box.delete(id);
  }

  /// Clear all warnings
  Future<void> clearWarnings() async {
    final box = await _getBox<WeatherWarningModel>(warningBox);
    await box.clear();
  }

  // ============ Favorites Operations ============

  /// Add favorite location
  Future<void> addFavorite(String location) async {
    final box = await _getBox<String>(favoritesBox);
    if (!box.values.contains(location)) {
      await box.add(location);
    }
  }

  /// Remove favorite location
  Future<void> removeFavorite(String location) async {
    final box = await _getBox<String>(favoritesBox);
    final key = box.keys.firstWhere(
      (k) => box.get(k) == location,
      orElse: () => null,
    );
    if (key != null) {
      await box.delete(key);
    }
  }

  /// Get all favorites
  List<String> getFavorites() {
    final box = _getBoxSync<String>(favoritesBox);
    return box?.values.toList() ?? [];
  }

  /// Check if location is favorite
  bool isFavorite(String location) {
    final box = _getBoxSync<String>(favoritesBox);
    return box?.values.contains(location) ?? false;
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    final box = await _getBox<String>(favoritesBox);
    await box.clear();
  }

  // ============ Watch Point Operations ============

  /// Create - Add new watch point
  Future<void> addWatchPoint(WatchPointModel watchPoint) async {
    final box = await _getBox<WatchPointModel>(watchPointBox);
    await box.put(watchPoint.id, watchPoint);
  }

  /// Read - Get all watch points
  List<WatchPointModel> getAllWatchPoints() {
    final box = _getBoxSync<WatchPointModel>(watchPointBox);
    return box?.values.toList() ?? [];
  }

  /// Read - Get watch point by ID
  WatchPointModel? getWatchPoint(String id) {
    final box = _getBoxSync<WatchPointModel>(watchPointBox);
    return box?.get(id);
  }

  /// Update - Update existing watch point
  Future<void> updateWatchPoint(WatchPointModel watchPoint) async {
    final box = await _getBox<WatchPointModel>(watchPointBox);
    await box.put(watchPoint.id, watchPoint);
  }

  /// Delete - Remove watch point by ID
  Future<void> deleteWatchPoint(String id) async {
    final box = await _getBox<WatchPointModel>(watchPointBox);
    await box.delete(id);
  }

  /// Clear all watch points
  Future<void> clearWatchPoints() async {
    final box = await _getBox<WatchPointModel>(watchPointBox);
    await box.clear();
  }

  // ============ Utility Operations ============

  /// Clear all data
  Future<void> clearAll() async {
    await clearWeather();
    await clearEarthquakes();
    await clearWarnings();
    await clearFavorites();
  }

  /// Get total data count
  Map<String, int> getDataCount() {
    final weatherLen = _getBoxSync<WeatherModel>(weatherBox)?.length ?? 0;
    final earthquakeLen = _getBoxSync<EarthquakeModel>(earthquakeBox)?.length ?? 0;
    final warningLen = _getBoxSync<WeatherWarningModel>(warningBox)?.length ?? 0;
    final favoritesLen = _getBoxSync<String>(favoritesBox)?.length ?? 0;

    return {
      'weather': weatherLen,
      'earthquake': earthquakeLen,
      'warning': warningLen,
      'favorites': favoritesLen,
    };
  }

  /// Close all boxes
  static Future<void> close() async {
    await Hive.close();
  }
}
