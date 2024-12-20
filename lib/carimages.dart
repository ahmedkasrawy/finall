import 'dart:convert';
import 'package:http/http.dart' as http;

class CarDatabaseService {
  final String apiKey = '8470272097mshd80352d733c5881p1ab6d8jsn924f9a166d24';
  final String baseUrl = 'https://cars-database-with-image.p.rapidapi.com/api';

  // Fetch car model generations and variants based on generation_id
  Future<Map<String, dynamic>> fetchCarGenerations(String generationId) async {
    final url = Uri.parse('$baseUrl/models/generations/variants/$generationId');

    final headers = {
      'x-rapidapi-host': 'cars-database-with-image.p.rapidapi.com',
      'x-rapidapi-key': apiKey,
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Successful response
        return json.decode(response.body);
      } else {
        // Error response
        throw Exception('Failed to load car generations');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw e;  // Re-throw the error
    }
  }
}
