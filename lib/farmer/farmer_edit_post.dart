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
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _imageUrl;
  File? _imageFile;
  String _condition = 'Brand New';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _typeController.text = widget.postData['type'] ?? '';
    _priceController.text = widget.postData['price']?.toString() ?? '';
    _descriptionController.text = widget.postData['description'] ?? '';
    _condition = widget.postData['condition'] ?? 'Brand New';
    _imageUrl = widget.postData['image_url'];
  }

  @override
  void dispose() {
    _typeController.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      return null;
    }
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? uploadedImageUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('farmer_posts')
          .doc(widget.postId)
          .update({
            'type': _typeController.text.trim(),
            'price': double.parse(_priceController.text.trim()),
            'description': _descriptionController.text.trim(),
            'condition': _condition,
            if (uploadedImageUrl != null) 'image_url': uploadedImageUrl,
            'updated_at': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update post: $e')));
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
                    TextFormField(
                      controller: _typeController,
                      decoration: const InputDecoration(
                        labelText: 'Product Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
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
                    DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Brand New', 'Used']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _condition = value);
                        }
                      },
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
