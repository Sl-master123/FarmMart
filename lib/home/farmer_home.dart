import 'package:flutter/material.dart';
import 'package:newadd/farmer/farmer_add_post.dart';

class FarmerHome extends StatefulWidget {
  final String userEmail;
  const FarmerHome({super.key, required this.userEmail});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const Center(child: Text('Home Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Market Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Add Post Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Notifications', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Profile Page', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FarmerAddPost(userEmail: widget.userEmail),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
        _pageController.jumpToPage(index);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Home'),
        centerTitle: true,
        backgroundColor: Colors.lightGreen,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        backgroundColor: Colors.lightGreen,
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
              // Left side icons
              Row(
                children: [
                  _buildNavItem(Icons.home, 0, 'Home'),
                  _buildNavItem(Icons.shopping_cart, 1, 'Market'),
                ],
              ),
              // Right side icons
              Row(
                children: [
                  _buildNavItem(Icons.notifications_none, 3, 'Alerts'),
                  _buildNavItem(Icons.person_outline, 4, 'Profile'),
                ],
              ),
            ],
          ),
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
                color: isSelected ? Colors.lightGreen : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.lightGreen : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
