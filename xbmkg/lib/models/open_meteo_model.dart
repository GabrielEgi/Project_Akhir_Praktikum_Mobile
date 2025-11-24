/// Model untuk response dari Open-Meteo API
class OpenMeteoWeather {
  final CurrentWeather current;
  final HourlyForecast hourly;
  final DailyForecast daily;

  OpenMeteoWeather({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory OpenMeteoWeather.fromJson(Map<String, dynamic> json) {
    return OpenMeteoWeather(
      current: CurrentWeather.fromJson(json['current'] ?? {}),
      hourly: HourlyForecast.fromJson(json['hourly'] ?? {}),
      daily: DailyForecast.fromJson(json['daily'] ?? {}),
    );
  }
}

class CurrentWeather {
  final DateTime? time;
  final double? temperature;
  final double? apparentTemperature;
  final int? humidity;
  final int? weatherCode;
  final double? windSpeed;
  final int? windDirection;
  final double? uvIndex;
  final int? cloudCover;
  final double? precipitation;
  final int? isDay;

  CurrentWeather({
    this.time,
    this.temperature,
    this.apparentTemperature,
    this.humidity,
    this.weatherCode,
    this.windSpeed,
    this.windDirection,
    this.uvIndex,
    this.cloudCover,
    this.precipitation,
    this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: json['time'] != null ? DateTime.tryParse(json['time']) : null,
      temperature: (json['temperature_2m'] as num?)?.toDouble(),
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble(),
      humidity: json['relative_humidity_2m'] as int?,
      weatherCode: json['weather_code'] as int?,
      windSpeed: (json['wind_speed_10m'] as num?)?.toDouble(),
      windDirection: json['wind_direction_10m'] as int?,
      uvIndex: (json['uv_index'] as num?)?.toDouble(),
      cloudCover: json['cloud_cover'] as int?,
      precipitation: (json['precipitation'] as num?)?.toDouble(),
      isDay: json['is_day'] as int?,
    );
  }

  String get weatherDescription => _getWeatherDescription(weatherCode);
  String get weatherEmoji => _getWeatherEmoji(weatherCode, isDay == 1);

  static String _getWeatherDescription(int? code) {
    if (code == null) return 'Tidak diketahui';
    return switch (code) {
      0 => 'Cerah',
      1 => 'Cerah Berawan',
      2 => 'Berawan Sebagian',
      3 => 'Berawan',
      45 || 48 => 'Berkabut',
      51 || 53 || 55 => 'Gerimis',
      56 || 57 => 'Gerimis Beku',
      61 || 63 || 65 => 'Hujan',
      66 || 67 => 'Hujan Beku',
      71 || 73 || 75 => 'Hujan Salju',
      77 => 'Butiran Salju',
      80 || 81 || 82 => 'Hujan Lebat',
      85 || 86 => 'Hujan Salju Lebat',
      95 => 'Badai Petir',
      96 || 99 => 'Badai Petir & Hujan Es',
      _ => 'Tidak diketahui',
    };
  }

  static String _getWeatherEmoji(int? code, bool isDay) {
    if (code == null) return '🌤️';
    return switch (code) {
      0 => isDay ? '☀️' : '🌙',
      1 => isDay ? '🌤️' : '🌙',
      2 => '⛅',
      3 => '☁️',
      45 || 48 => '🌫️',
      51 || 53 || 55 => '🌦️',
      56 || 57 => '🌧️❄️',
      61 || 63 || 65 => '🌧️',
      66 || 67 => '🌧️❄️',
      71 || 73 || 75 => '🌨️',
      77 => '❄️',
      80 || 81 || 82 => '🌧️',
      85 || 86 => '🌨️',
      95 => '⛈️',
      96 || 99 => '⛈️',
      _ => '🌤️',
    };
  }
}

class HourlyForecast {
  final List<DateTime> time;
  final List<double?> temperature;
  final List<double?> apparentTemperature;
  final List<int?> humidity;
  final List<int?> weatherCode;
  final List<double?> windSpeed;
  final List<int?> precipitationProbability;
  final List<double?> precipitation;
  final List<double?> uvIndex;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.weatherCode,
    required this.windSpeed,
    required this.precipitationProbability,
    required this.precipitation,
    required this.uvIndex,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final timeList = (json['time'] as List<dynamic>?)
            ?.map((t) => DateTime.tryParse(t.toString()) ?? DateTime.now())
            .toList() ??
        [];

    return HourlyForecast(
      time: timeList,
      temperature: _parseDoubleList(json['temperature_2m']),
      apparentTemperature: _parseDoubleList(json['apparent_temperature']),
      humidity: _parseIntList(json['relative_humidity_2m']),
      weatherCode: _parseIntList(json['weather_code']),
      windSpeed: _parseDoubleList(json['wind_speed_10m']),
      precipitationProbability: _parseIntList(json['precipitation_probability']),
      precipitation: _parseDoubleList(json['precipitation']),
      uvIndex: _parseDoubleList(json['uv_index']),
    );
  }

  int get length => time.length;

  HourlyData getHour(int index) {
    return HourlyData(
      time: time[index],
      temperature: temperature.elementAtOrNull(index),
      apparentTemperature: apparentTemperature.elementAtOrNull(index),
      humidity: humidity.elementAtOrNull(index),
      weatherCode: weatherCode.elementAtOrNull(index),
      windSpeed: windSpeed.elementAtOrNull(index),
      precipitationProbability: precipitationProbability.elementAtOrNull(index),
      precipitation: precipitation.elementAtOrNull(index),
      uvIndex: uvIndex.elementAtOrNull(index),
    );
  }
}

class HourlyData {
  final DateTime time;
  final double? temperature;
  final double? apparentTemperature;
  final int? humidity;
  final int? weatherCode;
  final double? windSpeed;
  final int? precipitationProbability;
  final double? precipitation;
  final double? uvIndex;

