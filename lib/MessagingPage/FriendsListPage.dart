import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PrivateChatPage.dart';
import 'Keys.dart';
import 'FirebaseKeys.dart';
import 'package:easy_localization/easy_localization.dart';

class FriendsListPage extends StatefulWidget {
  final String currentUserId;

  const FriendsListPage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _FriendsListPageState createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  List<Map<String, dynamic>> users = [];
  List<String> documents = [];
  bool isLoading = true; // Track loading state
  Map<String, bool> unreadStatusMap = {}; // Kullanıcıların okuma durumlarını saklar
  Map<String, int>unreadCountStatusMap = {};
  Map<String, Timestamp?> latestMessageTimestampMap = {}; // Store latest message timestamps

  @override
  void initState() {
    super.initState();
    fetchUsersFromFirestore(); // Fetch initially
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchUsersFromFirestore(); // Sayfa açıldığında güncel listeyi çek
  }

  void fetchUsersFromFirestore() {
    var userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Kullanıcıları dinleyerek anlık güncellemeler alır
    FirebaseFirestore.instance.collection(userCollection).snapshots().listen((querySnapshot) async {
      List<Map<String, dynamic>> fetchedUsers = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      var chatRoomsSnapshot = await FirebaseFirestore.instance.collection(privateChatCollection).get();
      List<String> validUserIds = [];

      for (var doc in chatRoomsSnapshot.docs) {
        // Her sohbet odasının messages alt koleksiyonunu dinler
        FirebaseFirestore.instance
            .collection(privateChatCollection)
            .doc(doc.id)
            .collection(privateSecondChatCollection)
            .snapshots()
            .listen((messageSnapshot) {
          // Mesajlar varsa kullanıcı ID'sini ayıkla
          if (messageSnapshot.docs.isNotEmpty) {
            String cleanedUserId = doc.id.replaceAll(userId, '').replaceAll('_', '');
            validUserIds.add(cleanedUserId);

            bool hasUnreadMessage = messageSnapshot.docs.any((messageDoc) =>
            messageDoc[privateChatIsRead] == false && messageDoc[privateChatReceiverId] == userId);
            unreadStatusMap[cleanedUserId] = hasUnreadMessage;

            int unreadCount = messageSnapshot.docs.where((messageDoc) =>
            messageDoc[privateChatIsRead] == false && messageDoc[privateChatReceiverId] == userId).length;
            unreadCountStatusMap[cleanedUserId] = unreadCount;

            // En son mesajın timestamp’ini al
            Timestamp? latestTimestamp;
            List<Timestamp> timestamps = messageSnapshot.docs
                .map((messageDoc) => messageDoc[privateChatTime] as Timestamp)
                .toList();
            if (timestamps.isNotEmpty) {
              latestTimestamp = timestamps.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
            }
            latestMessageTimestampMap[cleanedUserId] = latestTimestamp;

            // State’i anlık olarak güncelle
            setState(() {
              documents = validUserIds;
              users = fetchedUsers.where((user) => documents.contains(user['userID'])).toList();

              // Kullanıcıları en son mesaj tarihine göre sırala
              users.sort((a, b) {
                Timestamp? aTimestamp = latestMessageTimestampMap[a['userID']];
                Timestamp? bTimestamp = latestMessageTimestampMap[b['userID']];
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Contacts'.tr()),
        backgroundColor: Colors.transparent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : users.isEmpty
          ?  Center(child: Text('No friends found.'.tr()))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return buildUserCard(users[index]);
        },
      ),
    );
  }

  Widget buildUserCard(Map<String, dynamic> user) {
    bool hasUnreadMessages = unreadStatusMap[user[userId]] ?? false;
    int unreadCount = unreadCountStatusMap[user[userId]] ?? 0; // Get unread message count

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivateChatPage(
              receiverId: user[userId],
              receiverName: user[userName] ?? 'Unknown User',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: hasUnreadMessages ? Colors.green[600] : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // User card content
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user[profileImageUrl] != null && user[profileImageUrl].isNotEmpty
                          ? NetworkImage(user['profileImageUrl'])
                          : null,
                      child: user[profileImageUrl] == null
                          ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.teal,
                      )
                          : null,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          Text(
                            user[userName] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 23.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Country icon
                              if (user[userCountryIndex] != null)
                                Image.asset(
                                  'assets/flags/${CountriesIcon[user[userCountryIndex]]}.png',
                                  height: 27,
                                  width: 27,
                                ),
                              const SizedBox(width: 12.0),
                              // Gender icon
                              if (user[userGenderIndex] != null)
                                Image.asset(
                                  'assets/genders/${GendersIcon[user[userGenderIndex]]}.png',
                                  height: 27,
                                  width: 27,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Unread messages badge (Positioned inside Stack)
            if (unreadCount > 0)
              Positioned(
                right: 8.0,
                top: 8.0,
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
    );
  }

}