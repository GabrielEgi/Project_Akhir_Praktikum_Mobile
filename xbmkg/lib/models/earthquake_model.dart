import 'package:hive/hive.dart';

part 'earthquake_model.g.dart';

@HiveType(typeId: 2)
class EarthquakeModel extends HiveObject {
  @HiveField(0)
  final String? date;
  
  @HiveField(1)
  final String? time;
  
  @HiveField(2)
  final DateTime? datetime;
  
  @HiveField(3)
  final double? magnitude;
  
  @HiveField(4)
  final int? depth;
  
  @HiveField(5)
  final String? region;
  
  @HiveField(6)
  final double? latitude;
  
  @HiveField(7)
  final double? longitude;
  
  @HiveField(8)
  final String? potential;
  
  @HiveField(9)
  final String? felt;
  
  @HiveField(10)
  final String? shakemapUrl;

  EarthquakeModel({
    this.date,
    this.time,
    this.datetime,
    this.magnitude,
    this.depth,
    this.region,
    this.latitude,
    this.longitude,
    this.potential,
    this.felt,
    this.shakemapUrl,
  });

  factory EarthquakeModel.fromJson(Map<String, dynamic> json) {
    // Parse coordinates from string like "-9.47,116.53"
    double? lat;
    double? lon;

    // BMKG API uses 'Coordinates' (capital C)
    final coordsStr = json['Coordinates'] ?? json['coordinates'];
    if (coordsStr != null) {
      final coords = coordsStr.toString().split(',');
      if (coords.length == 2) {
        lat = double.tryParse(coords[0].trim());
        lon = double.tryParse(coords[1].trim());
      }
    }

    // Fallback: parse from Lintang/Bujur fields
    if (lat == null && json['Lintang'] != null) {
      final latStr = json['Lintang'].toString();
      final latValue = double.tryParse(latStr.replaceAll(RegExp(r'[^0-9.]'), ''));
      lat = latStr.contains('LS') ? -(latValue ?? 0) : latValue;
    }
    if (lon == null && json['Bujur'] != null) {
      final lonStr = json['Bujur'].toString();
      lon = double.tryParse(lonStr.replaceAll(RegExp(r'[^0-9.]'), ''));
    }

    // Parse datetime from DateTime field or construct from Tanggal + Jam
    DateTime? dt;
    if (json['DateTime'] != null) {
      dt = DateTime.tryParse(json['DateTime']);
    }
    if (dt == null) {
      final dateStr = json['Tanggal'] ?? json['tanggal'];
      final timeStr = json['Jam'] ?? json['jam'];
      if (dateStr != null && timeStr != null) {
        dt = DateTime.now(); // Fallback, actual parsing would need proper format
      }
    }

    // Parse depth - remove "km" suffix
    final depthStr = (json['Kedalaman'] ?? json['kedalaman'])?.toString() ?? '0';
    final depth = int.tryParse(depthStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // Parse magnitude
    final magStr = (json['Magnitude'] ?? json['magnitude'])?.toString() ?? '0';
    final magnitude = double.tryParse(magStr) ?? 0.0;

    return EarthquakeModel(
      date: json['Tanggal'] ?? json['tanggal'],
      time: json['Jam'] ?? json['jam'],
      datetime: dt,
      magnitude: magnitude,
      depth: depth,
      region: json['Wilayah'] ?? json['wilayah'] ?? json['area'],
      latitude: lat,
      longitude: lon,
      potential: json['Potensi'] ?? json['potensi'],
      felt: json['Dirasakan'] ?? json['dirasakan'],
      shakemapUrl: json['Shakemap'] ?? json['shakemap'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'time': time,
      'datetime': datetime?.toIso8601String(),
      'magnitude': magnitude,
      'depth': depth,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'potential': potential,
      'felt': felt,
      'shakemapUrl': shakemapUrl,
    };
  }

  String getMagnitudeCategory() {
    if (magnitude == null) return 'Tidak Diketahui';
    
    if (magnitude! < 3.0) return 'Mikro';
    if (magnitude! < 4.0) return 'Minor';
    if (magnitude! < 5.0) return 'Ringan';
    if (magnitude! < 6.0) return 'Sedang';
    if (magnitude! < 7.0) return 'Kuat';
    if (magnitude! < 8.0) return 'Mayor';
    return 'Sangat Besar';
  }

  String getMagnitudeColor() {
    if (magnitude == null) return '#9E9E9E';
    
    if (magnitude! < 3.0) return '#4CAF50';
    if (magnitude! < 4.0) return '#8BC34A';
    if (magnitude! < 5.0) return '#FFC107';
    if (magnitude! < 6.0) return '#FF9800';
    if (magnitude! < 7.0) return '#FF5722';
    return '#F44336';
  }
}