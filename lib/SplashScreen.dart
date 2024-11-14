import 'package:flutter/material.dart';
import 'LanguagePage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoFadeController;
  late AnimationController _textFadeController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Uygulama logosu için fade animasyonu (yanıp sönme)
    _logoFadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(parent: _logoFadeController, curve: Curves.easeInOut),
    );

    // Yazı için fade animasyonu (görünmezlikten görünürlüğe)
    _textFadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Logonun yanıp sönmesi
    await _logoFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _logoFadeController.reverse();
    await Future.delayed(const Duration(milliseconds: 500));

    // Yazının görünürlüğe doğru gelmesi
    await _textFadeController.forward();

    // Sayfayı değiştirmek için bir süre bekle
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LanguagePage()),
      );
    }
  }

  @override
  void dispose() {
    _logoFadeController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ortadaki animasyonlar
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Uygulama logosunun yanıp sönmesi
                RepaintBoundary(
                  child: FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: Image.asset(
                      'assets/images/aboutBelgiumLogo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      cacheWidth: 100, // Genişlik optimizasyonu
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // "About Belgium" yazısının görünmezlikten görünürlüğe doğru gelmesi
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Text(
                    'About Belgium',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [
                            Color(0xFFFFD700), // Sarı
                            Color(0xFFFF0000), // Kırmızı
                            Color(0xFF000000), // Siyah
                          ],
                        ).createShader(
                          const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                        ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // En alt metin
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Text(
              'Created by Yasir TIRAK',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
