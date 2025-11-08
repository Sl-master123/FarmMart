import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FarmerOrderProcess extends StatefulWidget {
  final String userEmail; // This is the farmer's email
  const FarmerOrderProcess({super.key, required this.userEmail});

  @override
  State<FarmerOrderProcess> createState() => _FarmerOrderProcessState();
}

class _FarmerOrderProcessState extends State<FarmerOrderProcess>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _ordersFromBuyers = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrdersFromBuyers();
  }

  Future<void> _fetchOrdersFromBuyers() async {
    try {
      final snapshot = await _firestore.collection('cart_buy').get();

      final List<Map<String, dynamic>> filteredOrders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        final matchedItems = items
            .where((item) => item['farmer_email'] == widget.userEmail)
            .toList();

        if (matchedItems.isNotEmpty) {
          filteredOrders.add({
            'id': doc.id,
            'user_email': data['user_email'],
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

      setState(() => _ordersFromBuyers = filteredOrders);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading buyer orders: $e')));
    }
  }

  Future<void> _markAsDelivered(String orderId) async {
    try {
      await _firestore.collection('cart_buy').doc(orderId).update({
        'all_completed': true,
      });
      _fetchOrdersFromBuyers();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    }
  }

  Widget _buildBuyerOrderTab() {
    if (_ordersFromBuyers.isEmpty) {
      return const Center(child: Text("No buyer orders available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _ordersFromBuyers.length,
      itemBuilder: (context, index) {
        final order = _ordersFromBuyers[index];
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
                  "Buyer: ${order['user_email']}",
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
                    "- ${item['type'] ?? item['rice_type']} | LKR ${item['price']}",
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Total: LKR ${order['total_cost']}",
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  "Date: $formattedDate",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                order['all_completed']
                    ? const Text(
                        "✔ Delivered",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _markAsDelivered(order['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("Mark as Delivered"),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFarmerViewOrderTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('farmer_cart_buy')
          .where('user_email', isEqualTo: widget.userEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var order = snapshot.data!.docs[index];
            var data = order.data() as Map<String, dynamic>;
            Timestamp timestamp = data['timestamp'];
            DateTime date = timestamp.toDate();
            String formattedDate = '${date.day}/${date.month}/${date.year}';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID: ${order.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Items: ${(data['items'] as List).length}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: LKR ${data['total_cost'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Chip(
                          label: Text(
                            data['all_completed'] == true
                                ? 'Delivered'
                                : 'Processing',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: data['all_completed'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'From Buyers'),
            Tab(text: 'My Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBuyerOrderTab(), _buildFarmerViewOrderTab()],
      ),
    );
  }
}
