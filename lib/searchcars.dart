// CarSearchPage.dart

import 'package:flutter/material.dart';
import 'api.dart'; // Make sure to import your CarSearchService

class CarSearchPage extends StatefulWidget {
  @override
  _CarSearchPageState createState() => _CarSearchPageState();
}

class _CarSearchPageState extends State<CarSearchPage> {
  final CarSearchService _carSearchService = CarSearchService();

  late final TextEditingController _makeController;
  List<Map<String, dynamic>> _cars = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController();
  }

  @override
  void dispose() {
    _makeController.dispose();
    super.dispose();
  }

  /// Fetch cars based on the make entered
  Future<void> _searchCars() async {
    FocusScope.of(context).unfocus();  // Dismiss the keyboard on search

    final make = _makeController.text.trim();
    if (make.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a car make.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cars = await _carSearchService.fetchCarsByMake(make);

      // Check if no cars are returned and handle that case
      if (cars.isEmpty) {
        setState(() {
          _errorMessage = 'No cars found for this make.';
        });
      } else {
        setState(() {
          _cars = cars;
        });
      }
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
        title: Text('Car Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input field for entering the car make
            TextField(
              controller: _makeController,
              decoration: InputDecoration(
                labelText: 'Enter car make (e.g., Toyota)',
                border: OutlineInputBorder(),
                errorText: _errorMessage, // Show error if any
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchCars,
              child: Text('Search'),
            ),
            SizedBox(height: 16),
            // Show loading indicator if fetching cars
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            // Show error message if any
            else if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              )
            // Display list of cars if available
            else if (_cars.isEmpty)
                Center(child: Text('No cars found.'))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _cars.length,
                    itemBuilder: (context, index) {
                      final car = _cars[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('${car['make']} ${car['model']}'),
                          subtitle: Text('Year: ${car['year']}'),
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
