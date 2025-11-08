import 'dart:async';
import 'package:flutter/material.dart';
import 'package:newadd/splash.dart'; // Make sure this exists

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds, then navigate to splash page
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/logo.png', width: 10),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 4,
            ),
          ),
        ],
      ),
    );
  }
}
