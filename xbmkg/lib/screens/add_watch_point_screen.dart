import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/watch_point_provider.dart';
import '../models/watch_point_model.dart';

class AddWatchPointScreen extends StatefulWidget {
  final WatchPointModel? watchPoint;

  const AddWatchPointScreen({super.key, this.watchPoint});

  @override
  State<AddWatchPointScreen> createState() => _AddWatchPointScreenState();
}

class _AddWatchPointScreenState extends State<AddWatchPointScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  final _descriptionController = TextEditingController();

  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = []; // Changed to store address info
  String? _searchError;

  bool get isEditMode => widget.watchPoint != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.watchPoint!.name;
      _addressController.text = widget.watchPoint!.address;
      _descriptionController.text = widget.watchPoint!.description ?? '';
      _selectedLat = widget.watchPoint!.latitude;
      _selectedLng = widget.watchPoint!.longitude;
      _selectedAddress = widget.watchPoint!.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      // Tambahkan "Indonesia" ke query untuk hasil yang lebih relevan
      final searchQuery =
          query.contains('Indonesia') ? query : '$query, Indonesia';

      final locations = await locationFromAddress(searchQuery);

      // Convert locations to include address info via reverse geocoding
      List<Map<String, dynamic>> resultsWithAddress = [];

      for (var location in locations) {
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          String address = '';
          String subtitle = '';

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            // Main address
            address = [
              place.name,
              place.street,
            ].where((e) => e != null && e.isNotEmpty).join(', ');

            // Subtitle with area info
            subtitle = [
              place.subLocality,
              place.locality,
              place.administrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');

            if (address.isEmpty) {
              address = subtitle;
              subtitle = '';
            }
          }

          resultsWithAddress.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
            'address': address.isNotEmpty ? address : query,
            'subtitle': subtitle,
            'fullAddress': [address, subtitle]
                .where((e) => e.isNotEmpty)
                .join(', '),
          });
        } catch (e) {
          // If reverse geocoding fails, still add with coordinates
          resultsWithAddress.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
            'address': query,
            'subtitle':
                '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            'fullAddress': query,
          });
        }
      }

      setState(() {
        _searchResults = resultsWithAddress;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = 'Alamat tidak ditemukan. Coba kata kunci lain.';
      });
    }
  }

  void _selectLocation(Map<String, dynamic> locationData) {
    setState(() {
      _selectedLat = locationData['latitude'];
      _selectedLng = locationData['longitude'];
      _selectedAddress = locationData['fullAddress'];
      _addressController.text = locationData['fullAddress'];
      _searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _saveWatchPoint() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi terlebih dahulu dengan mencari alamat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<WatchPointProvider>();
    bool success;

    if (isEditMode) {
      success = await provider.updateWatchPoint(
        id: widget.watchPoint!.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _selectedLat!,
        longitude: _selectedLng!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    } else {
      success = await provider.addWatchPoint(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _selectedLat!,
        longitude: _selectedLng!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Titik pantau berhasil diperbarui'
                  : 'Titik pantau berhasil ditambahkan',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Terjadi kesalahan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Titik Pantau' : 'Tambah Titik Pantau'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Titik Pantau
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Titik Pantau',
                  hintText: 'Contoh: Rumah, Kantor, Sawah Kakek',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama titik pantau tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Search Alamat Section
              Text(
                'Cari Lokasi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ketik alamat atau nama tempat...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _searchError = null;
                                });
                              },
                            )
                          : null,
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchAddress(value);
                    }
                  });
                },
                onSubmitted: _searchAddress,
              ),
              const SizedBox(height: 8),

              // Search Results
              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _searchError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (_searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final locationData = _searchResults[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: Text(
                          locationData['address'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          locationData['subtitle'].isNotEmpty
                              ? locationData['subtitle']
                              : '${(locationData['latitude'] as double).toStringAsFixed(4)}, ${(locationData['longitude'] as double).toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectLocation(locationData),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // Selected Location Display
              if (_selectedLat != null && _selectedLng != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Lokasi Terpilih',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLocationInfo(
                        'Koordinat',
                        '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                      ),
                      if (_selectedAddress != null)
                        _buildLocationInfo('Alamat', _selectedAddress!),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Alamat (readonly, filled from search)
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.place),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pilih lokasi dengan mencari alamat di atas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Catatan (optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Tambahkan catatan tentang lokasi ini...',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Consumer<WatchPointProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _saveWatchPoint,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(isEditMode ? Icons.save : Icons.add_location),
                      label: Text(
                        provider.isLoading
                            ? 'Menyimpan...'
                            : isEditMode
                                ? 'Simpan Perubahan'
                                : 'Tambah Titik Pantau',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
