import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/payment_complete.dart';

class BuyerBuyPage extends StatefulWidget {
  final String userEmail;
  final double totalPrice;

  const BuyerBuyPage({
    super.key,
    required this.userEmail,
    required this.totalPrice,
  });

  @override
  State<BuyerBuyPage> createState() => _BuyerBuyPageState();
}

class _BuyerBuyPageState extends State<BuyerBuyPage> {
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String deliveryMethod = '';
  String paymentMethod = '';

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Phone validation
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  // Address validation
  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
  }

  Future<void> _confirmOrder() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please fix the errors in the form'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (deliveryMethod.isEmpty || paymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select delivery and payment methods'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      // Step 1: Get cart items
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('user_email', isEqualTo: widget.userEmail)
          .get();

      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white),
                SizedBox(width: 8),
                Text('Your cart is empty'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Step 2: Process each item to get seller info
      final List<Map<String, dynamic>> cartItems = [];

      for (var doc in cartSnapshot.docs) {
        final item = doc.data();

        // Get the product from seller_posts using the product ID
        final postId = item['product_id'];
        final sellerPost = await FirebaseFirestore.instance
            .collection('seller_posts')
            .doc(postId)
            .get();

        final sellerData = sellerPost.data();
        if (sellerData != null) {
          item['user_email'] = sellerData['user_email']; // Set seller email
        }

        cartItems.add(item);
      }

      // Step 3: Save order
      DocumentReference orderRef = await FirebaseFirestore.instance
          .collection('cart_buy')
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

      // Step 4: Clear cart
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      // Step 5: Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentCompletePage(
            success: true,
            orderId: orderRef.id,
            userType: 'buyer', // ✅ important for redirection
            userEmail: widget.userEmail,
          ),
        ),
      );
    } catch (e) {
      // Step 6: Navigate to error page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentCompletePage(
            success: false,
            errorMessage: 'Failed to place order: $e',
            userType: 'buyer', // ✅ same here
            userEmail: widget.userEmail,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Your Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: addressController,
                validator: _validateAddress,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address *',
                  hintText: 'Enter your complete address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '07XXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'About Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: deliveryMethod.isNotEmpty ? deliveryMethod : null,
                decoration: const InputDecoration(
                  labelText: 'Delivery Method *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                hint: const Text('Select Delivery Method'),
                items: const [
                  DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
                  DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                ],
                onChanged: (val) => setState(() => deliveryMethod = val ?? ''),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod.isNotEmpty ? paymentMethod : null,
                decoration: const InputDecoration(
                  labelText: 'Payment Method *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
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
                        widget.totalPrice.toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: _confirmOrder,
                child: const Text(
                  'Confirm Order',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
