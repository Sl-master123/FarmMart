import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFarmerPostDialog extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const EditFarmerPostDialog({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<EditFarmerPostDialog> createState() => _EditFarmerPostDialogState();
}

class _EditFarmerPostDialogState extends State<EditFarmerPostDialog> {
  late TextEditingController _riceTypeController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _locationController;
  late TextEditingController _farmerEmailController;

  @override
  void initState() {
    super.initState();
    _riceTypeController = TextEditingController(
      text: widget.postData['rice_type'] ?? '',
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
    _locationController = TextEditingController(
      text: widget.postData['location'] ?? '',
    );
    _farmerEmailController = TextEditingController(
      text: widget.postData['farmer_email'] ?? '',
    );
  }

  @override
  void dispose() {
    _riceTypeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _farmerEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Validation
    if (_riceTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Text('Rice type cannot be empty'),
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

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Text('Description cannot be empty'),
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

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter a valid price'),
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

    try {
      await FirebaseFirestore.instance
          .collection('farmer_posts')
          .doc(widget.postId)
          .update({
            'rice_type': _riceTypeController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': price,
            'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
            'location': _locationController.text.trim(),
            'farmer_email': _farmerEmailController.text.trim(),
          });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Farmer post updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error updating post: $e')),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Farmer Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _riceTypeController,
              decoration: const InputDecoration(
                labelText: 'Rice Type',
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
                labelText: 'Price (LKR)',
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
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _farmerEmailController,
              decoration: const InputDecoration(
                labelText: 'Farmer Email',
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
