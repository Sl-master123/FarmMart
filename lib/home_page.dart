import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:newadd/admin_dashboard.dart';
import 'package:newadd/home/farmer_home.dart';
import 'package:newadd/home/buyer_home.dart';
import 'package:newadd/home/seller_home.dart';
import 'package:newadd/login/login.dart';
import 'package:newadd/contact.dart';

class Homepage extends StatefulWidget {
  final String userUid; // from FirebaseAuth

  const Homepage({super.key, required this.userUid});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _routeByRole();
  }

  Future<void> _routeByRole() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      // ✅ Check session user first
      if (user == null) {
        setState(() {
          _error = 'No active session. Please log in again.';
          _loading = false;
        });
        return;
      }

      // ✅ Ensure email verified
      await user.reload(); // refresh user info
      if (!user.emailVerified) {
        setState(() {
          _error =
              'Your email is not verified.\nPlease check your inbox and verify before using the app.';
          _loading = false;
        });
        return;
      }

      // ✅ Get profile from Firestore
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userUid)
          .get();

      if (!snap.exists) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Profile Not Found'),
            content: const Text(
              'Your profile was not found in our system. This may happen if your account was deleted by an admin. Please contact admin for assistance.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactPage(isLoggedIn: false),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Contact Admin'),
              ),
            ],
          ),
        );
        return;
      }

      final data = snap.data()!;
      final email = (data['email'] ?? '') as String;
      final rawType = (data['user_type'] ?? '').toString();
      final userType = rawType.trim().toLowerCase(); // normalize
      final isBlocked = data['blocked'] == true;

      if (isBlocked) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Account Blocked'),
            content: const Text(
              'Your account has been blocked by the admin. Please contact admin for more information.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactPage(isLoggedIn: false),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Contact Admin'),
              ),
            ],
          ),
        );
        return;
      }

      // ✅ Navigate by role
      Widget dest;
      switch (userType) {
        case 'farmer':
          dest = FarmerHome(userEmail: email);
          break;
        case 'seller':
          dest = SellerHome(userEmail: email);
          break;
        case 'buyer':
          dest = BuyerHome(userEmail: email);
          break;
        case 'admin':
          dest = AdminDashboard(userEmail: email);
          break;
        default:
          setState(() {
            _error = 'Invalid or missing user_type "$rawType".';
            _loading = false;
          });
          return;
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dest),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FarmMart'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _error ?? 'Routing...',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
