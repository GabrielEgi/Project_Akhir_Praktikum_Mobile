import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF), // BMKG soft blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8), // BMKG blue
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Prakiraan Cuaca',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          if (weatherProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)));
          }

          if (weatherProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(weatherProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8)
                    ),
                    onPressed: () => weatherProvider.refresh(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF1A73E8),
            onRefresh: () => weatherProvider.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentWeather(context, weatherProvider),
                  const SizedBox(height: 20),
                  _buildHourlyForecast(context, weatherProvider),
                  const SizedBox(height: 24),
                  _buildTemperatureChart(context, weatherProvider),
                  const SizedBox(height: 24),
                  _buildWeeklyForecast(context, weatherProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------
  // CURRENT WEATHER (HEADER CARD)
  // -------------------------------------------------------------------
  Widget _buildCurrentWeather(
    BuildContext context,
    WeatherProvider provider,
  ) {
    final temp = provider.getCurrentTemperature();
    final condition = provider.getCurrentWeatherCondition();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF42A5F5),
            Color(0xFF1E88E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            provider.selectedLocation,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            temp != null ? '${temp.toStringAsFixed(0)}°${provider.getTemperatureUnit()}' : '--°',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            condition ?? 'Memuat...',
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
  Widget _buildHourlyForecast(
    BuildContext context,
    WeatherProvider provider,
  ) {
    final forecasts = provider.getTodayForecast();

    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

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
            itemCount: forecasts.length,
            itemBuilder: (context, index) {
              final forecast = forecasts[index];
              return Container(
                width: 75,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                      color: Colors.black12.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(forecast.datetime!),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      forecast.getWeatherIcon(),
                      style: const TextStyle(fontSize: 26),
                    ),
                    Text(
                      '${provider.getTemperature(forecast.temperature)?.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // -------------------------------------------------------------------
  // TEMPERATURE CHART
  // -------------------------------------------------------------------
  Widget _buildTemperatureChart(
    BuildContext context,
    WeatherProvider provider,
  ) {
    final forecasts = provider.getTodayForecast();
    if (forecasts.isEmpty) return const SizedBox.shrink();

    // Calculate min, max, avg
    final temps = forecasts
        .where((f) => f.temperature != null)
        .map((f) => provider.getTemperature(f.temperature)!)
        .toList();

    if (temps.isEmpty) return const SizedBox.shrink();

    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final unit = provider.getTemperatureUnit();

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
                _buildTempSummary('Terendah', minTemp, unit, Colors.blue),
                _buildTempSummary('Rata-rata', avgTemp, unit, Colors.orange),
                _buildTempSummary('Tertinggi', maxTemp, unit, Colors.red),
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
                          if (idx < 0 || idx >= forecasts.length) {
                            return const SizedBox.shrink();
                          }
                          // Show every 2nd label to avoid crowding
                          if (idx % 2 != 0 && forecasts.length > 4) {
                            return const SizedBox.shrink();
                          }
                          final f = forecasts[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('HH:mm').format(f.datetime!),
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        '°$unit',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                      spots: forecasts.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          provider.getTemperature(entry.value.temperature) ?? 0,
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
                          final forecast = forecasts[idx];
                          return LineTooltipItem(
                            '${DateFormat('HH:mm').format(forecast.datetime!)}\n${spot.y.toStringAsFixed(1)}°$unit',
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

  Widget _buildTempSummary(String label, double temp, String unit, Color color) {
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
          '${temp.toStringAsFixed(1)}°$unit',
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
  Widget _buildWeeklyForecast(
    BuildContext context,
    WeatherProvider provider,
  ) {
    final forecasts = provider.getWeeklyForecast();

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
        if (forecasts.isEmpty)
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Data prakiraan 7 hari tidak tersedia',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coba refresh untuk memuat ulang data',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...forecasts.map((forecast) {
            final isToday = forecast.datetime != null &&
                forecast.datetime!.day == DateTime.now().day &&
                forecast.datetime!.month == DateTime.now().month;

            return Card(
              color: isToday ? const Color(0xFFE3F2FD) : Colors.white,
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Text(
                  forecast.getWeatherIcon(),
                  style: const TextStyle(fontSize: 36),
                ),
                title: Text(
                  isToday
                      ? 'Hari Ini'
                      : DateFormat('EEEE, d MMM', 'id_ID').format(forecast.datetime!),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday ? const Color(0xFF1E88E5) : null,
                  ),
                ),
                subtitle: Text(
                  forecast.weather ?? '-',
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: Text(
                  '${provider.getTemperature(forecast.temperature)?.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
