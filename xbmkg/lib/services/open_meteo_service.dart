import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/open_meteo_model.dart';

class OpenMeteoService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const Duration _timeout = Duration(seconds: 15);

  /// Fetch complete weather data untuk koordinat tertentu
  Future<OpenMeteoWeather?> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
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
          'apparent_temperature',
          'relative_humidity_2m',
          'weather_code',
          'wind_speed_10m',
          'precipitation_probability',
          'precipitation',
          'uv_index',
        ].join(','),
        // Daily forecast (7 hari)
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'sunrise',
          'sunset',
          'precipitation_probability_max',
          'precipitation_sum',
          'uv_index_max',
          'wind_speed_10m_max',
        ].join(','),
        'forecast_days': '7',
      });

      developer.log('Fetching Open-Meteo: $uri', name: 'OpenMeteoService');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OpenMeteoWeather.fromJson(data);
      } else {
        developer.log(
          'Open-Meteo error: ${response.statusCode} - ${response.body}',
          name: 'OpenMeteoService',
        );
        return null;
      }
    } catch (e) {
      developer.log('Open-Meteo exception: $e', name: 'OpenMeteoService');
      return null;
    }
  }

  /// Get wind direction as text (e.g., "Utara", "Timur Laut")
  static String getWindDirectionText(int? degrees) {
    if (degrees == null) return '-';

    const directions = [
      'U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'
    ];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Get UV Index level description
  static String getUvIndexLevel(double? uvIndex) {
    if (uvIndex == null) return '-';
    if (uvIndex < 3) return 'Rendah';
    if (uvIndex < 6) return 'Sedang';
    if (uvIndex < 8) return 'Tinggi';
    if (uvIndex < 11) return 'Sangat Tinggi';
    return 'Ekstrem';
  }

  /// Get UV Index color
  static int getUvIndexColor(double? uvIndex) {
    if (uvIndex == null) return 0xFF9E9E9E; // grey
    if (uvIndex < 3) return 0xFF4CAF50; // green
    if (uvIndex < 6) return 0xFFFFEB3B; // yellow
    if (uvIndex < 8) return 0xFFFF9800; // orange
    if (uvIndex < 11) return 0xFFF44336; // red
    return 0xFF9C27B0; // purple
  }
}
