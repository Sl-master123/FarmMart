import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerOrderProcess extends StatefulWidget {
  final String userEmail;

  const BuyerOrderProcess({super.key, required this.userEmail});

  @override
  State<BuyerOrderProcess> createState() => _BuyerOrderProcessState();
}

class _BuyerOrderProcessState extends State<BuyerOrderProcess> {
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cart_buy')
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

          // Calculate stats
          int totalOrders = snapshot.data!.docs.length;
          int pendingOrders = snapshot.data!.docs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['all_completed'] !=
                    true,
              )
              .length;
          int completedOrders = totalOrders - pendingOrders;

          return Column(
            children: [
              // Stats Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      totalOrders.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Pending',
                      pendingOrders.toString(),
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Delivered',
                      completedOrders.toString(),
                      Colors.blue,
                    ),
                  ],
                ),
              ),
              // Orders List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var order = snapshot.data!.docs[index];
                    var data = order.data() as Map<String, dynamic>;

                    Timestamp timestamp = data['timestamp'];
                    DateTime date = timestamp.toDate();
                    String formattedDate =
                        '${date.day}/${date.month}/${date.year}';

                    List items = data['items'] as List;
                    bool isCompleted = data['all_completed'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order ID, Date and Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #${order.id.substring(0, 8)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isCompleted ? 'Delivered' : 'Processing',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Order From (Seller Info)
                            _buildInfoRow(
                              Icons.store,
                              'Order From',
                              'Farmers (${items.length} items)',
                              Colors.green,
                            ),
                            const SizedBox(height: 8),

                            // Delivery Address
                            _buildInfoRow(
                              Icons.location_on,
                              'Delivery Address',
                              data['address'] ?? 'N/A',
                              Colors.red,
                            ),
                            const SizedBox(height: 8),

                            // Delivery Method
                            _buildInfoRow(
                              Icons.local_shipping,
                              'Delivery Method',
                              data['delivery_method'] ?? 'N/A',
                              Colors.blue,
                            ),
                            const SizedBox(height: 8),

                            // Payment Method
                            _buildInfoRow(
                              Icons.payment,
                              'Payment Method',
                              data['payment_method'] ?? 'N/A',
                              Colors.purple,
                            ),
                            const SizedBox(height: 8),

                            // Contact Info
                            _buildInfoRow(
                              Icons.phone,
                              'Mobile',
                              data['phone'] ?? 'N/A',
                              Colors.orange,
                            ),
                            const SizedBox(height: 8),

                            _buildInfoRow(
                              Icons.email,
                              'Email',
                              data['email'] ?? data['user_email'] ?? 'N/A',
                              Colors.teal,
                            ),
                            const Divider(height: 24),

                            // Items List
                            const Text(
                              'Items Ordered:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${item['type'] ?? 'Item'} (Qty: ${item['quantity'] ?? 1})',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),

                            // Total Cost
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Cost:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        'LKR ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        data['total_cost'].toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
