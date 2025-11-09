import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newadd/seller/seller_add_post.dart';
import 'package:newadd/seller/seller_edit_post.dart';
import 'package:newadd/seller/seller_order_process.dart';
import 'package:newadd/profile.dart';

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
      print('Error fetching ratings: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('seller_posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
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
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final product = docs[index].data() as Map<String, dynamic>;
            product['id'] = docs[index].id;
            return _buildProductCard(product);
          },
        );
      },
    );
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
                    Text(
                      'LKR ${product['price']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${product['condition'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    final productId = product['id'] ?? '';

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
                    const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      'LKR ${product['price'] ?? '0'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      (product['type'] ?? 'Unknown').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 2),

                    const Text(
                      '1kg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),

                    // Rating display
                    if (productId.isNotEmpty)
                      FutureBuilder<double>(
                        future: _getAverageRating(productId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(height: 14);
                          }
                          final rating = snapshot.data!;
                          if (rating == 0.0) {
                            return const Text(
                              'No reviews yet',
                              style: TextStyle(fontSize: 9, color: Colors.grey),
                            );
                          }
                          return Row(
                            children: [
                              _buildRatingStars(rating, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    const Spacer(), // pushes button to bottom safely

                    Align(alignment: Alignment.centerRight),
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
