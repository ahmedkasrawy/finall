import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ProfileScreen.dart';
import '../UserSelectionScreen.dart';
import '../top_cars_list_view.dart';
import '../carDetails.dart';
import '../api/api.dart';
import 'AddCarScreen.dart';
import 'FavoritesScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
  int _selectedIndex = 0;

  // Price filter variables
  double _minPrice = 0;
  double _maxPrice = 10000;

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

  /// Fetch user-added cars from Firestore
  Future<void> _fetchCarsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('cars')
          .get();
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

  /// Fetch cars from API
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
        'Dodge',
        'Chevrolet',
        'Audi',
        'Mercedes-Benz',
        'Volkswagen',
        'Nissan',
        'Hyundai',
        'Kia',
      ];
      List<Map<String, dynamic>> allCars = [];

      for (String make in manufacturers) {
        final cars = await _carSearchService.fetchVehiclesByMakeAndModel(
            make, '');
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

  /// Combine API and Firestore cars
  List<Map<String, dynamic>> get _combinedCars =>
      [
        ..._randomCars,
        ..._firestoreCars,
      ];

  /// Filter cars based on search input and price range
  void _filterCars() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCars = _combinedCars.where((car) {
          final price = car['price'] ?? 0;
          return price >= _minPrice && price <= _maxPrice;
        }).toList();
      } else {
        _filteredCars = _combinedCars.where((car) {
          final make = car['make']?.toLowerCase() ?? '';
          final model = car['model']?.toLowerCase() ?? '';
          final year = car['year']?.toString() ?? '';
          final price = car['price'] ?? 0;
          return (make.contains(query) || model.contains(query) || year.contains(query)) &&
              (price >= _minPrice && price <= _maxPrice);
        }).toList();
      }
    });

    // Debugging search results
    print("Search Query: $query");
    print("Filtered Cars: $_filteredCars");
  }

  /// Handle bottom navigation bar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break; // Home - already on HomeScreen
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FavoritesScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserSelectionScreen()),
        );
        break; // Placeholder for search
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by make, model, or year...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
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
            // Price Range Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text('Price Range: \$${_minPrice.toInt()} - \$${_maxPrice.toInt()}'),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    labels: RangeLabels(
                      _minPrice.toInt().toString(),
                      _maxPrice.toInt().toString(),
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                      _filterCars(); // Apply filter after slider change
                    },
                  ),
                ],
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
                  : _filteredCars.isEmpty
                  ? const Center(child: Text('No cars found.'))
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCarScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: Image.asset(
          'assets/add.png',
          height: 30,
          width: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}