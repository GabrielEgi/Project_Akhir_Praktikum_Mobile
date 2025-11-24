import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_point_provider.dart';
import '../models/watch_point_model.dart';
import 'add_watch_point_screen.dart';
import 'watch_point_detail_screen.dart';

class WatchPointScreen extends StatefulWidget {
  const WatchPointScreen({super.key});

  @override
  State<WatchPointScreen> createState() => _WatchPointScreenState();
}

class _WatchPointScreenState extends State<WatchPointScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Titik Pantau Cuaca',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Consumer<WatchPointProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
            );
          }

          if (provider.watchPoints.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: const Color(0xFF1A73E8),
            onRefresh: () async => provider.loadWatchPoints(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.watchPoints.length,
              itemBuilder: (context, index) {
                return _buildCard(context, provider.watchPoints[index], provider);
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text("Tambah Titik", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 90, color: Colors.blue.shade200),
            const SizedBox(height: 20),
            const Text(
              "Belum Ada Titik Pantau",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tambahkan lokasi untuk memantau cuaca di daerah yang kamu inginkan.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => _navigateToAdd(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text("Tambah Titik Pantau"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD ITEM
  // ---------------------------------------------------------------------------
  Widget _buildCard(BuildContext context, WatchPointModel item, WatchPointProvider provider) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetail(context, item),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.location_on, color: Color(0xFF1A73E8)),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.address,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _navigateToEdit(context, item);
                      if (value == 'delete') _confirmDelete(context, item, provider);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("Edit")],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Hapus", style: TextStyle(color: Colors.red))
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),

              Row(
                children: [
                  _infoChip(Icons.cloud, "Kota: ${item.nearestCity ?? '-'}", Colors.blue),
                  const SizedBox(width: 10),
                  _infoChip(Icons.my_location,
                      "${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}",
                      Colors.green),
                ],
              ),

              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.description!,
                  style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // CHIP
  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  // Navigation
  void _navigateToAdd(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWatchPointScreen()));
  }

  void _navigateToEdit(BuildContext context, WatchPointModel item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddWatchPointScreen(watchPoint: item)));
  }

  void _navigateToDetail(BuildContext context, WatchPointModel item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPointDetailScreen(watchPoint: item)));
  }

  // Delete Dialog
  void _confirmDelete(BuildContext context, WatchPointModel item, WatchPointProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Titik Pantau"),
        content: Text("Apakah kamu yakin ingin menghapus \"${item.name}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteWatchPoint(item.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Titik pantau dihapus" : "Gagal menghapus"),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}
