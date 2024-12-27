import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ProfileScreen.dart';
import '../top_cars_list_view.dart';
import '../carDetails.dart';
import '../api/api.dart';
import 'AddCarScreen.dart';
import 'FavoritesScreen.dart';
import 'mainlayout.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarSearchService _carSearchService = CarSearchService();
  late TextEditingController _searchController;
  final currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _randomCars = [];
  List<Map<String, dynamic>> _firestoreCars = [];
  List<Map<String, dynamic>> _filteredCars = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchRandomCars();
    _fetchCarsFromFirestore();
    _searchController.addListener(_filterCars);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCars);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCarsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('cars').get();
      final cars = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'make': data['make'],
          'model': data['model'],
          'year': data['year'],
          'price': data['price'],
          'image': data['image'] ?? 'https://via.placeholder.com/150',
        };
      }).toList();

      setState(() {
        _firestoreCars = cars;
        _filteredCars = _combinedCars;
      });
    } catch (e) {
      print('Error fetching cars from Firestore: $e');
    }
  }

  Future<void> _fetchRandomCars() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final manufacturers = [
        'Toyota',
        'Honda',
        'Ford',
        'BMW',
        'Tesla',
      ];

      List<Map<String, dynamic>> allCars = [];
      for (String make in manufacturers) {
        final cars = await _carSearchService.fetchVehiclesByMakeAndModel(make, '');
        allCars.addAll(cars);
      }

      final filteredCars = allCars.where((car) {
        final imageUrl = car['image'];
        return imageUrl != null && imageUrl.isNotEmpty;
      }).toList();

      setState(() {
        _randomCars = filteredCars;
        _filteredCars = _combinedCars;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching cars: $e';
        _randomCars = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _combinedCars => [..._randomCars, ..._firestoreCars];

  void _filterCars() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCars = _combinedCars;
      } else {
        _filteredCars = _combinedCars.where((car) {
          final make = car['make']?.toLowerCase() ?? '';
          final model = car['model']?.toLowerCase() ?? '';
          final year = car['year']?.toString() ?? '';
          return make.contains(query) || model.contains(query) || year.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0, // Highlight Home
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search cars...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : TopCarsListView(
                topCars: _filteredCars,
                onCarTap: (car) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarDetailsScreen(car: car),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
