import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';
import 'package:safeway/services/map_service.dart';

class LiveBusTrackingScreen extends StatefulWidget {
  const LiveBusTrackingScreen({super.key});

  @override
  State<LiveBusTrackingScreen> createState() => _LiveBusTrackingScreenState();
}

class _LiveBusTrackingScreenState extends State<LiveBusTrackingScreen> {
  final MapController _mapController = MapController();

  // ── Map Theme ──
  MapThemeMode _mapTheme = MapThemeMode.voyager;
  List<LatLng> _routePoints = [];

  // ── Locations ──
  LatLng _busLocation     = const LatLng(30.0444, 31.2357); // Cairo default
  LatLng _studentLocation = const LatLng(30.0500, 31.2400); // Cairo default

  // ── Status ──
  bool   _busConnected     = false;
  bool   _studentConnected = false;
  String _eta              = 'Calculating...';
  String _distance         = '...';
  String _currentTime      = '';

  Timer? _refreshTimer;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _fetchLocations();

    // Clock every second
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1), (_) => _updateTime(),
    );

    // Fetch locations every 5 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5), (_) => _fetchLocations(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now    = DateTime.now();
    final hour   = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _currentTime = '$hour:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $period';
      });
    }
  }

  // ── Fetch both bus and student locations ──
  Future<void> _fetchLocations() async {
    await Future.wait([
      _fetchBusLocation(),
      _fetchStudentLocation(),
    ]);
    _calculateETA();
    _updateRoute();
  }

  Future<void> _updateRoute() async {
    final pts = await MapService.fetchStreetRoute(_busLocation, _studentLocation);
    if (mounted) {
      setState(() {
        _routePoints = pts;
      });
    }
  }

  Future<void> _fetchBusLocation() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/buslocation/current'),
      ).timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _busLocation  = LatLng(data['latitude'], data['longitude']);
          _busConnected = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _busConnected = false);
    }
  }

  Future<void> _fetchStudentLocation() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/buslocation/student-current'),
      ).timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _studentLocation  = LatLng(data['latitude'], data['longitude']);
          _studentConnected = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _studentConnected = false);
    }
  }

  void _calculateETA() {
    final distanceMeters = const Distance().as(
      LengthUnit.Meter,
      _busLocation,
      _studentLocation,
    );

    final distanceKm = distanceMeters / 1000;
    final etaMins    = (distanceMeters / 300).ceil(); // ~18 km/h

    if (mounted) {
      setState(() {
        _distance = '${distanceKm.toStringAsFixed(1)} km';
        _eta      = etaMins <= 1 ? 'Arriving!' : '$etaMins min';
      });
    }
  }

  // ── Center map to show both markers ──
  void _fitBothMarkers() {
    final centerLat = (_busLocation.latitude + _studentLocation.latitude) / 2;
    final centerLng = (_busLocation.longitude + _studentLocation.longitude) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 13.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          _buildStatusBar(),
          Expanded(child: _buildMap()),
          _buildBottomInfo(),
        ],
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 14, left: 16, right: 16,
      ),
      color: const Color(0xFF16A34A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Live Bus Tracking',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.access_time, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(_currentTime, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── STATUS BAR — Bus + Student connection status ──
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF15803D),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bus status
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: _busConnected ? Colors.greenAccent : Colors.orange,
                    shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              _busConnected ? '🚌 Bus — Live' : '🚌 Bus — Waiting...',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),

          // Student status
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: _studentConnected ? Colors.greenAccent : Colors.orange,
                    shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              _studentConnected ? '🎒 Student — Live' : '🎒 Student — Waiting...',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),
        ],
      ),
    );
  }

  // ── MAP ──
  Widget _buildMap() {
    final routePts = _routePoints.isEmpty ? [_busLocation, _studentLocation] : _routePoints;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _busLocation,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            // ✅ CartoDB HD Retina Tiles (Free, No API Key needed)
            TileLayer(
              urlTemplate: MapService.getTileUrl(_mapTheme),
              subdomains: MapService.subdomains,
              userAgentPackageName: 'com.example.safeway',
              maxZoom: 19,
            ),

            // Route line along actual streets
            PolylineLayer(polylines: [
              // Outer glow line
              Polyline(
                points: routePts,
                color: const Color(0xFF6366F1).withOpacity(0.3),
                strokeWidth: 8.0,
              ),
              // Main road polyline
              Polyline(
                points: routePts,
                color: const Color(0xFF4F46E5),
                strokeWidth: 4.0,
              ),
            ]),

            // Custom Markers
            MarkerLayer(markers: [
              // 🚌 Bus Marker
              Marker(
                point: _busLocation,
                width: 90,
                height: 70,
                child: MapService.buildBusMarker(
                  busCode: 'BUS-101',
                  isLive: _busConnected,
                ),
              ),

              // 🎒 Student Marker
              Marker(
                point: _studentLocation,
                width: 90,
                height: 70,
                child: MapService.buildStudentMarker(
                  label: 'Student',
                  isLive: _studentConnected,
                ),
              ),
            ]),
          ],
        ),

        // ── ETA Badge top right ──
        Positioned(
          top: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Estimated Arrival', style: TextStyle(color: Colors.white70, fontSize: 10)),
                Text(_eta, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        // ── Map controls top left (Fit Screen + Theme Switcher) ──
        Positioned(
          top: 16, left: 16,
          child: Row(
            children: [
              GestureDetector(
                onTap: _fitBothMarkers,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.fit_screen, color: Color(0xFF4F46E5), size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_mapTheme == MapThemeMode.voyager) {
                      _mapTheme = MapThemeMode.light;
                    } else if (_mapTheme == MapThemeMode.light) {
                      _mapTheme = MapThemeMode.dark;
                    } else {
                      _mapTheme = MapThemeMode.voyager;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                  ),
                  child: Icon(
                    _mapTheme == MapThemeMode.dark
                        ? Icons.dark_mode
                        : (_mapTheme == MapThemeMode.light ? Icons.light_mode : Icons.map_rounded),
                    color: const Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Zoom controls ──
        Positioned(
          bottom: 20, right: 16,
          child: Column(children: [
            _zoomBtn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
            const SizedBox(height: 8),
            _zoomBtn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
          ]),
        ),

        // ── No location warning ──
        if (!_busConnected && !_studentConnected)
          Positioned(
            bottom: 80, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.wifi_off, color: Color(0xFFEA580C), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Waiting for bus and student to share location...',
                  style: TextStyle(fontSize: 11, color: Color(0xFFEA580C)),
                )),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
      ),
    );
  }

  // ── BOTTOM INFO ──
  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _statBox('Distance', _distance, const Color(0xFFDCFCE7), const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(child: _statBox('ETA', _eta, const Color(0xFFEFF6FF), const Color(0xFF1D4ED8))),
            const SizedBox(width: 10),
            Expanded(child: _statBox(
              'Status',
              _busConnected ? 'Live' : 'Offline',
              _busConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              _busConnected ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            )),
          ]),
          const SizedBox(height: 10),

          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 10, height: 10,
                decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Bus', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(width: 16),
            Container(width: 10, height: 10,
                decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Student', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(width: 16),
            const Text('— Route Line', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ]),

          const SizedBox(height: 8),
          Text('Last updated: $_currentTime',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color bg, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
      ]),
    );
  }
}