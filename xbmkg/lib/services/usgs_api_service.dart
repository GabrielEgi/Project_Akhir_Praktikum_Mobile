import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/earthquake_model.dart';

class UsgsApiService {
  // Base URL for USGS Earthquake API
  static const String baseUrl = 'https://earthquake.usgs.gov/fdsnws/event/1';

  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Fetch earthquakes from USGS with custom parameters
  ///
  /// Parameters:
  /// - [startTime]: Start time for the search (ISO8601 format or YYYY-MM-DD)
  /// - [endTime]: End time for the search (ISO8601 format or YYYY-MM-DD)
  /// - [minMagnitude]: Minimum earthquake magnitude (default: 4.5)
  /// - [maxMagnitude]: Maximum earthquake magnitude
  /// - [minLatitude]: Minimum latitude for bounding box
  /// - [maxLatitude]: Maximum latitude for bounding box
  /// - [minLongitude]: Minimum longitude for bounding box
  /// - [maxLongitude]: Maximum longitude for bounding box
  /// - [limit]: Maximum number of results (default: 100, max: 20000)
  /// - [orderBy]: Order results by 'time', 'time-asc', 'magnitude', or 'magnitude-asc'
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
    try {
      final queryParams = <String, String>{
        'format': 'geojson',
        'limit': limit.toString(),
        'orderby': orderBy,
      };

      if (startTime != null) queryParams['starttime'] = startTime;
      if (endTime != null) queryParams['endtime'] = endTime;
      if (minMagnitude != null) queryParams['minmagnitude'] = minMagnitude.toString();
      if (maxMagnitude != null) queryParams['maxmagnitude'] = maxMagnitude.toString();
      if (minLatitude != null) queryParams['minlatitude'] = minLatitude.toString();
      if (maxLatitude != null) queryParams['maxlatitude'] = maxLatitude.toString();
      if (minLongitude != null) queryParams['minlongitude'] = minLongitude.toString();
      if (maxLongitude != null) queryParams['maxlongitude'] = maxLongitude.toString();

      final uri = Uri.parse('$baseUrl/query').replace(queryParameters: queryParams);

      developer.log('Fetching USGS earthquakes: $uri', name: 'UsgsApiService');

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null) {
          final features = data['features'] as List;
          return features.map((feature) => _parseUsgsFeature(feature)).toList();
        }

        return [];
      } else {
        throw Exception('Failed to load USGS earthquake data: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching USGS earthquakes: $e', name: 'UsgsApiService');
      return [];
    }
  }

  /// Fetch recent significant earthquakes (M≥4.5) from the last 7 days
  Future<List<EarthquakeModel>> getRecentSignificantEarthquakes() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return await getEarthquakes(
      startTime: sevenDaysAgo.toIso8601String(),
      endTime: now.toIso8601String(),
      minMagnitude: 4.5,
      limit: 100,
      orderBy: 'time',
    );
  }

  /// Fetch earthquakes in Indonesia region
  Future<List<EarthquakeModel>> getIndonesiaEarthquakes({
    int days = 7,
    double minMagnitude = 2.5,
  }) async {
    final now = DateTime.now();
    final startTime = now.subtract(Duration(days: days));

    // Indonesia bounding box: approximately -11° to 6° latitude, 95° to 141° longitude
    return await getEarthquakes(
      startTime: startTime.toIso8601String(),
      endTime: now.toIso8601String(),
      minLatitude: -11.0,
      maxLatitude: 6.0,
      minLongitude: 95.0,
      maxLongitude: 141.0,
      minMagnitude: minMagnitude,
      limit: 200,
      orderBy: 'time',
    );
  }

  /// Fetch earthquakes today
  Future<List<EarthquakeModel>> getTodayEarthquakes({double minMagnitude = 2.5}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return await getEarthquakes(
      startTime: today.toIso8601String(),
      endTime: now.toIso8601String(),
      minMagnitude: minMagnitude,
      limit: 100,
      orderBy: 'time',
    );
  }

  /// Fetch major earthquakes (M≥6.0) from the last 30 days
  Future<List<EarthquakeModel>> getMajorEarthquakes() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return await getEarthquakes(
      startTime: thirtyDaysAgo.toIso8601String(),
      endTime: now.toIso8601String(),
      minMagnitude: 6.0,
      limit: 100,
      orderBy: 'time',
    );
  }

  /// Get application metadata
  Future<Map<String, dynamic>?> getApplicationMetadata() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/application.json')
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching USGS metadata: $e', name: 'UsgsApiService');
      return null;
    }
  }

  /// Parse USGS GeoJSON feature to EarthquakeModel
  EarthquakeModel _parseUsgsFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] ?? {};
    final geometry = feature['geometry'] ?? {};
    final coordinates = geometry['coordinates'] as List?;

    // Extract data
    final longitude = coordinates != null && coordinates.isNotEmpty
        ? (coordinates[0] as num?)?.toDouble()
        : null;
    final latitude = coordinates != null && coordinates.length > 1
        ? (coordinates[1] as num?)?.toDouble()
        : null;
    final depth = coordinates != null && coordinates.length > 2
        ? (coordinates[2] as num?)?.toDouble().toInt()
        : null;

    final magnitude = (properties['mag'] as num?)?.toDouble();
    final place = properties['place'] as String?;
    final time = properties['time'] as int?;
    final felt = properties['felt'] as int?;
    final tsunami = properties['tsunami'] as int?;

    // Convert timestamp to DateTime
    final datetime = time != null
        ? DateTime.fromMillisecondsSinceEpoch(time)
        : null;

    // Format date and time
    final date = datetime != null
        ? '${datetime.day.toString().padLeft(2, '0')}-${datetime.month.toString().padLeft(2, '0')}-${datetime.year}'
        : null;
    final timeStr = datetime != null
        ? '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}:${datetime.second.toString().padLeft(2, '0')} UTC'
        : null;

    // Determine potential tsunami
    String? potential;
    if (tsunami != null && tsunami > 0) {
      potential = 'Berpotensi Tsunami';
    } else if (magnitude != null && magnitude >= 6.5) {
      potential = 'Tidak berpotensi tsunami';
    }

    // Format felt info
    String? feltStr;
    if (felt != null && felt > 0) {
      feltStr = 'Dirasakan oleh $felt orang';
    }

    return EarthquakeModel(
      date: date,
      time: timeStr,
      datetime: datetime,
      magnitude: magnitude,
      depth: depth,
      region: place ?? 'Unknown Location',
      latitude: latitude,
      longitude: longitude,
      potential: potential,
      felt: feltStr,
      shakemapUrl: null, // USGS uses different shakemap system
    );
  }
}
