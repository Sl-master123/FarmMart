import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SellerOrderProcess extends StatefulWidget {
  final String userEmail; // This is the seller's email
  const SellerOrderProcess({super.key, required this.userEmail});

  @override
  State<SellerOrderProcess> createState() => _SellerOrderProcessState();
}

class _SellerOrderProcessState extends State<SellerOrderProcess> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final snapshot = await _firestore.collection('farmer_cart_buy').get();

      final List<Map<String, dynamic>> filteredOrders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        // ✅ Filter by seller_email instead of user_email
        final matchedItems = items
            .where((item) => item['seller_email'] == widget.userEmail)
            .toList();

        if (matchedItems.isNotEmpty) {
          filteredOrders.add({
            'id': doc.id,
            'user_email': data['user_email'], // Farmer who bought the items
            'address': data['address'],
            'phone': data['phone'],
            'email': data['email'],
            'delivery_method': data['delivery_method'],
            'payment_method': data['payment_method'],
            'total_cost': data['total_cost'],
            'status': data['status'],
            'timestamp': data['timestamp'],
            'all_completed': data['all_completed'],
            'items': matchedItems,
          });
        }
      }

      setState(() => _orders = filteredOrders);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading orders: $e')));
    }
  }

  Future<void> _markAsDelivered(String orderId) async {
    try {
      await _firestore.collection('farmer_cart_buy').doc(orderId).update({
        'all_completed': true,
      });
      _fetchOrders(); // Refresh after update
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Order List'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 243, 219, 33),
      ),
      body: _orders.isEmpty
          ? const Center(child: Text("No orders available"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final date = (order['timestamp'] as Timestamp).toDate();
                final formattedDate = DateFormat.yMMMd().add_jm().format(date);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Farmer: ${order['user_email']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text("Phone: ${order['phone']}"),
                        Text("Address: ${order['address']}"),
                        const SizedBox(height: 8),
                        const Text(
                          "Items:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...order['items'].map<Widget>(
                          (item) => Text(
                            "- ${item['type'] ?? item['product_type']} | LKR ${item['price']}",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Total: LKR ${order['total_cost']}",
                          style: const TextStyle(color: Colors.blue),
                        ),
                        Text(
                          "Date: $formattedDate",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        order['all_completed']
                            ? const Text(
                                "✅ Delivered",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () => _markAsDelivered(order['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text("Mark as Delivered"),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
