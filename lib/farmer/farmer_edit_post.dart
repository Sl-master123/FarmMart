import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FarmerEditPost extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const FarmerEditPost({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<FarmerEditPost> createState() => _FarmerEditPostState();
}

class _FarmerEditPostState extends State<FarmerEditPost> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _imageUrl;
  File? _imageFile;
  String? _selectedCategory;
  String? _selectedRiceType;
  String _productType = 'paddy';
  bool _isLoading = false;

  final Map<String, List<String>> _riceTypes = {
    'Traditional': [
      'Suwandel',
      'Kalu Heenati',
      'Maa-Wee',
      'Rathu El',
      'Pachchaperumal',
    ],
    'Improved': ['Samba', 'Kekulu', 'Nadu', 'Mottai Karuppan'],
    'Specialty & Hybrid': [
      'Basmati',
      'Red Rice (Rathu Kakulu)',
      'White Rice (Sudu Kakulu)',
      'Parboiled Rice (Sudu & Rathu Kekulu)',
    ],
  };

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.postData['price']?.toString() ?? '';
    _descriptionController.text = widget.postData['description'] ?? '';
    _productType = widget.postData['product_type'] ?? 'paddy';
    _selectedCategory = widget.postData['category'];
    _selectedRiceType = widget.postData['rice_type'];
    _imageUrl = widget.postData['image_url'];
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('farmer_posts')
          .child(
            '${widget.postId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to upload image: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return null;
    }
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select a rice type'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? uploadedImageUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('farmer_posts')
          .doc(widget.postId)
          .update({
            'category': _selectedCategory,
            'rice_type': _selectedRiceType,
            'price': double.parse(_priceController.text.trim()),
            'product_type': _productType,
            'description': _descriptionController.text.trim(),
            if (uploadedImageUrl != null) 'image_url': uploadedImageUrl,
            'updated_at': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Post updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to update post: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50),
                                  SizedBox(height: 8),
                                  Text('Tap to select image'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _productType,
                      decoration: const InputDecoration(
                        labelText: 'Product Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'paddy', child: Text('Paddy')),
                        DropdownMenuItem(value: 'rice', child: Text('Rice')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _productType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _riceTypes.keys
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _selectedRiceType = null;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRiceType,
                      decoration: const InputDecoration(
                        labelText: 'Rice Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _selectedCategory != null
                          ? _riceTypes[_selectedCategory]!
                                .map(
                                  (riceType) => DropdownMenuItem(
                                    value: riceType,
                                    child: Text(riceType),
                                  ),
                                )
                                .toList()
                          : [],
                      onChanged: (value) {
                        setState(() => _selectedRiceType = value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a rice type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (LKR)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updatePost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Update Post',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
