import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'EmailRegistrationPage.dart';
import 'FirebaseKeys.dart';
import 'package:aboutbelgium/MessagingPage/NewUserPage.dart' as newUser;
import 'package:aboutbelgium/MessagingPage/MessageCommunityPage.dart' as messageCommunity;

class EmailLoginPage extends StatefulWidget {
  @override
  _EmailLoginPageState createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          String userId = userCredential.user!.uid;

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
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;

        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found for this email.'.tr();
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.'.tr();
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.'.tr();
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.'.tr();
            break;
          case 'too-many-requests':
            errorMessage = 'Too many login attempts. Please try again later.'.tr();
            break;
          default:
            errorMessage = 'An unexpected error occurred. Please try again.'.tr();
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Önceki sayfaya döner
          },
        ),
      ),
      body: Stack(
        children: [
          // Sayfa içeriği
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25.0), // Köşelerin yumuşaklık derecesi
                            child: Image.asset(
                              'assets/images/aboutBelgiumLogo.png',
                              height: 120,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email'.tr(),
                              prefixIcon: const Icon(Icons.email, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email.'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password'.tr(),
                              prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password.'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _signInWithEmailAndPassword,
                            child: Text('Login'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () async {
                              final emailController = TextEditingController();
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Reset Password'.tr()),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Enter your email to receive a password reset link.'.tr()),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          labelText: 'Email'.tr(),
                                          prefixIcon: const Icon(Icons.email),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Cancel'.tr()),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (emailController.text.isNotEmpty) {
                                          try {
                                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                              email: emailController.text.trim(),
                                            );
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Password reset link has been sent to your email.'.tr(),
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } on FirebaseAuthException catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to send password reset email: ${e.message}'.tr(),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Text('Send'.tr()),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              'Forgot your password?'.tr(),
                              style: GoogleFonts.poppins(color: Colors.teal),
                            ),
                          ),
                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EmailRegistrationPage()),
                              );
                            },
                            child: Text(
                              'Don’t have an account? Register'.tr(),
                              style: GoogleFonts.poppins(color: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
