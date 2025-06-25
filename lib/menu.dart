import 'package:flutter/material.dart';
import 'profile.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 2; // Default is Cart

  final List<Map<String, String>> products = [
    {
      'image': 'assets/9.jpeg',
      'name': 'NPK 15-15-15',
      'price': 'LKR 590.00',
      'unit': 'Per Kg',
    },
    {
      'image': 'assets/1.jpeg',
      'name': 'NPK 10-20-10',
      'price': 'LKR 400.00',
      'unit': 'Per Kg',
    },
    {
      'image': 'assets/7.jpeg',
      'name': 'Compost',
      'price': 'LKR 200.00',
      'unit': 'Per Kg',
    },
    {
      'image': 'assets/6.jpeg',
      'name': 'Greenmanure',
      'price': 'LKR 150.00',
      'unit': 'Per Kg',
    },
    {
      'image': 'assets/8.jpeg',
      'name': 'Potash Fertilizer',
      'price': 'LKR 350.00',
      'unit': 'Per Kg',
    },
    {
      'image': 'assets/2.jpeg',
      'name': 'Urea 46%',
      'price': 'LKR 500.00',
      'unit': 'Per Kg',
    },
    {
      'image': 'assets/3.jpeg',
      'name': 'Organic Mulch',
      'price': 'LKR 180.00',
      'unit': 'Per Kg',
    },
    {
      'image': 'assets/4.jpeg',
      'name': 'Lime Powder',
      'price': 'LKR 220.00',
      'unit': 'Per Kg',
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildProductCard(Map<String, String> product) {
    return Container(
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              product['image']!,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    product['name']!,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  product['price']!,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  product['unit']!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.only(right: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white, size: 24),
                onPressed: () => print('Added ${product['name']}'),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductGrid() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.72,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: products.map(buildProductCard).toList(),
    );
  }

  Widget buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 6),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.tune, color: Colors.lightGreen),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (_selectedIndex == 2) {
      // Cart page
      return ListView(
        padding: EdgeInsets.all(10),
        children: [
          Row(children: [Icon(Icons.arrow_back, size: 26)]),
          SizedBox(height: 10),
          buildSearchBar(),
          SizedBox(height: 12),
          buildProductGrid(),
        ],
      );
    } else if (_selectedIndex == 4) {
      // Profile page
      return ProfilePage();
    } else {
      return Center(child: Text('Page ${_selectedIndex + 1}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: buildContent()),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 26),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded, size: 26),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined, size: 26),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded, size: 26),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 26),
            label: '',
          ),
        ],
      ),
    );
  }
}
