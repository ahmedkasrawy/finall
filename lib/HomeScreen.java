import 'package:flutter/material.dart';
import 'api.dart'; // Import the CarSearchService class
import 'top_cars_list_view.dart'; // Assuming this widget is already defined for displaying cars

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarSearchService _carSearchService = CarSearchService();

  List<Map<String, dynamic>> _topCars = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTopCars();
  }

  // Fetch top cars from the API
  Future<void> _fetchTopCars() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cars = await _carSearchService.fetchCarsByMake(''); // You can modify this to get cars without specifying a make, or use a specific filter
      setState(() {
        _topCars = cars;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching cars: $e';
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
              onTap: () {
                // Navigate to the SearchScreen when the TextField is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
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
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            )
          else if (_topCars.isEmpty)
            Center(child: Text('No cars found.'))
          else
            Expanded(
              child: TopCarsListView(topCars: _topCars),
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
                          ProfileScreen(toggleTheme: () {}, isDarkMode: true)),
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
