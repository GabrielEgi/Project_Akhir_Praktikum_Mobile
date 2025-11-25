# 🌦️ XBMKG - WeatherNews Indonesia

![Flutter](https://img.shields.io/badge/Flutter-3.9.0-blue)
![Dart](https://img.shields.io/badge/Dart-3.9.0-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green)

**Aplikasi Cuaca dan Gempa Bumi Indonesia** - Aplikasi mobile yang menyediakan informasi cuaca real-time dan data gempa bumi untuk wilayah Indonesia.

---

## 📋 Daftar Isi

1. [Tentang Aplikasi](#-tentang-aplikasi)
2. [Fitur Utama](#-fitur-utama)
3. [Arsitektur & Teknologi](#-arsitektur--teknologi)
4. [Database yang Digunakan](#-database-yang-digunakan)
5. [Folder Services](#-folder-services)
6. [Folder Providers](#-folder-providers)
7. [Instalasi](#-instalasi)
8. [Struktur Project](#-struktur-project)
9. [Screenshots](#-screenshots)
10. [Dependencies](#-dependencies)

---

## 🎯 Tentang Aplikasi

**XBMKG** adalah aplikasi mobile berbasis Flutter yang menyediakan:
- ☀️ Informasi cuaca real-time untuk berbagai kota di Indonesia
- 🌍 Data gempa bumi terkini dari BMKG dan USGS
- 📍 Fitur Watch Points untuk monitoring lokasi tertentu
- 🔔 Notifikasi cuaca ekstrem dan gempa bumi
- 📊 Visualisasi data dengan charts dan grafik

### Sumber Data API:
1. **BMKG API** - Badan Meteorologi, Klimatologi, dan Geofisika (Official Indonesia)
2. **Open-Meteo API** - Weather forecast (Free, no API key)
3. **USGS API** - United States Geological Survey (Global earthquake data)

---

## ✨ Fitur Utama

### 1. 🌤️ Cuaca Real-Time
- Auto-detect lokasi GPS user
- Prakiraan cuaca current, hourly (48 jam), dan daily (7 hari)
- Data detail: suhu, kelembaban, kecepatan angin, UV index, curah hujan
- Support multi kota (15+ kota besar Indonesia)
- Konversi Celsius/Fahrenheit

### 2. 🌍 Gempa Bumi
- **3 Kategori BMKG:**
  - Gempa Terkini (Latest)
  - Gempa M≥5.0 (Recent)
  - Gempa Dirasakan (Felt)
- **Data USGS** untuk gempa global
- Filter berdasarkan magnitudo dan region
- Sorting berdasarkan jarak dari lokasi user
- Detail: magnitudo, kedalaman, koordinat, shakemap

### 3. 📍 Watch Points (Titik Pantau)
- **Full CRUD Operations:**
  - ✅ Create: Tambah lokasi pantau
  - ✅ Read: Lihat semua lokasi
  - ✅ Update: Edit data lokasi
  - ✅ Delete: Hapus lokasi
- Geocoding: Search alamat dan convert ke koordinat
- Reverse geocoding: Koordinat ke alamat
- Auto-detect kota terdekat untuk data cuaca
- Monitoring cuaca di multiple lokasi

### 4. 🔐 Autentikasi
- Register & Login dengan Hive database
- Session management dengan SharedPreferences
- Auto-login jika sudah login sebelumnya

### 5. 🔔 Notifikasi
- Local notifications untuk cuaca ekstrem
- Alert gempa bumi dengan magnitudo tertentu
- Customizable notification settings

### 6. ⚙️ Settings & Preferences
- Pilih bahasa (Indonesia/English)
- Unit suhu (Celsius/Fahrenheit)
- Auto-refresh interval
- Toggle GPS on/off
- Minimum magnitudo untuk notifikasi gempa

---

## 🏗️ Arsitektur & Teknologi

### Pattern & Architecture
```
Pattern: MVVM (Model-View-ViewModel)
State Management: Provider Pattern
Local Database: Hive (NoSQL)
Preferences: SharedPreferences
API Client: HTTP Package
```

### Layer Architecture

```
┌─────────────────────────────────────────┐
│           UI Layer (Screens)            │
│  - splash, onboarding, home, weather,   │
│  - earthquake, watch_point, profile     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│     ViewModel Layer (Providers)         │
│  - WeatherProvider                      │
│  - EarthquakeProvider                   │
│  - WatchPointProvider                   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│       Service Layer (Services)          │
│  - API Services (BMKG, OpenMeteo, USGS) │
│  - LocalStorageService (Hive)           │
│  - PreferencesService (SharedPrefs)     │
│  - LocationService, NotificationService │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Data Layer (Models)            │
│  - WeatherModel, EarthquakeModel,       │
│  - WatchPointModel, UserModel           │
└─────────────────────────────────────────┘
```

---

## 💾 DATABASE YANG DIGUNAKAN

### 🗄️ Hive - NoSQL Local Database

**Nama Database:** `Hive` (Embedded NoSQL database)

#### Mengapa Hive?
- ✅ **Lightweight:** Tidak butuh server, embedded database
- ✅ **Super Fast:** Performance sangat tinggi untuk read/write
- ✅ **Type-safe:** Dengan code generation menggunakan `build_runner`
- ✅ **Cross-platform:** Support Android, iOS, Web, Desktop
- ✅ **Offline-first:** Semua data tersimpan lokal
- ✅ **No SQL syntax:** Key-value pairs, mudah digunakan

#### 📦 Box yang Digunakan (6 Box):

| No | Box Name | Type | Kegunaan | File Model |
|----|----------|------|----------|------------|
| 1 | `users` | `UserModel` | Menyimpan data user (username, password, email, photo) | `user_model.dart` |
| 2 | `earthquake_box` | `EarthquakeModel` | Cache data gempa dari BMKG & USGS API | `earthquake_model.dart` |
| 3 | `weather_box` | `WeatherModel` | Cache data cuaca dari BMKG API | `weather_model.dart` |
| 4 | `warning_box` | `WeatherWarningModel` | Menyimpan peringatan cuaca ekstrem | `weather_warning_model.dart` |
| 5 | `favorites_box` | `String` | Daftar lokasi favorit user | - |
| 6 | `watch_point_box` | `WatchPointModel` | **Titik pantau yang dibuat user (CRUD)** | `watch_point_model.dart` |

#### Inisialisasi Hive:

Lokasi: `lib/main.dart:18-38`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register all Hive adapters (auto-generated)
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(EarthquakeModelAdapter());
  Hive.registerAdapter(WeatherWarningModelAdapter());
  Hive.registerAdapter(WeatherModelAdapter());
  Hive.registerAdapter(WeatherDataAdapter());
  Hive.registerAdapter(WatchPointModelAdapter());

  // Open all Hive boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<EarthquakeModel>(LocalStorageService.earthquakeBox);
  await Hive.openBox<WeatherModel>(LocalStorageService.weatherBox);
  await Hive.openBox<WeatherWarningModel>(LocalStorageService.warningBox);
  await Hive.openBox<String>(LocalStorageService.favoritesBox);
  await Hive.openBox<WatchPointModel>(LocalStorageService.watchPointBox);

  runApp(const WeatherNewsApp());
}
```

#### Code Generation untuk Hive:

```bash
# Generate adapters
flutter pub run build_runner build

# Watch mode (auto-generate)
flutter pub run build_runner watch
```

#### Contoh Model dengan Hive Annotation:

```dart
import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Generated file

@HiveType(typeId: 0) // Unique ID untuk tiap model
class UserModel {
  @HiveField(0) // Unique field ID
  String username;

  @HiveField(1)
  String password;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? photoUrl;

  UserModel({
    required this.username,
    required this.password,
    this.email,
    this.photoUrl,
  });
}
```

---

### 🔧 SharedPreferences - Key-Value Storage

**Kegunaan:** Menyimpan **settings & preferences** user

#### Data yang Disimpan (13 Keys):

| No | Key | Type | Default | Kegunaan |
|----|-----|------|---------|----------|
| 1 | `language` | String | 'id' | Bahasa aplikasi (id/en) |
| 2 | `notifications` | bool | true | Toggle notifikasi |
| 3 | `show_earthquake_notif` | bool | true | Notifikasi gempa |
| 4 | `auto_refresh` | bool | true | Auto refresh data |
| 5 | `refresh_interval` | int | 30 | Interval refresh (menit) |
| 6 | `temperature_unit` | String | 'C' | Unit suhu (C/F) |
| 7 | `default_location` | String | 'Yogyakarta' | Lokasi default |
| 8 | `last_update` | String | null | Timestamp update terakhir |
| 9 | `theme_mode` | String | 'system' | Mode tema (light/dark/system) |
| 10 | `min_magnitude` | double | 5.0 | Minimum magnitudo notifikasi |
| 11 | `use_gps` | bool | true | Gunakan GPS auto-detect |
| 12 | `isLoggedIn` | bool | false | Status login user |
| 13 | `username` | String | - | Username yang sedang login |

#### Lokasi File:
`lib/services/preferences_service.dart`

#### Contoh Penggunaan:

```dart
// Inisialisasi (dipanggil di main.dart)
await PreferencesService.init();

// Save preferences
await PreferencesService.setLanguage('id');
await PreferencesService.setTemperatureUnit('C');
await PreferencesService.setUseGPS(true);

// Read preferences
String lang = PreferencesService.getLanguage();
bool useGPS = PreferencesService.getUseGPS();
String location = PreferencesService.getDefaultLocation();

// Cache management
bool isStale = PreferencesService.isDataStale(); // Cek apakah cache sudah expired
```

---

## 📁 FOLDER SERVICES

**Lokasi:** `lib/services/`

Folder ini berisi **Service Layer** yang menangani:
- HTTP API calls
- Local database operations
- Location & GPS handling
- Notifications
- Preferences management

---

### 1️⃣ `bmkg_api_service.dart`

**Kegunaan:** HTTP Client untuk **BMKG API** (Badan Meteorologi Indonesia)

#### Endpoints:

| Endpoint | Method | Kegunaan |
|----------|--------|----------|
| `/publik/prakiraan-cuaca?adm4={code}` | GET | Prakiraan cuaca per kota |
| `/DataMKG/TEWS/autogempa.json` | GET | Gempa terkini (latest) |
| `/DataMKG/TEWS/gempaterkini.json` | GET | Gempa M≥5.0 (recent) |
| `/DataMKG/TEWS/gempadirasakan.json` | GET | Gempa yang dirasakan |

#### Code Penting:

```dart
// City to ADM4 code mapping (BMKG membutuhkan kode wilayah)
static const Map<String, String> cityToAdm4Code = {
  'Jakarta': '31.74.01.1001',      // Jakarta Pusat - Gambir
  'Yogyakarta': '34.71.01.1001',   // Yogyakarta - Tegalrejo
  'Bandung': '32.73.01.1001',      // Bandung - Sukasari
  // ... dll
};

// Fetch weather forecast
Future<WeatherModel?> getWeatherForecast(String cityName) async {
  final adm4Code = cityToAdm4Code[cityName] ?? cityToAdm4Code['Yogyakarta']!;
  const url = '$weatherApiUrl/prakiraan-cuaca';
  final uri = Uri.parse(url).replace(queryParameters: {'adm4': adm4Code});

  final response = await http.get(uri).timeout(timeoutDuration);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return WeatherModel.fromJson(data);
  }
  return null;
}

// Fetch latest earthquakes
Future<List<EarthquakeModel>> getLatestEarthquakes() async {
  const url = '$earthquakeUrl/autogempa.json';
  final response = await http.get(Uri.parse(url)).timeout(timeoutDuration);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final gempaData = data['Infogempa']['gempa'];
    // Parse & return
  }
}
```

#### Fitur:
- ✅ Timeout handling (30 detik)
- ✅ Error handling dengan fallback ke dummy data
- ✅ Parse JSON response ke Model
- ✅ Support multiple earthquake categories

---

### 2️⃣ `open_meteo_service.dart`

**Kegunaan:** HTTP Client untuk **Open-Meteo API** (Weather forecast alternatif)

#### Endpoint:

```
Base URL: https://api.open-meteo.com/v1/forecast
```

#### Parameters yang Digunakan:

| Parameter | Values | Kegunaan |
|-----------|--------|----------|
| `latitude` | double | Koordinat lintang |
| `longitude` | double | Koordinat bujur |
| `timezone` | Asia/Jakarta | Timezone Indonesia |
| `current` | temperature_2m, humidity, wind, etc | Data cuaca saat ini |
| `hourly` | temperature, precipitation, weather_code | Forecast per jam (48 jam) |
| `daily` | temp_max, temp_min, sunrise, sunset | Forecast harian (7 hari) |

#### Code Penting:

```dart
Future<OpenMeteoWeather?> getWeather({
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse(_baseUrl).replace(queryParameters: {
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
    'timezone': 'Asia/Jakarta',
    // Current weather
    'current': [
      'temperature_2m',
      'apparent_temperature',
      'relative_humidity_2m',
      'weather_code',
      'wind_speed_10m',
      'wind_direction_10m',
      'uv_index',
      'cloud_cover',
      'precipitation',
      'is_day',
    ].join(','),
    // Hourly forecast (48 jam)
    'hourly': [
      'temperature_2m',
      'weather_code',
      'precipitation_probability',
      // ...
    ].join(','),
    // Daily forecast (7 hari)
    'daily': [
      'weather_code',
      'temperature_2m_max',
      'temperature_2m_min',
      'sunrise',
      'sunset',
      // ...
    ].join(','),
  });

  final response = await http.get(uri).timeout(_timeout);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return OpenMeteoWeather.fromJson(data);
  }
}

// Helper: Wind direction to text
static String getWindDirectionText(int? degrees) {
  const directions = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
  final index = ((degrees + 22.5) / 45).floor() % 8;
  return directions[index];
}

// Helper: UV Index level
static String getUvIndexLevel(double? uvIndex) {
  if (uvIndex < 3) return 'Rendah';
  if (uvIndex < 6) return 'Sedang';
  if (uvIndex < 8) return 'Tinggi';
  if (uvIndex < 11) return 'Sangat Tinggi';
  return 'Ekstrem';
}
```

#### Keunggulan:
- ✅ **Free & no API key required**
- ✅ Data lebih detail (UV index, apparent temp, precipitation probability)
- ✅ Support GPS coordinates langsung
- ✅ Hourly forecast sampai 48 jam
- ✅ Daily forecast sampai 7 hari

---

### 3️⃣ `usgs_api_service.dart`

**Kegunaan:** HTTP Client untuk **USGS API** (Global earthquake data)

#### Endpoint:

```
Base URL: https://earthquake.usgs.gov/fdsnws/event/1
```

#### Methods Utama:

| Method | Kegunaan | Parameters |
|--------|----------|------------|
| `getEarthquakes()` | Fetch custom earthquakes | startTime, endTime, minMag, bbox, limit |
| `getRecentSignificantEarthquakes()` | Gempa signifikan 7 hari terakhir | M≥4.5 |
| `getIndonesiaEarthquakes()` | Gempa di Indonesia region | Bounding box Indonesia |
| `getTodayEarthquakes()` | Gempa hari ini | minMagnitude |
| `getMajorEarthquakes()` | Gempa besar 30 hari terakhir | M≥6.0 |

#### Code Penting:

```dart
// Fetch earthquakes dengan custom parameters
Future<List<EarthquakeModel>> getEarthquakes({
  String? startTime,
  String? endTime,
  double? minMagnitude,
  double? maxMagnitude,
  double? minLatitude,
  double? maxLatitude,
  double? minLongitude,
  double? maxLongitude,
  int limit = 100,
  String orderBy = 'time',
}) async {
  final queryParams = <String, String>{
    'format': 'geojson',
    'limit': limit.toString(),
    'orderby': orderBy,
  };

  // Add optional parameters
  if (startTime != null) queryParams['starttime'] = startTime;
  if (minMagnitude != null) queryParams['minmagnitude'] = minMagnitude.toString();
  // ... etc

  final uri = Uri.parse('$baseUrl/query').replace(queryParameters: queryParams);
  final response = await http.get(uri).timeout(timeoutDuration);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final features = data['features'] as List;
    return features.map((f) => _parseUsgsFeature(f)).toList();
  }
}

// Indonesia earthquakes (bounding box)
Future<List<EarthquakeModel>> getIndonesiaEarthquakes({
  int days = 7,
  double minMagnitude = 2.5,
}) async {
  final now = DateTime.now();
  final startTime = now.subtract(Duration(days: days));

  // Indonesia bounding box: -11° to 6° lat, 95° to 141° lon
  return await getEarthquakes(
    startTime: startTime.toIso8601String(),
    endTime: now.toIso8601String(),
    minLatitude: -11.0,
    maxLatitude: 6.0,
    minLongitude: 95.0,
    maxLongitude: 141.0,
    minMagnitude: minMagnitude,
    limit: 200,
  );
}

// Parse USGS GeoJSON format ke EarthquakeModel
EarthquakeModel _parseUsgsFeature(Map<String, dynamic> feature) {
  final properties = feature['properties'] ?? {};
  final geometry = feature['geometry'] ?? {};
  final coordinates = geometry['coordinates'] as List?;

  final longitude = coordinates?[0]?.toDouble();
  final latitude = coordinates?[1]?.toDouble();
  final depth = coordinates?[2]?.toDouble().toInt();

  final magnitude = properties['mag']?.toDouble();
  final place = properties['place'] as String?;
  final time = properties['time'] as int?;

  // Convert timestamp to DateTime
  final datetime = time != null
      ? DateTime.fromMillisecondsSinceEpoch(time)
      : null;

  return EarthquakeModel(
    date: formatDate(datetime),
    time: formatTime(datetime),
    datetime: datetime,
    magnitude: magnitude,
    depth: depth,
    region: place ?? 'Unknown Location',
    latitude: latitude,
    longitude: longitude,
  );
}
```

#### Fitur:
- ✅ Global earthquake data
- ✅ Filter berdasarkan bounding box (region)
- ✅ Filter berdasarkan waktu & magnitudo
- ✅ Parse GeoJSON format
- ✅ Support tsunami & felt data

---

### 4️⃣ `local_storage_service.dart`

**Kegunaan:** **Repository/DAO** untuk operasi Hive database (CRUD semua box)

#### Methods untuk Setiap Box:

**A. Weather Operations:**
```dart
Future<void> saveWeather(String key, WeatherModel weather)
WeatherModel? getWeather(String key)
List<WeatherModel> getAllWeather()
Future<void> deleteWeather(String key)
Future<void> clearWeather()
```

**B. Earthquake Operations:**
```dart
Future<void> saveEarthquake(EarthquakeModel earthquake)
Future<void> saveEarthquakes(List<EarthquakeModel> earthquakes)
List<EarthquakeModel> getAllEarthquakes()
List<EarthquakeModel> getEarthquakesSorted() // Sorted by date DESC
Future<void> deleteEarthquake(String key)
Future<void> clearEarthquakes()
```

**C. Warning Operations:**
```dart
Future<void> saveWarning(WeatherWarningModel warning)
Future<void> saveWarnings(List<WeatherWarningModel> warnings)
List<WeatherWarningModel> getAllWarnings()
List<WeatherWarningModel> getActiveWarnings() // Filter active only
Future<void> deleteWarning(String id)
Future<void> clearWarnings()
```

**D. Favorites Operations:**
```dart
Future<void> addFavorite(String location)
Future<void> removeFavorite(String location)
List<String> getFavorites()
bool isFavorite(String location)
Future<void> clearFavorites()
```

**E. Watch Point Operations (CRUD):**
```dart
Future<void> addWatchPoint(WatchPointModel watchPoint)         // CREATE
List<WatchPointModel> getAllWatchPoints()                      // READ ALL
WatchPointModel? getWatchPoint(String id)                      // READ ONE
Future<void> updateWatchPoint(WatchPointModel watchPoint)      // UPDATE
Future<void> deleteWatchPoint(String id)                       // DELETE
Future<void> clearWatchPoints()                                // CLEAR ALL
```

#### Code Penting:

```dart
class LocalStorageService {
  // Box names (constants)
  static const String weatherBox = 'weather_box';
  static const String earthquakeBox = 'earthquake_box';
  static const String warningBox = 'warning_box';
  static const String favoritesBox = 'favorites_box';
  static const String watchPointBox = 'watch_point_box';

  // Helper: Safely get box (open if not already open)
  Future<Box<T>> _getBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  // Sync version - returns null if box not open
  Box<T>? _getBoxSync<T>(String boxName) {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return null;
  }

  // Example: Save earthquakes (batch insert)
  Future<void> saveEarthquakes(List<EarthquakeModel> earthquakes) async {
    final box = await _getBox<EarthquakeModel>(earthquakeBox);
    final Map<String, EarthquakeModel> dataMap = {};

    // Create unique key dari date_time
    for (var eq in earthquakes) {
      final key = '${eq.date}_${eq.time}';
      dataMap[key] = eq;
    }

    // Batch insert (lebih cepat dari insert satu-satu)
    await box.putAll(dataMap);
  }

  // Example: Get earthquakes sorted by date
  List<EarthquakeModel> getEarthquakesSorted() {
    final earthquakes = getAllEarthquakes();
    earthquakes.sort((a, b) {
      if (a.datetime == null || b.datetime == null) return 0;
      return b.datetime!.compareTo(a.datetime!); // Descending (newest first)
    });
    return earthquakes;
  }

  // Utility: Get data count for all boxes
  Map<String, int> getDataCount() {
    return {
      'weather': _getBoxSync<WeatherModel>(weatherBox)?.length ?? 0,
      'earthquake': _getBoxSync<EarthquakeModel>(earthquakeBox)?.length ?? 0,
      'warning': _getBoxSync<WeatherWarningModel>(warningBox)?.length ?? 0,
      'favorites': _getBoxSync<String>(favoritesBox)?.length ?? 0,
    };
  }
}
```

#### Kegunaan:
- ✅ Abstraksi untuk semua operasi database
- ✅ UI layer tidak tahu implementasi Hive
- ✅ Mudah untuk switch database di masa depan
- ✅ Type-safe operations

---

### 5️⃣ `preferences_service.dart`

**Kegunaan:** Wrapper untuk **SharedPreferences** (Settings & preferences)

#### Methods Utama:

```dart
// Initialization
static Future<void> init()

// Language Settings
static Future<bool> setLanguage(String language)
static String getLanguage()

// Notification Settings
static Future<bool> setNotificationsEnabled(bool enabled)
static bool getNotificationsEnabled()
static Future<bool> setEarthquakeNotificationsEnabled(bool enabled)
static bool getEarthquakeNotificationsEnabled()
static Future<bool> setMinMagnitude(double magnitude)
static double getMinMagnitude()

// Refresh Settings
static Future<bool> setAutoRefreshEnabled(bool enabled)
static bool getAutoRefreshEnabled()
static Future<bool> setRefreshInterval(int minutes)
static int getRefreshInterval()

// Display Settings
static Future<bool> setTemperatureUnit(String unit)
static String getTemperatureUnit()
static Future<bool> setThemeMode(String mode)
static String getThemeMode()

// Location Settings
static Future<bool> setDefaultLocation(String location)
static String getDefaultLocation()
static Future<bool> setUseGPS(bool use)
static bool getUseGPS()

// Cache Management
static Future<bool> setLastUpdate(DateTime time)
static DateTime? getLastUpdate()
static bool isDataStale() // Check if cache expired

// Utility
static Future<bool> clearAll()
static Map<String, dynamic> getAllSettings()
static Future<void> resetToDefaults()
```

#### Code Penting:

```dart
class PreferencesService {
  static SharedPreferences? _preferences;

  // Keys (constants)
  static const String keyLanguage = 'language';
  static const String keyNotifications = 'notifications';
  static const String keyAutoRefresh = 'auto_refresh';
  // ... dll

  // Initialize
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Get instance
  static SharedPreferences get instance {
    if (_preferences == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _preferences!;
  }

  // Cache invalidation strategy
  static bool isDataStale() {
    final lastUpdate = getLastUpdate();
    if (lastUpdate == null) return true;

    final refreshInterval = getRefreshInterval(); // default: 30 menit
    final staleDuration = Duration(minutes: refreshInterval);

    return DateTime.now().difference(lastUpdate) > staleDuration;
  }

  // Reset to defaults
  static Future<void> resetToDefaults() async {
    await clearAll();
    await setLanguage('id');
    await setNotificationsEnabled(true);
    await setAutoRefreshEnabled(true);
    await setRefreshInterval(30);
    await setTemperatureUnit('C');
    await setThemeMode('system');
    await setDefaultLocation('Yogyakarta');
    await setUseGPS(false);
    await setMinMagnitude(5.0);
  }
}
```

---

### 6️⃣ `location_service.dart`

**Kegunaan:** Handle **GPS location, permissions, dan distance calculation**

#### Methods Utama:

| Method | Return Type | Kegunaan |
|--------|-------------|----------|
| `isLocationPermissionGranted()` | `Future<bool>` | Cek permission granted |
| `requestLocationPermission()` | `Future<bool>` | Request permission |
| `isLocationServiceEnabled()` | `Future<bool>` | Cek GPS service aktif |
| `getCurrentPosition()` | `Future<Position?>` | Get current GPS position |
| `getLastKnownPosition()` | `Future<Position?>` | Get last known position |
| `calculateDistance()` | `double` | Hitung jarak (km) antara 2 koordinat |
| `getNearestCity()` | `String` | Cari kota terdekat dari koordinat |
| `openLocationSettings()` | `Future<void>` | Buka settings GPS |

#### Code Penting:

```dart
// Get current position
static Future<Position?> getCurrentPosition() async {
  try {
    // 1. Check if location service enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // 2. Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // 3. Get position
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

// Calculate distance (using Geolocator)
static double calculateDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  // Return in kilometers
  return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
}

// Get nearest city from coordinates
static String getNearestCity(double latitude, double longitude) {
  final cities = {
    'Jakarta': {'lat': -6.2088, 'lon': 106.8456},
    'Surabaya': {'lat': -7.2575, 'lon': 112.7521},
    'Bandung': {'lat': -6.9175, 'lon': 107.6191},
    // ... 15 kota besar Indonesia
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
```

#### Kegunaan:
- ✅ Auto-detect lokasi user untuk cuaca
- ✅ Calculate jarak user dari epicenter gempa
- ✅ Mapping koordinat ke nama kota
- ✅ Permission handling yang robust

---

### 7️⃣ `notification_service.dart`

**Kegunaan:** Handle **local notifications** untuk alert cuaca & gempa

#### Methods Utama:

```dart
static Future<void> init()                          // Initialize notification plugin
static Future<bool> requestPermission()             // Request notification permission (Android 13+)
static Future<void> showWeatherAlert({              // Show weather notification
  required String title,
  required String body,
})
```

#### Code Penting:

```dart
class WeatherNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Initialize
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _plugin.initialize(settings);
  }

  // Request permission (Android 13+)
  static Future<bool> requestPermission() async {
    final bool granted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
    return granted;
  }

  // Show notification
  static Future<void> showWeatherAlert({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'weather_channel',
      'Weather Alert',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      1,
      title,
      body,
      platformDetails,
    );
  }
}
```

#### Use Case:
- 🔔 Notifikasi gempa M≥5.0
- 🔔 Notifikasi cuaca ekstrem (hujan lebat, angin kencang)
- 🔔 Alert perubahan cuaca di watch points

---

## 🎨 FOLDER PROVIDERS

**Lokasi:** `lib/providers/`

**Kegunaan:** Folder ini berisi **ViewModel layer** yang menggunakan **Provider pattern** untuk **state management**.

### Apa itu Provider?

Provider adalah state management pattern di Flutter yang:
- ✅ Memisahkan **business logic** dari **UI**
- ✅ Membuat state **reactive** (UI auto-update saat state berubah)
- ✅ Mudah di-test dan di-maintain
- ✅ Support multiple listeners

### Pattern yang Digunakan:

```
UI Screen → Provider (ViewModel) → Service → API/Database
```

---

### 1️⃣ `weather_provider.dart`

**Kegunaan:** Manage **state & logic** untuk fitur cuaca

#### State Variables:

```dart
WeatherModel? _currentWeather;           // Data cuaca BMKG
OpenMeteoWeather? _openMeteoWeather;     // Data cuaca Open-Meteo
bool _isLoading = false;                 // Loading state
String? _error;                          // Error message
String _selectedLocation = 'Yogyakarta'; // Kota yang dipilih
double? _userLatitude;                   // GPS latitude
double? _userLongitude;                  // GPS longitude
```

#### Methods Utama:

| Method | Kegunaan |
|--------|----------|
| `_detectLocation()` | Auto-detect lokasi GPS user, find nearest city |
| `loadWeather()` | Load data cuaca (cek cache → API → save cache) |
| `refreshWithLocation()` | Refresh dengan detect GPS location baru |
| `changeLocation(String)` | Ganti kota secara manual |
| `refresh()` | Force refresh data |
| `getTodayForecast()` | Get forecast hari ini (filter by date) |
| `getWeeklyForecast()` | Get forecast 7 hari |
| `getCurrentTemperature()` | Get suhu saat ini |
| `getTemperature(double?)` | Convert Celsius ↔ Fahrenheit |
| `clearCache()` | Hapus cache cuaca |

#### Flow Logic:

```dart
// 1. DETECT LOCATION (GPS or default)
Future<void> _detectLocation() async {
  final useGPS = PreferencesService.getUseGPS();

  // Jika GPS OFF → pakai default location
  if (!useGPS) {
    _selectedLocation = PreferencesService.getDefaultLocation();
    return;
  }

  // Get GPS position
  final position = await LocationService.getCurrentPosition();
  if (position == null) {
    _selectedLocation = PreferencesService.getDefaultLocation();
    return;
  }

  _userLatitude = position.latitude;
  _userLongitude = position.longitude;

  // Cari kota terdekat
  final nearestCity = LocationService.getNearestCity(
    position.latitude,
    position.longitude,
  );

  _selectedLocation = nearestCity;
  await PreferencesService.setDefaultLocation(nearestCity);
}

// 2. LOAD WEATHER (cache-first strategy)
Future<void> loadWeather({bool forceRefresh = false}) async {
  _isLoading = true;
  _error = null;
  notifyListeners(); // Update UI

  try {
    // Cek cache jika tidak force refresh
    if (!forceRefresh && !PreferencesService.isDataStale()) {
      final cached = _storageService.getWeather(_selectedLocation);
      if (cached != null) {
        _currentWeather = cached;
        _isLoading = false;
        notifyListeners();
        return; // Use cache
      }
    }

    // Get coordinates untuk selected city
    final coords = cityCoordinates[_selectedLocation]!;
    final lat = coords['lat']!;
    final lon = coords['lon']!;

    // Fetch dari Open-Meteo API (prioritas)
    _openMeteoWeather = await _openMeteoService.getWeather(
      latitude: lat,
      longitude: lon,
    );

    // Fallback ke BMKG jika Open-Meteo gagal
    if (_openMeteoWeather == null) {
      final weather = await _apiService.getWeatherForecast(_selectedLocation);
      if (weather != null) {
        _currentWeather = weather;
        await _storageService.saveWeather(_selectedLocation, weather);
        await PreferencesService.setLastUpdate(DateTime.now());
      }
    } else {
      await PreferencesService.setLastUpdate(DateTime.now());
    }
  } catch (e) {
    _error = "Error loading weather: $e";

    // Fallback ke cache jika error
    final cached = _storageService.getWeather(_selectedLocation);
    if (cached != null) {
      _currentWeather = cached;
      _error = "Using cached data due to error.";
    }
  } finally {
    _isLoading = false;
    notifyListeners(); // Update UI
  }
}
```

#### Penggunaan di UI:

```dart
// Read & watch (rebuild saat state berubah)
final weatherProvider = context.watch<WeatherProvider>();

if (weatherProvider.isLoading) {
  return CircularProgressIndicator();
}

if (weatherProvider.error != null) {
  return Text('Error: ${weatherProvider.error}');
}

final temp = weatherProvider.getCurrentTemperature();
Text('${temp}°${weatherProvider.getTemperatureUnit()}');

// Call methods (tidak rebuild)
context.read<WeatherProvider>().loadWeather(forceRefresh: true);
context.read<WeatherProvider>().changeLocation('Jakarta');
```

---

### 2️⃣ `earthquake_provider.dart`

**Kegunaan:** Manage **state & logic** untuk fitur gempa bumi

#### State Variables:

```dart
List<EarthquakeModel> _latestEarthquakes = [];   // Gempa terkini
List<EarthquakeModel> _recentEarthquakes = [];   // Gempa M≥5.0
List<EarthquakeModel> _feltEarthquakes = [];     // Gempa dirasakan
List<EarthquakeModel> _usgsEarthquakes = [];     // Data USGS
bool _isLoading = false;
String? _error;
String _selectedTab = 'latest';                  // Tab yang dipilih
bool _useUsgsData = false;                       // Toggle USGS data
double? _userLatitude;                           // GPS user
double? _userLongitude;
```

#### Methods Utama:

| Method | Kegunaan |
|--------|----------|
| `_detectLocation()` | Detect GPS untuk distance calculation |
| `loadEarthquakes()` | Load semua data gempa (BMKG + USGS) |
| `_loadFromApi()` | Fetch dari BMKG API (3 endpoints) |
| `_loadUsgsData()` | Fetch dari USGS API |
| `toggleUsgsData(bool)` | Toggle USGS data source |
| `changeTab(String)` | Ganti tab (latest/recent/felt/usgs) |
| `getDistanceFromUser()` | Hitung jarak gempa dari user (km) |
| `getEarthquakesSortedByDistance()` | Sort gempa berdasarkan jarak |
| `filterByMagnitude(double)` | Filter berdasarkan magnitudo minimum |
| `filterByRegion(String)` | Filter berdasarkan region/wilayah |
| `refresh()` | Force refresh |
| `clearCache()` | Hapus cache gempa |

#### Flow Logic:

```dart
// Load from BMKG API (3 categories)
Future<void> _loadFromApi() async {
  try {
    // 1. Latest earthquake (autogempa.json)
    final latestRes = await http.get(Uri.parse(
        "https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json"));

    if (latestRes.statusCode == 200) {
      final data = jsonDecode(latestRes.body);
      final g = data["Infogempa"]["gempa"];
      _latestEarthquakes = [EarthquakeModel.fromJson(g)];
      _storageService.saveEarthquakes(_latestEarthquakes);
    }

    // 2. Recent earthquakes M≥5.0 (gempaterkini.json)
    final recentRes = await http.get(Uri.parse(
        "https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json"));

    if (recentRes.statusCode == 200) {
      final data = jsonDecode(recentRes.body);
      final list = data["Infogempa"]["gempa"] as List;
      _recentEarthquakes = list.map((e) => EarthquakeModel.fromJson(e)).toList();
    }

    // 3. Felt earthquakes (gempadirasakan.json)
    final feltRes = await http.get(Uri.parse(
        "https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json"));

    if (feltRes.statusCode == 200) {
      final data = jsonDecode(feltRes.body);
      final list = data["Infogempa"]["gempa"] as List;
      _feltEarthquakes = list.map((e) => EarthquakeModel.fromJson(e)).toList();
    }

    // 4. Load USGS data if enabled
    if (_useUsgsData) {
      await _loadUsgsData();
    }

    notifyListeners();
  } catch (e) {
    _error = "Gagal memuat data dari BMKG: $e";
  }
}

// Calculate distance from user
double? getDistanceFromUser(EarthquakeModel eq) {
  if (_userLatitude == null || _userLongitude == null ||
      eq.latitude == null || eq.longitude == null) {
    return null;
  }

  return LocationService.calculateDistance(
    _userLatitude!,
    _userLongitude!,
    eq.latitude!,
    eq.longitude!,
  );
}

// Sort by distance
List<EarthquakeModel> getEarthquakesSortedByDistance() {
  final sorted = List<EarthquakeModel>.from(currentList);
  sorted.sort((a, b) {
    final da = getDistanceFromUser(a);
    final db = getDistanceFromUser(b);
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db); // Ascending (terdekat dulu)
  });
  return sorted;
}
```

---

### 3️⃣ `watch_point_provider.dart`

**Kegunaan:** Manage **state & CRUD logic** untuk fitur Watch Points (Titik Pantau)

#### State Variables:

```dart
List<WatchPointModel> _watchPoints = [];         // Semua watch points
bool _isLoading = false;
String? _error;
List<Location> _searchResults = [];              // Hasil geocoding search
bool _isSearching = false;
String? _searchError;
```

#### Methods Utama (CRUD):

| Method | CRUD | Kegunaan |
|--------|------|----------|
| `addWatchPoint()` | **CREATE** | Tambah watch point baru |
| `getWatchPointById()` | **READ** | Ambil watch point by ID |
| `loadWatchPoints()` | **READ** | Load semua watch points |
| `updateWatchPoint()` | **UPDATE** | Update watch point existing |
| `deleteWatchPoint()` | **DELETE** | Hapus watch point |
| `searchAddress()` | - | Search alamat (geocoding) |
| `getAddressFromCoordinates()` | - | Reverse geocoding |
| `clearSearchResults()` | - | Clear search results |
| `_findNearestCity()` | - | Cari kota terdekat (private) |

#### Flow Logic CRUD:

```dart
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

    // 1. Cari kota terdekat untuk mapping ke data cuaca
    final nearestCity = _findNearestCity(latitude, longitude);

    // 2. Buat model
    final watchPoint = WatchPointModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      description: description,
      nearestCity: nearestCity,
      createdAt: DateTime.now(),
    );

    // 3. Save ke Hive database
    await _storageService.addWatchPoint(watchPoint);

    // 4. Reload list
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

    // 1. Cek apakah watch point exists
    final existingWatchPoint = _storageService.getWatchPoint(id);
    if (existingWatchPoint == null) {
      _error = 'Titik pantau tidak ditemukan';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // 2. Cari kota terdekat
    final nearestCity = _findNearestCity(latitude, longitude);

    // 3. Update dengan copyWith
    final updatedWatchPoint = existingWatchPoint.copyWith(
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      description: description,
      nearestCity: nearestCity,
      updatedAt: DateTime.now(),
    );

    // 4. Save update ke database
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

// GEOCODING - Search address
Future<void> searchAddress(String query) async {
  if (query.isEmpty) {
    _searchResults = [];
    return;
  }

  try {
    _isSearching = true;
    _searchError = null;
    notifyListeners();

    // Tambahkan "Indonesia" untuk hasil lebih relevan
    final searchQuery = query.contains('Indonesia')
        ? query
        : '$query, Indonesia';

    // Call geocoding API
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

// Find nearest city (Haversine formula)
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

// Haversine distance calculation
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
```

---

## 📦 INSTALASI

### Prerequisites:
- Flutter SDK ^3.9.0
- Dart SDK ^3.9.0
- Android Studio / VS Code
- Android Emulator / Physical Device

### Steps:

1. **Clone repository**
```bash
git clone <repository-url>
cd xbmkg
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code (Hive adapters)**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run app**
```bash
flutter run
```

---

## 📂 STRUKTUR PROJECT

```
xbmkg/
├── lib/
│   ├── auth/                     # Login & Register screens
│   │   ├── login.dart
│   │   └── register.dart
│   │
│   ├── models/                   # Data models (Hive + JSON)
│   │   ├── user_model.dart
│   │   ├── earthquake_model.dart
│   │   ├── weather_model.dart
│   │   ├── weather_warning_model.dart
│   │   ├── watch_point_model.dart
│   │   ├── open_meteo_model.dart
│   │   └── *.g.dart              # Generated files
│   │
│   ├── providers/                # State management (Provider)
│   │   ├── weather_provider.dart
│   │   ├── earthquake_provider.dart
│   │   └── watch_point_provider.dart
│   │
│   ├── screens/                  # UI Screens
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── main_screen.dart
│   │   ├── home_screen.dart
│   │   ├── weather_screen.dart
│   │   ├── earthquake_screen.dart
│   │   ├── earthquake_detail_screen.dart
│   │   ├── watch_point_screen.dart
│   │   ├── watch_point_detail_screen.dart
│   │   ├── add_watch_point_screen.dart
│   │   └── profile_screen.dart
│   │
│   ├── services/                 # Service layer
│   │   ├── bmkg_api_service.dart
│   │   ├── open_meteo_service.dart
│   │   ├── usgs_api_service.dart
│   │   ├── local_storage_service.dart
│   │   ├── preferences_service.dart
│   │   ├── location_service.dart
│   │   ├── notification_service.dart
│   │   └── permission_service.dart
│   │
│   └── main.dart                 # Entry point
│
├── pubspec.yaml                  # Dependencies
├── README.md                     # Documentation
└── DOKUMENTASI_PROJECT.md        # Detailed documentation
```

---

## 📸 SCREENSHOTS

(Tambahkan screenshots aplikasi di sini)

---

## 📚 DEPENDENCIES

### Production Dependencies:

```yaml
# UI & Design
cupertino_icons: ^1.0.8          # iOS icons
smooth_page_indicator: ^1.1.0    # Onboarding page indicator
fl_chart: ^0.69.0                # Charts & graphs
cached_network_image: ^3.4.1     # Image caching

# State Management
provider: ^6.1.2                 # Provider pattern

# Local Storage
hive: ^2.2.3                     # NoSQL database
hive_flutter: ^1.1.0             # Hive for Flutter
shared_preferences: ^2.2.2       # Key-value storage

# Network
http: ^1.2.0                     # HTTP client

# Location & Maps
geolocator: ^13.0.2              # GPS location
geocoding: ^3.0.0                # Geocoding API

# Permissions
permission_handler: ^11.3.1      # Permission handling

# Utilities
intl: ^0.19.0                    # Date formatting

# Notifications
flutter_local_notifications: ^19.5.0  # Local notifications
timezone: ^0.10.1                     # Timezone support

# Media
image_picker: ^1.1.2             # Image picker
```

### Dev Dependencies:

```yaml
# Testing
flutter_test:
  sdk: flutter

# Code Generation
build_runner: ^2.4.8             # Build runner
hive_generator: ^2.0.1           # Hive adapter generator

# Linting
flutter_lints: ^5.0.0            # Lint rules
```

---

## 🚀 CARA KERJA APLIKASI

### 1. **Startup Flow:**

```
SplashScreen → OnboardingScreen → LoginScreen → MainScreen
                                       ↓
                                  (if logged in)
                                       ↓
                                  MainScreen
```

### 2. **Data Flow:**

```
User Action → Provider (notifyListeners) → UI Rebuild
                ↓
         Service Layer
                ↓
        API / Database
```

### 3. **Cache Strategy:**

```
1. Check cache first
2. If cache valid → use cache
3. If cache stale → fetch from API
4. Save to cache
5. Update last_update timestamp
```

---

## 👨‍💻 DEVELOPER NOTES

### Code Generation:

Setiap kali ubah model dengan `@HiveType` atau `@HiveField`, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Database Location:

- **Hive:** Stored di `ApplicationDocumentsDirectory`
  - Android: `/data/data/com.example.xbmkg/app_flutter/`
  - iOS: `~/Library/Application Support/`

### API Rate Limits:

- **BMKG API:** No rate limit (public API)
- **Open-Meteo API:** 10,000 requests/day (free tier)
- **USGS API:** No official rate limit, tapi gunakan timeout

---

## 📄 LICENSE

MIT License - See LICENSE file for details

---

## 🤝 KONTRIBUSI

Contributions are welcome! Please read CONTRIBUTING.md for details.

---

## 📞 CONTACT

Untuk pertanyaan atau bug report, silakan buat issue di GitHub repository.

---

**Dibuat dengan ❤️ menggunakan Flutter**
