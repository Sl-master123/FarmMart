import 'dart:async';
import 'package:flutter/material.dart';
import 'package:newadd/splash.dart'; // Make sure this exists

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds, then navigate to splash page
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: AssetImage('assets/logo.png'),
            width: 10,
            fit: BoxFit.contain,
          ),
          Center(
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
