import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newadd/firestore.dart';

class FarmerAddPost extends StatefulWidget {
  final String userEmail;
  const FarmerAddPost({super.key, required this.userEmail});

  @override
  State<FarmerAddPost> createState() => _FarmerAddPostState();
}

class _FarmerAddPostState extends State<FarmerAddPost> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String? _selectedCategory;
  String? _selectedRiceType;
  String _productType = 'paddy';
  bool _isUploading = false;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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
    _recoverLostData();
  }

  Future<void> _recoverLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (!response.isEmpty && response.file != null) {
      setState(() => _image = File(response.file!.path));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image picker error: $e')));
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rice type')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _firestoreService.addFarmerPost(
        userEmail: widget.userEmail,
        category: _selectedCategory!,
        riceType: _selectedRiceType!,
        price: _priceController.text,
        productType: _productType,
        description: _descriptionController.text,
        imagePath: _image?.path, // Just file path saved here
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
      appBar: AppBar(title: const Text('Create New Post'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageCard(),
              const SizedBox(height: 16),
              _buildRiceTypeSelector(),
              const SizedBox(height: 16),
              _buildPriceInput(),
              const SizedBox(height: 16),
              _buildProductTypeSelector(),
              const SizedBox(height: 16),
              _buildDescriptionInput(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Image',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: _image == null
                  ? const Center(child: Icon(Icons.add_a_photo, size: 40))
                  : Image.file(
                      _image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildRiceTypeSelector() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rice Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._riceTypes.entries.map(
            (category) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<String>(
                  title: Text(category.key),
                  value: category.key,
                  groupValue: _selectedCategory,
                  onChanged: (value) => setState(() {
                    _selectedCategory = value;
                    _selectedRiceType = null;
                  }),
                ),
                if (_selectedCategory == category.key)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Column(
                      children: category.value
                          .map(
                            (type) => RadioListTile<String>(
                              title: Text(type),
                              value: type,
                              groupValue: _selectedRiceType,
                              onChanged: (value) =>
                                  setState(() => _selectedRiceType = value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPriceInput() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price (LKR/kg)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter price',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a price';
              if (double.tryParse(value) == null) return 'Enter a valid number';
              return null;
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildProductTypeSelector() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Form',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Paddy'),
                  value: 'paddy',
                  groupValue: _productType,
                  onChanged: (value) => setState(() => _productType = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Rice'),
                  value: 'rice',
                  groupValue: _productType,
                  onChanged: (value) => setState(() => _productType = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildDescriptionInput() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe your product...',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please enter a description'
                : null,
          ),
        ],
      ),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.lightGreen,
      ),
      onPressed: _isUploading ? null : _submitPost,
      child: _isUploading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'PUBLISH POST',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}
