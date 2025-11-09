import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SellerEditPost extends StatefulWidget {
  final String userEmail;
  final String postId;
  final Map<String, dynamic> postData;

  const SellerEditPost({
    super.key,
    required this.userEmail,
    required this.postId,
    required this.postData,
  });

  @override
  State<SellerEditPost> createState() => _SellerEditPostState();
}

class _SellerEditPostState extends State<SellerEditPost> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  late String _selectedType;
  late String _selectedCondition;
  File? _selectedImage;
  String? _existingImageUrl;

  final List<String> productTypes = [
    'Fertilizers',
    'Seeds',
    'Pesticides',
    'Equipment',
    'Vehicles',
  ];

  final List<String> conditions = ['Used', 'Brand New'];

  @override
  void initState() {
    super.initState();
    // Initialize with existing data
    _priceController = TextEditingController(
      text: widget.postData['price']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.postData['description']?.toString() ?? '',
    );
    _selectedType = widget.postData['type'] ?? 'Fertilizers';
    _selectedCondition = widget.postData['condition'] ?? 'Brand New';
    _existingImageUrl = widget.postData['image_url'];
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String imageUrl = _existingImageUrl ?? '';

      // Upload new image if selected
      if (_selectedImage != null) {
        String fileName = 'seller_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(
          'seller_images/$fileName',
        );

        UploadTask uploadTask = storageRef.putFile(_selectedImage!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('seller_posts')
          .doc(widget.postId)
          .update({
            'type': _selectedType,
            'condition': _selectedCondition,
            'price': _priceController.text.trim(),
            'description': _descriptionController.text.trim(),
            'image_url': imageUrl,
            'updated_at': Timestamp.now(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image preview
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_existingImageUrl != null &&
                  _existingImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _existingImageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepOrange),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.deepOrange.shade50,
                    ),
                    child: const Center(
                      child: Text(
                        'Tap to select image',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit),
                label: const Text('Change Image'),
              ),
              const SizedBox(height: 16),

              // Product Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Product Type'),
                items: productTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedType = value!;
                }),
              ),
              const SizedBox(height: 12),

              // Condition Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: conditions
                    .map(
                      (cond) =>
                          DropdownMenuItem(value: cond, child: Text(cond)),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedCondition = value!;
                }),
              ),
              const SizedBox(height: 12),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (LKR)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _updatePost,
                child: const Text('Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
