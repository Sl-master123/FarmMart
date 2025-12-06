import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerOrderProcess extends StatefulWidget {
  final String userEmail;

  const BuyerOrderProcess({super.key, required this.userEmail});

  @override
  State<BuyerOrderProcess> createState() => _BuyerOrderProcessState();
}

class _BuyerOrderProcessState extends State<BuyerOrderProcess> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cart_buy')
            .where('user_email', isEqualTo: widget.userEmail)
            // Removed orderBy to avoid composite index requirement
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
      ),
    );
  }
}
