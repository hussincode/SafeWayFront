import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';
import 'package:safeway/services/location_service.dart';
import 'package:safeway/services/map_service.dart';
import 'package:safeway/Pages/Student/change_pickup_station_screen.dart';
import 'package:safeway/Pages/login_page.dart';
import 'package:safeway/Pages/Student/Request_Route_Change.dart';
import 'package:safeway/Pages/Student/Bus_Traker.dart';
import 'package:safeway/Pages/Student/Alerts_Page.dart';
import 'package:safeway/Pages/Student/Profile_Page.dart';

// ── Palette (matches the mockup) ──
class _Palette {
  static const bg = Color(0xFFF3F4F0);
  static const card = Color(0xFFFFFFFF);
  static const dark = Color(0xFF12181F);
  static const green = Color(0xFF1F6F54);
  static const greenBg = Color(0xFFBFE8D4);
  static const textPrimary = Color(0xFF14181C);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5E7EB);
  static const avatar = Color(0xFFD98B72);
  static const orange = Color(0xFFE8734F);
  static const orangeBg = Color(0xFFFBDCD1);
}

// ── Models ──
class SubscriptionModel {
  final String status;
  final String startDate;
  final String endDate;
  SubscriptionModel({
    required this.status,
    required this.startDate,
    required this.endDate,
  });
  factory SubscriptionModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionModel(
        status: j['status'],
        startDate: j['startDate'],
        endDate: j['endDate'],
      );
}

