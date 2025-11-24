import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/watch_point_model.dart';
import '../models/weather_model.dart';
import '../services/bmkg_api_service.dart';

class _DailyForecastData {
  final DateTime? datetime;
  final String? weather;
  final double? minTemp;
  final double? maxTemp;

  _DailyForecastData({
    this.datetime,
    this.weather,
    this.minTemp,
    this.maxTemp,
  });
}

class WatchPointDetailScreen extends StatefulWidget {
  final WatchPointModel watchPoint;

  const WatchPointDetailScreen({super.key, required this.watchPoint});

  @override
  State<WatchPointDetailScreen> createState() => _WatchPointDetailScreenState();
}

class _WatchPointDetailScreenState extends State<WatchPointDetailScreen> {
  final BmkgApiService _apiService = BmkgApiService();

  WeatherModel? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Gunakan nearestCity untuk fetch cuaca
      final cityName = widget.watchPoint.nearestCity ?? 'Yogyakarta';
      final weather = await _apiService.getWeatherForecast(cityName);

      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data cuaca: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF), // BMKG soft blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8), // BMKG blue
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'WeatherNews EXBMKG',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          
        ),
         actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeather,
          ),
        ],
      ),
   
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationHeader(),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _buildErrorWidget()
              else if (_weather != null) ...[
                _buildCurrentWeather(),
                _buildHourlyForecast(),
                _buildTemperatureChart(),
                _buildDailyForecast(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade400,
            Colors.teal.shade700,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.watchPoint.address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                Icons.cloud,
                'Data cuaca: ${widget.watchPoint.nearestCity ?? '-'}',
              ),
            ],
          ),
          if (widget.watchPoint.description != null &&
              widget.watchPoint.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.watchPoint.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final forecasts = _weather?.forecasts ?? [];
    if (forecasts.isEmpty) return const SizedBox();

    // Get current forecast (closest to now)
    final now = DateTime.now();
    WeatherData? currentForecast;

    for (var forecast in forecasts) {
      if (forecast.datetime == null) continue;
      if (forecast.datetime!.isAfter(now.subtract(const Duration(hours: 3))) &&
          forecast.datetime!.isBefore(now.add(const Duration(hours: 3)))) {
        currentForecast = forecast;
        break;
      }
    }

    currentForecast ??= forecasts.first;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cuaca Saat Ini',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('HH:mm', 'id_ID').format(DateTime.now()),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                // Weather Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getWeatherEmoji(currentForecast.weather),
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(width: 20),
                // Temperature & Condition
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentForecast.temperature?.toStringAsFixed(0) ?? '-'}°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentForecast.weather ?? 'Tidak diketahui',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Additional Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherStat(
                  Icons.water_drop,
                  'Kelembapan',
                  '${currentForecast.humidity ?? '-'}%',
                  Colors.blue,
                ),
                _buildWeatherStat(
                  Icons.air,
                  'Angin',
                  '${currentForecast.windSpeed?.toStringAsFixed(0) ?? '-'} km/j',
                  Colors.teal,
                ),
                _buildWeatherStat(
                  Icons.explore,
                  'Arah',
                  currentForecast.windDirection ?? '-',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    final forecasts = _weather?.forecasts ?? [];
    if (forecasts.isEmpty) return const SizedBox();

    // Get upcoming forecasts (next 24 hours)
    final now = DateTime.now();
    final upcomingForecasts = forecasts.where((f) {
      if (f.datetime == null) return false;
      return f.datetime!.isAfter(now.subtract(const Duration(hours: 1)));
    }).take(8).toList();

    if (upcomingForecasts.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prakiraan Per Jam',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingForecasts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final forecast = upcomingForecasts[index];
                  return _buildHourlyItem(forecast);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyItem(WeatherData forecast) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            forecast.datetime != null
                ? DateFormat('HH:mm').format(forecast.datetime!)
                : '-',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            _getWeatherEmoji(forecast.weather),
            style: const TextStyle(fontSize: 22),
          ),
          Text(
            '${forecast.temperature?.toStringAsFixed(0) ?? '-'}°',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    final forecasts = _weather?.forecasts ?? [];
    if (forecasts.isEmpty) return const SizedBox();

    // Get next 24 hours data
    final now = DateTime.now();
    final chartData = forecasts.where((f) {
      if (f.datetime == null || f.temperature == null) return false;
      return f.datetime!.isAfter(now.subtract(const Duration(hours: 1)));
    }).take(8).toList();

    if (chartData.length < 2) return const SizedBox();

    // Calculate min/max for scaling
    final temps = chartData.map((f) => f.temperature!).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final tempRange = maxTemp - minTemp;
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Suhu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Temperature summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTempSummary('Min', minTemp, Colors.blue),
                _buildTempSummary('Rata-rata', avgTemp, Colors.orange),
                _buildTempSummary('Max', maxTemp, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            // Simple bar chart
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chartData.map((forecast) {
                  final temp = forecast.temperature!;
                  final normalizedHeight = tempRange > 0
                      ? ((temp - minTemp) / tempRange * 0.7 + 0.3)
                      : 0.5;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${temp.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 80 * normalizedHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.blue.shade300,
                                  _getTempColor(temp),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            forecast.datetime != null
                                ? DateFormat('HH').format(forecast.datetime!)
                                : '-',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempSummary(String label, double temp, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${temp.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getTempColor(double temp) {
    if (temp < 20) return Colors.blue;
    if (temp < 25) return Colors.cyan;
    if (temp < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDailyForecast() {
    final forecasts = _weather?.forecasts ?? [];
    if (forecasts.isEmpty) return const SizedBox();

    // Group by day - collect all forecasts per day to get min/max temp
    final Map<String, List<WeatherData>> dailyMap = {};

    for (var forecast in forecasts) {
      if (forecast.datetime == null) continue;

      final dateKey =
          '${forecast.datetime!.year}-${forecast.datetime!.month.toString().padLeft(2, '0')}-${forecast.datetime!.day.toString().padLeft(2, '0')}';

      dailyMap.putIfAbsent(dateKey, () => []);
      dailyMap[dateKey]!.add(forecast);
    }

    // Sort by date and take 7 days
    final sortedKeys = dailyMap.keys.toList()..sort();
    final dailyForecasts = sortedKeys.take(7).map((key) {
      final dayForecasts = dailyMap[key]!;

      // Get noon forecast for weather condition, or first available
      final noonForecast = dayForecasts.firstWhere(
        (f) => f.datetime?.hour == 12,
        orElse: () => dayForecasts.first,
      );

      // Calculate min/max temp for the day
      final temps = dayForecasts
          .where((f) => f.temperature != null)
          .map((f) => f.temperature!)
          .toList();

      double? minTemp;
      double? maxTemp;
      if (temps.isNotEmpty) {
        minTemp = temps.reduce((a, b) => a < b ? a : b);
        maxTemp = temps.reduce((a, b) => a > b ? a : b);
      }

      return _DailyForecastData(
        datetime: noonForecast.datetime,
        weather: noonForecast.weather,
        minTemp: minTemp,
        maxTemp: maxTemp,
      );
    }).toList();

    if (dailyForecasts.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prakiraan 7 Hari',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...dailyForecasts.map((data) => _buildDailyItem(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyItem(_DailyForecastData data) {
    final isToday = data.datetime != null &&
        data.datetime!.day == DateTime.now().day &&
        data.datetime!.month == DateTime.now().month;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              data.datetime != null
                  ? (isToday
                      ? 'Hari ini'
                      : DateFormat('EEE, d/M', 'id_ID').format(data.datetime!))
                  : '-',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            _getWeatherEmoji(data.weather),
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.weather ?? '-',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Min/Max temperature
          Row(
            children: [
              Text(
                '${data.minTemp?.toStringAsFixed(0) ?? '-'}°',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 13,
                ),
              ),
              const Text(' / ', style: TextStyle(fontSize: 13)),
              Text(
                '${data.maxTemp?.toStringAsFixed(0) ?? '-'}°',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeatherEmoji(String? weather) {
    if (weather == null) return '🌤️';

    final lowerWeather = weather.toLowerCase();

    if (lowerWeather.contains('cerah') && !lowerWeather.contains('berawan')) {
      return '☀️';
    } else if (lowerWeather.contains('cerah berawan')) {
      return '🌤️';
    } else if (lowerWeather.contains('berawan tebal')) {
      return '☁️';
    } else if (lowerWeather.contains('berawan')) {
      return '⛅';
    } else if (lowerWeather.contains('hujan ringan')) {
      return '🌦️';
    } else if (lowerWeather.contains('hujan sedang')) {
      return '🌧️';
    } else if (lowerWeather.contains('hujan lebat') ||
        lowerWeather.contains('hujan petir')) {
      return '⛈️';
    } else if (lowerWeather.contains('hujan')) {
      return '🌧️';
    } else if (lowerWeather.contains('kabut')) {
      return '🌫️';
    } else if (lowerWeather.contains('asap')) {
      return '😶‍🌫️';
    }

    return '🌤️';
  }
}
