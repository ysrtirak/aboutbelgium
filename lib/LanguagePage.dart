import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'WelcomePage.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ekranın tamamına yayılmasını sağladık
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.blueAccent], // Daha canlı renk geçişleri
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Ortalıyoruz
              children: [
                const SizedBox(height: 60), // Sayfanın üst kısmına boşluk bırakmak için
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 30, // Yazıyı biraz daha büyük yaptık
                    fontWeight: FontWeight.bold, // Kalın yazı
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ).tr(),
                const SizedBox(height: 10), // "Welcome" ile "Please select your language" arasında boşluk
                const Text(
                  'Please select your language:',
                  style: TextStyle(
                    fontSize: 22, // Daha küçük ve zarif yazı stili
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black38,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ).tr(),
                const SizedBox(height: 40), // Üst metin ile butonlar arasında boşluk
                const LanguageButton(
                  locale: Locale('en'),
                  buttonText: 'English',
                  flagCode: 'gb',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('fr'),
                  buttonText: 'Français',
                  flagCode: 'fr',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('de'),
                  buttonText: 'Deutsch',
                  flagCode: 'de',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('nl'),
                  buttonText: 'Nederlands',
                  flagCode: 'nl',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('it'),
                  buttonText: 'Italiano',
                  flagCode: 'it',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('es'),
                  buttonText: 'Español',
                  flagCode: 'es',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('ar'),
                  buttonText: 'العربية',
                  flagCode: 'sa',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('tr'),
                  buttonText: 'Türkçe',
                  flagCode: 'tr',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('pt'),
                  buttonText: 'Português',
                  flagCode: 'pt',
                ),
                const SizedBox(height: 20),
                const LanguageButton(
                  locale: Locale('pl'),
                  buttonText: 'Polski',
                  flagCode: 'pl',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageButton extends StatelessWidget {
  final Locale locale;
  final String buttonText;
  final String flagCode;

  const LanguageButton({
    required this.locale,
    required this.buttonText,
    required this.flagCode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.setLocale(locale); // Set the locale for EasyLocalization
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomePage(locale: locale), // Karşılama sayfasına yönlendir
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        width: MediaQuery.of(context).size.width * 0.8, // Sabit genişlikte buton
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/flags/$flagCode.png',
              width: 36,  // Sabit bayrak genişliği
              height: 36, // Sabit bayrak yüksekliği
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500, // Yazı kalınlığını azalttık
                  fontStyle: FontStyle.normal, // Daha zarif görünüm
                ),
                textAlign: TextAlign.center, // Metinleri ortaladık
              ),
            ),
          ],
        ),
      ),
    );
  }
}
