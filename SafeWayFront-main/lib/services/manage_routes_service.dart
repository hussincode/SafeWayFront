import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageRoutesService {
  // Backend port
  final String baseUrl = 'http://localhost:5143/api';

  Future<List<dynamic>> fetchRoutes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/routechangerequests/routes'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load routes (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<List<dynamic>> fetchStations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/routechangerequests/stations'),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load stations (${res.statusCode}): ${res.body}',
      );
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<List<dynamic>> fetchDrivers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/routechangerequests/drivers'),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load drivers (${res.statusCode}): ${res.body}',
      );
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<void> deleteRoute(int routeId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/routechangerequests/routes/$routeId'),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to delete route (${res.statusCode}): ${res.body}',
      );
    }
  }

  Future<void> updateRoute(
    int routeId, {
    String? name,
    List<int>? driverIds,
    List<String>? driverNames,
    String? busNumber,
    String? driverName,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/routechangerequests/routes/$routeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': ?name,
        'driverIds': ?driverIds,
        'driverNames': ?driverNames,
        'busNumber': ?busNumber,
        'driverName': ?driverName,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update route (${res.statusCode}): ${res.body}',
      );
    }
  }

  Future<void> addRoute({
    required String name,
    List<int>? driverIds,
    List<String>? driverNames,
    String? busNumber,
    String? driverName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/routechangerequests/routes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'driverIds': ?driverIds,
        'driverNames': ?driverNames,
        'busNumber': ?busNumber,
        'driverName': ?driverName,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to add route (${res.statusCode}): ${res.body}');
    }
  }
}
