import 'dart:convert';
import 'package:http/http.dart' as http;

class CarSearchService {
  final String baseUrl = 'https://mc-api.marketcheck.com/v2/';
  final String apiKey = 'VxQPRGvbK2nDBGwcj9mxBeOTM1nZuNcc';

  /// Fetch vehicles by make and model
  Future<List<Map<String, dynamic>>> fetchVehiclesByMakeAndModel(String make, String model) async {
    final url = Uri.parse(
        '$baseUrl/search/car/active?api_key=$apiKey&make=$make&model=$model&rows=10');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final listings = data['listings'] as List;

        // Extract vehicle data and ensure fallback image is applied consistently
        List<Map<String, dynamic>> vehicles = listings.map((vehicle) {
          final media = vehicle['media'] ?? {};
          final photoLinks = media['photo_links'] as List<dynamic>? ?? [];

          // Apply the fallback image if no valid image is found
          return {
            'make': vehicle['build']['make'] ?? 'Unknown Make',
            'model': vehicle['build']['model'] ?? 'Unknown Model',
            'year': vehicle['build']['year'] ?? 'Unknown Year',
            'image': (photoLinks.isNotEmpty && photoLinks.first.toString().isNotEmpty)
                ? photoLinks.first
                : 'assets/kisooo.png',
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
