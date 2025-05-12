import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  double _minPrice = 0;
  double _maxPrice = 5000;
  final currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _randomCars = [];
  List<Map<String, dynamic>> _firestoreCars = [];
  List<Map<String, dynamic>> _filteredCars = [];
  List<Map<String, dynamic>> _trendingCars = [];
  bool _isLoading = false;
  bool _isLoadingTrending = false;
  String? _errorMessage;
  String? _errorTrending;
  String? username;

  final Map<String, bool> _favorites = {}; // Track favorite state using car IDs

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchUsername();
    _fetchTrendingCars();
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

  Future<void> _fetchUsername() async {
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        setState(() {
          username = userDoc['username'] ?? 'User';
        });
      } catch (e) {
        print('Error fetching username: $e');
        setState(() {
          username = 'User';
        });
      }
    }
  }

  Future<void> _fetchTrendingCars() async {
    try {
      setState(() {
        _isLoadingTrending = true;
        _errorTrending = null;
      });

      final cars = await _carSearchService.fetchVehiclesByMakeAndModel('Ferrari', '');
      final random = Random();
      final trendingCarsWithPrices = cars.map((car) {
        return {
          ...car,
          'price': random.nextInt(4501) + 500,
        };
      }).toList();

      setState(() {
        _trendingCars = trendingCarsWithPrices;
      });
    } catch (e) {
      setState(() {
        _errorTrending = 'Error fetching trending cars: $e';
      });
    } finally {
      setState(() {
        _isLoadingTrending = false;
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> car) async {
    if (currentUser == null) return;

    final favoritesRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('cars');

    final carId = car['id'];
    final carDoc = await favoritesRef.doc(carId).get();

    if (carDoc.exists) {
      await favoritesRef.doc(carId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 200),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '${car['make']} ${car['model']} removed from favorites',
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.white,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    } else {
      await favoritesRef.doc(carId).set({
        'id': carId,
        'make': car['make'] ?? 'N/A',
        'model': car['model'] ?? 'N/A',
        'year': car['year'] ?? 'N/A',
        'price': car['price'] ?? 0,
        'image': car['image'] ?? 'https://via.placeholder.com/150',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 200),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '${car['make']} ${car['model']} added to favorites',
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.white,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    setState(() {
      _favorites[carId] = !carDoc.exists; // Toggle favorite state
    });
  }

  Future<void> _fetchCarsFromFirestore() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final snapshot = await FirebaseFirestore.instance.collection('cars').get();
      final cars = snapshot.docs.map((doc) {
        final data = doc.data();
        final random = Random();
        return {
          'id': doc.id,
          'make': data['make'] ?? 'Unknown',
          'model': data['model'] ?? 'Unknown',
          'year': data['year'] ?? 'Unknown',
          'price': data['price'] ?? (random.nextInt(4501) + 500), // Random price between 500 and 5,000 EGP per day
          'image': data['image'] ?? 'https://via.placeholder.com/150',
          'userId': data['userId'], // Add the userId field
        };
      }).toList();

      setState(() {
        _firestoreCars = cars;
        _filteredCars = _combinedCars;
      });
    } catch (e) {
      print('Error fetching cars from Firestore: $e');
      setState(() {
        _errorMessage = 'Error fetching cars from Firestore. Please try again.';
        _firestoreCars = [];
        _filteredCars = _randomCars; // Fallback to API cars if Firestore fails
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRandomCars() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final manufacturers = ['Toyota', 'Honda', 'Ford', 'BMW', 'Tesla', 'Dodge','Suzuki','Nissan','Mercedes','Audi','Volkswagen','Hyundai','Kia','Volvo','Jeep','Land Rover','Lexus','Mazda','Mercedes-Benz','Mitsubishi','Nissan','Peugeot','Renault','Skoda','Toyota','Volkswagen','Volvo'];
      final random = Random();

      List<Map<String, dynamic>> allCars = [];
      for (String make in manufacturers) {
        try {
          final cars = await _carSearchService.fetchVehiclesByMakeAndModel(make, '');
          // Add random prices to the cars
          final carsWithPrices = cars.map((car) => {
            ...car,
            'price': random.nextInt(4501) + 500,
            'userId': 'api_${make.toLowerCase()}_${random.nextInt(1000)}', // Add a unique userId for API cars
          }).toList();
          allCars.addAll(carsWithPrices);
        } catch (e) {
          print('Error fetching cars for $make: $e');
          // Continue with other manufacturers even if one fails
        }
      }

      setState(() {
        _randomCars = allCars;
        _filteredCars = _combinedCars;
      });
    } catch (e) {
      print('Error in _fetchRandomCars: $e');
      setState(() {
        _errorMessage = 'Error fetching cars from the API. Using local data only.';
        _randomCars = [];
        _filteredCars = _firestoreCars; // Fallback to Firestore cars if API fails
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
        _filteredCars = _combinedCars.where((car) {
          final price = car['price'] is String ? double.tryParse(car['price']) ?? 0 : car['price'] ?? 0;
          return price >= _minPrice && price <= _maxPrice;
        }).toList();
      } else {
        _filteredCars = _combinedCars.where((car) {
          final make = car['make']?.toString().toLowerCase() ?? '';
          final model = car['model']?.toString().toLowerCase() ?? '';
          final year = car['year']?.toString().toLowerCase() ?? '';
          final price = car['price'] is String ? double.tryParse(car['price']) ?? 0 : car['price'] ?? 0;

          return (make.contains(query) ||
              model.contains(query) ||
              year.contains(query)) &&
              price >= _minPrice &&
              price <= _maxPrice;
        }).toList();
      }
    });
  }

  Widget buildImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 150,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/kisooo.png',
            width: 150,
            height: 100,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.asset(
        'assets/kisooo.png',
        width: 150,
        height: 100,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainLayout(
        selectedIndex: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${username ?? 'User'}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Image.asset(
                      'assets/kasrawy.png',
                      width: 100,
                      height: 100,
                    ),
                    SizedBox(width: 10),
                    Expanded(
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
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Trending Cars",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 200,
                  child: _isLoadingTrending
                      ? const Center(child: CircularProgressIndicator())
                      : _errorTrending != null
                      ? Center(
                    child: Text(
                      _errorTrending!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _trendingCars.length,
                    itemBuilder: (context, index) {
                      final car = _trendingCars[index];
                      final carId = car['id'];
                      final isFavorite = _favorites[carId] ?? false;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CarDetailsScreen(car: car),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SizedBox(
                                  width: 150,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                        child: buildImage(car['image']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              car['make'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              car['model'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${car['price']} EGP/day',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 16,
                              child: IconButton(
                                onPressed: () => _toggleFavorite(car),
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                tooltip: isFavorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "All Cars",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 45),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddCarScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/add.png'),
                fit: BoxFit.cover,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
