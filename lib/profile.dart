import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;

  Future<void> onEditProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Widget buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back icon
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 26),
                  ),
                ],
              ),
            ),

            // Profile Image + Name + Email
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _imageFile != null
                              ? FileImage(_imageFile!)
                              : const AssetImage('assets/profile.jpg')
                                  as ImageProvider,
                    ),
                    GestureDetector(
                      onTap: onEditProfilePic,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Profile Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Profileuser@gmail.com',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Settings List
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  buildSettingItem(Icons.person, 'User Information', () {
                    print('User Information tapped');
                  }),
                  buildSettingItem(Icons.shopping_cart_outlined, 'My Cart', () {
                    print('My Cart tapped');
                  }),
                  buildSettingItem(Icons.favorite_border, 'My Favorites', () {
                    print('My Favorites tapped');
                  }),
                  buildSettingItem(
                    Icons.notifications_none,
                    'Notifications',
                    () {
                      print('Notifications tapped');
                    },
                  ),
                  buildSettingItem(Icons.headset_mic, 'Help', () {
                    print('Help tapped');
                  }),
                  buildSettingItem(Icons.logout, 'Logout', () {
                    print('Logout tapped');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
