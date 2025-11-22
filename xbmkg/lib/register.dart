import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  Future<void> registerAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username & password tidak boleh kosong")),
      );
      return;
    }

    final box = Hive.box<UserModel>('users');

    // Cek apakah username sudah dipakai
    final isExist = box.values.any((user) => user.username == username);

    if (isExist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username sudah digunakan")),
      );
      return;
    }

    // Simpan user baru
    final newUser = UserModel(username: username, password: password);
    await box.add(newUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pendaftaran berhasil!")),
    );

    // Kembali ke login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1, size: 90, color: Colors.white),

              const SizedBox(height: 15),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                "Daftar untuk mulai menggunakan aplikasi",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black26,
                      offset: Offset(0, 4),
                    )
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Username",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _inputField(
                      controller: _usernameController,
                      hint: "Masukkan username",
                      icon: Icons.person,
                    ),

                    const SizedBox(height: 20),

                  
                    const Text("Password",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),
                    _passwordField(),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: registerAccount,
                        child: const Text(
                          "DAFTAR",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Sudah punya akun? Login di sini",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Input normal
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF0288D1)),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Input password
  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF0288D1)),
          hintText: "Masukkan password",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
      ),
    );
  }
}
