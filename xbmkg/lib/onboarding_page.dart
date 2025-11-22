import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:xbmkg/login.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool isLastPage = false;
  int currentIndex = 0;

  Future<void> finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hasSeenOnboarding", true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // TOP ACTIONS → BACK & SKIP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // BACK BUTTON (sembunyikan di page 0)
                currentIndex > 0
                    ? TextButton(
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text("← Back",
                            style: TextStyle(fontSize: 16)),
                      )
                    : const SizedBox(width: 70), // placeholder biar simetris

                // SKIP BUTTON (langsung ke halaman terakhir)
                TextButton(
                  onPressed: () {
                    _controller.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                    isLastPage = index == 2;
                  });
                },
                children: [
                  onboardItem(
                    Icons.cloud_outlined,
                    "Cek Cuaca Real-Time",
                    "Dapatkan informasi lengkap langsung dari BMKG.",
                  ),
                  onboardItem(
                    Icons.newspaper,
                    "Berita Cuaca Terbaru",
                    "Ikuti berita dan artikel cuaca setiap hari.",
                  ),
                  onboardItem(
                    Icons.warning_amber_rounded,
                    "Peringatan Cuaca Dini",
                    "Tetap aman dengan notifikasi cuaca ekstrem.",
                  ),
                ],
              ),
            ),

            SmoothPageIndicator(
              controller: _controller,
              count: 3,
              effect: const WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: Colors.blue,
              ),
            ),

            const SizedBox(height: 30),

            // NEXT / GET STARTED BUTTON
            isLastPage
                ? ElevatedButton(
                    onPressed: finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 15),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Get Started",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                : TextButton(
                    onPressed: () {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text("Next →",
                        style: TextStyle(fontSize: 16)),
                  ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget onboardItem(IconData icon, String title, String subtitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 160,
          color: Colors.blue,
        ),
        const SizedBox(height: 30),
        Text(
          title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
