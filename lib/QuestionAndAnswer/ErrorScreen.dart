import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'It will be added very soon. You can try opening this page in other languages.'.tr(),
                style: const TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 30), // Geri ok ikonu
                onPressed: () {
                  Navigator.of(context).pop(); // Geri gitme işlevi
                },
                color: Colors.blue, // İkon rengi
              ),
            ],
          ),
        ),
      ),
    );
  }
}
