// CarSearchPage.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'api/api.dart'; // Make sure to import your CarSearchService

class CarSearchPage extends StatefulWidget {
  @override
  _CarSearchPageState createState() => _CarSearchPageState();
}

class _CarSearchPageState extends State<CarSearchPage> {
  final CarSearchService _CarSearchService = CarSearchService();
  List<Map<String, dynamic>> _vehicles = [];
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _debounce; // Timer for debouncing

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _debounce?.cancel(); // Cancel any active debounce timers
    super.dispose();
  }

  /// Debounce the search
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchVehicles();
      }
    });
  }

  /// Fetch vehicles based on make and model
  Future<void> _searchVehicles() async {
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();

    if (make.isEmpty || model.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both make and model.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _CarSearchService.fetchVehiclesByMakeAndModel(make, model);
      setState(() {
        _vehicles = vehicles;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch vehicles. Error: $e';
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
      appBar: AppBar(title: const Text('Marketcheck Car Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _makeController,
              decoration: const InputDecoration(
                labelText: 'Enter car make (e.g., Toyota)',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged, // Debounced search
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Enter car model (e.g., Camry)',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged, // Debounced search
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchVehicles,
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            else if (_vehicles.isEmpty)
                const Center(child: Text('No vehicles found.'))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return Card(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              vehicle['image'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ListTile(
                                title: Text('${vehicle['make']} ${vehicle['model']}'),
                                subtitle: Text('Year: ${vehicle['year']}'),
                              ),
                            ),
                          ],
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