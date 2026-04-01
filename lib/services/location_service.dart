import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';

class LocationService {
  static String get baseUrl => apiBaseUrl;
  static Timer? _timer;
  static bool _isSharing = false;

  static bool get isSharing => _isSharing;

 // ── Student sends location every 5 seconds ──
static Future<void> startStudentSharing() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }
  if (permission == LocationPermission.deniedForever) return;

  _isSharing = true;
  await _sendStudentLocation();

  _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
    await _sendStudentLocation();
  });
}

static Future<void> _sendStudentLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await http.post(
      Uri.parse('$baseUrl/api/buslocation/student-update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude':  position.latitude,
        'longitude': position.longitude,
      }),
    );
    print('📍 Student location sent: ${position.latitude}, ${position.longitude}');
  } catch (e) {
    print('❌ Failed to send student location: $e');
  }
}

static Future<Map<String, double>?> getStudentLocation() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/buslocation/student-current'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'latitude':  data['latitude'],
        'longitude': data['longitude'],
      };
    }
  } catch (e) {
    print('❌ Failed to get student location: $e');
  }
  return null;
}
}