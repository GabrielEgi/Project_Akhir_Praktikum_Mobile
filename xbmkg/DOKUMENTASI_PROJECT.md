# 📱 DOKUMENTASI PROJECT XBMKG
## Aplikasi Cuaca dan Gempa Bumi Indonesia

---

## 📋 DAFTAR ISI
1. [Overview Project](#overview-project)
2. [Arsitektur Aplikasi](#arsitektur-aplikasi)
3. [Fitur-Fitur Utama](#fitur-fitur-utama)
4. [Local Database & Storage](#local-database--storage)
5. [Shared Preferences](#shared-preferences)
6. [CRUD Operations](#crud-operations)
7. [API Integration](#api-integration)
8. [State Management](#state-management)
9. [Kelebihan & Kekurangan](#kelebihan--kekurangan)
10. [Dependency](#dependency)

---

## 🎯 OVERVIEW PROJECT

**Nama Aplikasi:** XBMKG (WeatherNews)
**Platform:** Flutter (Android, iOS, Web)
**Versi:** 0.1.0
**Bahasa:** Dart ^3.9.0

### Deskripsi
Aplikasi mobile yang menyediakan informasi cuaca real-time dan data gempa bumi untuk wilayah Indonesia. Mengintegrasikan data dari BMKG (Badan Meteorologi, Klimatologi, dan Geofisika), Open-Meteo API, dan USGS (United States Geological Survey).

---

## 🏗️ ARSITEKTUR APLIKASI

### Pattern yang Digunakan
- **State Management:** Provider Pattern
- **Architecture:** MVVM (Model-View-ViewModel)
- **Local Storage:** Hive (NoSQL Database)
- **Preferences:** SharedPreferences
- **API Client:** HTTP Package

### Struktur Folder
```
lib/
├── auth/                    # Halaman autentikasi
│   ├── login.dart          # Login screen
│   └── register.dart       # Register screen
├── models/                  # Data models
│   ├── user_model.dart     # User data model (Hive)
│   ├── earthquake_model.dart   # Earthquake data model (Hive)
│   ├── weather_model.dart      # Weather data model (Hive)
│   ├── weather_warning_model.dart  # Weather warning model (Hive)
│   ├── watch_point_model.dart      # Watch point model (Hive)
│   └── open_meteo_model.dart       # Open-Meteo API response model
├── providers/               # State management (Provider)
│   ├── weather_provider.dart       # Weather state & logic
│   ├── earthquake_provider.dart    # Earthquake state & logic
│   └── watch_point_provider.dart   # Watch point state & CRUD
├── screens/                 # UI Screens
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── main_screen.dart
│   ├── home_screen.dart
│   ├── weather_screen.dart
│   ├── earthquake_screen.dart
│   ├── earthquake_detail_screen.dart
│   ├── watch_point_screen.dart
│   ├── watch_point_detail_screen.dart
│   ├── add_watch_point_screen.dart
│   └── profile_screen.dart
└── services/                # Services layer
    ├── bmkg_api_service.dart       # BMKG API client
    ├── open_meteo_service.dart     # Open-Meteo API client
    ├── usgs_api_service.dart       # USGS API client
    ├── local_storage_service.dart  # Hive database operations
    ├── preferences_service.dart    # SharedPreferences wrapper
    ├── location_service.dart       # GPS & location operations
    ├── notification_service.dart   # Local notifications
    └── permission_service.dart     # Permission handling
```

---

## ✨ FITUR-FITUR UTAMA

### 1. 🌤️ **Fitur Cuaca (Weather)**
**File:** `lib/screens/weather_screen.dart` & `lib/providers/weather_provider.dart`

#### Logika Kerja:
1. **Deteksi Lokasi GPS**
   - Menggunakan `location_service.dart` untuk mendapatkan koordinat GPS
   - Mencari kota terdekat berdasarkan koordinat (Haversine formula)
   - Fallback ke lokasi default jika GPS gagal/ditolak

```dart
// weather_provider.dart:62-102
Future<void> _detectLocation() async {
  final useGPS = PreferencesService.getUseGPS();
  if (!useGPS) {
    _selectedLocation = PreferencesService.getDefaultLocation();
    return;
  }

  final position = await LocationService.getCurrentPosition();
  if (position == null) {
    _selectedLocation = PreferencesService.getDefaultLocation();
    return;
  }

  _userLatitude = position.latitude;
  _userLongitude = position.longitude;

  final nearestCity = LocationService.getNearestCity(
    position.latitude,
    position.longitude,
  );

  _selectedLocation = nearestCity;
}
```

2. **Load Data Cuaca**
   - Cek cache terlebih dahulu (dari Hive)
   - Validasi data stale (berdasarkan refresh interval)
   - Ambil data dari API (Open-Meteo prioritas, fallback ke BMKG)
   - Simpan ke cache untuk offline access

```dart
// weather_provider.dart:107-162
Future<void> loadWeather({bool forceRefresh = false}) async {
  // Cek cache jika tidak force refresh
  if (!forceRefresh && !PreferencesService.isDataStale()) {
    final cached = _storageService.getWeather(_selectedLocation);
    if (cached != null) {
      _currentWeather = cached;
      return;
    }
  }

  // Ambil koordinat kota
  final coords = cityCoordinates[_selectedLocation];

  // Fetch dari Open-Meteo API
  _openMeteoWeather = await _openMeteoService.getWeather(
    latitude: coords['lat'],
    longitude: coords['lon'],
  );

  // Fallback ke BMKG jika gagal
  if (_openMeteoWeather == null) {
    final weather = await _apiService.getWeatherForecast(_selectedLocation);
    if (weather != null) {
      _currentWeather = weather;
      await _storageService.saveWeather(_selectedLocation, weather);
    }
  }
}
```

3. **Data yang Ditampilkan:**
   - Suhu saat ini (Celsius/Fahrenheit)
   - Kondisi cuaca (Cerah, Berawan, Hujan, dll)
   - Kecepatan & arah angin
   - Kelembaban udara
   - Prakiraan cuaca 24 jam
   - Prakiraan cuaca 7 hari

---

### 2. 🌍 **Fitur Gempa Bumi (Earthquake)**
**File:** `lib/screens/earthquake_screen.dart` & `lib/providers/earthquake_provider.dart`

#### Logika Kerja:
1. **Sumber Data Multi-API**
   - BMKG API: Gempa terkini Indonesia
   - USGS API: Gempa global dengan filter Indonesia

2. **3 Kategori Gempa BMKG:**
   - **Latest (Gempa Terkini):** Gempa terakhir yang tercatat
   - **Recent (M≥5.0):** Gempa dengan magnitudo ≥5.0
   - **Felt (Gempa Dirasakan):** Gempa yang dilaporkan dirasakan masyarakat

```dart
// earthquake_provider.dart:99-138
Future<void> _loadFromApi() async {
  // Fetch latest earthquake
  final latestRes = await http.get(Uri.parse(
      "https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json"));

  if (latestRes.statusCode == 200) {
    final data = jsonDecode(latestRes.body);
    final g = data["Infogempa"]["gempa"];
    _latestEarthquakes = [EarthquakeModel.fromJson(g)];
    _storageService.saveEarthquakes(_latestEarthquakes);
  }

  // Fetch recent earthquakes (M≥5.0)
  final recentRes = await http.get(Uri.parse(
      "https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json"));

  // Fetch felt earthquakes
  final feltRes = await http.get(Uri.parse(
      "https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json"));
}
```

3. **Fitur Sorting & Filter:**
   - Sort berdasarkan jarak dari user (GPS)
   - Filter berdasarkan magnitudo minimum
   - Filter berdasarkan region/wilayah

```dart
// earthquake_provider.dart:228-254
double? getDistanceFromUser(EarthquakeModel eq) {
  if (_userLatitude == null || _userLongitude == null) return null;

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
    return da.compareTo(db);
  });
  return sorted;
}
```

---

### 3. 📍 **Fitur Titik Pantau (Watch Point)**
**File:** `lib/screens/watch_point_screen.dart` & `lib/providers/watch_point_provider.dart`

#### Logika Kerja:
Fitur ini memungkinkan user untuk menyimpan lokasi tertentu dan memantau cuaca di lokasi tersebut.

1. **Geocoding & Reverse Geocoding**
   - Search alamat menggunakan package `geocoding`
   - Convert alamat → koordinat (lat/long)
   - Convert koordinat → alamat lengkap

```dart
// watch_point_provider.dart:171-197
Future<void> searchAddress(String query) async {
  if (query.isEmpty) {
    _searchResults = [];
    return;
  }

  try {
    _isSearching = true;

    // Tambahkan "Indonesia" untuk hasil lebih relevan
    final searchQuery = query.contains('Indonesia')
        ? query
        : '$query, Indonesia';

    _searchResults = await locationFromAddress(searchQuery);

    _isSearching = false;
    notifyListeners();
  } catch (e) {
    _searchResults = [];
    _searchError = 'Alamat tidak ditemukan. Coba kata kunci lain.';
  }
}
```

2. **Mencari Kota Terdekat**
   - Menggunakan Haversine formula untuk menghitung jarak
   - Mapping ke kota yang didukung BMKG API
   - Digunakan untuk fetch data cuaca lokasi tersebut

```dart
// watch_point_provider.dart:221-240
String _findNearestCity(double lat, double lon) {
  String nearestCity = 'Jakarta';
  double minDistance = double.infinity;

  _supportedCities.forEach((city, coords) {
    final distance = _calculateDistance(
      lat, lon,
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

---

### 4. 🔐 **Fitur Autentikasi (Login/Register)**
**File:** `lib/auth/login.dart` & `lib/auth/register.dart`

#### Logika Kerja:
1. **Register:**
   - User memasukkan username, password
   - Validasi username belum dipakai
   - Hash password (dalam implementasi production sebaiknya di-hash)
   - Simpan ke Hive Box `users`

2. **Login:**
   - Validasi username & password dari Hive
   - Simpan status login ke SharedPreferences
   - Request permission lokasi setelah login sukses
   - Redirect ke MainScreen

```dart
// login.dart:22-61
Future<void> loginAccount() async {
  final username = usernameController.text.trim();
  final password = passwordController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    // Snackbar error
    return;
  }

  // Cari user di Hive
  final box = Hive.box<UserModel>('users');
  final user = box.values.firstWhere(
    (u) => u.username == username && u.password == password,
    orElse: () => UserModel(username: "", password: ""),
  );

  if (user.username.isEmpty) {
    // Username/password salah
    return;
  }

  // Save login state ke SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  await prefs.setString('username', username);

  // Request location permission
  await LocationService.requestLocationPermission();

  // Navigate to MainScreen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const MainScreen()),
  );
}
```

---

### 5. 🔔 **Fitur Notifikasi**
**File:** `lib/services/notification_service.dart`

#### Logika Kerja:
- Local notifications menggunakan `flutter_local_notifications`
- Notifikasi cuaca ekstrem
- Notifikasi gempa dengan magnitudo tertentu
- Notifikasi perubahan cuaca di watch points

---

## 💾 LOCAL DATABASE & STORAGE

### **Hive Database (NoSQL)**

**Lokasi:** `lib/services/local_storage_service.dart`

#### Mengapa Hive?
- ✅ **Lightweight:** Tidak butuh server, embedded database
- ✅ **Fast:** Performance tinggi untuk read/write
- ✅ **Type-safe:** Dengan code generation (build_runner)
- ✅ **Cross-platform:** Support Android, iOS, Web, Desktop
- ✅ **Offline-first:** Data tersimpan lokal

#### Box yang Digunakan:

| Box Name | Type | Kegunaan | File Model |
|----------|------|----------|------------|
| `users` | `UserModel` | Menyimpan data user (username, password) | `user_model.dart` |
| `earthquake_box` | `EarthquakeModel` | Cache data gempa dari API | `earthquake_model.dart` |
| `weather_box` | `WeatherModel` | Cache data cuaca BMKG | `weather_model.dart` |
| `warning_box` | `WeatherWarningModel` | Peringatan cuaca ekstrem | `weather_warning_model.dart` |
| `favorites_box` | `String` | Daftar lokasi favorit user | - |
| `watch_point_box` | `WatchPointModel` | Titik pantau yang dibuat user | `watch_point_model.dart` |

#### Inisialisasi Hive:

```dart
// main.dart:18-38
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register all Hive adapters (generated code)
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

#### Data yang Disimpan di Hive:

**1. User Data (`users` box)**
```dart
@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? photoUrl;
}
```

**2. Earthquake Data (`earthquake_box`)**
```dart
@HiveType(typeId: 1)
class EarthquakeModel {
  @HiveField(0) String? date;
  @HiveField(1) String? time;
  @HiveField(2) double? magnitude;
  @HiveField(3) String? region;
  @HiveField(4) double? latitude;
  @HiveField(5) double? longitude;
  @HiveField(6) String? depth;
  @HiveField(7) String? shakemap;
  // ... dll
}
```

**3. Weather Data (`weather_box`)**
```dart
@HiveType(typeId: 2)
class WeatherModel {
  @HiveField(0) String? area;
  @HiveField(1) String? province;
  @HiveField(2) DateTime? lastUpdate;
  @HiveField(3) List<WeatherData>? forecasts;
}
```

**4. Watch Point (`watch_point_box`)**
```dart
@HiveType(typeId: 5)
class WatchPointModel {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String address;
  @HiveField(3) double latitude;
  @HiveField(4) double longitude;
  @HiveField(5) String? description;
  @HiveField(6) String? nearestCity;
  @HiveField(7) DateTime createdAt;
  @HiveField(8) DateTime? updatedAt;
}
```

---

## 🔧 SHARED PREFERENCES

**Lokasi:** `lib/services/preferences_service.dart`

### Mengapa SharedPreferences?
- ✅ Simple key-value storage
- ✅ Untuk menyimpan settings/preferences user
- ✅ Ringan dan cepat
- ✅ Tidak perlu code generation

### Data yang Disimpan:

| Key | Type | Default | Kegunaan |
|-----|------|---------|----------|
| `language` | String | 'id' | Bahasa aplikasi (id/en) |
| `notifications` | bool | true | Aktifkan notifikasi |
| `show_earthquake_notif` | bool | true | Notifikasi gempa |
| `auto_refresh` | bool | true | Auto refresh data |
| `refresh_interval` | int | 30 | Interval refresh (menit) |
| `temperature_unit` | String | 'C' | Unit suhu (C/F) |
| `default_location` | String | 'Yogyakarta' | Lokasi default |
| `last_update` | String | null | Waktu update terakhir (ISO8601) |
| `theme_mode` | String | 'system' | Mode tema (light/dark/system) |
| `min_magnitude` | double | 5.0 | Magnitudo minimum untuk notifikasi |
| `use_gps` | bool | true | Gunakan GPS untuk deteksi lokasi |
| `isLoggedIn` | bool | false | Status login user |
| `username` | String | - | Username yang sedang login |

### Inisialisasi:

```dart
// main.dart:41
await PreferencesService.init();
```

### Contoh Penggunaan:

```dart
// Simpan settings
await PreferencesService.setLanguage('id');
await PreferencesService.setTemperatureUnit('C');
await PreferencesService.setUseGPS(true);

// Baca settings
String lang = PreferencesService.getLanguage();
bool useGPS = PreferencesService.getUseGPS();
String defaultLocation = PreferencesService.getDefaultLocation();

// Cek data stale (untuk cache invalidation)
bool isStale = PreferencesService.isDataStale();
```

### Cache Management:

```dart
// preferences_service.dart:159-167
static bool isDataStale() {
  final lastUpdate = getLastUpdate();
  if (lastUpdate == null) return true;

  final refreshInterval = getRefreshInterval(); // default: 30 menit
  final staleDuration = Duration(minutes: refreshInterval);

  return DateTime.now().difference(lastUpdate) > staleDuration;
}
```

---

## ✏️ CRUD OPERATIONS

### 1. **User CRUD (Login/Register)**
**Lokasi:** `lib/auth/login.dart`, `lib/auth/register.dart`

#### CREATE (Register)
```dart
// register.dart
Future<void> createAccount() async {
  final box = Hive.box<UserModel>('users');

  // Validasi username belum ada
  final exists = box.values.any((u) => u.username == username);
  if (exists) {
    // Username sudah dipakai
    return;
  }

  // Simpan user baru
  final newUser = UserModel(
    username: username,
    password: password,
  );

  await box.add(newUser);
}
```

#### READ (Login)
```dart
// login.dart:33-44
final box = Hive.box<UserModel>('users');

final user = box.values.firstWhere(
  (u) => u.username == username && u.password == password,
  orElse: () => UserModel(username: "", password: ""),
);

if (user.username.isEmpty) {
  // User tidak ditemukan atau password salah
}
```

---

### 2. **Weather CRUD**
**Lokasi:** `lib/services/local_storage_service.dart`

#### CREATE/UPDATE (Save)
```dart
// local_storage_service.dart:34-37
Future<void> saveWeather(String key, WeatherModel weather) async {
  final box = await _getBox<WeatherModel>(weatherBox);
  await box.put(key, weather); // put = create or update
}
```

#### READ
```dart
// local_storage_service.dart:40-43
WeatherModel? getWeather(String key) {
  final box = _getBoxSync<WeatherModel>(weatherBox);
  return box?.get(key);
}
```

#### DELETE
```dart
// local_storage_service.dart:52-55
Future<void> deleteWeather(String key) async {
  final box = await _getBox<WeatherModel>(weatherBox);
  await box.delete(key);
}
```

---

### 3. **Watch Point CRUD (Full CRUD)**
**Lokasi:** `lib/providers/watch_point_provider.dart`

#### CREATE
```dart
// watch_point_provider.dart:57-94
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

    // Cari kota terdekat untuk mapping data cuaca
    final nearestCity = _findNearestCity(latitude, longitude);

    // Buat model
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

    // Simpan ke Hive
    await _storageService.addWatchPoint(watchPoint);
    loadWatchPoints(); // Refresh list

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
```

#### READ
```dart
// watch_point_provider.dart:51-54
void loadWatchPoints() {
  _watchPoints = _storageService.getAllWatchPoints();
  notifyListeners();
}

// watch_point_provider.dart:97-99
WatchPointModel? getWatchPointById(String id) {
  return _storageService.getWatchPoint(id);
}
```

#### UPDATE
```dart
// watch_point_provider.dart:102-147
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

    // Cek apakah watch point ada
    final existingWatchPoint = _storageService.getWatchPoint(id);
    if (existingWatchPoint == null) {
      _error = 'Titik pantau tidak ditemukan';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Cari kota terdekat
    final nearestCity = _findNearestCity(latitude, longitude);

    // Update dengan copyWith
    final updatedWatchPoint = existingWatchPoint.copyWith(
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      description: description,
      nearestCity: nearestCity,
      updatedAt: DateTime.now(),
    );

    // Simpan update
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
```

#### DELETE
```dart
// watch_point_provider.dart:150-168
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
```

---

### 4. **Earthquake CRUD**
**Lokasi:** `lib/services/local_storage_service.dart`

#### CREATE (Save Multiple)
```dart
// local_storage_service.dart:73-83
Future<void> saveEarthquakes(List<EarthquakeModel> earthquakes) async {
  final box = await _getBox<EarthquakeModel>(earthquakeBox);
  final Map<String, EarthquakeModel> dataMap = {};

  // Buat unique key dari date_time
  for (var eq in earthquakes) {
    final key = '${eq.date}_${eq.time}';
    dataMap[key] = eq;
  }

  // Batch insert
  await box.putAll(dataMap);
}
```

#### READ (Sorted by Date)
```dart
// local_storage_service.dart:92-99
List<EarthquakeModel> getEarthquakesSorted() {
  final earthquakes = getAllEarthquakes();
  earthquakes.sort((a, b) {
    if (a.datetime == null || b.datetime == null) return 0;
    return b.datetime!.compareTo(a.datetime!); // Descending
  });
  return earthquakes;
}
```

---

## 🌐 API INTEGRATION

### 1. **BMKG API**
**File:** `lib/services/bmkg_api_service.dart`

#### Endpoints:

| Endpoint | Kegunaan | Response |
|----------|----------|----------|
| `https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4={code}` | Prakiraan cuaca per wilayah | `WeatherModel` |
| `https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json` | Gempa terkini (latest) | `EarthquakeModel` |
| `https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json` | Gempa M≥5.0 | `List<EarthquakeModel>` |
| `https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json` | Gempa yang dirasakan | `List<EarthquakeModel>` |

#### City Mapping (ADM4 Code):
```dart
// bmkg_api_service.dart:18-29
static const Map<String, String> cityToAdm4Code = {
  'Jakarta': '31.74.01.1001',      // Jakarta Pusat - Gambir
  'Yogyakarta': '34.71.01.1001',   // Yogyakarta - Tegalrejo
  'Bandung': '32.73.01.1001',      // Bandung - Sukasari
  'Surabaya': '35.78.01.1001',     // Surabaya - Karang Pilang
  'Semarang': '33.74.01.1001',     // Semarang - Semarang Tengah
  'Medan': '12.71.01.1001',        // Medan - Medan Kota
  // ... dll
};
```

---

### 2. **Open-Meteo API**
**File:** `lib/services/open_meteo_service.dart`

#### Endpoint:
```
https://api.open-meteo.com/v1/forecast
```

#### Parameters:
```dart
{
  'latitude': lat,
  'longitude': lon,
  'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m',
  'hourly': 'temperature_2m,relative_humidity_2m,precipitation_probability,precipitation,weather_code,wind_speed_10m',
  'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max',
  'timezone': 'Asia/Jakarta',
}
```

**Keunggulan:**
- ✅ Free & no API key
- ✅ Data lebih detail (hourly, daily, current)
- ✅ Support koordinat GPS langsung
- ✅ Respons cepat

---

### 3. **USGS API (Earthquake)**
**File:** `lib/services/usgs_api_service.dart`

#### Endpoint:
```
https://earthquake.usgs.gov/fdsnws/event/1/query
```

#### Parameters untuk Indonesia:
```dart
{
  'format': 'geojson',
  'starttime': startDate,
  'endtime': endDate,
  'minlatitude': -11,
  'maxlatitude': 6,
  'minlongitude': 95,
  'maxlongitude': 141,
  'minmagnitude': 2.5,
}
```

**Kegunaan:**
- Data gempa global
- Lebih lengkap detail teknis
- Filter berdasarkan region bounding box

---

## 🎨 STATE MANAGEMENT

### Provider Pattern

**Providers yang Digunakan:**

1. **WeatherProvider** (`lib/providers/weather_provider.dart`)
   - Manage state cuaca
   - Handle API calls
   - Cache management
   - Location detection

2. **EarthquakeProvider** (`lib/providers/earthquake_provider.dart`)
   - Manage state gempa
   - Multi-source data (BMKG + USGS)
   - Sorting & filtering
   - Distance calculation

3. **WatchPointProvider** (`lib/providers/watch_point_provider.dart`)
   - Manage CRUD watch points
   - Geocoding search
   - Nearest city detection

### Registrasi Provider:

```dart
// main.dart:55-60
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => WeatherProvider()),
    ChangeNotifierProvider(create: (_) => EarthquakeProvider()),
    ChangeNotifierProvider(create: (_) => WatchPointProvider()),
  ],
  child: MaterialApp(...),
)
```

### Menggunakan Provider di Widget:

```dart
// Read data (rebuild saat berubah)
final weatherProvider = context.watch<WeatherProvider>();
final temperature = weatherProvider.getCurrentTemperature();

// Read data (tidak rebuild)
final weatherProvider = context.read<WeatherProvider>();

// Akses method
context.read<WeatherProvider>().loadWeather(forceRefresh: true);
```

---

## ⚖️ KELEBIHAN & KEKURANGAN

### ✅ **KELEBIHAN PROJECT**

#### 1. **Arsitektur yang Solid**
- ✅ Menggunakan MVVM pattern dengan Provider
- ✅ Separation of concerns (Model, View, ViewModel, Service)
- ✅ Code reusability tinggi
- ✅ Mudah di-maintain dan di-scale

#### 2. **Offline-First Architecture**
- ✅ Hive untuk local database (fast & reliable)
- ✅ Cache strategy yang baik
- ✅ Aplikasi tetap bisa digunakan tanpa internet
- ✅ Data stale validation

#### 3. **Multi-Source Data**
- ✅ Integrasi BMKG API (sumber resmi Indonesia)
- ✅ Open-Meteo sebagai backup & data lebih detail
- ✅ USGS untuk data gempa global
- ✅ Fallback mechanism jika API gagal

#### 4. **User Experience**
- ✅ Auto-detect lokasi GPS
- ✅ Manual location selection
- ✅ Watch points untuk monitoring multiple lokasi
- ✅ Local notifications
- ✅ Smooth UI dengan loading states

#### 5. **Performance**
- ✅ Hive sangat cepat untuk read/write
- ✅ Cache strategy mengurangi API calls
- ✅ Lazy loading data
- ✅ Type-safe dengan code generation

#### 6. **Security**
- ✅ Data tersimpan lokal (tidak di cloud)
- ✅ Tidak ada personal data yang dikirim ke server
- ✅ Permission handling yang baik

#### 7. **Features**
- ✅ Autentikasi user (login/register)
- ✅ Weather forecast (current, hourly, daily)
- ✅ Earthquake monitoring (3 kategori)
- ✅ Watch points (CRUD)
- ✅ Geocoding & reverse geocoding
- ✅ Distance calculation (Haversine)
- ✅ Multiple unit support (Celsius/Fahrenheit)
- ✅ Settings & preferences

---

### ❌ **KEKURANGAN PROJECT**

#### 1. **Security**
- ❌ **Password disimpan plain text** (tidak di-hash)
  - **Fix:** Gunakan `bcrypt` atau `crypto` untuk hash password
  ```dart
  import 'package:crypto/crypto.dart';
  import 'dart:convert';

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  ```

- ❌ **Tidak ada session management**
  - Tidak ada token expiry
  - Tidak ada auto-logout

#### 2. **API Reliability**
- ❌ BMKG API kadang down/tidak stabil
- ❌ Tidak ada retry mechanism
- ❌ Error handling bisa lebih baik
  - **Fix:** Implementasi exponential backoff retry

#### 3. **Data Validation**
- ❌ Input validation kurang strict
- ❌ Tidak ada sanitization untuk user input
- ❌ Bisa rentan terhadap injection (meskipun Hive relatif aman)

#### 4. **Testing**
- ❌ **Tidak ada unit tests**
- ❌ **Tidak ada widget tests**
- ❌ **Tidak ada integration tests**
  - **Impact:** Sulit detect bug lebih awal
  - **Impact:** Refactoring lebih berisiko

#### 5. **Error Handling**
- ❌ Error messages kurang informatif untuk user
- ❌ Tidak ada logging system
- ❌ Crash analytics tidak ada

#### 6. **Performance Issues Potensial**
- ❌ Semua box dibuka saat startup (bisa lambat jika data banyak)
  - **Fix:** Lazy-load boxes saat dibutuhkan
- ❌ Tidak ada pagination untuk list gempa
  - **Fix:** Implementasi infinite scroll

#### 7. **UX/UI**
- ❌ Tidak ada dark mode (meskipun ada setting theme_mode)
- ❌ Tidak ada multi-language support (meskipun ada setting language)
- ❌ Loading states bisa lebih informatif
- ❌ Tidak ada empty states yang menarik

#### 8. **Code Quality**
- ❌ Beberapa magic numbers & hardcoded values
  ```dart
  // Bad
  final refreshInterval = 30;

  // Better
  static const int DEFAULT_REFRESH_INTERVAL_MINUTES = 30;
  ```
- ❌ Beberapa fungsi terlalu panjang (> 50 lines)
  - **Fix:** Break down menjadi fungsi kecil

#### 9. **Data Synchronization**
- ❌ Tidak ada sync antar device
- ❌ Tidak ada backup & restore
- ❌ Tidak ada export/import data

#### 10. **Weather API Limitation**
- ❌ BMKG API hanya support kota tertentu (mapping manual)
- ❌ Tidak cover semua kota di Indonesia
- ❌ Open-Meteo bisa lebih akurat untuk lokasi GPS

#### 11. **Watch Points**
- ❌ Tidak ada limit berapa banyak watch points
  - **Impact:** Bisa membebani memori
- ❌ Tidak ada sorting options
- ❌ Tidak ada grouping/categorization

#### 12. **Notifications**
- ❌ Tidak ada customizable notification settings per watch point
- ❌ Tidak ada snooze function
- ❌ Tidak ada notification history

#### 13. **Dependencies**
- ❌ Beberapa package sudah cukup lama (bisa outdated)
- ❌ Tidak ada version locking yang strict

---

## 📦 DEPENDENCY

### Production Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI & Design
  cupertino_icons: ^1.0.8          # iOS style icons
  smooth_page_indicator: ^1.1.0    # Page indicator untuk onboarding
  fl_chart: ^0.69.0                # Charts & graphs
  cached_network_image: ^3.4.1     # Image caching

  # State Management
  provider: ^6.1.2                 # State management pattern

  # Local Storage
  hive: ^2.2.3                     # NoSQL database
  hive_flutter: ^1.1.0             # Hive untuk Flutter
  shared_preferences: ^2.2.2       # Key-value storage

  # Network
  http: ^1.2.0                     # HTTP client untuk API calls

  # Location & Maps
  geolocator: ^13.0.2              # GPS location
  geocoding: ^3.0.0                # Geocoding & reverse geocoding

  # Permissions
  permission_handler: ^11.3.1      # Handle permissions

  # Utilities
  intl: ^0.19.0                    # Internationalization & date formatting

  # Notifications
  flutter_local_notifications: ^19.5.0  # Local push notifications
  timezone: ^0.10.1                     # Timezone support

  # Media
  image_picker: ^1.1.2             # Pick image dari galeri/camera

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.8             # Build runner untuk code generation
  hive_generator: ^2.0.1           # Generate Hive adapters

  # Linting
  flutter_lints: ^5.0.0            # Linting rules
```

### Code Generation Commands

```bash
# Generate Hive adapters & JSON serialization
flutter pub run build_runner build

# Watch mode (auto-generate saat file berubah)
flutter pub run build_runner watch

# Clean & rebuild
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📖 CARA RUNNING PROJECT

### 1. Clone & Install Dependencies
```bash
cd xbmkg
flutter pub get
```

### 2. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run App
```bash
flutter run

# Atau untuk specific device
flutter run -d chrome      # Web
flutter run -d emulator-id # Android emulator
```

---

## 🔍 STRUKTUR FILE MODEL HIVE

Semua model Hive menggunakan annotation `@HiveType` dan `@HiveField`:

```dart
import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Generated file

@HiveType(typeId: 0) // Unique typeId untuk setiap model
class UserModel {
  @HiveField(0) // Unique fieldId untuk setiap property
  String username;

  @HiveField(1)
  String password;

  UserModel({
    required this.username,
    required this.password,
  });
}
```

**Generated file:** `user_model.g.dart`
- Dibuat otomatis oleh `hive_generator`
- Jangan edit manual
- Berisi `UserModelAdapter` yang di-register di `main.dart`

---

## 🎯 BEST PRACTICES YANG DITERAPKAN

### 1. **Service Layer Pattern**
- Semua API calls & business logic di service layer
- UI layer tidak tahu detail implementasi

### 2. **Repository Pattern (via LocalStorageService)**
- Abstraksi untuk data access
- Mudah untuk switch implementation

### 3. **Error Handling**
- Try-catch di semua async operations
- Error state di Provider

### 4. **Loading States**
- Setiap Provider punya `isLoading` flag
- UI menampilkan loading indicator

### 5. **Null Safety**
- Full null safety support (Dart ^3.9.0)
- Minimal nullable variables

### 6. **Code Organization**
- Clear folder structure
- Separation of concerns

---

## 🚀 REKOMENDASI IMPROVEMENT

### High Priority:
1. ✅ Hash password dengan bcrypt
2. ✅ Tambahkan unit tests
3. ✅ Implementasi retry mechanism untuk API
4. ✅ Tambahkan error logging (Sentry/Firebase Crashlytics)
5. ✅ Implementasi dark mode

### Medium Priority:
6. ✅ Pagination untuk earthquake list
7. ✅ Backup & restore data
8. ✅ Export data ke CSV/JSON
9. ✅ Notification customization
10. ✅ Multi-language support

### Low Priority:
11. ✅ Widget tests
12. ✅ Integration tests
13. ✅ Better empty states
14. ✅ Onboarding tutorial
15. ✅ Analytics integration

---

## 📝 KESIMPULAN

Project XBMKG adalah aplikasi cuaca & gempa yang well-structured dengan:
- ✅ **Arsitektur solid** (MVVM + Provider)
- ✅ **Offline-first** dengan Hive
- ✅ **Multi-source data** (BMKG, Open-Meteo, USGS)
- ✅ **Feature-rich** (Weather, Earthquake, Watch Points, Auth)

Namun ada beberapa area yang perlu improvement terutama di:
- ❌ Security (password hashing)
- ❌ Testing (unit, widget, integration)
- ❌ Error handling & logging
- ❌ UX improvements (dark mode, multi-language)

Overall, project ini sudah bagus untuk **MVP (Minimum Viable Product)** dan siap untuk dikembangkan lebih lanjut.

---

**Dibuat oleh:** Tim Development XBMKG
**Tanggal:** 2025
**Versi Dokumentasi:** 1.0
