import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
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

  List<LatLng> _routePoints = [];

  static const _background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070708), Color(0xFF101012), Color(0xFF18181B)],
  );
  static const _red = Color(0xFFD32F2F);
  static const _lightRed = Color(0xFFEF4444);
  static const _darkRed = Color(0xFF991B1B);
  static const _burgundy = Color(0xFF65171B);
  static const _primaryText = Color(0xFFF5F5F5);
  static const _secondaryText = Color(0xFFB8B8BC);
  static const _mutedText = Color(0xFF77777D);

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
      backgroundColor: const Color(0xFF070708),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _background),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -120,
                right: -100,
                child: _AmbientGlow(color: _darkRed, size: 280),
              ),
              const Positioned(
                top: 190,
                left: -150,
                child: _AmbientGlow(color: _burgundy, size: 260),
              ),
              const Positioned(
                bottom: -160,
                right: -100,
                child: _AmbientGlow(color: _darkRed, size: 300),
              ),
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 52,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 26),
                        _buildIntro(),
                        const SizedBox(height: 22),
                        _buildStatusPills(),
                        const SizedBox(height: 14),
                        _buildMapCard(),
                        const SizedBox(height: 14),
                        _buildBottomInfo(),
                      ],
                    ),
                  ),
                ),
              ),
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
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_red, _darkRed]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: _red.withOpacity(0.28), blurRadius: 18),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SafeWay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
              Text(
                'SMART SCHOOL BUS',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),
        _glassPill(
          label: 'LIVE NETWORK',
          dotColor: _lightRed,
          textColor: _lightRed,
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE BUS TRACKING',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: _lightRed,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Move together\nArrive safer.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'One calm place for every school day journey.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 86,
          height: 62,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: _red.withOpacity(0.35), blurRadius: 28),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: _lightRed,
            size: 62,
          ),
        ),
      ],
    );
  }

  // ── STATUS PILLS — Bus + Student connection status ──
  Widget _buildStatusPills() {
    return Row(
      children: [
        Expanded(
          child: _pillBadge(
            dotColor: _busConnected ? _lightRed : _mutedText,
            label: _busConnected ? 'BUS · LIVE' : 'BUS · WAITING',
            bg: const Color(0x14141416),
            center: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pillBadge(
            dotColor: _studentConnected ? _lightRed : _mutedText,
            label: _studentConnected ? 'STUDENT · LIVE' : 'STUDENT · WAITING',
            bg: const Color(0x14141416),
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
        border: Border.all(color: const Color(0x2AFFFFFF)),
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
              color: textColor ?? _secondaryText,
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
          color: const Color(0x14141416),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x2AFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Stack(
              children: [
                SizedBox(
                  height: 340,
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
                        urlTemplate: MapService.getTileUrl(MapThemeMode.dark),
                        subdomains: MapService.subdomains,
                        userAgentPackageName: 'com.example.safeway',
                        maxZoom: 19,
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePts,
                            strokeWidth: 7.0,
                            color: _darkRed.withOpacity(0.45),
                          ),
                          Polyline(
                            points: routePts,
                            strokeWidth: 3.5,
                            color: _lightRed,
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
                    dotColor: bothLive ? _lightRed : _mutedText,
                    label: bothLive ? 'LIVE · $_eta' : 'CONNECTING',
                    bg: const Color(0xE6101012),
                    textColor: _primaryText,
                  ),
                ),

                // ── Refresh control top-right ──
                Positioned(
                  right: 10,
                  top: 10,
                  child: _circleIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: () => _fetchLocations(manual: true),
                    spinning: _refreshing,
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
                      color: const Color(0xE6101012),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x2AFFFFFF)),
                    ),
                    child: Text(
                      _distance,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
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
                        color: const Color(0xF2101012),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _darkRed.withOpacity(0.8)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: _lightRed, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Waiting for bus and student to share location...',
                              style: TextStyle(
                                fontSize: 11,
                                color: _secondaryText,
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
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool spinning = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xE6101012),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x2AFFFFFF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
          ],
        ),
        child: spinning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: _lightRed,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: 18, color: _primaryText),
      ),
    );
  }

  Widget _glassPill({
    required String label,
    required Color dotColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x14141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2AFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              fontSize: 9,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
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
          color: const Color(0x14141416),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x2AFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 22,
              offset: const Offset(0, 8),
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
                    valueColor: _busConnected ? _lightRed : _mutedText,
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
                    color: _lightRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Bus',
                  style: TextStyle(fontSize: 11, color: _mutedText),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryText,
                    border: Border.all(color: _lightRed, width: 2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Student',
                  style: TextStyle(fontSize: 11, color: _mutedText),
                ),
                const SizedBox(width: 16),
                const Text(
                  '— Route',
                  style: TextStyle(fontSize: 11, color: _mutedText),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pillBadge(
                  dotColor: _lightRed,
                  label: 'LIVE TRACKING',
                  bg: const Color(0x331F0A0C),
                  textColor: _lightRed,
                ),
                const SizedBox(width: 10),
                Text(
                  _updatedLabel(),
                  style: const TextStyle(fontSize: 12, color: _mutedText),
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
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x2AFFFFFF)),
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
                    color: valueColor ?? _primaryText,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _secondaryText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: _mutedText)),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.24), color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}
