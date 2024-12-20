import 'package:finall/top_cars_list_view.dart';
import 'package:flutter/material.dart';

class AllCars extends StatefulWidget {
  const AllCars({super.key});

  @override
  State<AllCars> createState() => _AllCarsState();
}

class _AllCarsState extends State<AllCars> {
  final List<Map<String, String>> topCars = [
    {'name': 'Tesla Model S', 'image': 'assets/sport-car.png', 'year': '2021', 'price': '\$85,000'},
    {'name': 'BMW 3 Series', 'image': 'assets/sport-car.png', 'year': '2020', 'price': '\$50,000'},
    {'name': 'Mercedes C-Class', 'image': 'assets/sport-car.png', 'year': '2022', 'price': '\$60,000'},
    {'name': 'Audi A4', 'image': 'assets/sport-car.png', 'year': '2021', 'price': '\$55,000'},
    {'name': 'Toyota Corolla', 'image': 'assets/sport-car.png', 'year': '2019', 'price': '\$25,000'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Cars'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Expanded(
        child: TopCarsListView(topCars: topCars, onCarTap: (Map<String, dynamic> car) {  },), // Use the new list view class here
      ),
    );
  }
}
