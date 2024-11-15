import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aboutbelgium/WelcomePage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'NewUserPage.dart';
import 'PrivateChatPage.dart';
import 'FriendsListPage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'FirebaseKeys.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'package:aboutbelgium/AdsKeys.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

class MessageCommunityPage extends StatefulWidget {
  const MessageCommunityPage({super.key});

  @override
  _MessageCommunityPageState createState() => _MessageCommunityPageState();
}

class _MessageCommunityPageState extends State<MessageCommunityPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isImageFullScreen = false; // Tam ekran durumu kontrolü için
  List<Map<String, dynamic>> users = [];
  Map<String, int>unreadCountStatusMap = {};
  List<String> documents = [];
  bool isLoading = true; // Track loading state
  Map<String, String> _profileImageCache = {};
  final ValueNotifier<int> totalUnreadUsers = ValueNotifier<int>(0); // Bildirim ikonunu güncellemek için ValueNotifier
  final ScrollController _scrollController = ScrollController();
  bool _isUploadingImage = false; // Track if an image is being uploaded
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isSendingMessage = false; // Mesaj gönderim kilidi
  List<String> _blockedByList = [];

  Future<void> _fetchBlockedByList() async {
    _firestore.collection(userCollection).doc(_currentUserId).snapshots().listen((userDoc) {
      if (userDoc.exists) {
        _blockedByList = List<String>.from(userDoc.data()?['blockedBy'] ?? []);
        setState(() {}); // Liste değiştiğinde yeniden çizin
      }
    });
  }


  Future<void> _sendImageMessage() async {
      setState(() {
        _isUploadingImage = true; // Set loading state to true
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        try {
          // Read the image from the file
          final originalImageBytes = await imageFile.readAsBytes();
          img.Image? originalImage = img.decodeImage(originalImageBytes);

          // Resize and compress the image
          if (originalImage != null) {
            // Resize to a width of 800 pixels, maintaining aspect ratio
            img.Image resizedImage = img.copyResize(originalImage, width: 800);

            // Convert the resized image to JPEG format with quality of 85%
            List<int> compressedImageBytes = img.encodeJpg(resizedImage, quality: 85);

            // Create a temporary file to store the resized image
            File compressedImageFile = await File('${pickedFile.path}_compressed.jpg').writeAsBytes(compressedImageBytes);

            // Prepare the file for uploading
            String fileName = '${storageGeneralMessageImages}/${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            UploadTask uploadTask = FirebaseStorage.instance.ref(fileName).putFile(compressedImageFile);
            TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});

            // Get the download URL
            String downloadUrl = await taskSnapshot.ref.getDownloadURL();
            var userDoc = await FirebaseFirestore.instance.collection(userCollection).doc(_currentUserId).get();
            String userN = userDoc[userName];

            // Send the image message
            await _firestore.collection(generalMessages).add({
              privateChatImages: downloadUrl,
              generalUserId: _currentUserId,
              generalTime: FieldValue.serverTimestamp(),
              userName: userN,
            });
          }
        } catch (e) {
          print('Image send error: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('An error occurred while sending the image.'.tr()),
          ));
        }
        setState(() {
          _isUploadingImage = false; // Set loading state to true
        });
      }
  }

  // Sign out method remains the same
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      await googleSignIn.signOut();
      print('Kullanıcı çıkış yaptı.');
    } catch (error) {
      print('Çıkış sırasında hata oluştu: $error');
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage(locale: Locale('en'))),
    );
  }

  // Delete account method with confirmation dialog
  Future<void> _deleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'.tr()),
        content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            child: Text('Delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        // Firebase Authentication'dan kullanıcıyı sil
        await FirebaseAuth.instance.currentUser!.delete();
        // Eğer başarılıysa tüm verileri sil
        await _deleteUserData();
      } on FirebaseAuthException catch (e) {
        print('Error FirebaseAuthException: $e');

        if (e.code == "requires-recent-login") {
          // Yeniden kimlik doğrulama ve silme işlemi
          bool reauthenticated = await _reauthenticateAndDelete();
          if (reauthenticated) {
            await FirebaseAuth.instance.currentUser!.delete();

            await _deleteUserData(); // Tüm verileri sil
            // Firebase Authentication'dan kullanıcıyı sil
          } else {
            // Kullanıcı giriş yapamazsa işlem iptal edilir
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(
              content: Text('Re-authentication failed. Account deletion canceled.'.tr()),
            ));
          }
        } else {
          // Diğer Firebase hatalarını yönet
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(
            content: Text('An error occurred. Please try again.'.tr()),
          ));
        }
      } catch (e) {
        print('Error : $e');
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(
          content: Text('An error occurred. Please try again.'.tr()),
        ));
      }
    }
  }

  Future<bool> _reauthenticateAndDelete() async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    try {
      final providerData = firebaseAuth.currentUser?.providerData.first;

      if (providerData != null) {
        if (AppleAuthProvider().providerId == providerData.providerId) {
          await firebaseAuth.currentUser!
              .reauthenticateWithProvider(AppleAuthProvider());
        } else if (GoogleAuthProvider().providerId == providerData.providerId) {
          await firebaseAuth.currentUser!
              .reauthenticateWithProvider(GoogleAuthProvider());
        }

        return true; // Giriş başarılı, veri silmeye devam et
      }
    } catch (e) {
      print('Re-authentication failed: $e');
    }

    return false; // Giriş başarısız, işlem iptal edilecek
  }

  Future<void> _deleteUserData() async {
    try {
      // Firestore verilerini, depolama ve diğer işlemleri sil
      final facetofaceSnapshot =
      await _firestore.collection(privateChatCollection).get();

      for (var doc in facetofaceSnapshot.docs) {
        if (doc.id.contains(_currentUserId)) {
          final messagesSnapshot =
          await doc.reference.collection(privateSecondChatCollection).get();
          for (var messageDoc in messagesSnapshot.docs) {
            await messageDoc.reference.delete(); // Mesajları sil
          }

          await doc.reference.delete(); // Ana dokümanı sil
        }
      }

      final messagesSnapshot = await _firestore
          .collection(generalMessages)
          .where(generalUserId, isEqualTo: _currentUserId)
          .get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      final chatImagesRef =
      FirebaseStorage.instance.ref().child(storageGeneralMessageImages);
      final chatImagesList = await chatImagesRef.listAll();
      for (var item in chatImagesList.items) {
        if (item.name.contains(_currentUserId)) {
          await item.delete();
        }
      }

      final userImagesRef =
      FirebaseStorage.instance.ref().child('${storageProfileImages}/$_currentUserId');
      await userImagesRef.listAll().then((listResult) async {
        for (var item in listResult.items) {
          await item.delete();
        }
      });

      await _firestore.collection(userCollection).doc(_currentUserId).delete();

      // Son olarak çıkış yap
      _signOut();
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        content: Text('Error deleting account. Please try again.'.tr()),
      ));
    }
  }

  // New method to navigate to Update Profile Page
  void _updateProfile() async {
    final userDoc = await _firestore.collection(userCollection).doc(_currentUserId).get();

    if (userDoc.exists) {
      String username = userDoc.data()?[userName] ?? '';
      String age = userDoc.data()?[userAge]?.toString() ?? '';
      String gender = userDoc.data()?[userGenderIndex]?.toString() ?? '';
      String country = userDoc.data()?[userCountryIndex]?.toString() ?? '';
      String shortInfo = userDoc.data()?[userShortInfo] ?? '';
      String profileImageUrl = '';

      // Fetch the profile image URL
      try {
        final ref = FirebaseStorage.instance.ref().child('${storageProfileImages}/$_currentUserId/profile_image.jpg');
        profileImageUrl = await ref.getDownloadURL();
      } catch (e) {
        print('Error fetching image URL: $e');
      }

      // Convert gender and country to integers (index based on your original list)
      int? genderIndex = int.tryParse(gender); // Assuming gender is stored as an index in the Firestore
      int? countryIndex = int.tryParse(country); // Assuming country is stored as an index in the Firestore

      // Navigate to NewUserPage with the fetched data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewUserPage(
            username: username,
            age: age,
            country: countryIndex != null ? countryIndex.toString() : null, // Convert to string
            gender: genderIndex != null ? genderIndex.toString() : null, // Convert to string
            shortInfo: shortInfo,
            profileImageUrl: profileImageUrl,
          ),
        ),
      );
    } else {
      // Optionally, handle the case where the user document does not exist
      print("User profile does not exist.");
    }
  }
  @override
  void initState() {
    super.initState();
    fetchUsersFromFirestore();
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
  void _scrollToBottom() {
    // Son mesaja otomatik olarak kaydır
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  Future<void> _sendMessage() async {
    if (_isSendingMessage) return; // Eğer mesaj gönderiliyorsa tekrar gönderme

    setState(() {
      _isSendingMessage = true; // Gönderim başladığında kilidi etkinleştir
    });
    var userDoc = await FirebaseFirestore.instance.collection(userCollection).doc(_currentUserId).get();
    String userN = userDoc[userName];
    if (_messageController.text.isNotEmpty) {
      await _firestore.collection(generalMessages).add({
        generalText: _messageController.text,
        generalUserId: _currentUserId,
        generalTime: FieldValue.serverTimestamp(),
        userName : userN,
      });
      _messageController.clear();
    }
    setState(() {
      _isSendingMessage = false; // Gönderim tamamlandığında kilidi kaldır
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchUsersFromFirestore(); // Sayfa açıldığında güncel listeyi çek
  }
  // Mevcut fetchUsersFromFirestore işlevini güncelle
  void fetchUsersFromFirestore() async {
    await _fetchBlockedByList(); // Engelleyenleri önce al

    var userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    FirebaseFirestore.instance.collection(privateChatCollection).snapshots().listen((chatRoomSnapshot) {
      unreadCountStatusMap.clear();
      int totalUnread = 0;

      for (var doc in chatRoomSnapshot.docs) {
        String cleanedUserId = doc.id.replaceAll(userId, '').replaceAll('_', '');

        // Eğer kullanıcı sizi engellediyse, işlemden atla
        if (_blockedByList.contains(cleanedUserId)) {
          continue;
        }

        FirebaseFirestore.instance
            .collection(privateChatCollection)
            .doc(doc.id)
            .collection(privateSecondChatCollection)
            .where(privateChatReceiverId, isEqualTo: userId)
            .where(privateChatIsRead, isEqualTo: false)
            .snapshots()
            .listen((unreadMessagesSnapshot) {
          int unreadCount = unreadMessagesSnapshot.docs.length;

          // Engellenen kullanıcıların unreadCount içine dahil edilmesini engelle
          if (!_blockedByList.contains(cleanedUserId)) {
            unreadCountStatusMap[cleanedUserId] = unreadCount;
          }
          totalUnread = unreadCountStatusMap.values.where((count) => count > 0).length;
          totalUnreadUsers.value = totalUnread;
        });
      }
    });
  }



  int getUnreadCount() {
    return unreadCountStatusMap.values.where((count) => count > 0).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: const Icon(Icons.home), // Example: Home icon
          onPressed: () {
            _showRandomInterstitialAds();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomePage(locale: Locale('en')),
              ),
            );
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.group),
                onPressed: () async {
                  _showRandomInterstitialAds();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendsListPage(currentUserId: _currentUserId),
                    ),
                  );
                },
              ),
              // Use ValueListenableBuilder to listen only for icon updates
              ValueListenableBuilder<int>(
                valueListenable: totalUnreadUsers,
                builder: (context, unreadCount, child) {
                  if (unreadCount > 0) {
                    return Positioned(
                      right: 8.0,
                      top: 8.0,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink(); // Return an empty widget if no notifications
                  }
                },
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'update_profile') {
                _updateProfile();
                _showRandomInterstitialAds();
              } else if (value == 'sign_out') {
                _signOut();
                _showRandomInterstitialAds();
              } else if (value == 'delete_account') {
                _deleteAccount();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'update_profile',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.teal[400]),
                      const SizedBox(width: 10),
                      Text('Update Profile'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sign_out',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[400]),
                      const SizedBox(width: 10),
                      Text('Sign Out'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete_account',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red[400]),
                      const SizedBox(width: 10),
                      Text('Delete Account'.tr()),
                    ],
                  ),
                ),
              ];
            },
            icon: const Icon(Icons.settings),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.grey[100],
            elevation: 8,
            offset: const Offset(0, 50),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orangeAccent, // Orange tones at sunset
              Colors.pinkAccent, // Soft pink tones
              Colors.deepPurpleAccent, // Purple tones
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child:
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection(generalMessages).orderBy(generalTime, descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!.docs.where((message) {
                      // Eğer mesaj gönderen kullanıcı sizi engellediyse atla
                      final userId = message[generalUserId];
                      return !_blockedByList.contains(userId);
                    }).toList().reversed.toList();

                    if (messages.isNotEmpty) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _scrollToBottom();
                            });
                          }
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageData = messages[index];
                        final isMe = messageData[generalUserId] == _currentUserId;
                        return _buildMessageBubble(messageData, isMe);
                      },
                    );
                  },
                ),
            ),
            _isUploadingImage ? _buildLoadingIndicator() : _buildMessageInput(),
          ],
        ),
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
            'Sending image...',
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
  // Method to build the message input area
  Widget _buildMessageInput() {
    return Container(
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
            onPressed: _sendImageMessage,  // Resim gönderme fonksiyonunu çağır
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
          GestureDetector(
            onTap: _isSendingMessage ? null : _sendMessage, // Gönderim devam ediyorsa devre dışı bırak
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
    );
  }


  Widget _buildMessageBubble(QueryDocumentSnapshot messageData, bool isMe) {
    String userId = messageData[generalUserId];
    String userN = messageData[userName];
    Map<String, dynamic> data = messageData.data() as Map<String, dynamic>;

    String text = data.containsKey(generalText) ? data[generalText] : '';
    String? imageUrl = data.containsKey(generalChatImages) ? data[generalChatImages] : null;

    final List<Color> userColors = [
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.red[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
      Colors.amber[300]!,
      Colors.cyan[300]!,
      Colors.indigo[300]!,
      Colors.brown[300]!,
    ];

    int colorIndex = userId.hashCode % userColors.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildUserProfileImage(userId),
          Flexible(
            child: GestureDetector(
          onLongPress: () async {
          if (isMe) {
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
                  // Mesajı silindi olarak güncelle (metin veya resim)
                  await _firestore.collection(generalMessages).doc(messageData.id).update({
                    generalText: '---------!!!',       // Yazı kısmını "Deleted" yap
                    generalChatImages: null,        // Resim URL'sini kaldır
                  });
                }
              }else {
            // Diğer kullanıcının mesajını şikayet etme işlemi
            await _showReportDialog(
              reportedUserId: userId,
              reportedUserName: userN,
              messageContent: text,
              messageId: messageData.id,
              imageUrl: imageUrl, // Resim URL'sini ekledik

            );
          }
          },
              onTap: !isMe
                  ? () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivateChatPage(
                      receiverId: userId,
                      receiverName: userN,
                    ),
                  ),
                );
              }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          userN,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: userColors[colorIndex],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Eğer "Deleted" mesajı varsa göster
                          Text(
                            text.isNotEmpty ? text : '',  // Sadece "Deleted" yazı varsa göster
                            style: TextStyle(color: Colors.grey[800], fontFamily: 'Roboto'),
                          ),
                          if (imageUrl != null) // Eğer mesajda resim varsa göster
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isImageFullScreen = !_isImageFullScreen;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: _isImageFullScreen
                                    ? Image.network(imageUrl) // Tam ekran resim
                                    : Image.network(
                                  imageUrl,
                                  width: 150, // Küçük boyutta göster
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _showReportDialog({
    required String reportedUserId,
    required String reportedUserName,
    required String messageContent,
    required String messageId,
    String? imageUrl,
  }) async {
    String reportReason = '';
    String email = '';
    String confirmEmail = '';
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Report it'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık ikonu eklendi
                  Icon(
                    Icons.report_problem,
                    color: Colors.redAccent,
                    size: 60,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please enter your email address. This will be used to provide you with feedback.'.tr(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Your Email Address'.tr(),
                      hintText: 'example@domain.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address.'.tr();
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email address.'.tr();
                      }
                      return null;
                    },
                    onChanged: (value) {
                      email = value;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Verify Your Email Address'.tr(),
                      hintText: 'example@domain.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please re-enter your email address.'.tr();
                      } else if (value != email) {
                        return 'The email addresses do not match.'.tr();
                      }
                      return null;
                    },
                    onChanged: (value) {
                      confirmEmail = value;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    onChanged: (value) {
                      reportReason = value;
                    },
                    decoration: InputDecoration(
                      labelText: 'Reason for Complaint'.tr(),
                      hintText: 'Please describe the issue...'.tr(),
                      prefixIcon: Icon(Icons.comment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (reportReason.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('reports').add({
                      'reportedUserId': reportedUserId,
                      'reportedUserName': reportedUserName,
                      'messageContent': messageContent,
                      'messageId': messageId,
                      'imageUrl': imageUrl,
                      'reportReason': reportReason,
                      'reportingUserId': _currentUserId,
                      'reportingUserEmail': email,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Your complaint has been sent.'.tr())),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter the reason for the complaint.'.tr())),
                    );
                  }
                }
              },
              child: Text('Send'.tr()),
            ),
          ],
        );
      },
    );
  }


  Widget _buildUserProfileImage(String userId) {
    if (_profileImageCache.containsKey(userId)) {
      // Eğer cache'te varsa, direkt cache'den alıyoruz
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(_profileImageCache[userId]!),
      );
    } else {
      return FutureBuilder<String>(
        future: _getUserImageUrl(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircleAvatar(
              radius: 20,
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            );
          } else {
            // URL'yi cache'e ekliyoruz
            _profileImageCache[userId] = snapshot.data!;
            return CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(snapshot.data!),
            );
          }
        },
      );
    }
  }

  Future<String> _getUserImageUrl(String userId) async {
    final ref = FirebaseStorage.instance.ref().child('userImages/$userId/profile_image.jpg');
    try {
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }
}