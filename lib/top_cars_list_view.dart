import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopCarsListView extends StatefulWidget {
  final List<Map<String, dynamic>> topCars;
  final void Function(Map<String, dynamic> car) onCarTap;

  TopCarsListView({required this.topCars, required this.onCarTap});

  @override
  _TopCarsListViewState createState() => _TopCarsListViewState();
}

class _TopCarsListViewState extends State<TopCarsListView> {
  final Map<int, bool> _favorites = {}; // To track favorite state for each car
  final currentUser = FirebaseAuth.instance.currentUser;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${car['name']} removed from favorites!')),
      );
    } else {
      // Add to favorites
      await favoritesRef.doc(car['id']).set({
        'name': car['name'] ?? '${car['make']} ${car['model']}',
        'image': car['image'],
        'price': car['price'] ?? 'N/A',
        'modelYear': car['year'] ?? 'N/A',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${car['name']} added to favorites!')),
      );
    }

    setState(() {
      _favorites[index] = !(carDoc.exists); // Toggle the favorite state
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.topCars.length,
      itemBuilder: (context, index) {
        final car = widget.topCars[index];
        final isFavorite = _favorites[index] ?? false;

        return GestureDetector(
          onTap: () => widget.onCarTap(car),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: car['image'] != null && car['image'].isNotEmpty
                        ? Image.network(
                      car['image'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                        : Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Car Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          car['name'] ?? '${car['make']} ${car['model']}' ?? 'Unknown Car',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Make: ${car['make'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Model: ${car['model'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Year: ${car['year'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
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
