import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // change this to your PC IP address if testing on real phone
  // keep localhost if testing on emulator
  static const String baseUrl = 'http://192.168.100.2:5143';

  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String uniqueID, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uniqueID': uniqueID,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // save token and role to secure storage
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'role', value: data['role']);
        await storage.write(key: 'fullName', value: data['fullName']);
        await storage.write(key: 'uniqueID', value: data['uniqueID']);

        return {'success': true, 'role': data['role']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server.'};
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }
}