import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'Keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'FirebaseKeys.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:aboutbelgium/AdsKeys.dart';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'dart:math';

class PrivateChatPage extends StatefulWidget {
  final String receiverId; // Hedef kullanıcının ID'si
  final String receiverName; // Hedef kullanıcının adı

  const PrivateChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _PrivateChatPageState createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> with WidgetsBindingObserver{
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? receiverData; // Karşı tarafın bilgilerini tutacağız.
  bool _isImageFullScreen = false; // Tam ekran durumu kontrolü için
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isUploadingImage = false; // Track if an image is being uploaded
  bool _isSendingMessage = false; // Mesaj gönderim kilidi

  Future<void> _sendImageMessage() async {
    setState(() {
      _isUploadingImage = true; // Set loading state to true
    });

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    final chatRoomId = _createChatRoomId(_currentUserId, widget.receiverId);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      try {
        // Load and decode the image from the file
        final originalImageBytes = await imageFile.readAsBytes();
        img.Image? originalImage = img.decodeImage(originalImageBytes);

        // Resize and compress the image if decoding is successful
        if (originalImage != null) {
          // Resize to a width of 800 pixels, maintaining aspect ratio
          img.Image resizedImage = img.copyResize(originalImage, width: 800);

          // Convert the resized image to JPEG format with quality of 85%
          List<int> compressedImageBytes = img.encodeJpg(resizedImage, quality: 85);

          // Create a temporary file to store the resized image for upload
          File compressedImageFile = await File('${pickedFile.path}_compressed.jpg').writeAsBytes(compressedImageBytes);

          // Construct file name and upload compressed image to Firebase Storage
          String fileName = '${storagePrivateChatImages}/${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          UploadTask uploadTask = FirebaseStorage.instance.ref(fileName).putFile(compressedImageFile);
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});

          // Get the download URL of the uploaded image
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          // Add image URL and message details to Firestore under private chat collection
          await _firestore.collection(privateChatCollection)
              .doc(chatRoomId)
              .collection(privateSecondChatCollection).add({
            privateChatImages: downloadUrl,
            privateChatSenderId: _currentUserId,
            privateChatTime: FieldValue.serverTimestamp(),
            privateChatIsRead: false, // Mark as unread initially
            privateChatReceiverId: widget.receiverId,
          });

          // Automatically scroll down to the latest message
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        } else {
          print('Failed to decode image.');
        }

      } catch (e) {
        print('Image send error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while sending the image.'.tr()),
          ),
        );
      }
      setState(() {
        _isUploadingImage = false; // Set loading state to true
      });
    }

  }
  // Sohbet odası oluşturmak için ID
  String _createChatRoomId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 ? "$userId1\_$userId2" : "$userId2\_$userId1";
  }

  // Karşı kullanıcının bilgilerini almak için fonksiyon
  Future<void> _fetchReceiverData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(userCollection)
          .doc(widget.receiverId)
          .get();

      if (snapshot.exists) {
        setState(() {
          receiverData = snapshot.data(); // Verileri alıyoruz.
        });
      }
    } catch (e) {
      print("Error fetching receiver data: $e");
    }
  }
  Future<void> _markMessagesAsRead() async {
    final chatRoomId = _createChatRoomId(_currentUserId, widget.receiverId);
    final unreadMessagesQuery = _firestore
        .collection(privateChatCollection)
        .doc(chatRoomId)
        .collection(privateSecondChatCollection)
        .where(privateChatReceiverId, isEqualTo: _currentUserId)
        .where(privateChatIsRead, isEqualTo: false);

    final unreadMessagesSnapshot = await unreadMessagesQuery.get();
    for (var doc in unreadMessagesSnapshot.docs) {
      await doc.reference.update({privateChatIsRead: true});
    }
  }
  @override
  void initState() {
    super.initState();
    _markMessagesAsRead(); // Mesajları okundu olarak işaretle
    _fetchReceiverData(); // Karşı tarafın bilgilerini almak için çağırıyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
    _loadInterstitialAd();
  }
  void _showRandomInterstitialAds(){
    Random random = Random();
    int sayi = random.nextInt(4) + 1;
    if (sayi == 2){
      print ("neden bu say $sayi ");
      _showInterstitialAd();
    }
  }
  @override
  void dispose() {
    if (_isInterstitialAdReady) {
      _interstitialAd.dispose();
    }
    super.dispose();
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
  @override
  Widget build(BuildContext context) {
    final chatRoomId = _createChatRoomId(_currentUserId, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
      ),
      body: Column(
        children: [
          receiverData != null
              ? _buildUserProfile() // Profil bilgileri doluysa göster
              : const Center(child: CircularProgressIndicator()), // Yükleniyorsa bekletiyoruz
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection(privateChatCollection)
                  .doc(chatRoomId)
                  .collection(privateSecondChatCollection)
                  .orderBy(privateChatTime)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                // Yeni mesajlar geldiğinde otomatik olarak aşağı kaydır
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    final isMe = messageData[privateChatSenderId] == _currentUserId;
                    return _buildMessageItem(messageData, isMe);
                  },
                );
              },
            ),
          ),
          _isUploadingImage ? _buildLoadingIndicator() : _buildMessageInput(chatRoomId), // Removed the extra semicolon here
        ],
      ),
    );
  }

