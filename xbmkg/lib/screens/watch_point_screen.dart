import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_point_provider.dart';
import '../models/watch_point_model.dart';
import 'add_watch_point_screen.dart';
import 'watch_point_detail_screen.dart';

class WatchPointScreen extends StatelessWidget {
  const WatchPointScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Titik Pantau'),
        centerTitle: true,
      ),
      body: Consumer<WatchPointProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.watchPoints.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              provider.loadWatchPoints();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.watchPoints.length,
              itemBuilder: (context, index) {
                final watchPoint = provider.watchPoints[index];
                return _buildWatchPointCard(context, watchPoint, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddScreen(context),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Tambah Titik'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Titik Pantau',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan titik pantau untuk memantau cuaca di lokasi yang kamu inginkan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddScreen(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Tambah Titik Pantau'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchPointCard(
    BuildContext context,
    WatchPointModel watchPoint,
    WatchPointProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetailScreen(context, watchPoint),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          watchPoint.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          watchPoint.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditScreen(context, watchPoint);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, watchPoint, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.cloud,
                    'Kota: ${watchPoint.nearestCity ?? '-'}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    Icons.my_location,
                    '${watchPoint.latitude.toStringAsFixed(4)}, ${watchPoint.longitude.toStringAsFixed(4)}',
                    Colors.green,
                  ),
                ],
              ),
              if (watchPoint.description != null &&
                  watchPoint.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  watchPoint.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
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

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddWatchPointScreen()),
    );
  }

  void _navigateToEditScreen(BuildContext context, WatchPointModel watchPoint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddWatchPointScreen(watchPoint: watchPoint),
      ),
    );
  }

  void _navigateToDetailScreen(BuildContext context, WatchPointModel watchPoint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WatchPointDetailScreen(watchPoint: watchPoint),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WatchPointModel watchPoint,
    WatchPointProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Titik Pantau'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${watchPoint.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteWatchPoint(watchPoint.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Titik pantau berhasil dihapus'
                          : 'Gagal menghapus titik pantau',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
