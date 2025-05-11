import 'dart:convert';
import 'package:http/http.dart' as http;

class CarSearchService {
  final String baseUrl = 'https://mc-api.marketcheck.com/v2/';
  final String apiKey = 'iZsSUKwuLk6ouzkbGv3Ws4kBSHktIkX4';

  // Fallback car data in case API fails
  final List<Map<String, dynamic>> _fallbackCars = [
    {
      'make': 'Toyota',
      'model': 'Camry',
      'year': '2022',
      'image': 'https://via.placeholder.com/150',
    },
    {
      'make': 'Honda',
      'model': 'Civic',
      'year': '2022',
      'image': 'https://via.placeholder.com/150',
    },
    {
      'make': 'Ford',
      'model': 'Mustang',
      'year': '2022',
      'image': 'https://via.placeholder.com/150',
    },
  ];

  /// Fetch vehicles by make and model with fallback and logs
  Future<List<Map<String, dynamic>>> fetchVehiclesByMakeAndModel(String make, String model) async {
    try {
      // Normalize inputs
      make = make.capitalize();
      model = model.capitalize();

      List<Map<String, dynamic>> vehicles = await _fetch(make, model);

      // Fallback: if model returns no result, try make only
      if (vehicles.isEmpty && model.isNotEmpty) {
        print('No results found for "$make $model". Retrying with make only...');
        vehicles = await _fetch(make, '');
      }

      // If still no results, return filtered fallback data
      if (vehicles.isEmpty) {
        print('No results found. Using fallback data...');
        return _fallbackCars.where((car) {
          final carMake = car['make'].toString().toLowerCase();
          final carModel = car['model'].toString().toLowerCase();
          return carMake.contains(make.toLowerCase()) ||
              carModel.contains(model.toLowerCase());
        }).toList();
      }

      return vehicles;
    } catch (e) {
      print('Error in fetchVehiclesByMakeAndModel: $e');
      // Return filtered fallback data on error
      return _fallbackCars.where((car) {
        final carMake = car['make'].toString().toLowerCase();
        final carModel = car['model'].toString().toLowerCase();
        return carMake.contains(make.toLowerCase()) ||
            carModel.contains(model.toLowerCase());
      }).toList();
    }
  }

  Future<List<Map<String, dynamic>>> _fetch(String make, String model) async {
    final queryParams = [
      'api_key=$apiKey',
      if (make.isNotEmpty) 'make=$make',
      if (model.isNotEmpty) 'model=$model',
      'rows=10',
    ].join('&');

    final url = Uri.parse('$baseUrl/search/car/active?$queryParams');

    try {
      print('Fetching from: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final listings = data['listings'] as List?;

        if (listings == null || listings.isEmpty) {
          print('No vehicles found in response.');
          return [];
        }

        return listings.map((vehicle) {
          final media = vehicle['media'] ?? {};
          final photoLinks = media['photo_links'] as List<dynamic>? ?? [];

          return {
            'make': vehicle['build']['make'] ?? 'Unknown Make',
            'model': vehicle['build']['model'] ?? 'Unknown Model',
            'year': vehicle['build']['year'] ?? 'Unknown Year',
            'image': (photoLinks.isNotEmpty && photoLinks.first.toString().isNotEmpty)
                ? photoLinks.first
                : 'assets/kisooo.png',
          };
        }).toList();
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch vehicles: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during fetch: $e');
      throw Exception('Error fetching vehicles: $e');
    }
  }
}

/// String extension to capitalize input
extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
