import 'package:flutter/material.dart';
import 'allcars.dart';
import 'api.dart';
import 'carDetails.dart';
import 'top_cars_list_view.dart';
import 'profilescreen.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchRandomCars(); // Fetch random cars when the screen loads
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch random cars
  Future<void> _fetchRandomCars() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final randomCars = await _carSearchService.fetchCarsByMake('Toyota'); // Fetch cars by default make
      setState(() {
        _randomCars = randomCars;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching random cars: $e';
        _randomCars = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch cars when a search is performed
  Future<void> _searchCars() async {
    final make = _searchController.text.trim();
    if (make.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a car make.';
        _randomCars = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cars = await _carSearchService.fetchCarsByMake(make);
      setState(() {
        _randomCars = cars;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: const Text(
          'Browse Cars',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _searchCars(), // Trigger search when enter is pressed
              decoration: InputDecoration(
                hintText: 'Search for cars...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  "Top Cars",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to the all cars screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AllCars()),
                    );
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show Loading, Error, or Cars List
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Text(
                _errorMessage ?? '', // Safe null check for error message
                style: TextStyle(color: Colors.red),
              ),
            )
          else if (_randomCars.isEmpty)
              Center(child: Text('No random cars available.'))
            else
              Expanded(
                child: TopCarsListView(
                  topCars: _randomCars,
                  onCarTap: (car) {
                    // Navigate to the CarDetailsScreen when a car is tapped
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              icon: Image.asset(
                'assets/home.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                // Navigate to the search screen
              },
              icon: Image.asset(
                'assets/magnifying-glass.png',
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(toggleTheme: () {}, isDarkMode: true),
                  ),
                );
              },
              icon: Image.asset(
                'assets/user.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
          ],
        ),
      ),
    );
  }
}
