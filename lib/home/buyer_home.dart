import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final snapshot = await _firestore.collection('farmer_posts').get();
      final dataList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'riceType': data['rice_type'] ?? 'Unknown',
          'price': data['price'] ?? '0.00',
          'productType': data['product_type'] ?? 'rice',
          'description': data['description'] ?? '',
          'imagePath': data['image_path'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
            child: Text("Types", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product['imagePath'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Builder(
                builder: (context) {
                  final imageFile = File(product['imagePath']);
                  return imageFile.existsSync()
                      ? Image.file(
                          imageFile,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(
                          height: 100,
                          child: Center(child: Icon(Icons.broken_image)),
                        );
                },
              ),
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
                  product['riceType'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const Text(
                  "1kg",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      // Navigate to cart.dart (you'll implement this later)
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
