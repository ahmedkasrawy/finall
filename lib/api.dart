import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class CarSearchService {
  final String baseUrl = 'https://api.api-ninjas.com/v1/cars';
  final String apiKey = 'E6Aqk+ogaA/JgEVBtY2jvw==G9C3CajP3jRJiUfr'; // Replace with your API key

  /// Fetch cars by make
  Future<List<Map<String, dynamic>>> fetchCarsByMake(String make) async {
    final url = '$baseUrl?make=$make';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Api-Key': apiKey, // Add API key to headers
          'Accept': 'application/json',
        },
      );

      print('API Response: ${response.body}'); // Debugging log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isEmpty) {
          print('No data received from API'); // Debugging log
          return [];
        }

        List<Map<String, dynamic>> cars = List<Map<String, dynamic>>.from(data).map((car) {
          return {
            'make': car['make'],
            'model': car['model'],
            'year': car['year'],
            'price': car['price'] ?? 'N/A',
            'image': car['image'] ?? 'assets/default_image.png',
          };
        }).toList();

        // Log the cars fetched
        print('Fetched Cars: $cars'); // Debugging log

        final random = Random();
        List<Map<String, dynamic>> randomCars = [];
        for (int i = 0; i < 5; i++) {
          final randomIndex = random.nextInt(cars.length);
          randomCars.add(cars[randomIndex]);
        }

        return randomCars;
      } else {
        throw Exception('Failed to fetch cars: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cars: $e'); // Debugging log
      rethrow;
    }
  }
}
