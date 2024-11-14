import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aboutbelgium/QuestionAndAnswer/LegalPage.dart';
import 'package:aboutbelgium/QuestionAndAnswer/HousingPage.dart';
import 'package:aboutbelgium/QuestionAndAnswer/HealthcarePage.dart';
import 'package:aboutbelgium/QuestionAndAnswer/EducationPage.dart';
import 'package:aboutbelgium/QuestionAndAnswer/EmploymentPage.dart';
import 'package:aboutbelgium/QuestionAndAnswer/TransportationPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aboutbelgium/QuestionAndAnswer/Links.dart';
import 'package:aboutbelgium/QuestionAndAnswer/ErrorScreen.dart'; // Import the new error screen
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:aboutbelgium/AdsKeys.dart';

import '../MessagingPage/LoginPage.dart';

class HomePage extends StatefulWidget {
  final Locale locale;

  const HomePage({super.key, required this.locale});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> jsonData;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;
  @override
  void initState() {
    super.initState();
    jsonData = fetchData();
    adsBanner();
    _loadInterstitialAd();
  }
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdsInterstitial, // Replace with your actual Interstitial Ad Unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }
  void _showInterstitialAd() {
    if (_isInterstitialAdReady) {
      _interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          print("Interstitial ad dismissed.");
          ad.dispose();
          _loadInterstitialAd(); // Reklam kapatıldıktan sonra yeni reklamı yükler
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          print("Failed to show interstitial ad: $error");
          ad.dispose();
          _loadInterstitialAd(); // Gösterim başarısız olursa yeni reklam yükler
        },
      );
      _interstitialAd.show();
      _isInterstitialAdReady = false;
    } else {
      print("Interstitial ad is not ready.");
    }
  }

  void adsBanner (){
   _bannerAd = BannerAd(
     adUnitId: AdsBanner, // Test veya gerçek reklam ID'nizi girin
     request: AdRequest(),
     size: AdSize.banner,
     listener: BannerAdListener(
       onAdLoaded: (_) {
         setState(() {
           _isBannerAdReady = true;
         });
       },
       onAdFailedToLoad: (ad, error) {
         print('Banner failed to load: $error');
         _isBannerAdReady = false;
         ad.dispose();
       },
     ),
   );

   _bannerAd.load();
 }
  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  String getUrlForLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return en_Main_Url;
      case 'fr':
        return fr_Main_Url;
      case 'de':
        return de_Main_Url;
      case 'nl':
        return nl_Main_Url;
      case 'it':
        return it_Main_Url;
      case 'es':
        return es_Main_Url;
      case 'ar':
        return ar_Main_Url;
      case 'tr':
        return tr_Main_Url;
      case 'pt':
        return pt_Main_Url;
      case 'pl':
        return pl_Main_Url;
      default:
        return en_Main_Url; // Default to English
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse(getUrlForLocale(widget.locale)));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  void _showAddQuestionDialog() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Kullanıcı giriş yapmamışsa LoginPage'e yönlendirme
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(locale: widget.locale),
        ),
      );
    } else {
      // Pop-up dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Yuvarlak köşeler
          ),
          child: SingleChildScrollView(
          child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
          gradient: LinearGradient(
          colors: [Colors.white, Colors.green.shade50], // Arka plan gradyanı
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your own question".tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.green.shade800),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _questionController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: "Question".tr(),
                      labelStyle: TextStyle(color: Colors.green.shade800),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.shade500, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _explanationController,
                    maxLength: 300,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Explanation".tr(),
                      labelStyle: TextStyle(color: Colors.green.shade800),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.shade500, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final String question = _questionController.text.trim();
                      final String explanation = _explanationController.text.trim();

                      // Karakter kontrolü
                      if (question.length < 10 || question.length > 100) {
                        _showMessageDialog(
                          title: "Invalid Question".tr(),
                          message: "Question must be between 10 and 100 characters.".tr(),
                        );
                        return;
                      }

                      if (explanation.length > 300) {
                        _showMessageDialog(
                          title: "Invalid Explanation".tr(),
                          message: "Explanation cannot exceed 300 characters.".tr(),
                        );
                        return;
                      }

                      try {
                        // Firebase'e veri gönderme
                        await FirebaseFirestore.instance
                            .collection('questions')
                            .doc(currentUser.uid)
                            .set({
                          'userId': currentUser.uid,
                          'question': question,
                          'explanation': explanation,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        // Alanları temizle
                        _questionController.clear();
                        _explanationController.clear();

                        // Dialog'u kapat ve onay mesajı göster
                        Navigator.of(context).pop();
                        _showMessageDialog(
                          title: "Success".tr(),
                          message: "Question added successfully! Your answer will be processed into the system within a few days.".tr(),
                        );
                        _showInterstitialAd();
                      } catch (error) {
                        _showMessageDialog(
                          title: "Error".tr(),
                          message: "Failed to add question. Please try again.".tr(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      backgroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Add".tr(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "WARNING".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "After submitting your question, the answer will be added to the system within a few days.".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      );
    }
  }

  void _showMessageDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK".tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.green.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: jsonData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
// Navigate to the ErrorScreen when there's an error
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ErrorScreen(
                      message: 'It will be added very soon. You can try opening this page in other languages.'.tr(),
                    ),
                  ),
                );
              });
              return const SizedBox.shrink();            } else if (!snapshot.hasData || snapshot.data == null) {
              return  Center(child: Text('No data found.'.tr()));
            } else {
              final homePageData = snapshot.data!["homePage"];
              final String description = homePageData["description"];
              final List<dynamic>? menuItems = homePageData["menu"];

              if (menuItems == null || menuItems.isEmpty) {
                return const Center(child: Text('No menu items found.'));
              }
              return SafeArea(
                child: Column(
                  children: [
                    AppBar(
                      title: Text('Explore Belgium'.tr()),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final menuItem = menuItems[index];
                          return _buildInfoCard(
                            context,
                            menuItem["title"],
                            _getIconData(menuItem["route"]), // Change here to use route
                                () {
                              Navigator.push(
                                context,
                                _getPageRoute(menuItem["route"], menuItem["title"]),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showAddQuestionDialog,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02, // Ekran yüksekliğine göre dikey padding
                          horizontal: MediaQuery.of(context).size.width * 0.05, // Ekran genişliğine göre yatay padding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Yuvarlak köşeler
                        ),
                      ),
                      child: Text(
                        "+ Add your own question",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045, // Ekran genişliğine göre yazı boyutu
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    if (_isBannerAdReady)
                      Container(
                        alignment: Alignment.center,
                        child: AdWidget(ad: _bannerAd),
                        width: _bannerAd.size.width.toDouble(),
                        height: _bannerAd.size.height.toDouble(),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  MaterialPageRoute _getPageRoute(String routeName, String title) {
    switch (routeName) {
      case 'LegalPage':
        return MaterialPageRoute(builder: (context) => LegalPage(title: title, locale: widget.locale));
      case 'HousingPage':
        return MaterialPageRoute(builder: (context) => HousingPage(title: title, locale: widget.locale));
      case 'HealthcarePage':
        return MaterialPageRoute(builder: (context) => HealthcarePage(title: title, locale: widget.locale));
      case 'EducationPage':
        return MaterialPageRoute(builder: (context) => EducationPage(title: title, locale: widget.locale));
      case 'EmploymentPage':
        return MaterialPageRoute(builder: (context) => EmploymentPage(title: title, locale: widget.locale));
      case 'TransportationPage':
        return MaterialPageRoute(builder: (context) => TransportationPage(title: title, locale: widget.locale));
      default:
        return MaterialPageRoute(builder: (context) => const HomePage(locale: Locale('en')));
    }
  }

  IconData _getIconData(String route) {
    switch (route) {
      case 'EducationPage':
        return Icons.school;
      case 'EmploymentPage':
        return Icons.work;
      case 'HealthcarePage':
        return Icons.local_hospital;
      case 'LegalPage':
        return Icons.gavel;
      case 'HousingPage':
        return Icons.home;
      case 'TransportationPage':
        return Icons.directions_car;
      default:
        return Icons.info;
    }
  }


  Widget _buildInfoCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(icon, size: 40, color: Colors.green.shade600),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
