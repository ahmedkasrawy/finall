import 'package:flutter/material.dart';

class TopCarsListView extends StatelessWidget {
  final List<Map<String, dynamic>> topCars;
  final void Function(Map<String, dynamic> car) onCarTap;

  TopCarsListView({required this.topCars, required this.onCarTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: topCars.length,
      itemBuilder: (context, index) {
        final car = topCars[index];
        return GestureDetector(
          onTap: () => onCarTap(car),
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (car['image'] != null)
                    Image.network(
                      car['image'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car['name'] ?? 'Unknown Car',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Make: ${car['make'] ?? 'N/A'}'),
                      Text('Model: ${car['model'] ?? 'N/A'}'),
                    ],
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
