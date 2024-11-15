import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:aboutbelgium/MessagingPage/FirebaseKeys.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:aboutbelgium/SplashScreen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:advertising_id/advertising_id.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.body}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

  await _requestNotificationPermission();
  FirebaseMessaging.onBackgroundMessage(_messageHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      print("Notification Title: ${notification.title}");
      print("Notification Body: ${notification.body}");
    }
  });
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,

  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale("en"),
        Locale("fr"),
        Locale("tr"),
        Locale("es"),
        Locale("de"),
        Locale("nl"),
        Locale("ar"),
        Locale("pl"),
        Locale("pt"),
        Locale("it"),
      ],
      path: "assets/languages",
      fallbackLocale: const Locale("en"),
      child: const MyApp(),
    ),
  );
  FlutterNativeSplash.remove();

}

Future<void> _requestNotificationPermission() async {
  // Eğer izin verilmişse fonksiyonu erken sonlandır
  if (await Permission.notification.isGranted) {
    print("Notification permission has already been granted.");
    return; // İzin verildiyse erken çıkış
  }
  // İzin iste
  var status = await Permission.notification.request();

  if (status.isGranted) {
    print("Notification permission granted.");
  } else if (status.isDenied) {
    print("Notification permission denied.");
  } else if (status.isPermanentlyDenied) {
    print("Notification permission permanently denied. Please enable it from settings.");
    openAppSettings();
  }
}


class MyApp extends StatefulWidget { // Change to StatefulWidget
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState(); // Create a state for MyApp
}

class _MyAppState extends State<MyApp> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore
  String? _token;

  @override
  void initState() {
    super.initState();
    _getToken();
    _configureFirebaseMessaging();
    getAdvertisingId();
  }
  Future<void> getAdvertisingId() async {
    try {
      final idfa = await AdvertisingId.id(true); // true for iOS, false for Android
      print('IDFA: $idfa');
    } catch (e) {
      print('Error retrieving IDFA: $e');
    }
  }

  Future<void> _getToken() async {
    try {
      // Repeatedly check if APNS token is null before attempting to retrieve FCM token
      String? apnsToken;
      while (apnsToken == null) {
        apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(Duration(seconds: 1));
      }
      print("APNS Token: $apnsToken");

      String? token = await _firebaseMessaging.getToken();
      setState(() {
        _token = token;
      });
      print("FCM Token: $token");
      _updateTokenInFirestore(_token);
    } catch (e) {
      print("Error getting FCM token: $e");
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      setState(() {
        _token = newToken;
      });
      print("FCM Token refreshed: $newToken");
      _updateTokenInFirestore(newToken);
    });
  }

  Future<void> _updateTokenInFirestore(String? token) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userDocRef = _firestore.collection(userCollection).doc(currentUserId);
    await userDocRef.update({'fcmToken': token}).then((_) {
      print("FCM Token updated in Firestore for user $currentUserId");
    }).catchError((error) {
      print("Error updating FCM Token in Firestore: $error");
    });
  }

  void _configureFirebaseMessaging() {
    _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: $message");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onMessageOpenedApp: $message");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'About Belgium',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const SplashScreen(), // Splash ekranını ilk sayfa olarak ayarla
    );
  }
}
