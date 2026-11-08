import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:safeway/Constant/Constant_Color.dart';

enum MapThemeMode { voyager, light, dark }

class MapService {
  // Free high-quality tiles that do NOT require any API key and have no watermark
  static const String voyager =
      'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  static const String osmStandard =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String esriDark =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';

  // Backwards compatibility aliases
  static const String cartoVoyager = voyager;
  static const String cartoLight = osmStandard;
  static const String cartoDark = esriDark;

  static const List<String> subdomains = ['a', 'b'];

  static String getTileUrl(MapThemeMode mode) {
    switch (mode) {
      case MapThemeMode.light:
        return osmStandard;
      case MapThemeMode.dark:
        return esriDark;
      case MapThemeMode.voyager:
        return voyager;
    }
  }

  /// Fetches real road coordinates following actual streets between start and end using OSRM engine.
  static Future<List<LatLng>> fetchStreetRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final coordinates = routes[0]['geometry']['coordinates'] as List?;
          if (coordinates != null && coordinates.isNotEmpty) {
            return coordinates.map<LatLng>((item) {
              final lng = (item[0] as num).toDouble();
              final lat = (item[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();
          }
        }
      }
    } catch (_) {
      // Return straight line as fallback if connection fails
    }
    return [start, end];
  }

  /// Custom Bus Live Marker Widget
  static Widget buildBusMarker({
    required String busCode,
    bool isLive = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLive ? AppColors.darkNavy : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (isLive ? AppColors.accentGreen : Colors.black).withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isLive ? AppColors.accentGreen : Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  busCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.darkNavy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                  )
                ],
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: AppColors.accentGreen,
                size: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Custom Student Marker Widget
  static Widget buildStudentMarker({
    required String label,
    bool isLive = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
              )
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }
}
