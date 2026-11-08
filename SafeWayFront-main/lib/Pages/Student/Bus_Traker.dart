import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeway/services/location_service.dart';
import 'package:safeway/services/map_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  MapThemeMode _mapTheme = MapThemeMode.dark;
  List<LatLng> _routePoints = [];

  LatLng? _busLocation;
  String _eta = 'Loading...';
  double _milesAway = 0;
  bool _isConnected = false;
  bool _refreshing = false;
  DateTime? _lastUpdated;

  // SafeWay Design System
  static const Color _backgroundTop = Color(0xFF050506);
  static const Color _backgroundMid = Color(0xFF0C0C0F);
  static const Color _backgroundBottom = Color(0xFF151518);

  static const Color _surface = Color(0xFF18181B);
  static const Color _surfaceLight = Color(0xFF202024);

  static const Color _primaryRed = Color(0xFFD32F2F);
  static const Color _brightRed = Color(0xFFEF4444);
  static const Color _darkRed = Color(0xFF991B1B);
  static const Color _burgundy = Color(0xFF65171B);

  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFB8B8BC);
  static const Color _textMuted = Color(0xFF77777D);

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
    if (manual) {
      setState(() => _refreshing = true);
    }

    final location = await LocationService.getStudentLocation();

    if (!mounted) return;

    if (location != null) {
      final newPos = LatLng(
        location['latitude']!,
        location['longitude']!,
      );

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

      final etaMins = (distanceMeters / 300).ceil();

      setState(() {
        _busLocation = newPos;
        _eta = etaMins <= 1 ? 'Arriving!' : '$etaMins min';
        _milesAway = distanceMiles;
        _isConnected = true;
        _lastUpdated = DateTime.now();
        _refreshing = false;
      });

      MapService.fetchStreetRoute(
        newPos,
        widget.myStop,
      ).then((pts) {
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

    final secondsAgo =
        DateTime.now().difference(_lastUpdated!).inSeconds;

    if (secondsAgo < 10) return 'Updated just now';
    if (secondsAgo < 60) return 'Updated ${secondsAgo}s ago';

    return 'Updated ${(secondsAgo / 60).floor()}m ago';
  }

  Future<void> _callDriver() async {
    final phone = widget.driverPhone;

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _surfaceLight,
          content: const Text(
            'Driver phone number is not available.',
            style: TextStyle(color: _textPrimary),
          ),
        ),
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _surfaceLight,
          content: const Text(
            'Could not start the call.',
            style: TextStyle(color: _textPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busLoc = _busLocation ?? widget.myStop;

    return Scaffold(
      backgroundColor: _backgroundTop,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _backgroundTop,
              _backgroundMid,
              _backgroundBottom,
            ],
            stops: [
              0.0,
              0.55,
              1.0,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient red glow
            Positioned(
              top: -100,
              right: -100,
              child: _redGlow(230),
            ),

            Positioned(
              bottom: 100,
              left: -130,
              child: _redGlow(250),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _buildMapCard(busLoc),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildJourneyCard(),
                    const SizedBox(height: 18),
                    _buildCallDriverButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _redGlow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _darkRed.withOpacity(0.18),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withOpacity(0.12),
            blurRadius: 100,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _roundIconButton(
          Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _brightRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'LIVE JOURNEY',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: _brightRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Track your bus',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.09),
              ),
            ),
            child: spinning
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _brightRed,
                    ),
                  )
                : Icon(
                    icon,
                    color: _textPrimary,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(LatLng busLoc) {
    final routePts = _routePoints.isEmpty
        ? [busLoc, widget.myStop]
        : _routePoints;

    return _glassContainer(
      padding: const EdgeInsets.all(10),
      radius: 26,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                SizedBox(
                  height: 320,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: busLoc,
                      initialZoom: 14.0,
                      interactionOptions:
                          const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            MapService.getTileUrl(_mapTheme),
                        subdomains: MapService.subdomains,
                        userAgentPackageName:
                            'com.example.safeway',
                        maxZoom: 19,
                      ),

                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePts,
                            strokeWidth: 9,
                            color:
                                _primaryRed.withOpacity(0.20),
                          ),
                          Polyline(
                            points: routePts,
                            strokeWidth: 4,
                            color: _primaryRed,
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
                              label: widget.pickupStopName,
                              isLive: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Live status
                Positioned(
                  left: 12,
                  top: 12,
                  child: _mapBadge(
                    icon: Icons.circle,
                    label: _isConnected
                        ? 'LIVE · $_eta'
                        : 'CONNECTING',
                    iconColor:
                        _isConnected ? _brightRed : Colors.orange,
                  ),
                ),

                // Map theme
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_mapTheme == MapThemeMode.voyager) {
                          _mapTheme = MapThemeMode.light;
                        } else if (_mapTheme ==
                            MapThemeMode.light) {
                          _mapTheme = MapThemeMode.dark;
                        } else {
                          _mapTheme = MapThemeMode.voyager;
                        }
                      });
                    },
                    child: _mapCircleButton(
                      _mapTheme == MapThemeMode.dark
                          ? Icons.dark_mode_rounded
                          : (_mapTheme ==
                                  MapThemeMode.light
                              ? Icons.light_mode_rounded
                              : Icons.map_rounded),
                    ),
                  ),
                ),

                // Bus number
                Positioned(
                  right: 62,
                  top: 12,
                  child: _smallMapLabel(
                    widget.busNumber,
                  ),
                ),

                // Pickup
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _smallMapLabel(
                    widget.pickupStopName,
                    icon: Icons.location_on_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                _pillBadge(
                  dotColor: _brightRed,
                  label: 'LIVE TRACKING',
                  bg: _burgundy.withOpacity(0.45),
                  textColor: _brightRed,
                ),
                Text(
                  _updatedLabel(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapBadge({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xDD101012),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 7,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapCircleButton(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xDD101012),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: _textPrimary,
      ),
    );
  }

  Widget _smallMapLabel(
    String text, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xDD101012),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: _brightRed,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dotColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: textColor ?? _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final onSchedule =
        _isConnected && _eta != 'Arriving!';

    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.timer_outlined,
            value: _eta == 'Loading...'
                ? '--'
                : _eta.replaceAll(' min', ''),
            unit: 'min',
            label: 'away',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.near_me_outlined,
            value: _milesAway.toStringAsFixed(1),
            unit: '',
            label: 'miles',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.schedule_rounded,
            value: onSchedule
                ? 'ON'
                : (_isConnected ? 'DUE' : '--'),
            unit: '',
            label: 'schedule',
            valueColor:
                onSchedule ? _brightRed : _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    Color? valueColor,
  }) {
    return _glassContainer(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      radius: 18,
      child: Column(
        children: [
          Icon(
            icon,
            size: 17,
            color: _primaryRed,
          ),

          const SizedBox(height: 8),

          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color:
                        valueColor ?? _textPrimary,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard() {
    return _glassContainer(
      padding: const EdgeInsets.all(19),
      radius: 23,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.busNumber} · ${widget.routeName}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your journey',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _darkRed,
                      _primaryRed,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _primaryRed.withOpacity(0.22),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Journey line
          Row(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: _brightRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          _brightRed.withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  height: 2,
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 2,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _brightRed,
                        _darkRed,
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: _surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _brightRed,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pickupStopName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pickup · ${widget.pickupTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.arrivalStopName,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Arrival · ${widget.arrivalTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
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
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _darkRed,
              _primaryRed,
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withOpacity(0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _callDriver,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 9),
              const Text(
                'Call Driver',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({
    required Widget child,
    required EdgeInsetsGeometry padding,
    required double radius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.085),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}