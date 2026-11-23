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
    List<String>? stationNames,
    int? stops,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (driverIds != null) body['driverIds'] = driverIds;
    if (driverNames != null) body['driverNames'] = driverNames;
    if (busNumber != null) body['busNumber'] = busNumber;
    if (driverName != null) body['driverName'] = driverName;
    if (stationNames != null) body['stationNames'] = stationNames;
    if (stops != null) body['stops'] = stops;

    // Send PATCH request for partial update
    http.Response res = await http.patch(
      Uri.parse('$baseUrl/routechangerequests/routes/$routeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    // If PATCH is not allowed by an older running server instance, fall back to PUT
    if (res.statusCode == 405 || res.statusCode == 404) {
      res = await http.put(
        Uri.parse('$baseUrl/routechangerequests/routes/$routeId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    }

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
    List<String>? stationNames,
    int? stops,
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
        'stationNames': ?stationNames,
        'stops': ?stops,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to add route (${res.statusCode}): ${res.body}');
    }
  }
}
