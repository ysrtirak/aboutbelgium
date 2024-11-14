import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aboutbelgium/AdsKeys.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class QuestionDetailPage extends StatefulWidget {
  final String question;
  final List<dynamic> content;

  const QuestionDetailPage({
    super.key,
    required this.question,
    required this.content,
  });

  @override
  _QuestionDetailPageState createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  late Future<void> _loadContentFuture;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  @override
  void initState() {
    super.initState();
    // Initialize the loading future
    _loadContentFuture = Future.delayed(const Duration(seconds: 1), () {
      return;
    });
    adsBanner ();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Set semi-transparent background color for AppBar
        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: FutureBuilder<void>(
        future: _loadContentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.builder(
                itemCount: widget.content.length + 2, // +2 for the question and ad
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Card(
                        elevation: 4,
                        color: const Color(0xFFF9F9F9),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            widget.question,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Adjust index for content
                  if (index == widget.content.length + 1) {
                    // Display the banner ad at the bottom
                    return Container(
                      alignment: Alignment.center,
                      child: _isBannerAdReady
                          ? Container(
                        height: 50, // Banner ad height
                        child: AdWidget(ad: _bannerAd), // AdMob banner widget
                      )
                          : SizedBox(), // Display empty if the ad is not ready
                    );
                  }

                  final item = widget.content[index - 1];

                  // İçerik türüne göre widget seçimi
                  if (item["type"] == "paragraph") {
                    final String? text = item["text"];
                    if (text == null) {
                      return const SizedBox();
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      color: const Color(0xFFF9F9F9),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  } else if (item["type"] == "image") {
                    final String? imageUrl = item["url"];
                    if (imageUrl == null) {
                      return const SizedBox();
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      color: const Color(0xFFF9F9F9),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          imageUrl,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                const SizedBox(height: 8),
                                Text(
                                  'Image could not be loaded'.tr(),
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }
                  else if (item["type"] == "video") {
                    final String? videoUrl = item["url"];
                    if (videoUrl == null) {
                      return const SizedBox();
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      color: const Color(0xFFF9F9F9),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            YoutubePlayerWidget(videoUrl: videoUrl),
                          ],
                        ),
                      ),
                    );
                  } else if (item["type"] == "source") {
                    final String? sourceUrl = item["url"];
                    if (sourceUrl == null) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          if (await canLaunch(sourceUrl)) {
                            await launch(sourceUrl);
                          } else {
                            throw 'Could not launch $sourceUrl';
                          }
                        },
                        child: Text(
                          'Source'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            );
          }
        },
      ),
      backgroundColor: const Color(0xFFE8F5E9),
    );
  }
}

// Youtube oynatıcı widget'ı
class YoutubePlayerWidget extends StatefulWidget {
  final String videoUrl;

  const YoutubePlayerWidget({super.key, required this.videoUrl});

  @override
  _YoutubePlayerWidgetState createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    )..addListener(() {
      if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        onReady: () {
          _isPlayerReady = true;
        },
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(color: Colors.black, fontSize: 18.0), // Adjusted for visibility
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black, size: 25.0), // Updated icon color
            onPressed: () {
              debugPrint('Settings Tapped!');
            },
          ),
        ],
      ),
      builder: (context, player) {
        return Column(
          children: [
            player,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black, // Updated play/pause icon color
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _controller.value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                    color: Colors.black, // Updated volume icon color
                  ),
                  onPressed: _isPlayerReady
                      ? () {
                    if (_controller.value.volume == 0) {
                      _controller.unMute(); // Ses kapalıysa sesi aç
                    } else {
                      _controller.mute(); // Ses açıkken sesi kapat
                    }
                    setState(() {});
                  }
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
