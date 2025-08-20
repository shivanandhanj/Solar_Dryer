import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictionService {
  static const String baseUrl = 'https://solar-dryer-model.onrender.com';
  static const String predictEndpoint = '/predict';

  static Future<Map<String, dynamic>> predictDryingTime({
    required String produceType,
    required String name,
    required double dryingTemperatureC,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$predictEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'produce_type': produceType,
          'name': name,
          'drying_temperature_C': dryingTemperatureC,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error making prediction: $e');
    }
  }
}