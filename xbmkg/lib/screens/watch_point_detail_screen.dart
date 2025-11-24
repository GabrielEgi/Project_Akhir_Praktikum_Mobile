import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/watch_point_model.dart';
import '../models/open_meteo_model.dart';
import '../services/open_meteo_service.dart';

class WatchPointDetailScreen extends StatefulWidget {
  final WatchPointModel watchPoint;

  const WatchPointDetailScreen({super.key, required this.watchPoint});

  @override
  State<WatchPointDetailScreen> createState() => _WatchPointDetailScreenState();
}

class _WatchPointDetailScreenState extends State<WatchPointDetailScreen> {
  final OpenMeteoService _weatherService = OpenMeteoService();
  OpenMeteoWeather? _weather;
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

    final weather = await _weatherService.getWeather(
      latitude: widget.watchPoint.latitude,
      longitude: widget.watchPoint.longitude,
    );

    setState(() {
      _weather = weather;
      _isLoading = false;
      if (weather == null) _error = 'Gagal memuat data cuaca';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Cuaca',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeather,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
      );
    }

    if (_error != null || _weather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Tidak ada data'),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
              ),
              onPressed: _loadWeather,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1A73E8),
      onRefresh: _loadWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentWeather(),
            const SizedBox(height: 20),
            _buildHourlyForecast(),
            const SizedBox(height: 24),
            _buildTemperatureChart(),
            const SizedBox(height: 24),
            _buildWeeklyForecast(),
            const SizedBox(height: 24),
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // CURRENT WEATHER (HEADER CARD)
  // -------------------------------------------------------------------
  Widget _buildCurrentWeather() {
    final current = _weather!.current;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.watchPoint.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${current.temperature?.round() ?? '--'}°C',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            current.weatherDescription,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // HOURLY FORECAST (SCROLL CARD)
  // -------------------------------------------------------------------
  Widget _buildHourlyForecast() {
    final hourly = _weather!.hourly;
    final now = DateTime.now();
    final startIndex = hourly.time.indexWhere(
      (t) => t.isAfter(now.subtract(const Duration(hours: 1))),
    );
    if (startIndex == -1) return const SizedBox.shrink();

    final itemCount = 12.clamp(0, hourly.length - startIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prakiraan Per Jam',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final data = hourly.getHour(startIndex + index);
              final isNow = index == 0;

              return Container(
                width: 75,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: isNow
                      ? const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isNow ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: isNow ? 8 : 4,
                      spreadRadius: isNow ? 2 : 1,
                      offset: const Offset(0, 2),
                      color: isNow
                          ? const Color(0xFF1E88E5).withValues(alpha: 0.4)
                          : Colors.black12.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      isNow ? 'Sekarang' : DateFormat('HH:mm').format(data.time),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                        color: isNow ? Colors.white : Colors.grey,
                      ),
                    ),
                    Text(
                      data.weatherEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                    Text(
                      '${data.temperature?.round() ?? '-'}°',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isNow ? Colors.white : const Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // TEMPERATURE CHART
  // -------------------------------------------------------------------
  Widget _buildTemperatureChart() {
    final hourly = _weather!.hourly;
    final now = DateTime.now();
    final startIndex = hourly.time.indexWhere(
      (t) => t.isAfter(now.subtract(const Duration(hours: 1))),
    );
    if (startIndex == -1) return const SizedBox.shrink();

    final chartCount = 12.clamp(0, hourly.length - startIndex);
    final List<HourlyData> chartData = [];

    for (var i = 0; i < chartCount; i++) {
      final data = hourly.getHour(startIndex + i);
      if (data.temperature != null) {
        chartData.add(data);
      }
    }

    if (chartData.isEmpty) return const SizedBox.shrink();

    final temps = chartData.map((d) => d.temperature!).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Temperatur Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 12),
            // Temperature summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTempSummary('Terendah', minTemp, Colors.blue),
                _buildTempSummary('Rata-rata', avgTemp, Colors.orange),
                _buildTempSummary('Tertinggi', maxTemp, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Perubahan suhu per jam (°C)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: (minTemp - 2).floorToDouble(),
                  maxY: (maxTemp + 2).ceilToDouble(),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Waktu',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= chartData.length) {
                            return const SizedBox.shrink();
                          }
                          if (idx % 2 != 0 && chartData.length > 4) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('HH:mm').format(chartData[idx].time),
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        '°C',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.temperature ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF1E88E5),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF42A5F5).withValues(alpha: 0.3),
                            const Color(0xFF42A5F5).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final data = chartData[idx];
                          return LineTooltipItem(
                            '${DateFormat('HH:mm').format(data.time)}\n${spot.y.toStringAsFixed(1)}°C',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
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
        Icon(
          label == 'Terendah'
              ? Icons.arrow_downward
              : label == 'Tertinggi'
                  ? Icons.arrow_upward
                  : Icons.thermostat,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          '${temp.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // WEEKLY FORECAST
  // -------------------------------------------------------------------
  Widget _buildWeeklyForecast() {
    final daily = _weather!.daily;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prakiraan 7 Hari',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(daily.length.clamp(0, 7), (i) {
          final data = daily.getDay(i);
          final isToday = i == 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isToday ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  blurRadius: isToday ? 8 : 4,
                  spreadRadius: isToday ? 1 : 0,
                  offset: const Offset(0, 2),
                  color: isToday
                      ? const Color(0xFF1E88E5).withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Text(
                data.weatherEmoji,
                style: const TextStyle(fontSize: 36),
              ),
              title: Text(
                isToday ? 'Hari Ini' : DateFormat('EEEE, d MMM', 'id_ID').format(data.time),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Row(
                children: [
                  Flexible(
                    child: Text(
                      data.weatherDescription,
                      style: TextStyle(
                        color: isToday ? Colors.white70 : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (data.precipitationProbabilityMax != null &&
                      data.precipitationProbabilityMax! > 0) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.water_drop,
                      size: 14,
                      color: isToday ? Colors.white70 : Colors.blue.shade300,
                    ),
                    Text(
                      ' ${data.precipitationProbabilityMax}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.white70 : Colors.blue.shade400,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.temperatureMax?.round() ?? '-'}°',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : const Color(0xFF1E88E5),
                    ),
                  ),
                  Text(
                    '${data.temperatureMin?.round() ?? '-'}°',
                    style: TextStyle(
                      fontSize: 14,
                      color: isToday ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------------
  // ADDITIONAL INFO
  // -------------------------------------------------------------------
  Widget _buildAdditionalInfo() {
    final current = _weather!.current;
    final daily = _weather!.daily;
    final todayData = daily.length > 0 ? daily.getDay(0) : null;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Cuaca',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 16),
            // Row 1
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      Icons.thermostat_rounded,
                      'Terasa',
                      '${current.apparentTemperature?.round() ?? '-'}°C',
                      const Color(0xFFFF7043), // Deep Orange
                      const Color(0xFFFBE9E7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoTile(
                      Icons.water_drop_rounded,
                      'Kelembapan',
                      '${current.humidity ?? '-'}%',
                      const Color(0xFF29B6F6), // Light Blue
                      const Color(0xFFE1F5FE),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Row 2
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      Icons.air_rounded,
                      'Angin',
                      '${current.windSpeed?.round() ?? '-'} km/j',
                      const Color(0xFF26A69A), // Teal
                      const Color(0xFFE0F2F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoTile(
                      Icons.explore_rounded,
                      'Arah Angin',
                      OpenMeteoService.getWindDirectionText(current.windDirection),
                      const Color(0xFF5C6BC0), // Indigo
                      const Color(0xFFE8EAF6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Row 3
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      Icons.wb_sunny_rounded,
                      'UV Index',
                      '${current.uvIndex?.round() ?? '-'} ${OpenMeteoService.getUvIndexLevel(current.uvIndex)}',
                      Color(OpenMeteoService.getUvIndexColor(current.uvIndex)),
                      Color(OpenMeteoService.getUvIndexColor(current.uvIndex)).withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoTile(
                      Icons.cloud_rounded,
                      'Awan',
                      '${current.cloudCover ?? '-'}%',
                      const Color(0xFF78909C), // Blue Grey
                      const Color(0xFFECEFF1),
                    ),
                  ),
                ],
              ),
            ),
            // Sunrise & Sunset
            if (todayData?.sunrise != null && todayData?.sunset != null) ...[
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        Icons.wb_twilight_rounded,
                        'Terbit',
                        DateFormat('HH:mm').format(todayData!.sunrise!),
                        const Color(0xFFFFB74D), // Orange
                        const Color(0xFFFFF3E0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoTile(
                        Icons.nights_stay_rounded,
                        'Terbenam',
                        DateFormat('HH:mm').format(todayData.sunset!),
                        const Color(0xFF7E57C2), // Deep Purple
                        const Color(0xFFEDE7F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor.computeLuminance() > 0.5
                        ? Colors.grey.shade800
                        : iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
