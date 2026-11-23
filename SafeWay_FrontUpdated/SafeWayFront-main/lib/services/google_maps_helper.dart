import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class StationStopInfo {
  String name;
  String mapUrl;
  double? latitude;
  double? longitude;

  StationStopInfo({
    required this.name,
    this.mapUrl = '',
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  LatLng? get latLng =>
      hasCoordinates ? LatLng(latitude!, longitude!) : null;

  Map<String, dynamic> toJson() => {
        'name': name,
        'mapUrl': mapUrl,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory StationStopInfo.fromJson(Map<String, dynamic> j) => StationStopInfo(
        name: (j['name'] ?? '').toString(),
        mapUrl: (j['mapUrl'] ?? '').toString(),
        latitude: j['latitude'] != null
            ? double.tryParse(j['latitude'].toString())
            : null,
        longitude: j['longitude'] != null
            ? double.tryParse(j['longitude'].toString())
            : null,
      );
}

class ParsedRouteData {
  final String? routeDirectionName;
  final StationStopInfo? beginStation;
  final List<StationStopInfo> stopStations;

  ParsedRouteData({
    this.routeDirectionName,
    this.beginStation,
    this.stopStations = const [],
  });

  int get totalStops =>
      (beginStation != null ? 1 : 0) + stopStations.length;
}

class GoogleMapsHelper {
  /// Generates a standard Google Maps search URL from coordinates
  static String generateGoogleMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  /// Cleans and formats station names extracted from URLs
  static String cleanStationName(String raw) {
    var decoded = Uri.decodeComponent(raw.replaceAll('+', ' ')).trim();
    // Remove query parameters or trailing coordinates if attached
    if (decoded.contains('?')) {
      decoded = decoded.split('?').first.trim();
    }
    // Remove @lat,lng coordinates if appended
    decoded = decoded.replaceAll(RegExp(r'@-?\d+\.\d+,-?\d+\.\d+.*'), '').trim();
    // Replace underscores or multiple dashes with spaces
    decoded = decoded.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return decoded;
  }

  /// Extracts coordinates from a string if present (e.g. "30.0444, 31.2357" or "@30.0444,31.2357")
  static LatLng? extractCoordinates(String input) {
    final atRegex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
    final atMatch = atRegex.firstMatch(input);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    final qRegex = RegExp(r'[?&](?:q|query|ll)=(-?\d+\.\d+),(-?\d+\.\d+)');
    final qMatch = qRegex.firstMatch(input);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    final rawRegex = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    final rawMatch = rawRegex.firstMatch(input);
    if (rawMatch != null) {
      final lat = double.tryParse(rawMatch.group(1)!);
      final lng = double.tryParse(rawMatch.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    return null;
  }

  /// Parses a Google Maps Direction / Route URL
  /// Supports:
  /// - https://www.google.com/maps/dir/Origin/WayPoint1/WayPoint2/Destination
  /// - https://www.google.com/maps/dir/30.0444,31.2357/31.2001,29.9187
  /// - https://www.google.com/maps/dir/?api=1&origin=...&destination=...&waypoints=...
  /// - https://maps.google.com/maps?saddr=...&daddr=...
  static ParsedRouteData parseGoogleMapsDirectionUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return ParsedRouteData();

    try {
      final uri = Uri.parse(trimmed);

      // Check query parameters (origin / destination / waypoints)
      final originParam = uri.queryParameters['origin'] ?? uri.queryParameters['saddr'];
      final destParam = uri.queryParameters['destination'] ?? uri.queryParameters['daddr'];
      final waypointsParam = uri.queryParameters['waypoints'];

      if (originParam != null || destParam != null) {
        StationStopInfo? beginStation;
        if (originParam != null) {
          final originCoords = extractCoordinates(originParam);
          final originName = cleanStationName(originParam);
          beginStation = StationStopInfo(
            name: originName.isNotEmpty ? originName : 'Start Station',
            mapUrl: originCoords != null
                ? generateGoogleMapsUrl(originCoords.latitude, originCoords.longitude)
                : trimmed,
            latitude: originCoords?.latitude,
            longitude: originCoords?.longitude,
          );
        }

        final stopStations = <StationStopInfo>[];

        if (waypointsParam != null && waypointsParam.isNotEmpty) {
          final parts = waypointsParam.split('|');
          for (final part in parts) {
            final partCoords = extractCoordinates(part);
            final partName = cleanStationName(part);
            stopStations.add(
              StationStopInfo(
                name: partName.isNotEmpty ? partName : 'Stop #${stopStations.length + 1}',
                mapUrl: partCoords != null
                    ? generateGoogleMapsUrl(partCoords.latitude, partCoords.longitude)
                    : '',
                latitude: partCoords?.latitude,
                longitude: partCoords?.longitude,
              ),
            );
          }
        }

        if (destParam != null) {
          final destCoords = extractCoordinates(destParam);
          final destName = cleanStationName(destParam);
          stopStations.add(
            StationStopInfo(
              name: destName.isNotEmpty ? destName : 'End Station',
              mapUrl: destCoords != null
                  ? generateGoogleMapsUrl(destCoords.latitude, destCoords.longitude)
                  : '',
              latitude: destCoords?.latitude,
              longitude: destCoords?.longitude,
            ),
          );
        }

        String? directionName;
        if (beginStation != null && stopStations.isNotEmpty) {
          directionName = '${beginStation.name} to ${stopStations.last.name}';
        }

        return ParsedRouteData(
          routeDirectionName: directionName,
          beginStation: beginStation,
          stopStations: stopStations,
        );
      }

      // Check path segments for /dir/...
      if (uri.path.contains('/dir/')) {
        final pathAfterDir = uri.path.substring(uri.path.indexOf('/dir/') + 5);
        final rawSegments = pathAfterDir.split('/').where((s) => s.trim().isNotEmpty).toList();

        // Filter out view parameters like @30.0444,31.2357,12z or data=...
        final stationSegments = rawSegments.where((s) {
          final decoded = Uri.decodeComponent(s);
          return !decoded.startsWith('@') && !decoded.startsWith('data=');
        }).toList();

        if (stationSegments.isNotEmpty) {
          // First segment is the Begin Station
          final originRaw = stationSegments[0];
          final originCoords = extractCoordinates(originRaw);
          var originName = cleanStationName(originRaw);
          if (originName.isEmpty || originCoords != null && RegExp(r'^[-0-9.,\s]+$').hasMatch(originName)) {
            originName = originCoords != null
                ? 'Begin Station (${originCoords.latitude.toStringAsFixed(4)}, ${originCoords.longitude.toStringAsFixed(4)})'
                : 'Begin Station';
          }

          final beginStation = StationStopInfo(
            name: originName,
            mapUrl: originCoords != null
                ? generateGoogleMapsUrl(originCoords.latitude, originCoords.longitude)
                : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(originName)}',
            latitude: originCoords?.latitude,
            longitude: originCoords?.longitude,
          );

          // Subsequent segments are the Stop Stations
          final stopStations = <StationStopInfo>[];
          for (int i = 1; i < stationSegments.length; i++) {
            final seg = stationSegments[i];
            final segCoords = extractCoordinates(seg);
            var segName = cleanStationName(seg);
            if (segName.isEmpty || segCoords != null && RegExp(r'^[-0-9.,\s]+$').hasMatch(segName)) {
              segName = segCoords != null
                  ? 'Stop #$i (${segCoords.latitude.toStringAsFixed(4)}, ${segCoords.longitude.toStringAsFixed(4)})'
                  : 'Stop #$i';
            }

            stopStations.add(
              StationStopInfo(
                name: segName,
                mapUrl: segCoords != null
                    ? generateGoogleMapsUrl(segCoords.latitude, segCoords.longitude)
                    : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(segName)}',
                latitude: segCoords?.latitude,
                longitude: segCoords?.longitude,
              ),
            );
          }

          String? directionName;
          if (stopStations.isNotEmpty) {
            directionName = '${beginStation.name} to ${stopStations.last.name}';
          } else {
            directionName = 'Route from ${beginStation.name}';
          }

          return ParsedRouteData(
            routeDirectionName: directionName,
            beginStation: beginStation,
            stopStations: stopStations,
          );
        }
      }
    } catch (_) {
      // Fallback
    }

    // If it's a single place or coordinates link, parse as Begin Station
    final single = parseLocationUrl(trimmed);
    if (single != null) {
      return ParsedRouteData(
        routeDirectionName: 'Route from ${single.name}',
        beginStation: single,
        stopStations: [],
      );
    }

    return ParsedRouteData();
  }

  /// Parses a single place, search, or coordinate URL / string
  static StationStopInfo? parseLocationUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final coords = extractCoordinates(trimmed);

    // Check if it has a place name in the URL: /place/Name/@lat,lng
    String name = '';
    if (trimmed.contains('/place/')) {
      final afterPlace = trimmed.substring(trimmed.indexOf('/place/') + 7);
      final rawName = afterPlace.split('/').first;
      name = cleanStationName(rawName);
    } else if (trimmed.contains('q=')) {
      final uri = Uri.tryParse(trimmed);
      final q = uri?.queryParameters['q'];
      if (q != null && !RegExp(r'^[-0-9.,\s]+$').hasMatch(q)) {
        name = cleanStationName(q);
      }
    }

    if (name.isEmpty) {
      if (coords != null) {
        name = 'Station (${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)})';
      } else {
        name = cleanStationName(trimmed);
      }
    }

    final url = coords != null
        ? generateGoogleMapsUrl(coords.latitude, coords.longitude)
        : (trimmed.startsWith('http') ? trimmed : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}');

    return StationStopInfo(
      name: name,
      mapUrl: url,
      latitude: coords?.latitude,
      longitude: coords?.longitude,
    );
  }

  /// Performs reverse geocoding via OpenStreetMap Nominatim
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'SafeWayBusTransportApp/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final road = addr['road'] ?? addr['pedestrian'] ?? addr['suburb'] ?? addr['neighbourhood'];
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['state'];
          if (road != null && city != null) {
            return '$road, $city';
          } else if (road != null) {
            return road.toString();
          } else if (city != null) {
            return city.toString();
          }
        }
        if (data['display_name'] != null) {
          final parts = (data['display_name'] as String).split(',');
          if (parts.length >= 2) {
            return '${parts[0].trim()}, ${parts[1].trim()}';
          }
          return parts.first.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Opens any URL in external browser or Google Maps app
  static Future<bool> openInGoogleMaps(String urlOrQuery) async {
    final trimmed = urlOrQuery.trim();
    if (trimmed.isEmpty) return false;

    Uri? uri;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      uri = Uri.tryParse(trimmed);
    } else {
      uri = Uri.tryParse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}');
    }

    if (uri != null && await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
