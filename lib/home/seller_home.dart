import 'package:flutter/material.dart';

class SellerHome extends StatelessWidget {
  final String userEmail;

  const SellerHome({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Home')),
      body: Center(child: Text('Welcome Seller! Email: $userEmail')),
    );
  }
}
