import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminService {
  final String baseUrl = "http://localhost:5143/api/admin"; // Backend port

  // Get complete dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard-summary'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard summary');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // Get stats
  Future<List<dynamic>> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // Get buses
  Future<List<dynamic>> getBuses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/buses'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load buses');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // Get activities
  Future<List<dynamic>> getActivities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/activities'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load activities');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}
