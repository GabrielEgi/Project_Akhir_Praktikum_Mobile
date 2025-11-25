import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/earthquake_provider.dart';
import 'earthquake_detail_screen.dart';

class EarthquakeScreen extends StatelessWidget {
  const EarthquakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
   final bmkgBlue = const Color(0xFF0077C8);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF), // BMKG soft blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8), // BMKG blue
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gempa Bumi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildBMKGTabBar(context, provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  color: bmkgBlue,
                  child: _buildEarthquakeList(context, provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB BAR
  // ---------------------------------------------------------
  Widget _buildBMKGTabBar(BuildContext context, EarthquakeProvider provider) {
    final bmkgBlue = const Color(0xFF005AAC);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: bmkgBlue.withValues(alpha: 0.1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              child: _buildTab(
                context,
                'Terkini',
                'latest',
                provider.selectedTab == 'latest',
                () => provider.changeTab('latest'),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              child: _buildTab(
                context,
                'M ≥ 5',
                'recent',
                provider.selectedTab == 'recent',
                () => provider.changeTab('recent'),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              child: _buildTab(
                context,
                'Dirasakan',
                'felt',
                provider.selectedTab == 'felt',
                () => provider.changeTab('felt'),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              child: _buildTab(
                context,
                'USGS',
                'usgs',
                provider.selectedTab == 'usgs',
                () {
                  provider.changeTab('usgs');
                  // Load USGS data if not loaded yet
                  if (provider.usgsEarthquakes.isEmpty) {
                    provider.loadUsgsDataByRegion(days: 7, minMagnitude: 2.5);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    String tab,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final bmkgBlue = const Color(0xFF005AAC);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? bmkgBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? bmkgBlue : Colors.black54,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // LIST GEMPA
  // ---------------------------------------------------------
  Widget _buildEarthquakeList(
    BuildContext context,
    EarthquakeProvider provider,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.red),
            const SizedBox(height: 12),
            Text(provider.error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.refresh(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final earthquakes = provider.currentList;
    if (earthquakes.isEmpty) {
      return const Center(
        child: Text('Tidak ada data gempa'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: earthquakes.length,
      itemBuilder: (context, index) {
        final e = earthquakes[index];

        return Card(
          elevation: 3,
          shadowColor: Colors.black26,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EarthquakeDetailScreen(earthquake: e),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MAGNITUDE & DEPTH
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getMagnitudeColor(e.magnitude),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'M ${e.magnitude?.toStringAsFixed(1) ?? '-'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  e.getMagnitudeCategory(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (provider.selectedTab == 'usgs') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'USGS',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'Kedalaman: ${e.depth} Km',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),

                  const SizedBox(height: 12),
                  // REGION
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.region ?? 'Tidak diketahui',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // TIME
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        '${e.date} ${e.time}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  if (e.felt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.warning,
                            size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Dirasakan: ${e.felt}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // MAGNITUDE COLOR
  // ---------------------------------------------------------
  Color _getMagnitudeColor(double? m) {
    if (m == null) return Colors.grey;
    if (m < 3.0) return Colors.green;
    if (m < 5.0) return Colors.orange.shade700;
    if (m < 7.0) return Colors.red.shade400;
    return Colors.red.shade900;
  }
}
