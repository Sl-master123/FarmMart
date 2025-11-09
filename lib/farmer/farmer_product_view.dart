import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/farmer/farmer_cart.dart';

class FarmerProductView extends StatefulWidget {
  final String productId;
  final String userEmail;

  const FarmerProductView({
    super.key,
    required this.productId,
    required this.userEmail,
  });

  @override
  State<FarmerProductView> createState() => _FarmerProductViewState();
}

class _FarmerProductViewState extends State<FarmerProductView> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  double averageRating = 0.0;
  List<Map<String, dynamic>> reviews = [];
  String? _cachedUserName;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReviews();
    _cacheUserData();
  }

  Future<void> _cacheUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        _cachedUserName = userDoc.docs.first.data()['name'] ?? 'Unknown User';
      }
    } catch (e) {
      _cachedUserName = 'User';
    }
  }

  Future<void> _loadProduct() async {
    final doc = await FirebaseFirestore.instance
        .collection('seller_posts')
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

  String _getProductUnit() {
    if (productData == null) return '1kg';
    final productType = (productData!['product_type'] ?? '').toLowerCase();
    final type = (productData!['type'] ?? '').toLowerCase();
    if (productType.contains('vehicle') ||
        productType.contains('equipment') ||
        type.contains('vehicle') ||
        type.contains('equipment')) {
      return '1 unit';
    }
    return '1kg';
  }

  Future<void> _showReviewDialog() async {
    double rating = 5;
    final controller = TextEditingController();

    // Use cached user name or fetch if not available
    final userName = _cachedUserName ?? 'User';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.rate_review,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Write a Review',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Rating',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Wrap(
                      spacing: 4,
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 36,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              rating = (index + 1).toDouble();
                            });
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Review',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                    maxLength: 300,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Please write a review'),
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
                if (controller.text.trim().length < 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Review must be at least 5 characters'),
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

                // Close dialog immediately and submit in background
                Navigator.pop(context);

                // Show inline progress indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Submitting review...'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Submit review asynchronously
                try {
                  await FirebaseFirestore.instance.collection('feedback').add({
                    'product_id': widget.productId,
                    'review': controller.text.trim(),
                    'rating': rating,
                    'timestamp': Timestamp.now(),
                    'user_email': widget.userEmail,
                    'user_name': userName,
                  });

                  if (mounted) {
                    _loadReviews();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Review submitted successfully!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Error: $e')),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    final cartCollection = FirebaseFirestore.instance.collection('farmer_cart');

    final existing = await cartCollection
        .where('user_email', isEqualTo: widget.userEmail)
        .where('product_id', isEqualTo: widget.productId)
        .get();

    if (existing.docs.isEmpty) {
      await cartCollection.add({
        'user_email': widget.userEmail,
        'seller_email': productData!['user_email'],
        'product_id': widget.productId,
        'type': productData!['type'],
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
        builder: (context) => FarmerCart(userEmail: widget.userEmail),
      ),
    );
  }

  Future<void> _buyNow() async {
    final cartCollection = FirebaseFirestore.instance.collection('farmer_cart');

    // Clear all existing items for this user
    final existingItems = await cartCollection
        .where('user_email', isEqualTo: widget.userEmail)
        .get();

    for (var doc in existingItems.docs) {
      await cartCollection.doc(doc.id).delete();
    }

    // Add only the current product
    await cartCollection.add({
      'user_email': widget.userEmail,
      'seller_email': productData!['user_email'],
      'product_id': widget.productId,
      'type': productData!['type'],
      'price': productData!['price'],
      'image_url': productData!['image_url'],
      'quantity': 1,
      'created_at': Timestamp.now(),
    });

    // Navigate to cart screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmerCart(userEmail: widget.userEmail),
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
                          productData!['type'] ?? 'Unknown',
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'LKR ',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${productData!['price']}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.add_circle_outline),
                            const SizedBox(width: 4),
                            Text(_getProductUnit()),
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
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Customer Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        reviews.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No reviews yet. Be the first to review!',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviews.length,
                                itemBuilder: (context, index) {
                                  final review = reviews[index];
                                  final rating = (review['rating'] ?? 0)
                                      .toDouble();
                                  final reviewText = review['review'] ?? '';
                                  final userName =
                                      review['user_name'] ?? 'Anonymous';
                                  final userEmail = review['user_email'] ?? '';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.green,
                                                child: Text(
                                                  userName[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      userName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (userEmail.isNotEmpty)
                                                      Text(
                                                        userEmail,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              ...List.generate(5, (i) {
                                                return Icon(
                                                  i < rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 16,
                                                );
                                              }),
                                              const SizedBox(width: 8),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (reviewText.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              reviewText,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
