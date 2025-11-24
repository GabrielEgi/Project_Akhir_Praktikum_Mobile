import 'package:geolocator/geolocator.dart';

class LocationService {
  // ---------------------------------------------------------
  // CEK IZIN LOKASI
  // ---------------------------------------------------------
  static Future<bool> isLocationPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ---------------------------------------------------------
  // REQUEST IZIN
  // ---------------------------------------------------------
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  // ---------------------------------------------------------
  // AMBIL POSISI GPS
  // ---------------------------------------------------------
  static Future<Position?> getCurrentPosition() async {
    try {
      // Service lokasi aktif atau tidak
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ GPS dimatikan oleh pengguna");
        return null;
      }

      // Cek izin
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("❌ Izin lokasi ditolak");
        return null;
      }

      // Ambil posisi
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("📍 GPS Position: ${pos.latitude}, ${pos.longitude}");
      return pos;

    } catch (e) {
      print("⚠️ LOCATION ERROR: $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // CARI KOTA TERDEKAT DARI KOORDINAT
  // ---------------------------------------------------------
  static String getNearestCity(double lat, double lon) {
    const cities = {
      "Yogyakarta": [-7.797068, 110.370529],
      "Jakarta": [-6.2088, 106.8456],
      "Bandung": [-6.9175, 107.6191],
      "Surabaya": [-7.2504, 112.7688],
      "Semarang": [-6.9667, 110.4167],
      "Denpasar": [-8.65, 115.2167],
      "Medan": [3.5952, 98.6722],
      "Makassar": [-5.1477, 119.4327],
      "Balikpapan": [-1.2379, 116.8529],
    };

    String nearest = "Yogyakarta";
    double minDistance = double.infinity;

    for (var entry in cities.entries) {
      final cityLat = entry.value[0];
      final cityLon = entry.value[1];

      final distance = Geolocator.distanceBetween(
        lat,
        lon,
        cityLat,
        cityLon,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = entry.key;
      }
    }

    print("📌 Kota terdekat = $nearest (jarak: ${minDistance.toStringAsFixed(0)} m)");
    return nearest;
  }
}