// Method to build the loading indicator
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(
            'Sending image...'.tr(),
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
  // Dinamik olarak kullanıcı profilini gösteren widget
  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.all(10.0), // Container'a dış boşluk ekliyoruz
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), // Gölgeli görünüm
          ),
        ],
      ),
      child: Row(
        children: [
          // GestureDetector ile profil resmine tıklanabilirlik ekliyoruz.
          GestureDetector(
            onTap: () {
              // Resme tıklandığında büyük gösterim
              _showProfileImageFullScreen(receiverData?[profileImageUrl]);
            },
            child: CircleAvatar(
              radius: 40.0,
              backgroundImage: NetworkImage(
                receiverData?[profileImageUrl] ?? 'https://via.placeholder.com/150',
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          // Kullanıcı Bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı Adı
                Text(
                  receiverData?[userName] ?? 'Unknown User',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900, // const kaldırıldı
                  ),
                ),
                const SizedBox(height: 6.0),
                // Ülke ve Yaş
                Row(
                  children: [
                    // Country Icon
                    Image.asset(
                      'assets/flags/${CountriesIcon[receiverData?[userCountryIndex]]}.png',
                      height: 30, // Smaller size for the country icon
                      width: 30,
                    ),
                    const SizedBox(width: 20.0),
                    // Age Icon
                    Text(
                      "${receiverData?[userAge] ?? 'Unknown'}",
                      style: TextStyle(color: Colors.teal.shade900, fontSize: 18),
                    ),
                    const SizedBox(width: 20.0),
                    // Cinsiyet
                    Image.asset(
                      'assets/genders/${GendersIcon[receiverData?[userGenderIndex]]}.png',
                      height: 30, // Smaller size for the gender icon
                      width: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                // Kısa Bilgi (ShortInfo)
                SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal.shade700, size: 18),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          receiverData?[userShortInfo] ?? 'No information provided.',
                          style: TextStyle(color: Colors.teal.shade900, fontSize: 14),
                          softWrap: true, // Metni otomatik olarak sar
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // Profil resmini tam ekran göstermek için fonksiyon
  void _showProfileImageFullScreen(String? imageUrl) {
    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context); // Tekrar dokunulduğunda tam ekran kapatılır.
          },
          child: Dialog(
            backgroundColor: Colors.transparent, // Arkaplanı şeffaf yapıyoruz
            child: Center(
              child: Image.network(imageUrl), // Resmi büyük olarak gösteriyoruz
            ),
          ),
        );
      },
    );
  }

  // Mesaj balonları
  Widget _buildMessageItem(QueryDocumentSnapshot messageData, bool isMe) {

    Map<String, dynamic> data = messageData.data() as Map<String, dynamic>;

    String text = data['text'] ?? '';
    String? imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: isMe // Only allow the current user to delete their messages
                  ? () async {
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title:  Text('Delete Message'.tr()),
                    content:  Text('Are you sure you want to delete this message?'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child:  Text('Cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child:  Text('Delete'.tr()),
                      ),
                    ],
                  ),
                );

                if (confirmDelete) {
                  // Update the message as deleted
                  await _firestore
                      .collection('facetofacechat')
                      .doc(_createChatRoomId(_currentUserId, widget.receiverId))
                      .collection('messages')
                      .doc(messageData.id)
                      .update({
                    'text': '-----!!!', // Set the text as "Deleted"
                    'imageUrl': null,
                    // Remove the image URL
                  });
                }
              }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isMe ? Colors.green[100] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (text.isNotEmpty)
                        Text(
                          text,
                          style: TextStyle(color: Colors.grey[800], fontFamily: 'Roboto'),
                        ),
                      if (imageUrl != null) // Show image if available
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isImageFullScreen = !_isImageFullScreen;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: _isImageFullScreen
                                ? Image.network(imageUrl) // Show full-screen image
                                : Image.network(
                              imageUrl,
                              width: 150, // Show small-sized image
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMessageInput(String chatRoomId) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo, color: Colors.grey[700]),
                onPressed: _sendImageMessage,  // Image sending function
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Write a message...'.tr(),
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  GestureDetector(
                    onTap: () async {
                    if ( _messageController.text.isNotEmpty) {
                      if (_isSendingMessage) return; // Eğer mesaj gönderiliyorsa tekrar gönderme
                      setState(() {
                          _isSendingMessage = true; // Gönderim başladığında kilidi etkinleştir
                        });
                        await _firestore.collection('facetofacechat')
                            .doc(chatRoomId)
                            .collection('messages')
                            .add({
                          'chatRoomId': chatRoomId,
                          'text': _messageController.text,
                          'senderId': _currentUserId,
                          'receiverId': widget.receiverId,
                          'timestamp': FieldValue.serverTimestamp(),
                          'isRead': false,
                        });
                        await _firestore.collection('facetofacechat')
                            .doc(chatRoomId)
                            .set({
                          'chatRoomId': chatRoomId,
                        }, SetOptions(merge: true));
                        _messageController.clear();
                        _scrollToBottom();
                      }
                    setState(() {
                      _isSendingMessage = false; // Gönderim tamamlandığında kilidi kaldır
                    });
                    },
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),

                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
// Function to scroll to the bottom of the message list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
}
