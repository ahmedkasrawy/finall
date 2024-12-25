import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Favorites')),
        body: Center(child: Text('Please log in to see your favorites')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Favorites')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .doc(currentUser!.uid)
            .collection('cars')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No favorite cars yet.'));
          }

          final favoriteCars = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteCars.length,
            itemBuilder: (context, index) {
              final car = favoriteCars[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(car['image'], width: 50, height: 50),
                title: Text(car['name']),
                subtitle: Text('Year: ${car['modelYear']}'),
              );
            },
          );
        },
      ),
    );
  }
}
