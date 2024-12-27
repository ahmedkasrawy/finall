import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCarsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("My Cars")),
        body: Center(
          child: Text("Please log in to view your cars."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("My Cars")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cars')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No cars added yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final cars = snapshot.data!.docs;

          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              final carData = car.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Image.network(
                    carData['image'] ?? 'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                  ),
                  title: Text('${carData['make']} ${carData['model']}'),
                  subtitle: Text('Price: \$${carData['price']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showEditPriceDialog(context, car.id, carData['price']);
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

  void _showEditPriceDialog(BuildContext context, String carId, dynamic currentPrice) {
    final priceController = TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Price"),
          content: TextField(
            controller: priceController,
            decoration: InputDecoration(
              labelText: 'New Price',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(priceController.text);
                if (newPrice != null && newPrice > 0) {
                  await FirebaseFirestore.instance
                      .collection('cars')
                      .doc(carId)
                      .update({'price': newPrice});
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Price updated successfully!")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid price.")),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
