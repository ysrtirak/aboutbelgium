import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'MessageCommunityPage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'FirebaseKeys.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:aboutbelgium/AdsKeys.dart';
import 'package:image/image.dart' as img;

class NewUserPage extends StatefulWidget {
  final String? userID;
  final String? username;
  final String? age;
  final String? country;
  final String? shortInfo;
  final String? profileImageUrl;
  final String? gender;

  const NewUserPage({
    this.userID,
    this.username,
    this.age,
    this.country,
    this.shortInfo,
    this.profileImageUrl,
    this.gender,
    super.key,
  });

  @override
  _NewUserPageState createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _shortInfoController = TextEditingController();
  int? _selectedCountryIndex;
  int? _selectedGenderIndex;
  XFile? _image;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool _profileExists = false;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _checkProfileExistence();
    adsBanner();
    _loadInterstitialAd(); // Load interstitial ad
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

  @override
  void dispose() {
    _bannerAd.dispose();
    if (_isInterstitialAdReady) {
      _interstitialAd.dispose();
    }
    super.dispose();
  }

  Future<void> _checkProfileExistence() async {
    var userDoc = await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    if (userDoc.exists) {
      setState(() {
        _profileExists = true;
      });
    } else {
      setState(() {
        _profileExists = false;
      });
    }
  }

