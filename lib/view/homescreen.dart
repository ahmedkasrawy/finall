import 'package:flutter/material.dart';
import '../allcars.dart'; // Ensure this is implemented correctly
import '../profilescreen.dart'; // Ensure this exists
import '../top_cars_list_view.dart';
import '../carDetails.dart';
import '../api/api.dart'; // Adjust path if necessary

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarSearchService _carSearchService = CarSearchService();
  late TextEditingController _searchController;

  List<Map<String, dynamic>> _randomCars = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = 0; // Track selected item in the bottom app bar

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchRandomCars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRandomCars() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch cars for multiple manufacturers
      final manufacturers = ['Toyota', 'Honda', 'Ford', 'BMW', 'Tesla'];
      List<Map<String, dynamic>> allCars = [];

      for (String make in manufacturers) {
        final cars = await _carSearchService.fetchVehiclesByMakeAndModel(make, '');
        allCars.addAll(cars);
      }

      // Filter cars with valid image URLs
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

  Future<void> _searchCars() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a car make or model.';
        _randomCars = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Split the query into potential make and model parts
      final queryParts = query.split(' ');
      final make = queryParts.isNotEmpty ? queryParts[0] : '';
      final model = queryParts.length > 1 ? queryParts[1] : '';

      // Fetch cars for the entered make and/or model
      final cars = await _carSearchService.fetchVehiclesByMakeAndModel(make, model);

      if (cars.isEmpty) {
        setState(() {
          _errorMessage = 'No cars found for "$query".';
          _randomCars = [];
        });
        return;
      }

      // Filter cars with valid image URLs
      final filteredCars = cars.where((car) {
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



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
      // Home - Already on HomeScreen
        break;
      case 1:
      // Navigate to Favorites (replace with actual implementation)
        break;
      case 2:
      // Search Functionality
        _searchCars();
        break;
      case 3:
      // Navigate to Profile Screen
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
                      onSubmitted: (_) => _searchCars(),
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
                  : _randomCars.isEmpty
                  ? const Center(child: Text('No cars found.'))
                  : TopCarsListView(
                topCars: _randomCars,
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomAppBar(
            shape: CircularNotchedRectangle(),
            notchMargin: 6.0,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
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
          const SizedBox(height: 16), // Padding below the BottomAppBar
        ],
      ),
    );
  }
}
