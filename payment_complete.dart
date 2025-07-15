import 'package:flutter/material.dart';
import 'package:newadd/home/farmer_home.dart';
import 'package:newadd/home/buyer_home.dart';

class PaymentCompletePage extends StatelessWidget {
  final bool success;
  final String? orderId;
  final String? errorMessage;
  final String userType; // 'farmer' or 'buyer'
  final String userEmail; // ✅ Required to pass to the correct home page

  const PaymentCompletePage({
    super.key,
    required this.success,
    this.orderId,
    this.errorMessage,
    required this.userType,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
        leading: BackButton(onPressed: () => _navigateToHome(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                size: 100,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                success ? 'Order Confirmed' : 'Order Failed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                success
                    ? 'Your order has been confirmed.\nWill be delivered soon'
                    : errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (success && orderId != null)
                Text(
                  'Order ID: $orderId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _navigateToHome(context),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Widget homePage;

    if (userType == 'farmer') {
      homePage = FarmerHome(userEmail: userEmail);
    } else {
      homePage = BuyerHome(userEmail: userEmail);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => homePage),
      (route) => false,
    );
  }
}
