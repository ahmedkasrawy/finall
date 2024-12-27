import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'bottom.dart';

class FavoritesScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return MainScaffold(
        selectedIndex: 1, // Highlight the Favorites tab
        child: const Center(
          child: Text(
            'Please log in to see your favorites',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return MainScaffold(
      selectedIndex: 1, // Highlight the Favorites tab
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .doc(currentUser!.uid)
            .collection('cars')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No favorite cars yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final favoriteCars = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteCars.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final car = favoriteCars[index].data() as Map<String, dynamic>;

              // Fallback values for null fields
              final carName = car['name'] ?? 'Unknown Car';
              final carImage = car['image'] ?? ''; // Empty string for missing image
              final carYear = car['modelYear'] ?? 'N/A';
              final carPrice = car['price'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: carImage.isNotEmpty
                        ? Image.network(
                      carImage,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(
                        Icons.car_rental,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                        : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  title: Text(
                    carName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Year: $carYear',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Price: $carPrice',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      // Handle unfavorite logic
                      FirebaseFirestore.instance
                          .collection('favorites')
                          .doc(currentUser!.uid)
                          .collection('cars')
                          .doc(favoriteCars[index].id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from favorites')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
