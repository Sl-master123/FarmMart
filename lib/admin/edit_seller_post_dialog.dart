import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSellerPostDialog extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const EditSellerPostDialog({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<EditSellerPostDialog> createState() => _EditSellerPostDialogState();
}

class _EditSellerPostDialogState extends State<EditSellerPostDialog> {
  late TextEditingController _typeController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _brandController;
  late TextEditingController _sellerEmailController;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(
      text: widget.postData['type'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.postData['description'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.postData['price']?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.postData['quantity']?.toString() ?? '',
    );
    _brandController = TextEditingController(
      text: widget.postData['brand'] ?? '',
    );
    _sellerEmailController = TextEditingController(
      text: widget.postData['seller_email'] ?? '',
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _sellerEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('seller_posts')
          .doc(widget.postId)
          .update({
            'type': _typeController.text,
            'description': _descriptionController.text,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'quantity': int.tryParse(_quantityController.text) ?? 0,
            'brand': _brandController.text,
            'seller_email': _sellerEmailController.text,
          });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller post updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Seller Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Product Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sellerEmailController,
              decoration: const InputDecoration(
                labelText: 'Seller Email',
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
