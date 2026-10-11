import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Test the connection by requesting the current user's information.
  static Future<void> testConnection() async {
    final url = Uri.parse('$baseUrl/user');

    try {
     final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      print('Status code: ${response.statusCode}');
      print('Response: ${response.body}');
    } catch (e) {
      print('Connection error: $e');
    }
  }
}
