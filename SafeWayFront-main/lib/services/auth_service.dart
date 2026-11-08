import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safeway/services/api_config.dart';

class AuthService {
  // For Android emulator: use http://10.0.2.2:5143
  // For iOS simulator or web: use http://localhost:5143
  // For a real device: use your PC IP address, e.g., http://192.168.100.46:5143
  // (Use the IP shown by `ipconfig` on the machine running the backend.)
  static String get baseUrl => apiBaseUrl;

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
        // After successful login, save ALL these:
await storage.write(key: 'token',    value: data['token']);
await storage.write(key: 'userId',   value: data['id'].toString()); // ← this must exist
await storage.write(key: 'fullName', value: data['fullName']);
await storage.write(key: 'uniqueID', value: data['uniqueID']);
await storage.write(key: 'role',     value: data['role']);

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