import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageRoutesService {
  // Backend port
  final String baseUrl = 'http://localhost:5143/api';

  Future<List<dynamic>> fetchRoutes() async {
    final res = await http.get(Uri.parse('$baseUrl/routechangerequests/routes'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load routes (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<List<dynamic>> fetchStations() async {
    final res = await http.get(Uri.parse('$baseUrl/routechangerequests/stations'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load stations (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }
}

