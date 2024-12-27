import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'MainLayout.dart'; // Use MainLayout for consistent navigation bar

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({Key? key}) : super(key: key);

  @override
  _AddCarScreenState createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();

  Uint8List? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        Uint8List originalBytes = await pickedFile.readAsBytes();

        // Compress the image
        img.Image? decodedImage = img.decodeImage(originalBytes);
        if (decodedImage != null) {
          Uint8List compressedBytes = Uint8List.fromList(
            img.encodeJpg(decodedImage, quality: 75),
          );
          setState(() {
            _selectedImage = compressedBytes;
          });
        } else {
          throw Exception('Failed to decode image.');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<String> _uploadImageToStorage(Uint8List imageBytes) async {
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

    final snapshot = await uploadTask.whenComplete(() => {});
    setState(() {
      _isUploading = false;
    });
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveCar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to add cars.')),
        );
        return;
      }

      if (_makeController.text.isEmpty ||
          _modelController.text.isEmpty ||
          _yearController.text.isEmpty ||
          _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill out all fields.')),
        );
        return;
      }

      final year = int.tryParse(_yearController.text.trim());
      final price = double.tryParse(_priceController.text.trim());

      if (year == null || year <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid year entered.')),
        );
        return;
      }

      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid price entered.')),
        );
        return;
      }

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('cars').add({
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': year,
        'price': price,
        'image': imageUrl ?? 'https://via.placeholder.com/150',
        'userId': user.uid,
        'createdAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Car added successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0, // Highlight the Home tab or relevant section
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedImage != null)
                    Center(
                      child: Image.memory(
                        _selectedImage!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        height: 150,
                        width: 150,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Photo'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _makeController,
                    decoration: const InputDecoration(
                      labelText: 'Car Make',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Car Model',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.drive_eta),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveCar,
                      child: const Text('Save Car'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading: ${_uploadProgress.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
