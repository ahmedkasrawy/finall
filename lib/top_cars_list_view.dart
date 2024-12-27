import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TopCarsListView extends StatefulWidget {
  final List<Map<String, dynamic>> topCars;
  final void Function(Map<String, dynamic> car) onCarTap;

  TopCarsListView({required this.topCars, required this.onCarTap});

  @override
  _TopCarsListViewState createState() => _TopCarsListViewState();
}

class _TopCarsListViewState extends State<TopCarsListView> {
  final Map<int, bool> _favorites = {}; // Track favorite state for each car
  final currentUser = FirebaseAuth.instance.currentUser;

  final _random = Random(); // Random number generator for price

  Future<void> _toggleFavorite(Map<String, dynamic> car, int index) async {
    if (currentUser == null) return;

    final favoritesRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('cars');

    final carDoc = await favoritesRef.doc(car['id']).get();

    if (carDoc.exists) {
      // Remove from favorites
      await favoritesRef.doc(car['id']).delete();
      Fluttertoast.showToast(
        msg: '${car['name'] ?? 'Car'} removed from favorites!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      // Add to favorites
      await favoritesRef.doc(car['id']).set({
        'id': car['id'],
        'name': car['name'] ?? '${car['make']} ${car['model']}',
        'make': car['make'] ?? 'N/A',
        'model': car['model'] ?? 'N/A',
        'year': car['year'] ?? 'N/A',
        'price': car['price'] ?? (500 + _random.nextInt(9500)),
        'image': car['image'] ?? 'https://via.placeholder.com/150',
      });
      Fluttertoast.showToast(
        msg: '${car['name'] ?? 'Car'} added to favorites!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    setState(() {
      _favorites[index] = !carDoc.exists; // Toggle favorite state
    });
  }

  Widget buildImage(String imagePath) {
    return Image.network(
      imagePath,
      height: 80,
      width: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/kisooo.png',
        height: 80,
        width: 80,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.topCars.length,
      itemBuilder: (context, index) {
        final car = widget.topCars[index];

        // Assign a random price if not already set
        car['price'] ??= 500 + _random.nextInt(9500);

        final isFavorite = _favorites[index] ?? false;

        return GestureDetector(
          onTap: () => widget.onCarTap(car),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: buildImage(car['image']),
                  ),
                  const SizedBox(width: 16),
                  // Car Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car['name'] ?? '${car['make']} ${car['model']}' ?? 'Unknown Car',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make: ${car['make'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        Text(
                          'Model: ${car['model'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        Text(
                          'Year: ${car['year'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Price: \$${car['price']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite Icon
                  IconButton(
                    onPressed: () => _toggleFavorite(car, index),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
