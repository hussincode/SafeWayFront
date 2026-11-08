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

  // Get active routes (full data for ManageRoutes page)
  // (legacy) Get active routes
  Future<List<dynamic>> getRoutes() async {
    try {
      final routeBase = baseUrl.replaceFirst(
        '/api/admin',
        '/api/routechangerequests',
      );
      final response = await http.get(Uri.parse('$routeBase/routes'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception(
          'Failed to load routes (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // Get stations (full data for ManageRoutes page)
  Future<List<dynamic>> getStations() async {
    try {
      final routeBase = baseUrl.replaceFirst(
        '/api/admin',
        '/api/routechangerequests',
      );
      final response = await http.get(Uri.parse('$routeBase/stations'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception(
          'Failed to load stations (${response.statusCode}): ${response.body}',
        );
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

  // Get drivers (Admin -> Manage Drivers)
  Future<List<dynamic>> getDrivers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/drivers'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load drivers');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<void> addDriver({
    required String fullName,
    required String busNumber,
    required String phone,
    required String routeName,
  }) async {
    final payload = {
      'fullName': fullName,
      'busNumber': busNumber,
      'phone': phone,
      'routeName': routeName,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/drivers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      // surface backend JSON body (e.g. { message, error }) for better debugging
      throw Exception(
        'Failed to add driver (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Update driver (PUT)
  Future<void> updateDriver({
    required int id,
    required String fullName,
    required String busNumber,
    required String phone,
    required String routeName,
  }) async {
    final payload = {
      'fullName': fullName,
      'busNumber': busNumber,
      'phone': phone,
      'routeName': routeName,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/drivers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update driver (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Delete driver (DELETE)
  Future<void> deleteDriver({required int id}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/drivers/$id'),
      headers: const {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete driver (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Add student (POST)
  Future<void> addStudent({
    required String fullName,
    required String uniqueID,
    required String busNumber,
    required String routeName,
    required String grade,
  }) async {
    final payload = {
      'fullName': fullName,
      'uniqueID': uniqueID,
      'busNumber': busNumber,
      'routeName': routeName,
      'grade': grade,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/students'),
      headers: {
        'Content-Type': 'application/json',
        // Some ASP.NET setups require a user-agent; harmless otherwise.
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to add student (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Update student (PUT)
  Future<void> updateStudent({
    required int id,
    required String fullName,
    required String uniqueID,
    required String busNumber,
    required String routeName,
    required String grade,
    String? subscriptionStatus,
  }) async {
    final payload = {
      'id': id,
      'fullName': fullName,
      'uniqueID': uniqueID,
      'busNumber': busNumber,
      'routeName': routeName,
      'grade': grade,
      'subscriptionStatus': ?subscriptionStatus,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/students/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update student (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Delete student (DELETE)
  Future<void> deleteStudent({required int id}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/students/$id'),
      headers: const {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete student (${response.statusCode}): ${response.body}',
      );
    }
  }
}
