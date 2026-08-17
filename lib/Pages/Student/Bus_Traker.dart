import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeway/Constant/Constant_Color.dart';
import 'package:safeway/services/location_service.dart';
import 'package:safeway/services/map_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class TrackBusScreen extends StatefulWidget {
  final String busNumber;
  final String routeName;
  final LatLng myStop;
  final String pickupStopName;
  final String pickupTime;
  final String arrivalStopName;
  final String arrivalTime;
  final String? driverPhone;
  final Widget? bottomNavigationBar;

  const TrackBusScreen({
    super.key,
    required this.busNumber,
    required this.routeName,
    required this.myStop,
    required this.pickupStopName,
    required this.pickupTime,
    required this.arrivalStopName,
    required this.arrivalTime,
    this.driverPhone,
    this.bottomNavigationBar,
  });

  @override
  State<TrackBusScreen> createState() => _TrackBusScreenState();
}

class _TrackBusScreenState extends State<TrackBusScreen> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;

  MapThemeMode _mapTheme = MapThemeMode.voyager;
  List<LatLng> _routePoints = [];

  LatLng? _busLocation;
  String _eta = 'Loading...';
  double _milesAway = 0;
  bool _isConnected = false;
  bool _refreshing = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchLocation(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation({bool manual = false}) async {
    if (manual) setState(() => _refreshing = true);

    final location = await LocationService.getStudentLocation();
    if (!mounted) return;

    if (location != null) {
      final newPos = LatLng(location['latitude']!, location['longitude']!);
      final distanceMeters = const Distance().as(
        LengthUnit.Meter,
        newPos,
        widget.myStop,
      );
      final distanceMiles = const Distance().as(
        LengthUnit.Mile,
        newPos,
        widget.myStop,
      );
      final etaMins = (distanceMeters / 300).ceil(); // ~18 km/h

      setState(() {
        _busLocation = newPos;
        _eta = etaMins <= 1 ? 'Arriving!' : '$etaMins min';
        _milesAway = distanceMiles;
        _isConnected = true;
        _lastUpdated = DateTime.now();
        _refreshing = false;
      });

      MapService.fetchStreetRoute(newPos, widget.myStop).then((pts) {
        if (mounted) {
          setState(() {
            _routePoints = pts;
          });
        }
      });
    } else {
      setState(() {
        _isConnected = false;
        _refreshing = false;
      });
    }
  }

  String _updatedLabel() {
    if (_lastUpdated == null) return 'Not yet updated';
    final secondsAgo = DateTime.now().difference(_lastUpdated!).inSeconds;
    if (secondsAgo < 10) return 'Updated just now';
    if (secondsAgo < 60) return 'Updated ${secondsAgo}s ago';
    return 'Updated ${(secondsAgo / 60).floor()}m ago';
  }

  Future<void> _callDriver() async {
    final phone = widget.driverPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number is not available.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start the call.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busLoc = _busLocation ?? widget.myStop;

    return Scaffold(
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.softBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildMapCard(busLoc),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                _buildJourneyCard(),
                const SizedBox(height: 16),
                _buildCallDriverButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _roundIconButton(Icons.arrow_back, onTap: () => Navigator.pop(context)),
        Expanded(
          child: Column(
            children: [
              const Text(
                'LIVE JOURNEY',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Track your bus',
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
          onTap: () => _fetchLocation(manual: true),
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

  Widget _buildMapCard(LatLng busLoc) {
    final routePts = _routePoints.isEmpty
        ? [busLoc, widget.myStop]
        : _routePoints;

    return Container(
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
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                SizedBox(
                  height: 320,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: busLoc,
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // CartoDB HD Retina Tiles
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
                            point: busLoc,
                            width: 90,
                            height: 70,
                            child: MapService.buildBusMarker(
                              busCode: widget.busNumber,
                              isLive: _isConnected,
                            ),
                          ),
                          Marker(
                            point: widget.myStop,
                            width: 90,
                            height: 70,
                            child: MapService.buildStudentMarker(
                              label: widget.pickupStopName.isNotEmpty
                                  ? widget.pickupStopName
                                  : widget.pickupStopName,
                              isLive: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _pillBadge(
                    dotColor: _isConnected
                        ? AppColors.accentGreen
                        : Colors.orange,
                    label: _isConnected ? 'LIVE · $_eta' : 'CONNECTING',
                    bg: Colors.white.withOpacity(0.92),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: GestureDetector(
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        _mapTheme == MapThemeMode.dark
                            ? Icons.dark_mode
                            : (_mapTheme == MapThemeMode.light
                                  ? Icons.light_mode
                                  : Icons.map_rounded),
                        size: 18,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 52,
                  top: 10,
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
                      widget.busNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
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
                      widget.pickupStopName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pillBadge(
                  dotColor: AppColors.accentGreen,
                  label: 'LIVE TRACKING',
                  bg: AppColors.badgeDot,
                  textColor: AppColors.divider,
                ),
                Text(
                  _updatedLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge({
    required Color dotColor,
    required String label,
    required Color bg,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final onSchedule = _isConnected && _eta != 'Arriving!';
    return Row(
      children: [
        Expanded(
          child: _statTile(
            value: _eta == 'Loading...' ? '--' : _eta.replaceAll(' min', ''),
            unit: 'min',
            label: 'away',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            value: _milesAway.toStringAsFixed(1),
            unit: '',
            label: 'miles',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            value: onSchedule ? 'ON' : (_isConnected ? 'DUE' : '--'),
            unit: '',
            label: 'schedule',
            valueColor: onSchedule
                ? AppColors.accentGreen
                : AppColors.textPrimary,
          ),
        ),
      ],
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
        color: AppColors.cardBg,
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
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJourneyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.busNumber} · ${widget.routeName}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Your journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.accentGreen,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(height: 2, color: AppColors.accentGreen),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.accentGreen, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pickupStopName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pickup · ${widget.pickupTime}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.arrivalStopName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Arrival · ${widget.arrivalTime}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallDriverButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _callDriver,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.cardBg),
          ),
        ),
        child: const Text(
          'Call Driver',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
      ),
    );
  }
}
