import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/home/farmer_home.dart';
import 'package:newadd/home/buyer_home.dart';
import 'package:newadd/home/seller_home.dart';

class Homepage extends StatefulWidget {
  final String userEmail; // email passed from login

  const Homepage({super.key, required this.userEmail});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userType = snapshot.docs.first.get('user_type');
        final userEmail = snapshot.docs.first.get(
          'email',
        ); // Get email from document

        if (userType == 'Farmer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FarmerHome(userEmail: userEmail)),
          );
        } else if (userType == 'Buyer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BuyerHome(userEmail: userEmail)),
          );
        } else if (userType == 'Seller') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SellerHome(userEmail: userEmail)),
          );
        } else {
          _showError('Unknown user type: $userType');
        }
      } else {
        _showError('User not found.');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // While loading & redirecting
      ),
    );
  }
}
