import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aboutbelgium/MessagingPage/NewUserPage.dart' as newUser;
import 'package:aboutbelgium/MessagingPage/MessageCommunityPage.dart' as messageCommunity;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aboutbelgium/WelcomePage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'EmailLoginPage.dart';
import 'FirebaseKeys.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginPage extends StatefulWidget {
  final Locale locale;

  const LoginPage({super.key, required this.locale});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _showAlert(String message) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text('Warning!'.tr()),
          content: Text(message),
          actions: [
            TextButton(
              child:  Text('Okay'.tr()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Google Sign-In method
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          String userId = userCredential.user!.uid;

          // Check if the user has a profile
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(userCollection).doc(userId).get();

          if (!userDoc.exists) {
            // User does not have a profile, navigate to NewUserPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const newUser.NewUserPage(),
              ),
            );
          } else {
            // User has a profile, navigate to MessageCommunityPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const messageCommunity.MessageCommunityPage(),
              ),
            );
          }
        }
      }
    } catch (error) {
      print('Login failed: $error');
      _showAlert('Failed to sign in with Google. Please try again.'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Arka plan rengini şeffaf yap
      extendBodyBehindAppBar: true, // AppBar'ın arkasını şeffaf yap
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomePage(locale: Locale('en')),
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[300]!, Colors.green[700]!],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(-4, -4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25.0), // Köşelerin yumuşaklık derecesi
                    child: Image.asset(
                      'assets/images/aboutBelgiumLogo.png',
                      height: 120,
                    ),
                  ),

                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[500]!, Colors.yellow[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(FontAwesomeIcons.google, color: Colors.white),
                      label: LayoutBuilder(
                        builder: (context, constraints) {
                          // Ekran boyutuna göre yazı boyutunu ayarlıyoruz
                          double fontSize = constraints.maxWidth * 0.07; // Yüzde 5'lik bir oranla font boyutunu ayarlıyoruz.
                          if (fontSize > 20) fontSize = 20; // Maksimum font boyutunu 20 ile sınırlıyoruz.

                          return Text(
                            'Continue with Google'.tr(),
                            style: GoogleFonts.poppins(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                        backgroundColor: Colors.transparent, // Transparan zemin rengi
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                   const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmailLoginPage()),
                      );
                    },
                    child: Text(
                      'Login with Email/Password'.tr(),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
