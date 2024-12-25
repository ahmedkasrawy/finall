import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCarScreen extends StatefulWidget {
  @override
  _AddCarScreenState createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> _saveCar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to add cars.')),
        );
        return;
      }

      // Save car data to Firestore
      await FirebaseFirestore.instance.collection('cars').add({
        'make': _makeController.text.trim().toLowerCase(),
        'model': _modelController.text.trim().toLowerCase(),
        'year': _yearController.text.trim(),
        'price': _priceController.text.trim(),
        'image': 'default_image_url',
        'userId': user.uid,
        'createdAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Car added successfully!')),
      );

      Navigator.of(context).pop(); // Go back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Car'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _makeController,
                decoration: InputDecoration(labelText: 'Car Make'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _modelController,
                decoration: InputDecoration(labelText: 'Car Model'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _yearController,
                decoration: InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveCar,
                child: Text('Save Car'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
