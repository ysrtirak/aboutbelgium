import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'QuestionDetailPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:aboutbelgium/AdsKeys.dart';
import 'dart:math';

class BasePage extends StatefulWidget {
  final String title;
  final Locale locale;
  final String Function(Locale) getUrlForLocale; // URL'yi locale'e göre getirecek fonksiyon

  const BasePage({
    super.key,
    required this.title,
    required this.locale,
    required this.getUrlForLocale,
  });

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  late Future<List<dynamic>> questionsData;
  List<dynamic> filteredQuestions = []; // List to store filtered questions
  final TextEditingController searchController = TextEditingController(); // Controller for the search field
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;

  @override
  void initState() {
    super.initState();
    questionsData = fetchQuestionsData();
    adsBanner();
    _loadInterstitialAd();
  }

  void _showRandomInterstitialAds(){
    Random random = Random();
    int sayi = random.nextInt(3) + 1;
    if (sayi == 2){
      print ("neden bu say $sayi ");
      _showInterstitialAd();
    }
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
    if (_isInterstitialAdReady) {
      _interstitialAd.dispose();
    }
    super.dispose();
  }

  Future<List<dynamic>> fetchQuestionsData() async {
    final response = await http.get(Uri.parse(widget.getUrlForLocale(widget.locale)));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      filteredQuestions = data["questions"]; // Initialize filtered questions with all questions
      return filteredQuestions;
    } else {
      throw Exception('Failed to load data');
    }
  }

  void filterQuestions(String query) {
    if (query.isEmpty) {
      // If the query is empty, reset to the original list
      setState(() {
        filteredQuestions = [];
      });
      questionsData.then((data) {
        setState(() {
          filteredQuestions = data;
        });
      });
    } else {
      setState(() {
        filteredQuestions = filteredQuestions.where((question) {
          return question["question"].toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  double _calculateIconSize(String question) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: question,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87, // Updated color for better visibility
        ),
      ),
      maxLines: 2,
      textDirection: Directionality.of(context),
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 70);
    return textPainter.size.height * 0.8;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              const SizedBox(height: 4.0),
              // Banner Ad burada yerleştiriliyor
              if (_isBannerAdReady)
                Container(
                  height: 50,
                  child: AdWidget(ad: _bannerAd),
                ),
                const SizedBox(height: 4.0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: searchController,
                  onChanged: filterQuestions,
                  decoration: InputDecoration(
                    hintText: 'Search questions...'.tr(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: questionsData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                    } else if (filteredQuestions.isEmpty) {
                      return const Center(child: Text('No questions found.', style: TextStyle(color: Colors.black87)));
                    } else {
                      final List<dynamic> questions = filteredQuestions.isNotEmpty
                          ? filteredQuestions
                          : snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index]["question"];
                          final content = questions[index]["content"];

                          double iconSize = _calculateIconSize(question);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12.0),
                              title: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  question,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.3,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.green,
                                  size: iconSize,
                                ),
                                onPressed: () {
                                  _showRandomInterstitialAds();
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => QuestionDetailPage(
                                        question: question,
                                        content: content,
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOut;

                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                        var offsetAnimation = animation.drive(tween);

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              // ListTile'ın tamamına tıklandığında çalışacak onTap
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => QuestionDetailPage(
                                      question: question,
                                      content: content,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;

                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      var offsetAnimation = animation.drive(tween);

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
