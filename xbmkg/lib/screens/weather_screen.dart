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
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: forecasts.length,
            itemBuilder: (context, index) {
              final forecast = forecasts[index];
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                      color: Colors.black12.withOpacity(0.1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(forecast.datetime!),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forecast.getWeatherIcon(),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${provider.getTemperature(forecast.temperature)?.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
              'Grafik Temperatur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= forecasts.length) return const Text('');
                          final f = forecasts[value.toInt()];
                          return Text(
                            DateFormat('HH:mm').format(f.datetime!),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: forecasts.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          provider.getTemperature(entry.value.temperature) ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF1E88E5),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        ...forecasts.map((forecast) {
          return Card(
            color: Colors.white,
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Text(
                forecast.getWeatherIcon(),
                style: const TextStyle(fontSize: 36),
              ),
              title: Text(
                DateFormat('EEEE, d MMM', 'id_ID').format(forecast.datetime!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                forecast.weather ?? '',
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
