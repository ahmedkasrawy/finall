import 'dart:convert';
import 'package:http/http.dart' as http;

class CarSearchService {
  final String baseUrl = 'https://mc-api.marketcheck.com/v2/';
  final String apiKey = 'ILhyyK4pKIq9v5sXFxILYLmyFZyqSHGY';

  /// Fetch vehicles by make and model
  Future<List<Map<String, dynamic>>> fetchVehiclesByMakeAndModel(String make, String model) async {
    final url = Uri.parse(
        '$baseUrl/search/car/active?api_key=$apiKey&make=$make&model=$model&rows=10');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final listings = data['listings'] as List;

        // Extract vehicle data, including media links directly from the response
        List<Map<String, dynamic>> vehicles = listings.map((vehicle) {
          final media = vehicle['media'] ?? {};
          final photoLinks = media['photo_links'] as List<dynamic>? ?? [];

          return {
            'make': vehicle['build']['make'],
            'model': vehicle['build']['model'],
            'year': vehicle['build']['year'],
            'image': photoLinks.isNotEmpty ? photoLinks.first : 'https://via.placeholder.com/150',
          };
        }).toList();

        return vehicles;
      } else {
        throw Exception('Failed to fetch vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }
}
