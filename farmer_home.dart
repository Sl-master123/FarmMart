import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/farmer/farmer_order_process.dart';
import 'package:newadd/farmer/farmer_product_view.dart';
import 'package:newadd/profile.dart';
import 'package:newadd/farmer/farmer_add_post.dart';

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
      final dataList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? data['rice_type'] ?? 'Unknown',
          'price': data['price'] ?? '0.00',
          'condition': data['condition'] ?? '',
          'description': data['description'] ?? '',
          'imagePath': data['image_path'],
          'user_email': data['user_email'] ?? '',
        };
      }).toList();

      setState(() {
        _allProducts = dataList;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Home'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
            child: Text("Types", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      return Stack(
                        children: [
                          _buildProductCard(product),
                          if (_selectedIndex == 1 &&
                              product['user_email'] == widget.userEmail)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePost(product['id']),
                              ),
                            ),
                        ],
                      );
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FarmerProductView(
              productId: product['id'],
              userEmail: widget.userEmail,
            ),
          ),
        );
      },
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
            if (product['imagePath'] != null &&
                File(product['imagePath']).existsSync())
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.file(
                  File(product['imagePath']),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const SizedBox(
                height: 100,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEW',
                    style: TextStyle(color: Colors.red, fontSize: 10),
                  ),
                  Text(
                    'LKR ${product['price']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    product['type'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    product['condition'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
