import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ProfileScreen.dart';
import '../top_cars_list_view.dart';
import '../carDetails.dart';
import '../api/api.dart';
import 'AddCarScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarSearchService _carSearchService = CarSearchService();
  late TextEditingController _searchController;

  List<Map<String, dynamic>> _randomCars = [];
  List<Map<String, dynamic>> _firestoreCars = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchRandomCars();
    _fetchFirestoreCars(); // Fetch Firestore cars
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch cars from the API
  Future<void> _fetchRandomCars() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final manufacturers = ['Toyota', 'Honda', 'Ford', 'BMW', 'Tesla'];
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

  /// Fetch cars from Firestore
  Future<void> _fetchFirestoreCars() async {
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
      });
    } catch (e) {
      print('Error fetching cars from Firestore: $e');
    }
  }

  /// Combine API cars and Firestore cars
  List<Map<String, dynamic>> get _allCars => [..._randomCars, ..._firestoreCars];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/kisooo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _fetchRandomCars(),
                      decoration: InputDecoration(
                        hintText: 'Search for cars...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Top Cars",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
                  : _allCars.isEmpty
                  ? const Center(child: Text('No cars found.'))
                  : TopCarsListView(
                topCars: _allCars,
                onCarTap: (car) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CarDetailsScreen(car: car),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCarScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
