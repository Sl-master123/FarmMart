import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/seller/seller_add_post.dart';
import 'package:newadd/seller/seller_edit_post.dart';
import 'package:newadd/seller/seller_order_process.dart';
import 'package:newadd/profile.dart';
import 'package:newadd/login/login.dart';

class SellerHome extends StatefulWidget {
  final String userEmail;
  const SellerHome({super.key, required this.userEmail});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final Map<String, double> _productRatings = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<double> _getAverageRating(String productId) async {
    // Check cache first
    if (_productRatings.containsKey(productId)) {
      return _productRatings[productId]!;
    }

    try {
      final feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .where('product_id', isEqualTo: productId)
          .limit(100) // Limit to recent 100 reviews for performance
          .get();

      if (feedbackSnapshot.docs.isEmpty) {
        _productRatings[productId] = 0.0;
        return 0.0;
      }

      double totalRating = 0.0;
      int count = 0;

      for (var doc in feedbackSnapshot.docs) {
        final rating = doc.data()['rating'];
        if (rating != null) {
          totalRating += (rating is int ? rating.toDouble() : rating);
          count++;
        }
      }

      final averageRating = count > 0 ? totalRating / count : 0.0;
      _productRatings[productId] = averageRating;
      return averageRating;
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildRatingStars(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating && rating % 1 >= 0.5) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  String _getProductUnit(String productType) {
    final type = productType.toLowerCase();
    // Equipment and Vehicles use "1 unit"
    if (type.contains('equipment') || type.contains('vehicle')) {
      return '1 unit';
    }
    // Fertilizers, Seeds, and Pesticides use "1kg"
    else if (type.contains('fertilizer') ||
        type.contains('seed') ||
        type.contains('pesticide')) {
      return '1kg';
    }
    // Default to "1 unit" for unknown types
    return '1 unit';
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellerAddPost(userEmail: widget.userEmail),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Icon(Icons.storefront, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hello, ${widget.userEmail.split('@')[0]}!',
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: _buildPageContent(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _onItemTapped(2),
          backgroundColor: Colors.deepOrange,
          elevation: 4,
          child: const Icon(Icons.add, size: 32),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildNavItem(Icons.home, 0, 'Home'),
                    _buildNavItem(Icons.shopping_bag_outlined, 1, 'My Shop'),
                  ],
                ),
                Row(
                  children: [
                    _buildNavItem(Icons.delivery_dining_outlined, 3, 'Orders'),
                    _buildNavItem(Icons.person_outline, 4, 'Profile'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildAllPosts();
      case 1:
        return _buildMyPosts();
      case 3:
        return SellerOrderProcess(userEmail: widget.userEmail);
      case 4:
        return ProfilePage(userEmail: widget.userEmail);
      default:
        return const Center(child: Text('Unknown page'));
    }
  }

  Widget _buildAllPosts() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAndSortProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        final products = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            8,
            8,
            8,
            88,
          ), // keep clear of BottomAppBar/FAB
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.65, // more vertical space per tile
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAndSortProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('seller_posts')
          .get();

      // Create list with products and their ratings
      final List<Map<String, dynamic>> productsWithRatings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = doc.id;

        // Get average rating for each product
        final rating = await _getAverageRating(productId);

        productsWithRatings.add({
          'id': productId,
          'type': data['type'],
          'price': data['price'],
          'condition': data['condition'],
          'description': data['description'],
          'image_url': data['image_url'],
          'created_at': data['created_at'],
          'user_email': data['user_email'],
          'rating': rating,
        });
      }

      // Sort by rating (highest first), then by created_at (newest first)
      productsWithRatings.sort((a, b) {
        final ratingCompare = (b['rating'] as double).compareTo(
          a['rating'] as double,
        );
        if (ratingCompare != 0) return ratingCompare;

        // If ratings are equal, sort by date
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return productsWithRatings;
    } catch (e) {
      print('Error fetching and sorting products: $e');
      return [];
    }
  }

  Widget _buildMyPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('seller_posts')
          .where('user_email', isEqualTo: widget.userEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final product = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: product['image_url'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(product['type'] ?? 'No title'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'LKR ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${product['price']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _getProductUnit(product['type'] ?? ''),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${product['condition'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Rating display
                    FutureBuilder<double>(
                      future: _getAverageRating(docId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(height: 16);
                        }
                        final rating = snapshot.data!;
                        if (rating == 0.0) {
                          return const Text(
                            'No reviews yet',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                        return Row(
                          children: [
                            _buildRatingStars(rating, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${rating.toStringAsFixed(1)} / 5',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SellerEditPost(
                              userEmail: widget.userEmail,
                              postId: docId,
                              postData: product,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: const Text(
                              'Are you sure you want to delete this product?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('seller_posts')
                                      .doc(docId)
                                      .delete();
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===== Overflow-proof product card =====
  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageUrl = (product['image_url'] ?? '').toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Colors.white,
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed ratio image so every tile has predictable top area
            AspectRatio(
              aspectRatio: 16 / 9,
              child: (imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image)),
                    )
                  : const Center(child: Icon(Icons.image_not_supported)),
            ),

            // The rest expands to the available height of the grid cell
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'LKR ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${product['price'] ?? '0'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    Text(
                      (product['type'] ?? 'Unknown').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      _getProductUnit(product['type'] ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),

                    // Rating display - now using pre-fetched rating from product data
                    _buildRatingStars(product['rating'] ?? 0.0, size: 14),

                    const Spacer(), // pushes button to bottom safely
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _selectedIndex == index;
    return SizedBox(
      width: MediaQuery.of(context).size.width / 5.5,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected ? Colors.deepOrange : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.deepOrange : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
