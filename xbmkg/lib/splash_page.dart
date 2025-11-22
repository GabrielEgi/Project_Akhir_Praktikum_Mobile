import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page.dart';
import 'login.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  _checkOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? hasSeen = prefs.getBool("hasSeenOnboarding");

    await Future.delayed(const Duration(seconds: 2));

    if (hasSeen == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4FC3F7),
              Color(0xFF0288D1),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_outlined,
              size: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              "WeatherNews",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Cuaca · Berita · Peringatan",
              style: TextStyle(
                color: Colors.white70,
              ),
            )
          ],
        ),
      ),
    );
  }
}
