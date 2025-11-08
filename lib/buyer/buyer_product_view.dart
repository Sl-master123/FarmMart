import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/buyer/buyer_cart.dart';

class BuyerProductView extends StatefulWidget {
  final String productId;
  final String userEmail;

  const BuyerProductView({
    super.key,
    required this.productId,
    required this.userEmail,
  });

  @override
  State<BuyerProductView> createState() => _BuyerProductViewState();
}

class _BuyerProductViewState extends State<BuyerProductView> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  double averageRating = 0.0;
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReviews();
  }

  Future<void> _loadProduct() async {
    final doc = await FirebaseFirestore.instance
        .collection('farmer_posts')
        .doc(widget.productId)
        .get();
    if (doc.exists) {
      setState(() {
        productData = doc.data();
        isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('feedback')
        .where('product_id', isEqualTo: widget.productId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      reviews = snapshot.docs.map((doc) => doc.data()).toList();
      double total = reviews.fold(
        0.0,
        (sum, item) => sum + (item['rating'] ?? 0),
      );
      setState(() {
        averageRating = total / reviews.length;
      });
    }
  }

  Future<void> _showReviewDialog() async {
    double rating = 5;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Your review'),
            ),
            const SizedBox(height: 12),
            DropdownButton<double>(
              value: rating,
              items: List.generate(5, (i) => (i + 1).toDouble())
                  .map(
                    (val) => DropdownMenuItem(value: val, child: Text('$val')),
                  )
                  .toList(),
              onChanged: (val) => setState(() => rating = val ?? 5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('feedback').add({
                'product_id': widget.productId,
                'review': controller.text,
                'rating': rating,
                'timestamp': Timestamp.now(),
              });
              _loadReviews();
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    final cartCollection = FirebaseFirestore.instance.collection('cart');

    final existing = await cartCollection
        .where('user_email', isEqualTo: widget.userEmail)
        .where('product_id', isEqualTo: widget.productId)
        .get();

    if (existing.docs.isEmpty) {
      await cartCollection.add({
        'user_email': widget.userEmail,
        'farmer_email': productData!['user_email'],
        'product_id': widget.productId,
        'rice_type': productData!['rice_type'],
        'price': productData!['price'],
        'image_url': productData!['image_url'],
        'quantity': 1,
        'created_at': Timestamp.now(),
      });
    } else {
      final docId = existing.docs.first.id;
      await cartCollection.doc(docId).update({
        'quantity': (existing.docs.first['quantity'] ?? 1) + 1,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuyerCart(userEmail: widget.userEmail),
      ),
    );
  }

  Future<void> _buyNow() async {
    final cartCollection = FirebaseFirestore.instance.collection('cart');

    // Delete existing cart items
    final existingItems = await cartCollection
        .where('user_email', isEqualTo: widget.userEmail)
        .get();

    for (var doc in existingItems.docs) {
      await cartCollection.doc(doc.id).delete();
    }

    // Add only the current product
    await cartCollection.add({
      'user_email': widget.userEmail,
      'farmer_email': productData!['user_email'],
      'product_id': widget.productId,
      'rice_type': productData!['rice_type'],
      'price': productData!['price'],
      'image_url': productData!['image_url'],
      'quantity': 1,
      'created_at': Timestamp.now(),
    });

    // Navigate to cart
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuyerCart(userEmail: widget.userEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : productData == null
          ? const Center(child: Text('No product data'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        child: productData!['image_url'] != null
                            ? Image.network(
                                productData!['image_url'],
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 250,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 250,
                                child: Center(
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 40,
                        left: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productData!['rice_type'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productData!['product_type'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showReviewDialog,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${reviews.length} reviews)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'LKR ${productData!['price']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 4),
                            Text('1Kg'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Descriptions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          productData!['description'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _addToCart,
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Add to Cart'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: _buyNow,
                                child: const Text(
                                  'Buy Now',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
