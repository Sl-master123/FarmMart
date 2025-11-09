import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrdersFromBuyers();
  }

  Future<void> _fetchOrdersFromBuyers() async {
    setState(() => _isLoading = true);

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

      setState(() {
        _ordersFromBuyers = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error loading buyer orders: $e')),
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

  Future<void> _markAsDelivered(String orderId) async {
    try {
      await _firestore.collection('cart_buy').doc(orderId).update({
        'all_completed': true,
      });
      _fetchOrdersFromBuyers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error updating order: $e')),
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

  Widget _buildBuyerOrderTab() {
    final pendingCount = _ordersFromBuyers
        .where((o) => !(o['all_completed'] ?? false))
        .length;
    final completedCount = _ordersFromBuyers
        .where((o) => o['all_completed'] ?? false)
        .length;

    return Column(
      children: [
        // Stats Header for Buyer Orders
        Container(
          color: Colors.green,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Text(
                        'Pending',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$completedCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'Completed',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_ordersFromBuyers.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Orders List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text('Loading orders...'),
                    ],
                  ),
                )
              : _ordersFromBuyers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No buyer orders yet",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrdersFromBuyers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ordersFromBuyers.length,
                    itemBuilder: (context, index) {
                      final order = _ordersFromBuyers[index];
                      final date = (order['timestamp'] as Timestamp).toDate();
                      String formattedDate =
                          '${date.day}/${date.month}/${date.year}';
                      final isCompleted = order['all_completed'] ?? false;
                      final items = order['items'] as List;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order ID, Date and Status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order #${order['id'].toString().substring(0, 8)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
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

                              // Order Placed By (Buyer)
                              _buildInfoRow(
                                Icons.person,
                                'Order Placed By',
                                order['user_email'].split('@')[0],
                                Colors.blue,
                              ),
                              const SizedBox(height: 8),

                              // Delivery Address
                              _buildInfoRow(
                                Icons.location_on,
                                'Delivery Address',
                                order['address'] ?? 'N/A',
                                Colors.red,
                              ),
                              const SizedBox(height: 8),

                              // Delivery Method
                              _buildInfoRow(
                                Icons.local_shipping,
                                'Delivery Method',
                                order['delivery_method'] ?? 'N/A',
                                Colors.green,
                              ),
                              const SizedBox(height: 8),

                              // Payment Method
                              _buildInfoRow(
                                Icons.payment,
                                'Payment Method',
                                order['payment_method'] ?? 'N/A',
                                Colors.purple,
                              ),
                              const SizedBox(height: 8),

                              // Mobile Number
                              _buildInfoRow(
                                Icons.phone,
                                'Mobile',
                                order['phone'] ?? 'N/A',
                                Colors.orange,
                              ),
                              const SizedBox(height: 8),

                              // Email
                              _buildInfoRow(
                                Icons.email,
                                'Email',
                                order['email'] ?? order['user_email'] ?? 'N/A',
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
                              ...items.map<Widget>((item) {
                                final productType =
                                    item['type'] ??
                                    item['rice_type'] ??
                                    'Product';
                                final price = item['price'] ?? 0;
                                final quantity = item['quantity'] ?? 1;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$productType (Qty: $quantity)',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const Text(
                                        'LKR ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '$price',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
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
                                  color: Colors.green.shade50,
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
                                          '${order['total_cost']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Mark as Delivered Button
                              if (!isCompleted) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _markAsDelivered(order['id']),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Mark as Delivered'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
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

        final orders = snapshot.data!.docs;
        final pendingCount = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !(data['all_completed'] ?? false);
        }).length;
        final completedCount = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['all_completed'] ?? false;
        }).length;

        return Column(
          children: [
            // Stats Header for My Orders
            Container(
              color: Colors.blue,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$pendingCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'Pending',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$completedCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Completed',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${orders.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No orders found",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        var order = orders[index];
                        var data = order.data() as Map<String, dynamic>;
                        Timestamp timestamp = data['timestamp'];
                        DateTime date = timestamp.toDate();
                        String formattedDate =
                            '${date.day}/${date.month}/${date.year}';
                        final isCompleted = data['all_completed'] ?? false;
                        final items = data['items'] as List;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order ID, Date and Status
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${order.id.substring(0, 8)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
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
                                        isCompleted
                                            ? 'Delivered'
                                            : 'Processing',
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

                                // Order From (Seller)
                                _buildInfoRow(
                                  Icons.store,
                                  'Order From',
                                  data['seller_email']?.split('@')[0] ??
                                      'Seller',
                                  Colors.deepOrange,
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

                                // Mobile Number
                                _buildInfoRow(
                                  Icons.phone,
                                  'Mobile',
                                  data['phone'] ?? 'N/A',
                                  Colors.orange,
                                ),
                                const SizedBox(height: 8),

                                // Email
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
                                ...items.map<Widget>((item) {
                                  final productType = item['type'] ?? 'Product';
                                  final quantity = item['quantity'] ?? 1;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$productType (Qty: $quantity)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
                                    color: Colors.green.shade50,
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
                                            data['total_cost'].toStringAsFixed(
                                              2,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Farmer Orders'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
