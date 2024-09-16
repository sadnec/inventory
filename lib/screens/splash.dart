import 'dart:async'; // Needed for the Timer
import 'package:flutter/material.dart';
import 'package:inventorytracker/screens/login.dart'; // Import the login screen

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    // Start the timer when the widget is built
    Timer(const Duration(seconds: 3), () {
      // Navigate to the Login screen after 3 seconds
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF93C852), // Primary color as background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display logo or image
            Image.asset(
              'assets/images/logo.png', // Make sure the image exists in your assets
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 20),
            // Display a loading indicator or any other widget
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
