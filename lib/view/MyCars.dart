import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCarsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("My Cars"),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Text(
            "Please log in to view your cars.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Cars"),
        backgroundColor: Colors.blueAccent,
      ),
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
            padding: EdgeInsets.all(12),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              final carData = car.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          carData['image'] ?? 'https://via.placeholder.com/150',
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Car Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${carData['make']} ${carData['model']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Year: ${carData['year']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Price: ${carData['price']} EGP/day',
                              style: TextStyle(fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditPriceDialog(context, car.id, carData['price']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDeleteCar(context, car.id);
                            },
                          ),
                        ],
                      ),
                    ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Edit Price"),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New Price (EGP)',
              prefixText: 'EGP ',
            ),
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
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Price updated successfully!",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Invalid price.",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
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

  void _confirmDeleteCar(BuildContext context, String carId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Delete Car"),
          content: Text("Are you sure you want to delete this car?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('cars').doc(carId).delete();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Car deleted successfully!",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Failed to delete car: $e",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
