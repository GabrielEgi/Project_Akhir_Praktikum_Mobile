import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:xbmkg/screens/weather_screen.dart';
import 'package:xbmkg/screens/earthquake_screen.dart';
import 'package:xbmkg/screens/watch_point_screen.dart';

import '../providers/weather_provider.dart';
import '../providers/earthquake_provider.dart';
import '../services/preferences_service.dart';
import '../services/location_service.dart';

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

  if (!useGPS) return;

  // 👉 Cek izin lokasi
  bool granted = await LocationService.isLocationPermissionGranted();

  // 👉 Jika belum ada izin → minta izin
  if (!granted) {
    granted = await LocationService.requestLocationPermission();
  }

  // 👉 Jika tetap ditolak → jangan paksa, tampilkan popup
  if (!granted) {
    if (mounted) {
      _showPermissionDeniedDialog();
    }
    return;
  }

  // 👉 Jika sudah diizinkan → refresh sesuai GPS
  await context.read<WeatherProvider>().refreshWithLocation();
}


  @override
  Widget build(BuildContext context) {
    final bmkgBlue = const Color(0xFF0077C8);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'WeatherNews EXBMKG',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      // ==========================================================
      // FINAL FIX: REFRESH SELALU BALIK GPS
      // ==========================================================
      body: RefreshIndicator(
        color: bmkgBlue,
        onRefresh: () async {
          final wp = context.read<WeatherProvider>();
          final ep = context.read<EarthquakeProvider>();

          await wp.refreshWithLocation();
          await ep.refresh();
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
  // LOKASI
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
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                            .format(DateTime.now()),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
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
  // CUACA
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
                          style:
                              const TextStyle(fontSize: 18, color: Colors.white),
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
  // GEMPA
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
                    Icon(
                      Icons.warning_amber_rounded,
                      color: (data?.magnitude ?? 0) >= 5
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                if (data != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _getMagnitudeColor(data.magnitude),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "M ${data.magnitude?.toStringAsFixed(1)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
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
  // MENU CEPAT
  // ---------------------------------------------------------
  Widget _buildQuickActions(Color bmkgBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Akses Cepat",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _quickAction(
              Icons.cloud_rounded,
              "Prakiraan Cuaca",
              const Color(0xFF1E88E5),
              const Color(0xFFE3F2FD),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeatherScreen()),
              ),
            ),
            _quickAction(
              Icons.terrain_rounded,
              "Info Gempa",
              const Color(0xFFFF7043),
              const Color(0xFFFBE9E7),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarthquakeScreen()),
              ),
            ),
            _quickAction(
              Icons.location_on_rounded,
              "Titik Pantau",
              const Color(0xFF26A69A),
              const Color(0xFFE0F2F1),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WatchPointScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(
    IconData icon,
    String title,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 26, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UTIL
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

  // ---------------------------------------------------------
  // POPUP PILIH LOKASI MANUAL
  // ---------------------------------------------------------
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
  void _showPermissionDeniedDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Izin Lokasi Ditolak'),
      content: const Text(
          'Aplikasi memerlukan izin lokasi untuk menampilkan cuaca berdasarkan lokasi Anda. '
          'Silakan aktifkan izin lokasi di pengaturan perangkat Anda.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
  
}
  