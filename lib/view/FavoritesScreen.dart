import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
        ),
        body: const Center(
          child: Text(
            'Please log in to see your favorites',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                    child: Image.network(
                      car['image'],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.car_rental,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  title: Text(
                    car['name'],
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
                        'Year: ${car['modelYear']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (car.containsKey('price'))
                        Text(
                          'Price: \$${car['price']}',
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
