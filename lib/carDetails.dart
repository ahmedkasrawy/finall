import 'package:flutter/material.dart';

import 'carBookingScreen.dart';

class CarDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> car;

  CarDetailsScreen({required this.car});

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Text(car['name'] ?? 'Car Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (car['image'] != null)
              Center(
                child: Image.network(
                  car['image'],
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),
            Text(
              car['name'] ?? 'Unknown Car',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Make: ${car['make'] ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Model: ${car['model'] ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Year: ${car['year'] ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Price per day: ${car['price_per_day'] ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            // Embedding the CarBookingScreen inside the Container
            Container(
              margin: EdgeInsets.symmetric(vertical: 16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CarBookingScreen(), // Embed the CarBookingScreen here
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CarBookingScreen();
                }));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
              ),
              child: Text(
                'Book Now',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
