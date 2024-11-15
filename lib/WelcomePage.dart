import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aboutbelgium/MessagingPage/LoginPage.dart';
import 'package:aboutbelgium/QuestionAndAnswer/HomePage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:aboutbelgium/MessagingPage/NewUserPage.dart' as newUser;
import 'package:aboutbelgium/MessagingPage/MessageCommunityPage.dart' as messageCommunity;
import 'package:aboutbelgium/MessagingPage/FirebaseKeys.dart';
import 'LanguagePage.dart';
class WelcomePage extends StatefulWidget {
  final Locale locale;
  const WelcomePage({super.key, required this.locale});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  List<Map<String, dynamic>> users = [];
  List<String> documents = [];
  bool isLoading = true; // Track loading state
  Map<String, bool> unreadStatusMap = {}; // Kullanıcıların okuma durumlarını saklar
  Map<String, int>unreadCountStatusMap = {};
  Map<String, Timestamp?> latestMessageTimestampMap = {}; // Store latest message timestamps
  List<String> _blockedByList = [];

  Future<void> _fetchBlockedByList() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc = await FirebaseFirestore.instance.collection(userCollection).doc(userId).get();

    if (userDoc.exists) {
      _blockedByList = List<String>.from(userDoc.data()?['blockedBy'] ?? []);
      setState(() {}); // Liste değiştiğinde yeniden çizin
    }
  }

  void _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'aboutbelgiuminfo@gmail.com',
      query: Uri.encodeFull('subject=Suggestion and Complaint&body='),
    );

    await launchUrl(emailLaunchUri);
  }

  // Pop-up açan fonksiyon
  void _showInfoPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children: [
                    Text(
                    'About This App'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                  'This phone app serves as a platform for connecting with others, sharing insights, and addressing questions about topics you may encounter in Belgium. Below, you will find more details about the app’s main features.'.tr(),
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Text(
            'Community Section'.tr(),
            style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            ),
            ),
            const SizedBox(height: 10),
            Text(
            'In the Community section, users can create a public profile through Google login. Once created, this profile is visible to others, allowing you to share photos and posts that the community can view. You can edit your profile anytime, delete posts, and even temporarily log out or delete your account entirely if needed. By tapping on others’ posts, you have the option to start a private conversation with them and explore detailed profile information. Please remember to be cautious with any personal information you share in this public space.'.tr(),
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Text(
            'Q&A Section'.tr(),
            style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            ),
            ),
            const SizedBox(height: 10),
            Text(
            'This section offers a space for users to ask and answer questions on a variety of topics related to Belgium. However, please keep in mind that responses are based on users’ personal experiences or internet research and may not always reflect official information. Particularly in legal matters, we recommend consulting an official source or a licensed lawyer. The responses here are intended for general guidance and may become outdated over time.'.tr(),
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Text(
            'Suggestions & Complaints Section'.tr(),
            style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            ),
            ),
            const SizedBox(height: 10),
            Text(
            'If you have suggestions or complaints or if there are specific questions you would like us to investigate, feel free to send us an email through this section. We value your feedback and strive to improve the app based on user input.'.tr(),
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('Close'.tr()),
            ),
            ],
            ),
            ),
            );
          },
        );
      },
    );
  }


  Future<void> _navigateToMessagingPage(BuildContext context) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(userCollection).doc(userId).get();

      if (!userDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const newUser.NewUserPage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const messageCommunity.MessageCommunityPage(),
          ),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(locale: widget.locale),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsersFromFirestore();
    Future.delayed(Duration.zero, () {
      showLanguageSupportSnackbar();
    });
  }

  void showLanguageSupportSnackbar() {
    final snackBar = SnackBar(
      content: Text(
        'An update will be coming soon for language support.'.tr(),
        style: TextStyle(fontSize: 16), // Customize text size if needed
      ),
      duration: Duration(seconds: 1), // The duration for which the message will be visible
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchUsersFromFirestore(); // Sayfa açıldığında güncel listeyi çek
  }
  void fetchUsersFromFirestore() async {
    await _fetchBlockedByList(); // Engellenenleri önce al

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    FirebaseFirestore.instance.collection(userCollection).snapshots().listen((querySnapshot) async {
      List<Map<String, dynamic>> fetchedUsers = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      final chatRoomsSnapshot = await FirebaseFirestore.instance.collection(privateChatCollection).get();
      List<String> validUserIds = [];

      for (var doc in chatRoomsSnapshot.docs) {
        // Sohbet odasının messages alt koleksiyonunu dinler
        FirebaseFirestore.instance
            .collection(privateChatCollection)
            .doc(doc.id)
            .collection(privateSecondChatCollection)
            .snapshots()
            .listen((messageSnapshot) {
          if (messageSnapshot.docs.isNotEmpty) {
            String cleanedUserId = doc.id.replaceAll(userId, '').replaceAll('_', '');

            // Engellenen kullanıcıları atla
            if (_blockedByList.contains(cleanedUserId)) {
              return;
            }

            validUserIds.add(cleanedUserId);

            bool hasUnreadMessage = messageSnapshot.docs.any((messageDoc) =>
            messageDoc[privateChatIsRead] == false && messageDoc[privateChatReceiverId] == userId);
            unreadStatusMap[cleanedUserId] = hasUnreadMessage;

            int unreadCount = messageSnapshot.docs.where((messageDoc) =>
            messageDoc[privateChatIsRead] == false && messageDoc[privateChatReceiverId] == userId).length;
            unreadCountStatusMap[cleanedUserId] = unreadCount;

            // En son mesajın zaman damgasını al
            Timestamp? latestTimestamp;
            List<Timestamp> timestamps = messageSnapshot.docs
                .map((messageDoc) => messageDoc[privateChatTime] as Timestamp)
                .toList();
            if (timestamps.isNotEmpty) {
              latestTimestamp = timestamps.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
            }
            latestMessageTimestampMap[cleanedUserId] = latestTimestamp;

            setState(() {
              documents = validUserIds;
              users = fetchedUsers.where((user) => documents.contains(user[userId])).toList();

              // Kullanıcıları en son mesaj tarihine göre sırala
              users.sort((a, b) {
                Timestamp? aTimestamp = latestMessageTimestampMap[a[userId]];
                Timestamp? bTimestamp = latestMessageTimestampMap[b[userId]];
                if (aTimestamp == null && bTimestamp == null) return 0;
                if (aTimestamp == null) return 1;
                if (bTimestamp == null) return -1;
                return bTimestamp.compareTo(aTimestamp);
              });
              isLoading = false;
            });
          }
        });
      }
    }, onError: (error) {
      print("Error fetching users or chat rooms: $error");
      setState(() {
        isLoading = false;
      });
    });
  }

  int getUnreadCount() {
    return unreadCountStatusMap.entries
        .where((entry) => !_blockedByList.contains(entry.key) && entry.value > 0)
        .map((entry) => entry.value)
        .fold(0, (prev, count) => prev + count);
  }


  void _goToLanguagePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LanguagePage(), // Burada LanguagePage'yi kendi sayfanızla değiştirin
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    int unreadCount = getUnreadCount(); // Okunmamış mesajı olan kullanıcı sayısını al

    return Scaffold(
      body: Stack(
        children: [
          // Belçika manzarası arka plan resmi
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/background2.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high, // Kaliteyi artırır
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Butonları sol ve sağa yerleştirir
                  children: [
                    // Language change button placed on the left side
                    Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(top: 40, left: 16.0), // Changed to left alignment
                      child: IconButton(
                        icon: const Icon(Icons.public, size: 30, color: Colors.white),
                        onPressed: () => _goToLanguagePage(context), // Navigate to LanguagePage
                      ),
                    ),
                    // Suggestion and Complaint butonu
                    Container(
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(top: 40, right: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: _sendEmail,
                        icon: const Icon(Icons.info_outline, size: 20, color: Colors.white),
                        label:  Text(
                          'Suggestion & Complaint'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).tr(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Tanıtım butonu, Suggestion and Complaint butonunun hemen altına ve sağa yerleştirildi
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 8, right: 16.0),
                  child: ElevatedButton.icon(  // Use ElevatedButton.icon instead of ElevatedButton
                    onPressed: () => _showInfoPopup(context),
                    icon: const Icon(Icons.info_outline, size: 20, color: Colors.white),  // Icon for the button
                    label:  Text(  // Label for the button text
                      'About App'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Community button
                  // Community button with unread count badge inside it
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        AnimatedButton(
                          onTap: () => _navigateToMessagingPage(context),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.blueAccent], // Gradient from white to blue
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderColor: Colors.transparent, // No border for gradient buttons
                          child:  Text(
                            'Community'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ).tr(),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8.0, // Adjust this value to position the badge correctly
                            child: Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: Colors.red[200],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$unreadCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Question & Answer button
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: AnimatedButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(locale: widget.locale),
                          ),
                        );
                      },
                      gradient: LinearGradient(
                        colors: [Colors.greenAccent, Colors.white], // Gradient from green to white
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderColor: Colors.transparent, // No border for gradient buttons
                      child:  Text(
                        'Question & Answer'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).tr(),
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 60),
                Text(
                  'Created by Yasir TIRAK'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
class AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Gradient gradient;
  final Color borderColor;
  final Widget child;

  const AnimatedButton({
    required this.onTap,
    required this.gradient,
    required this.borderColor,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() {
        _isPressed = true;
      }),
      onTapUp: (_) => setState(() {
        _isPressed = false;
        widget.onTap();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: _isPressed ? 12 : 16), // Slightly adjust padding
        decoration: BoxDecoration(
          gradient: widget.gradient, // Use the gradient
          borderRadius: BorderRadius.circular(30), // Rounded corners
          boxShadow: _isPressed
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5, // Softer shadow
              offset: const Offset(0, 3), // Slight shadow offset
            ),
          ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
