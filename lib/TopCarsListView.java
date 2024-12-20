// top_cars_list_view.dart

import 'package:flutter/material.dart';

class TopCarsListView extends StatelessWidget {
  final List<Map<String, dynamic>> topCars;

  TopCarsListView({required this.topCars});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: topCars.length,
      itemBuilder: (context, index) {
        final car = topCars[index];
        return Card(
          child: ListTile(
            leading: Image.asset(
              car['image'], // Use image URL or asset
              width: 50, // Specify a fixed size for images
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text('${car['make']} ${car['model']}'),
            subtitle: Text('Year: ${car['year']}, Price: ${car['price']}'),
          ),
        );
      },
    );
  }
}
