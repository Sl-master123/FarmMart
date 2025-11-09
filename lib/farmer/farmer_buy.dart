import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/payment_complete.dart';

class FarmerBuyPage extends StatefulWidget {
  final String userEmail;
  final double totalPrice;

  const FarmerBuyPage({
    super.key,
    required this.userEmail,
    required this.totalPrice,
  });

  @override
  State<FarmerBuyPage> createState() => _FarmerBuyPageState();
}

class _FarmerBuyPageState extends State<FarmerBuyPage> {
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  String deliveryMethod = '';
  String paymentMethod = '';

  Future<void> _confirmOrder() async {
    if (addressController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        deliveryMethod.isEmpty ||
        paymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      // Step 1: Get cart items from farmer_cart
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('farmer_cart')
          .where('user_email', isEqualTo: widget.userEmail)
          .get();

      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
        return;
      }

      final List<Map<String, dynamic>> cartItems = [];

      for (var doc in cartSnapshot.docs) {
        final item = doc.data();

        // Get seller info from seller_posts
        final postId = item['product_id'];
        final sellerPost = await FirebaseFirestore.instance
            .collection('seller_posts')
            .doc(postId)
            .get();

        final sellerData = sellerPost.data();
        if (sellerData != null) {
          item['farmer_email'] = sellerData['user_email'];
        }

        cartItems.add(item);
      }

      // Step 2: Save the order
      final orderRef = await FirebaseFirestore.instance
          .collection('farmer_cart_buy')
          .add({
            'user_email': widget.userEmail,
            'address': addressController.text,
            'phone': phoneController.text,
            'email': emailController.text,
            'delivery_method': deliveryMethod,
            'payment_method': paymentMethod,
            'total_cost': widget.totalPrice,
            'status': paymentMethod == 'Online Payment' ? 'Paid' : 'Pending',
            'timestamp': Timestamp.now(),
            'items': cartItems,
            'all_completed': false,
          });

      // Step 3: Clear cart
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      // Step 4: Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentCompletePage(
            success: true,
            orderId: orderRef.id,
            userType: 'farmer', // ✅ for correct redirection
            userEmail: widget.userEmail,
          ),
        ),
      );
    } catch (e) {
      // Error navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentCompletePage(
            success: false,
            errorMessage: 'Order failed: $e',
            userType: 'farmer', // ✅ still needed
            userEmail: widget.userEmail,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Purchase')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Your Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: deliveryMethod.isNotEmpty ? deliveryMethod : null,
              hint: const Text('Select Delivery Method'),
              items: const [
                DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
                DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
              ],
              onChanged: (val) => setState(() => deliveryMethod = val ?? ''),
            ),
            DropdownButtonFormField<String>(
              value: paymentMethod.isNotEmpty ? paymentMethod : null,
              hint: const Text('Select Payment Method'),
              items: const [
                DropdownMenuItem(
                  value: 'Cash on Delivery',
                  child: Text('Cash on Delivery'),
                ),
                DropdownMenuItem(
                  value: 'Online Payment',
                  child: Text('Online Payment'),
                ),
              ],
              onChanged: (val) => setState(() => paymentMethod = val ?? ''),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    const Text(
                      'LKR ',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      '${widget.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _confirmOrder,
              child: const Text(
                'Confirm Order',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
