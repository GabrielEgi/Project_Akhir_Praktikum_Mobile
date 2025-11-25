import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../auth/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final box = Hive.box<UserModel>('users');
    if (box.isNotEmpty) {
      _currentUser = box.values.first;
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Pilih dari Galeri"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Ambil dari Kamera"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null && _currentUser != null) {
      _currentUser!.profileImage = pickedFile.path;
      await _currentUser!.save();
      setState(() {});
    }
  }

  String _getUsername() => _currentUser?.username ?? 'User';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildMenus()),
        ],
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    final image = _currentUser?.profileImage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: Colors.blue.shade700,
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              backgroundImage: (image != null && File(image).existsSync())
                  ? FileImage(File(image))
                  : null,
              child: (image == null)
                  ? const Text(
                      "A",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getUsername(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Selamat datang kembali!",
            style: TextStyle(
              color: Colors.blue.shade100,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- MENU LIST ----------
  Widget _buildMenus() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _menuTile(Icons.help_outline, "Bantuan", _showHelpDialog),
        _menuTile(Icons.info_outline, "Tentang Aplikasi", _showAboutAppDialog),
        const SizedBox(height: 20),
        _logoutButton(),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback tap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: tap,
      ),
    );
  }

  Widget _logoutButton() {
    return ElevatedButton.icon(
      onPressed: _showLogoutDialog,
      icon: const Icon(Icons.logout),
      label: const Text('Keluar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------- DIALOGS ----------
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              // Clear login state from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('username');

              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Bantuan'),
        content: Text.rich(
  TextSpan(
    text: 'Aplikasi Informasi Cuaca BMKG.\n\n'
          'Untuk bantuan lebih lanjut, silakan hubungi '
          'Aslab kami dan berikan kami ',
    children: <TextSpan>[
      TextSpan(
        text: 'nilai A',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  ),
)

      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Tentang Aplikasi'),
content: const Text(
  'WeatherNews v1.0.0\n\n'
  'Aplikasi ini menyediakan informasi cuaca terkini '
  'yang bersumber dari Badan Meteorologi, Klimatologi, dan Geofisika (BMKG).\n\n'
  'Dikembangkan oleh:\n'
  '• Gabriel Egi Putra Setiawan — 1242390096\n'
  '• Muhammad Agam Febryan — 1242390093\n\n'
  'Terima kasih telah menggunakan aplikasi WeatherNews.',
),
      ),
    );
  }
}
