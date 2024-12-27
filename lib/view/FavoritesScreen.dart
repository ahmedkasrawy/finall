import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mainlayout.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return MainLayout(
        selectedIndex: 1,
        child: Center(
          child: Text(
            'Please log in to see your favorites',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return MainLayout(
      selectedIndex: 1,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .doc(currentUser.uid)
            .collection('cars')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No favorite cars yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final favoriteCars = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteCars.length,
            itemBuilder: (context, index) {
              final car = favoriteCars[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(
                  car['image'] ?? '',
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.car_rental, size: 50, color: Colors.grey),
                ),
                title: Text(car['name'] ?? 'Unknown Car'),
                subtitle: Text(
                  'Year: ${car['modelYear'] ?? 'N/A'}, Price: ${car['price'] ?? 'N/A'}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('favorites')
                        .doc(currentUser.uid)
                        .collection('cars')
                        .doc(favoriteCars[index].id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed from favorites')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
