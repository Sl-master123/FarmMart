import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/farmer/farmer_order_process.dart';
import 'package:newadd/farmer/farmer_product_view.dart';
import 'package:newadd/profile.dart';
import 'package:newadd/farmer/farmer_add_post.dart';
import 'package:newadd/farmer/farmer_edit_post.dart';
import 'package:newadd/login/login.dart';

class FarmerHome extends StatefulWidget {
  final String userEmail;
  const FarmerHome({super.key, required this.userEmail});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  final List<String> types = [
    'Fertilizers',
    'Seeds',
    'Pesticides',
    'Equipment',
    'Vehicles',
  ];

  String selectedType = '';
  String searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final collection = _selectedIndex == 1 ? 'farmer_posts' : 'seller_posts';
      final snapshot = await _firestore.collection(collection).get();

      // Create list with products and their ratings
      final List<Map<String, dynamic>> dataListWithRatings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = doc.id;

        // Get average rating for each product
        final rating = await _getAverageRating(productId);

        dataListWithRatings.add({
          'id': productId,
          'type': data['type'] ?? data['rice_type'] ?? 'Unknown',
          'price': data['price'] ?? '0.00',
          'condition': data['condition'] ?? '',
          'description': data['description'] ?? '',
          'image_url': data['image_url'],
          'user_email': data['user_email'] ?? '',
          'created_at': data['created_at'] ?? Timestamp.now(),
          'rating': rating,
        });
      }

      // Sort by rating (highest first), then by created_at (newest first)
      dataListWithRatings.sort((a, b) {
        final ratingCompare = (b['rating'] as double).compareTo(
          a['rating'] as double,
        );
        if (ratingCompare != 0) return ratingCompare;

        final aTime = (a['created_at'] as Timestamp).millisecondsSinceEpoch;
        final bTime = (b['created_at'] as Timestamp).millisecondsSinceEpoch;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _allProducts = dataListWithRatings;
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching products: $e')));
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final type = product['type'].toLowerCase();
        final description = product['description'].toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            type.contains(searchQuery.toLowerCase()) ||
            description.contains(searchQuery.toLowerCase());
        final matchesType =
            selectedType.isEmpty || type == selectedType.toLowerCase();

        if (_selectedIndex == 1) {
          return matchesSearch &&
              matchesType &&
              product['user_email'] == widget.userEmail;
        }

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FarmerOrderProcess(userEmail: widget.userEmail),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilePage(userEmail: widget.userEmail),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
      _fetchProducts();
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

  Future<void> _deletePost(String postId) async {
    try {
      await _firestore.collection('farmer_posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
      _fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
    }
  }

  Future<void> _editPost(Map<String, dynamic> product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FarmerEditPost(postId: product['id'], postData: product),
      ),
    );
    if (result == true) {
      _fetchProducts();
    }
  }

  Future<double> _getAverageRating(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('feedback')
          .where('product_id', isEqualTo: productId)
          .limit(100) // Limit to recent 100 reviews for performance
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] ?? 0).toDouble();
      }
      return total / snapshot.docs.length;
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildRatingStars(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  // Helper function to get appropriate unit for product type
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
              const Icon(Icons.agriculture, size: 22),
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
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8),
              child: Text("Hello, chief!", style: TextStyle(fontSize: 14)),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 2),
              child: Text(
                "What are you looking for ?",
                style: TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search keywords..',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  searchQuery = value;
                  _applyFilters();
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Types",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  final isSelected = selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(type, style: const TextStyle(fontSize: 13)),
                      selected: isSelected,
                      selectedColor: Colors.green[100],
                      onSelected: (_) {
                        setState(() {
                          selectedType = isSelected ? '' : type;
                          _applyFilters();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                "Featured products",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _filteredProducts.isEmpty
                  ? const Center(child: Text("No products found"))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final isMyPost =
                            _selectedIndex == 1 &&
                            product['user_email'] == widget.userEmail;

                        return isMyPost
                            ? _buildMyPostCard(product)
                            : _buildProductCard(product);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FarmerAddPost(userEmail: widget.userEmail),
              ),
            );
          },
          backgroundColor: Colors.green,
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
                    _buildNavItem(Icons.shop, 1, 'My Posts'),
                  ],
                ),
                Row(
                  children: [
                    _buildNavItem(Icons.receipt_long, 2, 'Orders'),
                    _buildNavItem(Icons.person, 3, 'Profile'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 5.5,
      child: InkWell(
        onTap: () => _onBottomNavTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: _selectedIndex == index ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: _selectedIndex == index ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyPostCard(Map<String, dynamic> product) {
    return FutureBuilder<double>(
      future: _getAverageRating(product['id']),
      builder: (context, snapshot) {
        final rating = snapshot.data ?? 0.0;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product['image_url'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    product['image_url'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                )
              else
                const SizedBox(
                  height: 100,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'LKR ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${product['price']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product['type'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (product['condition'] != null &&
                              product['condition'].toString().isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                product['condition'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                          Text(
                            _getProductUnit(product['type']),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      _buildRatingStars(rating, size: 10),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _editPost(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 3,
                                ),
                                minimumSize: const Size(0, 22),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _deletePost(product['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 3,
                                ),
                                minimumSize: const Size(0, 22),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 100,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            )
          : const SizedBox(
              height: 100,
              child: Center(child: Icon(Icons.image_not_supported)),
            ),
    );
  }

  Widget _buildCardContainer({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final rating = product['rating'] ?? 0.0;

    return _buildCardContainer(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FarmerProductView(
            productId: product['id'],
            userEmail: widget.userEmail,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(product['image_url']),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
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
                          '${product['price']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['type'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (product['condition'] != null &&
                          product['condition'].toString().isNotEmpty) ...[
                        Expanded(
                          child: Text(
                            product['condition'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                      Text(
                        _getProductUnit(product['type']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildRatingStars(rating, size: 14),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
