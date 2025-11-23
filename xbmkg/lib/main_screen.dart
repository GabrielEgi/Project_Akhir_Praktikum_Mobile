import 'package:flutter/material.dart';
import 'services/weather_api.dart';

class MainScreen extends StatefulWidget {
  final String username;
  const MainScreen({super.key, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService apiService = ApiService();

  // Dropdown memakai kode kabupaten
  String selectedKode = "34.71"; // Default: Kota Yogyakarta

  // Mapping kabupaten → ADM4
  final Map<String, String> adm4Map = {
    "34.01": "ID-3401160001", // Kulon Progo - Wates
    "34.02": "ID-3402172004", // Bantul - Gadingsari
    "34.03": "ID-3403040005", // Gunungkidul - Wonosari
    "34.04": "ID-3471071002", // Sleman - Depok
    "34.71": "ID-3471030003", // Kota Yogyakarta - Baciro
  };

  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    final adm4 = adm4Map[selectedKode]!;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await apiService.getWeather(adm4);
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Gagal memuat data cuaca: $e";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildKabupatenDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilih Kabupaten/Kota",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: selectedKode,
            isExpanded: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: "34.01",
                child: Text("Kabupaten Kulon Progo"),
              ),
              DropdownMenuItem(
                value: "34.02",
                child: Text("Kabupaten Bantul"),
              ),
              DropdownMenuItem(
                value: "34.03",
                child: Text("Kabupaten Gunungkidul"),
              ),
              DropdownMenuItem(
                value: "34.04",
                child: Text("Kabupaten Sleman"),
              ),
              DropdownMenuItem(
                value: "34.71",
                child: Text("Kota Yogyakarta"),
              ),
            ],
            onChanged: (value) {
              setState(() => selectedKode = value!);
              fetchWeather();
            },
          ),
        ),
      ],
    );
  }

  Widget buildWeatherCard() {
    if (weatherData == null) {
      return const Text("Tidak ada data cuaca", style: TextStyle(color: Colors.white));
    }

    final info = weatherData!["data"][0];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info["lokasi_nama"] ?? "Wilayah",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.cloud, size: 60, color: Colors.blue.shade400),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${info["cuaca"][0]["temp"]}°C",
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    info["cuaca"][0]["weather_desc"] ?? "",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile("Kelembapan", "${info["cuaca"][0]["humidity"]}%"),
              _infoTile("Angin", "${info["cuaca"][0]["wind_speed"]} km/j"),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Halo, ${widget.username}!"),
        backgroundColor: Colors.blue,
      ),

      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            children: [
              buildKabupatenDropdown(),
              const SizedBox(height: 20),

              if (isLoading)
                const CircularProgressIndicator(color: Colors.white),

              if (errorMessage != null)
                Text(errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16)),

              if (!isLoading && errorMessage == null)
                buildWeatherCard(),
            ],
          ),
        ),
      ),
    );
  }
}
