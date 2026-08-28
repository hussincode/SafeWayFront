import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';

class LocationService {
  static String get baseUrl => apiBaseUrl;
  static Timer? _timer;
  static Timer? _driverTimer;
  static bool _isSharing = false;
  static bool _isDriverSharing = false;

  static bool get isSharing => _isSharing;
  static bool get isDriverSharing => _isDriverSharing;

  // ══════════════════════════════════════════════════════════════════════════
  //  DRIVER — sends GPS to POST /api/buslocation/update every 10 seconds
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> startDriverSharing() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _isDriverSharing = true;
    await _sendDriverLocation();

    _driverTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _sendDriverLocation();
    });
  }

  static Future<void> _sendDriverLocation() async {
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
      print('🚌 Driver location sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Failed to send driver location: $e');
    }
  }

  static void stopDriverSharing() {
    _driverTimer?.cancel();
    _driverTimer = null;
    _isDriverSharing = false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUS LOCATION — fetches driver position from GET /api/buslocation/current
  //  Used by Student & Parent to track the bus on the map.
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, double>?> getBusLocation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/buslocation/current'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'latitude': (data['latitude'] as num).toDouble(),
          'longitude': (data['longitude'] as num).toDouble(),
        };
      }
    } catch (e) {
      print('❌ Failed to get bus location: $e');
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STUDENT — sends GPS every 15 seconds, parent fetches it
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> startStudentSharing() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _isSharing = true;
    await _sendStudentLocation();

    _timer = Timer.periodic(const Duration(seconds: 15), (_) async {
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
          'latitude': position.latitude,
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
          'latitude': (data['latitude'] as num).toDouble(),
          'longitude': (data['longitude'] as num).toDouble(),
        };
      }
    } catch (e) {
      print('❌ Failed to get student location: $e');
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Stop all sharing
  // ══════════════════════════════════════════════════════════════════════════

  static void stopAllSharing() {
    _timer?.cancel();
    _timer = null;
    _isSharing = false;
    stopDriverSharing();
  }
}