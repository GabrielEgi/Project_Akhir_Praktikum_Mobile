import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../providers/earthquake_provider.dart';
import '../services/permission_service.dart';
import '../services/preferences_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final useGPS = PreferencesService.getUseGPS();
    if (useGPS) {
      final hasPermission = await LocationService.isLocationPermissionGranted();
      if (!hasPermission) {
        await LocationService.requestLocationPermission();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmkgBlue = const Color(0xFF0077C8);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        backgroundColor: bmkgBlue,
        elevation: 0,
        title: const Text(
          'WeatherNews BMKG',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        color: bmkgBlue,
        onRefresh: () async {
          await Future.wait([
            context.read<WeatherProvider>().refresh(),
            context.read<EarthquakeProvider>().refresh(),
          ]);
        },

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationCard(bmkgBlue),
              const SizedBox(height: 16),
              _buildWeatherSummary(bmkgBlue),
              const SizedBox(height: 16),
              _buildEarthquakeSummary(),
              const SizedBox(height: 16),
              _buildQuickActions(bmkgBlue),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  SECTION: LOKASI
  // ---------------------------------------------------------
  Widget _buildLocationCard(Color bmkgBlue) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bmkgBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: bmkgBlue, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lokasi Saat Ini',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        provider.selectedLocation,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                            .format(DateTime.now()),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_location_alt),
                  onPressed: () => _showLocationDialog(),
                  color: bmkgBlue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  //  SECTION: CUACA HARI INI
  // ---------------------------------------------------------
  Widget _buildWeatherSummary(Color bmkgBlue) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _loadingCard(height: 200);
        }

        final temp = provider.getCurrentTemperature();
        final kondisi = provider.getCurrentWeatherCondition();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bmkgBlue, bmkgBlue.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Cuaca Hari Ini",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.cloud, color: Colors.white, size: 34),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      temp != null ? "${temp.toStringAsFixed(0)}°" : "--°",
                      style: const TextStyle(
                        fontSize: 60,
                        height: 1,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kondisi ?? "Memuat...",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.selectedLocation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  //  SECTION: GEMPA
  // ---------------------------------------------------------
  Widget _buildEarthquakeSummary() {
    return Consumer<EarthquakeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _loadingCard(height: 150);
        }

        final data = provider.latestEarthquakes.isNotEmpty
            ? provider.latestEarthquakes.first
            : null;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Gempa Terkini",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    Icon(Icons.warning_amber_rounded,
                        color:
                            (data?.magnitude ?? 0) >= 5 ? Colors.orange : Colors.grey),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                if (data != null)
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _getMagnitudeColor(data.magnitude),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "M ${data.magnitude?.toStringAsFixed(1)}",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.region ?? "Tidak diketahui",
                                style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("${data.date} ${data.time}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Center(
                    child: Text(
                      "Tidak ada data gempa terbaru",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  //  SECTION: MENU CEPAT
  // ---------------------------------------------------------
  Widget _buildQuickActions(Color bmkgBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Akses Cepat",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _quickAction(Icons.cloud_queue, "Prakiraan Cuaca", bmkgBlue, () {}),
            _quickAction(Icons.terrain, "Info Gempa", Colors.orange, () {}),
            _quickAction(Icons.air, "Kualitas Udara", Colors.green, () {}),
            _quickAction(Icons.settings, "Pengaturan", Colors.grey, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  UTIL
  // ---------------------------------------------------------
  Widget _loadingCard({double height = 100}) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Color _getMagnitudeColor(double? m) {
    if (m == null) return Colors.grey;
    if (m < 3) return Colors.green;
    if (m < 5) return Colors.yellow.shade700;
    if (m < 7) return Colors.orange;
    return Colors.red;
  }

  // popup lokasi
  void _showLocationDialog() {
    final cities = [
      "Jakarta",
      "Yogyakarta",
      "Bandung",
      "Surabaya",
      "Semarang",
      "Medan",
      "Palembang",
      "Makassar",
      "Denpasar",
      "Malang",
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pilih Lokasi"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: cities.length,
            shrinkWrap: true,
            itemBuilder: (_, i) => ListTile(
              title: Text(cities[i]),
              onTap: () {
                context.read<WeatherProvider>().changeLocation(cities[i]);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }
}