  void _initializeForm() {
    _usernameController.text = widget.username ?? '';
    _ageController.text = widget.age ?? '';
    _shortInfoController.text = widget.shortInfo ?? '';
    _selectedCountryIndex = int.tryParse(widget.country ?? '');
    _selectedGenderIndex = int.tryParse(widget.gender ?? '');

  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  bool _validateInputs() {
    if (_usernameController.text.isEmpty ||
        _usernameController.text.length < 3 ||
        RegExp(r'[0-9]').hasMatch(_usernameController.text)) {
      _showAlert(
          "Full Name must contain at least 3 characters and cannot contain numbers.".tr());
      return false;
    }
    if (_ageController.text.isEmpty ||
        int.tryParse(_ageController.text) == null ||
        int.parse(_ageController.text) < 18 ||
        int.parse(_ageController.text) > 99) {
      _showAlert("Age must be a number between 18 and 99.".tr());
      return false;
    }
    if (_shortInfoController.text.isEmpty ||
        _shortInfoController.text.length < 10 ||
        _shortInfoController.text.length > 100) {
      _showAlert("Short Info must be between 10 and 100 characters.".tr());
      return false;
    }

    if (_image == null &&
        (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty)) {
      _showAlert("Please select a profile image.".tr());
      return false;
    }
    return true;
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text('Warning!'.tr()),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text('OK'.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUserDataToFirebase() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    String imageUrl = widget.profileImageUrl ?? '';
    if (_image != null) {
      try {
        // Load and decode the image from the selected file
        final originalImageBytes = await File(_image!.path).readAsBytes();
        img.Image? originalImage = img.decodeImage(originalImageBytes);

        // Resize and compress the image if decoding is successful
        if (originalImage != null) {
          // Resize to a width of 800 pixels, maintaining aspect ratio
          img.Image resizedImage = img.copyResize(originalImage, width: 800);

          // Convert the resized image to JPEG format with quality of 85%
          List<int> compressedImageBytes = img.encodeJpg(resizedImage, quality: 85);

          // Create a temporary file to store the resized image for upload
          File compressedImageFile = await File('${_image!.path}_compressed.jpg').writeAsBytes(compressedImageBytes);

          // Upload compressed image to Firebase Storage
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('${storageProfileImages}/${FirebaseAuth.instance.currentUser!.uid}/profile_image.jpg');
          UploadTask uploadTask = storageRef.putFile(compressedImageFile);
          TaskSnapshot taskSnapshot = await uploadTask;
          imageUrl = await taskSnapshot.ref.getDownloadURL();
        } else {
          print('Failed to decode image.');
        }
      } catch (e) {
        print('Image upload error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while uploading the profile image.'.tr()),
          ),
        );
      }
    }

    String? fcmToken = await FirebaseMessaging.instance.getToken();

    await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      userName: _usernameController.text,
      userAge: int.tryParse(_ageController.text) ?? 0,
      userCountryIndex: _selectedCountryIndex,  // update to use _selectedCountryIndex
      userShortInfo: _shortInfoController.text,
      profileImageUrl: imageUrl,
      userGenderIndex: _selectedGenderIndex,  // update to use _selectedGenderIndex
      userFcmToken: fcmToken,
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MessageCommunityPage()),
    );
  }

  Future<void> _createNewUserProfile() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    String imageUrl = '';
    if (_image != null) {
      try {
        // Load and decode the image from the selected file
        final originalImageBytes = await File(_image!.path).readAsBytes();
        img.Image? originalImage = img.decodeImage(originalImageBytes);

        // Resize and compress the image if decoding is successful
        if (originalImage != null) {
          // Resize to a width of 800 pixels, maintaining aspect ratio
          img.Image resizedImage = img.copyResize(originalImage, width: 800);

          // Convert the resized image to JPEG format with quality of 85%
          List<int> compressedImageBytes = img.encodeJpg(resizedImage, quality: 85);

          // Create a temporary file to store the resized image for upload
          File compressedImageFile = await File('${_image!.path}_compressed.jpg').writeAsBytes(compressedImageBytes);

          // Upload compressed image to Firebase Storage
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('${storageProfileImages}/${FirebaseAuth.instance.currentUser!.uid}/profile_image.jpg');
          UploadTask uploadTask = storageRef.putFile(compressedImageFile);
          TaskSnapshot taskSnapshot = await uploadTask;
          imageUrl = await taskSnapshot.ref.getDownloadURL();
        } else {
          print('Failed to decode image.');
        }
      } catch (e) {
        print('Image upload error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while uploading the profile image.'.tr()),
          ),
        );
      }
    }

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('FCM token is not available');
        return;
      }

      await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        userId: FirebaseAuth.instance.currentUser!.uid,
        userName: _usernameController.text,
        userAge: int.tryParse(_ageController.text) ?? 0,
        userCountryIndex: _selectedCountryIndex,
        userShortInfo: _shortInfoController.text,
        profileImageUrl: imageUrl,
        userGenderIndex: _selectedGenderIndex,
        userFcmToken: fcmToken,
      });
    } catch (e) {
      print('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MessageCommunityPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profileExists ? 'Update Profile'.tr() : 'Create Profile'.tr()),
        backgroundColor: Colors.indigo.shade700,
        centerTitle: true,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Full Name'.tr(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  labelStyle: TextStyle(color: Colors.indigo.shade700),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: Colors.indigo.shade700, width: 2.0),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age'.tr(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  labelStyle: TextStyle(color: Colors.indigo.shade700),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: Colors.indigo.shade700, width: 2.0),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Gender Selection
               Text('Gender'.tr()),
              SizedBox(
                height: 80,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
                  itemCount: GendersIcon.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGenderIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedGenderIndex == index ? Colors.indigo : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          color: _selectedGenderIndex == index ? Colors.indigo.withOpacity(0.1) : Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/genders/${GendersIcon[index]}.png',
                            height: 50, // Adjust height as needed
                            width: 50, // Adjust width as needed
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
// Country Selection
               Text('Country'.tr()),
              SizedBox(
                height: 80,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
                  itemCount: CountriesIcon.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCountryIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedCountryIndex == index ? Colors.indigo : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          color: _selectedCountryIndex == index ? Colors.indigo.withOpacity(0.1) : Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/flags/${CountriesIcon[index]}.png',
                            height: 50, // Adjust height as needed
                            width: 50, // Adjust width as needed
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _shortInfoController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Short Info'.tr(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  labelStyle: TextStyle(color: Colors.indigo.shade700),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: Colors.indigo.shade700, width: 2.0),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[300],
                  child: ClipOval(
                    child: _image != null
                        ? Image.file(
                      File(_image!.path),
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                        : (widget.profileImageUrl != null &&
                        widget.profileImageUrl!.isNotEmpty
                        ? Image.network(
                      widget.profileImageUrl!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                        : const Icon(
                      Icons.camera_alt,
                      size: 60,
                      color: Colors.indigo,
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                  if (_isInterstitialAdReady) {
                    _interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
                      onAdDismissedFullScreenContent: (InterstitialAd ad) {
                        ad.dispose(); // Dispose the ad when dismissed
                        _isInterstitialAdReady = false; // Reset ready state
                        _loadInterstitialAd(); // Load a new ad for next time
                        // Call either _saveUserDataToFirebase or _createNewUserProfile

                      },
                    );

                    // Show the interstitial ad
                    _interstitialAd.show();
                  }
                  if (_profileExists) {
                    _saveUserDataToFirebase();
                  } else {
                    _createNewUserProfile();
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                  _profileExists ? 'Update Profile'.tr() : 'Create Profile'.tr(),
                  style: const TextStyle(fontSize: 20,color: Colors.white),
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
        ),
      ),
    );
  }
}
