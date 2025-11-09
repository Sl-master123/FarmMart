import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/buyer/buyer_product_view.dart';
import 'package:newadd/buyer/buyer_cart.dart';
import 'package:newadd/buyer/buyer_order_process.dart';
import 'package:newadd/profile.dart';
import 'package:newadd/login/login.dart';

class BuyerHome extends StatefulWidget {
  final String userEmail;
  const BuyerHome({super.key, required this.userEmail});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = false;

  final List<String> riceTypes = [
    'Suwandel',
    'Kalu Heenati',
    'Maa-Wee',
    'Rathu El',
    'Pachchaperumal',
    'Samba',
    'Kekulu',
    'Nadu',
    'Mottai Karuppan',
    'Basmati',
    'Red Rice (Rathu Kakulu)',
    'White Rice (Sudu Kakulu)',
    'Parboiled Rice (Sudu & Rathu Kekulu)',
  ];

  String selectedType = '';
  String searchQuery = '';
  String productTypeFilter = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore.collection('farmer_posts').get();

      // Create list with products and their ratings
      final List<Map<String, dynamic>> dataListWithRatings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = doc.id;

        // Get average rating for each product
        final rating = await _getAverageRating(productId);

        dataListWithRatings.add({
          'id': productId,
          'riceType': data['rice_type'] ?? 'Unknown',
          'price': data['price'] ?? '0.00',
          'productType': data['product_type'] ?? 'rice',
          'description': data['description'] ?? '',
          'imageUrl': data['image_url'],
          'createdAt': data['created_at'],
          'rating': rating,
        });
      }

      // Sort by rating (highest first), then by created_at (newest first)
      dataListWithRatings.sort((a, b) {
        final ratingCompare = (b['rating'] as double).compareTo(
          a['rating'] as double,
        );
        if (ratingCompare != 0) return ratingCompare;

        // If ratings are equal, sort by date
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _allProducts = dataListWithRatings;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error fetching products: $e')),
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

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final riceType = product['riceType'].toLowerCase();
        final description = product['description'].toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            riceType.contains(searchQuery.toLowerCase()) ||
            description.contains(searchQuery.toLowerCase());
        final matchesType =
            selectedType.isEmpty || riceType == selectedType.toLowerCase();
        final matchesProductType =
            productTypeFilter.isEmpty ||
            product['productType'].toLowerCase() ==
                productTypeFilter.toLowerCase();

        return matchesSearch && matchesType && matchesProductType;
      }).toList();
    });
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

  void _onBottomNavTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        // Already on home, just reset the index
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerCart(userEmail: widget.userEmail),
          ),
        ).then((_) {
          // Reset to home when returning
          setState(() => _selectedIndex = 0);
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerOrderProcess(userEmail: widget.userEmail),
          ),
        ).then((_) {
          // Reset to home when returning
          setState(() => _selectedIndex = 0);
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(userEmail: widget.userEmail),
          ),
        ).then((_) {
          // Reset to home when returning
          setState(() => _selectedIndex = 0);
        });
        break;
    }
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
              const Icon(Icons.shopping_bag, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Welcome, ${widget.userEmail.split('@')[0]}!',
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
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
                "What are you looking for?",
                style: TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search keywords..',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      setState(() {
                        productTypeFilter = (productTypeFilter == 'rice')
                            ? 'paddy'
                            : (productTypeFilter == 'paddy')
                            ? ''
                            : 'rice';
                        _applyFilters();
                      });
                    },
                  ),
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
                itemCount: riceTypes.length,
                itemBuilder: (context, index) {
                  final type = riceTypes[index];
                  final isSelected = selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(type, style: const TextStyle(fontSize: 13)),
                      selected: isSelected,
                      selectedColor: Colors.blue[100],
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
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text('Loading products...'),
                        ],
                      ),
                    )
                  : _filteredProducts.isEmpty
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
                        return _buildProductCard(product);
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
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
              child: Center(child: Icon(Icons.broken_image)),
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final rating = product['rating'] ?? 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuyerProductView(
            productId: product['id'],
            userEmail: widget.userEmail,
          ),
        ),
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product['imageUrl']),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${product['price']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['riceType'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "1kg",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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
      ),
    );
  }
}