class StudentInfoModel {
  final String fullName;
  final String uniqueID;
  final String grade;
  final String busNumber;
  final String driverName;
  final String routeName;
  final String stopName;
  StudentInfoModel({
    required this.fullName,
    required this.uniqueID,
    required this.grade,
    required this.busNumber,
    required this.driverName,
    required this.routeName,
    required this.stopName,
  });
  factory StudentInfoModel.fromJson(Map<String, dynamic> j) => StudentInfoModel(
    fullName: j['fullName'] ?? '',
    uniqueID: j['uniqueID'] ?? '',
    grade: j['grade'] ?? '',
    busNumber: j['busNumber'] ?? 'Not assigned',
    driverName: j['driverName'] ?? 'Not assigned',
    routeName: j['routeName'] ?? 'Not assigned',
    stopName: j['stopName'] ?? 'Not assigned',
  );
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});
  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _storage = const FlutterSecureStorage();

  // ── User ──
  int _userId = 0;
  StudentInfoModel? _studentInfo;
  bool _infoLoading = true;

  // ── Bus tracking ──
  LatLng _busLocation = const LatLng(24.7136, 46.6753);
  final LatLng _myStop = const LatLng(24.7200, 46.6800);
  List<LatLng> _routePoints = [];
  String _eta = 'Loading...';
  bool _isConnected = false;
  Timer? _refreshTimer;
  final MapController _mapController = MapController();

  // ── Subscription ──
  SubscriptionModel? _subscription;
  bool _subscriptionLoading = true;

  // ── Bottom nav (visual only for the tabs without a screen yet) ──
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Start sharing student location to API
    LocationService.startStudentSharing();

    final userIdStr = await _storage.read(key: 'userId') ?? '0';
    final fullName = await _storage.read(key: 'fullName') ?? '';
    final uniqueID = await _storage.read(key: 'uniqueID') ?? '';

    print('🔑 userId from storage: $userIdStr');
    print('🔑 fullName from storage: $fullName');
    print('🔑 uniqueID from storage: $uniqueID');

    _userId = int.tryParse(userIdStr) ?? 0;

    if (_userId == 0) {
      print('⚠️ userId is 0 — login did not save userId correctly!');
      setState(() {
        _infoLoading = false;
        _subscriptionLoading = false;
      });
      return;
    }

    await Future.wait([_loadStudentInfo(), _loadSubscription()]);

    _fetchBusLocation();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchBusLocation(),
    );
  }

  // ── Load student info (name, bus, driver, route, stop) ──
  Future<void> _loadStudentInfo() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/student-info/$_userId'),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final info = StudentInfoModel.fromJson(jsonDecode(res.body));
        setState(() {
          _studentInfo = info;
          _infoLoading = false;
        });
      } else {
        setState(() => _infoLoading = false);
      }
    } catch (e) {
      print('StudentInfo error: $e');
      if (mounted) setState(() => _infoLoading = false);
    }
  }

  // ── Load subscription ──
  Future<void> _loadSubscription() async {
    if (_userId == 0) {
      setState(() => _subscriptionLoading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/subscription/student/$_userId'),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _subscription = SubscriptionModel.fromJson(jsonDecode(res.body));
          _subscriptionLoading = false;
        });
      } else {
        setState(() => _subscriptionLoading = false);
      }
    } catch (e) {
      print('Subscription error: $e');
      if (mounted) setState(() => _subscriptionLoading = false);
    }
  }

  // ── Fetch live bus location ──
  Future<void> _fetchBusLocation() async {
    final location = await LocationService.getStudentLocation();
    if (!mounted) return;

    if (location != null) {
      final newPos = LatLng(location['latitude']!, location['longitude']!);
      final distance = const Distance().as(LengthUnit.Meter, newPos, _myStop);
      final etaMins = (distance / 300).ceil(); // ~18 km/h speed

      setState(() {
        _busLocation = newPos;
        _eta = etaMins <= 1 ? 'Arriving!' : '$etaMins min';
        _isConnected = true;
      });

      MapService.fetchStreetRoute(newPos, _myStop).then((pts) {
        if (mounted) {
          setState(() {
            _routePoints = pts;
          });
        }
      });
    } else {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  String _greetingLabel() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  String _greetingSubtitle() {
    if (!_isConnected) return 'Waiting for your bus to start sharing location.';
    if (_eta == 'Arriving!') return 'Your bus is arriving now!';
    return 'Your bus is right on schedule.';
  }

  String _firstName() {
    final full = _studentInfo?.fullName ?? '';
    if (full.isEmpty) return 'there';
    return full.split(' ').first;
  }

  String _initials() {
    final full = _studentInfo?.fullName ?? '';
    if (full.trim().isEmpty) return '?';
    final parts = full.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  List<String> _activeAlerts() {
    final alerts = <String>[];
    if (!_isConnected) {
      alerts.add('Waiting for the driver to start sharing location.');
    }
    if (_subscription != null) {
      if (_subscription!.status == 'UNPAID') {
        alerts.add(
          'Your subscription is unpaid. Contact your parent or school admin.',
        );
      } else if (_subscription!.status == 'EXPIRED') {
        alerts.add(
          'Your subscription has expired. Please renew with your school admin.',
        );
      }
    }
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTab == 1) {
      return TrackBusScreen(
        busNumber: 'Bus #${_studentInfo?.busNumber ?? '101'}',
        routeName: _studentInfo?.routeName ?? 'Morning Route',
        myStop: _myStop,
        pickupStopName: _studentInfo?.stopName ?? 'Your Stop',
        pickupTime: '7:40 AM',
        arrivalStopName: 'Main Campus',
        arrivalTime: '8:15 AM',
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    if (_selectedTab == 2) {
      return AlertsPage(
        showBottomNav: true,
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    if (_selectedTab == 3) {
      return ProfilePage(
        fullName: _studentInfo?.fullName ?? '',
        uniqueID: _studentInfo?.uniqueID ?? '',
        grade: _studentInfo?.grade ?? '',
        busNumber: _studentInfo?.busNumber ?? '',
        routeName: _studentInfo?.routeName ?? '',
        stopName: _studentInfo?.stopName ?? '',
        onLogout: _logout,
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _sectionLabel('YOUR NEXT TRIP'),
              const SizedBox(height: 8),
              _buildLiveTrackerCard(),
              const SizedBox(height: 28),
              _sectionLabel('YOUR ROUTE'),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's stops",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {}, // TODO: full stop list screen
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        color: _Palette.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStopsCard(),
              const SizedBox(height: 28),
              _sectionLabel('QUICK ACTIONS'),
              const SizedBox(height: 4),
              const Text(
                'Make a request',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _Palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 100), // room above the floating nav bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
        color: _Palette.green,
      ),
    );
  }

  // ── HEADER — greeting + bell + avatar ──
  Widget _buildHeader() {
    final alerts = _activeAlerts();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingLabel(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: _Palette.green,
                ),
              ),
              const SizedBox(height: 6),
              _infoLoading
                  ? Container(
                      width: 140,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : Text(
                      'Hi, ${_firstName()}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _Palette.textPrimary,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                _greetingSubtitle(),
                style: const TextStyle(
                  fontSize: 13,
                  color: _Palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => setState(() => _selectedTab = 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: _Palette.textPrimary,
                  size: 22,
                ),
              ),
              if (alerts.isNotEmpty)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showProfileSheet,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _Palette.avatar,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAlertsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlertsPage(showBottomNav: false),
      ),
    );
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _studentInfo?.fullName ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if ((_studentInfo?.uniqueID ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'ID: ${_studentInfo!.uniqueID}',
                  style: const TextStyle(color: _Palette.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── NEXT TRIP CARD ──
  Widget _buildLiveTrackerCard() {
    final routeName = _studentInfo?.routeName ?? 'Loading...';
    final busNumber = _studentInfo?.busNumber ?? '...';
    final stopName = _studentInfo?.stopName ?? '...';
    final routePts = _routePoints.isEmpty ? [_busLocation, _myStop] : _routePoints;

    final String badgeText = !_isConnected
        ? 'OFFLINE'
        : (_eta == 'Arriving!' ? 'ARRIVING' : 'ON TIME');
    final Color badgeColor = !_isConnected
        ? _Palette.textMuted
        : _Palette.green;
    final Color badgeBg = !_isConnected
        ? const Color(0xFFE5E7EB)
        : _Palette.greenBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.card,
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
              Expanded(
                child: Text(
                  'Route $routeName',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _Palette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _tripStat(
                  Icons.directions_bus_rounded,
                  busNumber,
                  'Your bus',
                ),
              ),
              Expanded(
                child: _tripStat(Icons.access_time_rounded, _eta, 'Away'),
              ),
              Expanded(
                child: _tripStat(
                  Icons.location_on_outlined,
                  stopName,
                  'Next stop',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: 170,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _busLocation,
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapService.cartoVoyager,
                        subdomains: MapService.subdomains,
                        userAgentPackageName: 'com.example.safeway',
                        maxZoom: 19,
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePts,
                            strokeWidth: 7.0,
                            color: _Palette.green.withOpacity(0.3),
                          ),
                          Polyline(
                            points: routePts,
                            strokeWidth: 3.5,
                            color: _Palette.green,
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
                              busCode: 'BUS',
                              isLive: _isConnected,
                            ),
                          ),
                          Marker(
                            point: _myStop,
                            width: 90,
                            height: 70,
                            child: MapService.buildStudentMarker(
                              label: 'Stop',
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _isConnected
                                ? _Palette.green
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isConnected ? 'LIVE · $_eta' : 'CONNECTING',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ARRIVAL AT YOUR STOP',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: _Palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _eta == 'Loading...' ? '--:--' : _eta,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _Palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _openFullMap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.dark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Track bus',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _Palette.textPrimary),
        const SizedBox(height: 6),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _Palette.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _Palette.textMuted),
        ),
      ],
    );
  }

  void _openFullMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackBusScreen(
          busNumber: 'Bus #${_studentInfo?.busNumber ?? '101'}',
          routeName: _studentInfo?.routeName ?? 'Morning Route',
          myStop: _myStop,
          pickupStopName: _studentInfo?.stopName ?? 'Your Stop',
          pickupTime: '7:40 AM',
          arrivalStopName: 'Main Campus',
          arrivalTime: '8:15 AM',
          // driverPhone: _studentInfo?.stopName,
        ),
      ),
    );
  }

  // ── STOPS TIMELINE CARD ──
  Widget _buildStopsCard() {
    // First two stops are illustrative; the middle one reflects the
    // student's real assigned stop from the database.
    final myStop = _studentInfo?.stopName ?? 'Your Stop';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _Palette.card,
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
          _stopRow(
            name: 'Imperial Park',
            time: '07:30 AM',
            status: _StopStatus.passed,
            isFirst: true,
          ),
          _stopRow(name: myStop, time: '07:45 AM', status: _StopStatus.current),
          _stopRow(
            name: 'Cedar Grove School',
            time: '08:00 AM',
            status: _StopStatus.upcoming,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _stopRow({
    required String name,
    required String time,
    required _StopStatus status,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final bool isCurrent = status == _StopStatus.current;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Expanded(
                    child: isFirst
                        ? const SizedBox()
                        : Container(width: 2, color: _Palette.divider),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? _Palette.green : Colors.white,
                      border: Border.all(
                        color: isCurrent ? _Palette.green : _Palette.divider,
                        width: 2,
                      ),
                    ),
                    child: isCurrent
                        ? const Icon(Icons.circle, size: 6, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: isLast
                        ? const SizedBox()
                        : Container(width: 2, color: _Palette.divider),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: status == _StopStatus.passed
                          ? _Palette.textMuted
                          : _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _statusPill(status),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(_StopStatus status) {
    late String label;
    late Color fg;
    Color? bg;
    switch (status) {
      case _StopStatus.passed:
        label = 'PASSED';
        fg = const Color.fromARGB(255, 19, 70, 53);
        bg = null;
        break;
      case _StopStatus.current:
        label = 'YOUR STOP';
        fg = const Color(0xFF1F6F54);
        bg = _Palette.greenBg;
        break;
      case _StopStatus.upcoming:
        label = 'UP NEXT';
        fg = _Palette.textMuted;
        bg = null;
        break;
    }
    if (bg == null) {
      return Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // ── QUICK ACTIONS ──
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickActionTile(
            icon: Icons.location_on_outlined,
            label: 'Pickup station',
            iconColor: _Palette.green,
            iconBg: _Palette.greenBg,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChangePickupStationScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Change route',
            iconColor: _Palette.orange,
            iconBg: _Palette.orangeBg,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestRouteChangePage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Palette.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: _Palette.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _Palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM NAV ──
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_rounded, 'Home'),
          _navItem(1, Icons.navigation_outlined, 'Track'),
          _navItem(2, Icons.notifications_none_rounded, 'Alerts'),
          _navItem(3, Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: active ? _Palette.greenBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? _Palette.green : _Palette.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? _Palette.green : _Palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

enum _StopStatus { passed, current, upcoming }
