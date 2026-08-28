import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';
import 'package:safeway/services/map_service.dart';
import 'package:safeway/Constant/Constant_Color.dart';

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
  LatLng _busLocation = const LatLng(30.0444, 31.2357); // Cairo default
  LatLng _studentLocation = const LatLng(30.0500, 31.2400); // Cairo default

  // ── Status ──
  bool _busConnected = false;
  bool _studentConnected = false;
  bool _refreshing = false;
  String _eta = 'Calculating...';
  String _distance = '...';
  DateTime? _lastUpdated;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchLocations();

    // Fetch locations every 5 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchLocations(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Fetch both bus and student locations ──
  Future<void> _fetchLocations({bool manual = false}) async {
    if (manual) setState(() => _refreshing = true);

    await Future.wait([_fetchBusLocation(), _fetchStudentLocation()]);
    _calculateETA();
    _updateRoute();

    if (mounted) {
      setState(() {
        _lastUpdated = DateTime.now();
        _refreshing = false;
      });
    }
  }

  Future<void> _updateRoute() async {
    final pts = await MapService.fetchStreetRoute(
      _busLocation,
      _studentLocation,
    );
    if (mounted) {
      setState(() {
        _routePoints = pts;
      });
    }
  }

  Future<void> _fetchBusLocation() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/buslocation/current'))
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _busLocation = LatLng(data['latitude'], data['longitude']);
          _busConnected = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _busConnected = false);
    }
  }

  Future<void> _fetchStudentLocation() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/buslocation/student-current'))
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _studentLocation = LatLng(data['latitude'], data['longitude']);
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
    final etaMins = (distanceMeters / 300).ceil(); // ~18 km/h

    if (mounted) {
      setState(() {
        _distance = '${distanceKm.toStringAsFixed(1)} km';
        _eta = etaMins <= 1 ? 'Arriving!' : '$etaMins min';
      });
    }
  }

  // ── Center map to show both markers ──
  void _fitBothMarkers() {
    final centerLat = (_busLocation.latitude + _studentLocation.latitude) / 2;
    final centerLng = (_busLocation.longitude + _studentLocation.longitude) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 13.0);
  }

  void _cycleTheme() {
    setState(() {
      if (_mapTheme == MapThemeMode.voyager) {
        _mapTheme = MapThemeMode.light;
      } else if (_mapTheme == MapThemeMode.light) {
        _mapTheme = MapThemeMode.dark;
      } else {
        _mapTheme = MapThemeMode.voyager;
      }
    });
  }

  String _updatedLabel() {
    if (_lastUpdated == null) return 'Not yet updated';
    final secondsAgo = DateTime.now().difference(_lastUpdated!).inSeconds;
    if (secondsAgo < 10) return 'Updated just now';
    if (secondsAgo < 60) return 'Updated ${secondsAgo}s ago';
    return 'Updated ${(secondsAgo / 60).floor()}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.softBackground),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _buildHeader(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatusPills(),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildMapCard()),
              _buildBottomInfo(),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _roundIconButton(Icons.arrow_back, onTap: () => Navigator.pop(context)),
        Expanded(
          child: Column(
            children: [
              const Text(
                'LIVE TRACKING',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Live Bus Tracking',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        _roundIconButton(
          Icons.refresh_rounded,
          onTap: () => _fetchLocations(manual: true),
          spinning: _refreshing,
        ),
      ],
    );
  }

  Widget _roundIconButton(
    IconData icon, {
    required VoidCallback onTap,
    bool spinning = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: spinning
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentGreen,
                ),
              )
            : Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  // ── STATUS PILLS — Bus + Student connection status ──
  Widget _buildStatusPills() {
    return Row(
      children: [
        Expanded(
          child: _pillBadge(
            dotColor: _busConnected ? AppColors.accentGreen : Colors.orange,
            label: _busConnected ? '🚌 Bus · Live' : '🚌 Bus · Waiting',
            bg: AppColors.cardBg,
            center: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pillBadge(
            dotColor: _studentConnected ? AppColors.accentGreen : Colors.orange,
            label: _studentConnected
                ? '🎒 Student · Live'
                : '🎒 Student · Waiting',
            bg: AppColors.cardBg,
            center: true,
          ),
        ),
      ],
    );
  }

  Widget _pillBadge({
    required Color dotColor,
    required String label,
    required Color bg,
    Color? textColor,
    bool center = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── MAP CARD ──
  Widget _buildMapCard() {
    final routePts = _routePoints.isEmpty
        ? [_busLocation, _studentLocation]
        : _routePoints;
    final bothLive = _busConnected && _studentConnected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              SizedBox.expand(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _busLocation,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapService.getTileUrl(_mapTheme),
                      subdomains: MapService.subdomains,
                      userAgentPackageName: 'com.example.safeway',
                      maxZoom: 19,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePts,
                          strokeWidth: 7.0,
                          color: AppColors.accentGreen.withOpacity(0.3),
                        ),
                        Polyline(
                          points: routePts,
                          strokeWidth: 3.5,
                          color: AppColors.accentGreen,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _busLocation,
                          width: 90,
                          height: 70,
                          child: MapService.buildBusMarker(
                            busCode: 'BUS-101',
                            isLive: _busConnected,
                          ),
                        ),
                        Marker(
                          point: _studentLocation,
                          width: 90,
                          height: 70,
                          child: MapService.buildStudentMarker(
                            label: 'Student',
                            isLive: _studentConnected,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Live/ETA badge top-left ──
              Positioned(
                left: 10,
                top: 10,
                child: _pillBadge(
                  dotColor: bothLive ? AppColors.accentGreen : Colors.orange,
                  label: bothLive ? 'LIVE · $_eta' : 'CONNECTING',
                  bg: Colors.white.withOpacity(0.92),
                ),
              ),

              // ── Theme toggle top-right ──
              Positioned(
                right: 10,
                top: 10,
                child: _circleIconButton(
                  icon: _mapTheme == MapThemeMode.dark
                      ? Icons.dark_mode
                      : (_mapTheme == MapThemeMode.light
                            ? Icons.light_mode
                            : Icons.map_rounded),
                  onTap: _cycleTheme,
                ),
              ),

              // ── Fit-to-screen below theme toggle ──
              Positioned(
                right: 10,
                top: 52,
                child: _circleIconButton(
                  icon: Icons.fit_screen,
                  onTap: _fitBothMarkers,
                ),
              ),

              // ── Zoom controls bottom-right ──
              Positioned(
                bottom: 10,
                right: 10,
                child: Column(
                  children: [
                    _circleIconButton(
                      icon: Icons.add,
                      onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _circleIconButton(
                      icon: Icons.remove,
                      onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      ),
                    ),
                  ],
                ),
              ),

              // ── ETA/distance label bottom-left ──
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _distance,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // ── No location warning ──
              if (!_busConnected && !_studentConnected)
                Positioned(
                  bottom: 60,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Waiting for bus and student to share location...',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.darkNavy),
      ),
    );
  }

  // ── BOTTOM INFO ──
  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    value: _distance.replaceAll(' km', ''),
                    unit: 'km',
                    label: 'distance',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    value: _eta.replaceAll(' min', ''),
                    unit: _eta.contains('min') ? 'min' : '',
                    label: 'eta',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    value: _busConnected ? 'LIVE' : 'OFF',
                    unit: '',
                    label: 'bus status',
                    valueColor: _busConnected
                        ? AppColors.accentGreen
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Bus',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.accentGreen, width: 2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Student',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(width: 16),
                const Text(
                  '— Route',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pillBadge(
                  dotColor: AppColors.accentGreen,
                  label: 'LIVE TRACKING',
                  bg: AppColors.badgeBg,
                  textColor: AppColors.darkNavy,
                ),
                const SizedBox(width: 10),
                Text(
                  _updatedLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required String value,
    required String unit,
    required String label,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