  HourlyData({
    required this.time,
    this.temperature,
    this.apparentTemperature,
    this.humidity,
    this.weatherCode,
    this.windSpeed,
    this.precipitationProbability,
    this.precipitation,
    this.uvIndex,
  });

  String get weatherEmoji => CurrentWeather._getWeatherEmoji(weatherCode, time.hour >= 6 && time.hour < 18);
  String get weatherDescription => CurrentWeather._getWeatherDescription(weatherCode);
}

class DailyForecast {
  final List<DateTime> time;
  final List<int?> weatherCode;
  final List<double?> temperatureMax;
  final List<double?> temperatureMin;
  final List<DateTime?> sunrise;
  final List<DateTime?> sunset;
  final List<int?> precipitationProbabilityMax;
  final List<double?> precipitationSum;
  final List<double?> uvIndexMax;
  final List<double?> windSpeedMax;

  DailyForecast({
    required this.time,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.sunrise,
    required this.sunset,
    required this.precipitationProbabilityMax,
    required this.precipitationSum,
    required this.uvIndexMax,
    required this.windSpeedMax,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      time: (json['time'] as List<dynamic>?)
              ?.map((t) => DateTime.tryParse(t.toString()) ?? DateTime.now())
              .toList() ??
          [],
      weatherCode: _parseIntList(json['weather_code']),
      temperatureMax: _parseDoubleList(json['temperature_2m_max']),
      temperatureMin: _parseDoubleList(json['temperature_2m_min']),
      sunrise: (json['sunrise'] as List<dynamic>?)
              ?.map((t) => DateTime.tryParse(t.toString()))
              .toList() ??
          [],
      sunset: (json['sunset'] as List<dynamic>?)
              ?.map((t) => DateTime.tryParse(t.toString()))
              .toList() ??
          [],
      precipitationProbabilityMax: _parseIntList(json['precipitation_probability_max']),
      precipitationSum: _parseDoubleList(json['precipitation_sum']),
      uvIndexMax: _parseDoubleList(json['uv_index_max']),
      windSpeedMax: _parseDoubleList(json['wind_speed_10m_max']),
    );
  }

  int get length => time.length;

  DailyData getDay(int index) {
    return DailyData(
      time: time[index],
      weatherCode: weatherCode.elementAtOrNull(index),
      temperatureMax: temperatureMax.elementAtOrNull(index),
      temperatureMin: temperatureMin.elementAtOrNull(index),
      sunrise: sunrise.elementAtOrNull(index),
      sunset: sunset.elementAtOrNull(index),
      precipitationProbabilityMax: precipitationProbabilityMax.elementAtOrNull(index),
      precipitationSum: precipitationSum.elementAtOrNull(index),
      uvIndexMax: uvIndexMax.elementAtOrNull(index),
      windSpeedMax: windSpeedMax.elementAtOrNull(index),
    );
  }
}

class DailyData {
  final DateTime time;
  final int? weatherCode;
  final double? temperatureMax;
  final double? temperatureMin;
  final DateTime? sunrise;
  final DateTime? sunset;
  final int? precipitationProbabilityMax;
  final double? precipitationSum;
  final double? uvIndexMax;
  final double? windSpeedMax;

  DailyData({
    required this.time,
    this.weatherCode,
    this.temperatureMax,
    this.temperatureMin,
    this.sunrise,
    this.sunset,
    this.precipitationProbabilityMax,
    this.precipitationSum,
    this.uvIndexMax,
    this.windSpeedMax,
  });

  String get weatherEmoji => CurrentWeather._getWeatherEmoji(weatherCode, true);
  String get weatherDescription => CurrentWeather._getWeatherDescription(weatherCode);
}

// Helper functions
List<double?> _parseDoubleList(dynamic list) {
  if (list == null) return [];
  return (list as List).map((e) => (e as num?)?.toDouble()).toList();
}

List<int?> _parseIntList(dynamic list) {
  if (list == null) return [];
  return (list as List).map((e) => e as int?).toList();
}
