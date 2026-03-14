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

  // ── Start sending location every 5 seconds ──
  static Future<void> startSharing() async {
    // 1. Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _isSharing = true;

    // 2. Send immediately once
    await _sendLocation();

    // 3. Then every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _sendLocation();
    });
  }

  // ── Stop sending ──
  static void stopSharing() {
    _timer?.cancel();
    _timer = null;
    _isSharing = false;
  }

  // ── Get current position and POST to API ──
  static Future<void> _sendLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await http.post(
        Uri.parse('$baseUrl/api/buslocation/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      print('📍 Location sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Failed to send location: $e');
    }
  }

  // ── Get bus location (for student/parent) ──
  static Future<Map<String, double>?> getBusLocation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/buslocation/current'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      }
    } catch (e) {
      print('❌ Failed to get location: $e');
    }
    return null;
  }
}