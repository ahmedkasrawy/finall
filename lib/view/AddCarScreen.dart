import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCarScreen extends StatefulWidget {
  @override
  _AddCarScreenState createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carMakeController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carYearController = TextEditingController();
  final _carPriceController = TextEditingController();

  Uint8List? _imageBytes;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')),
      );
    }
  }

  Future<String> _uploadImageToStorage(Uint8List imageBytes) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('car_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putData(imageBytes);

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        setState(() {
          _isUploading = true;
          _uploadProgress = progress;
        });
      });

      final snapshot = await uploadTask.whenComplete(() {});
      setState(() {
        _isUploading = false;
      });

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> _saveCar() async {
    if (_formKey.currentState!.validate() && _imageBytes != null) {
      try {
        final imageUrl = await _uploadImageToStorage(_imageBytes!);
        await FirebaseFirestore.instance.collection('cars').add({
          'make': _carMakeController.text,
          'model': _carModelController.text,
          'year': _carYearController.text,
          'price': _carPriceController.text,
          'image': imageUrl,
          'createdAt': DateTime.now(),
          'userId': FirebaseAuth.instance.currentUser!.uid,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Car added successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save car: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and add an image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Car'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImageFromCamera,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageBytes != null
                    ? Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.camera_alt,
                  color: Colors.grey,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _carMakeController,
                    decoration: const InputDecoration(
                      labelText: 'Car Make',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter car make';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _carModelController,
                    decoration: const InputDecoration(
                      labelText: 'Car Model',
                      prefixIcon: Icon(Icons.drive_eta),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter car model';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _carYearController,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter year';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _carPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveCar,
                    child: _isUploading
                        ? Text('Uploading: ${_uploadProgress.toStringAsFixed(0)}%')
                        : const Text('Save Car'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
