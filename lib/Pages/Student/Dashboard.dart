import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';
import 'package:safeway/services/location_service.dart';
import 'package:safeway/Pages/Student/change_pickup_station_screen.dart';

// ── Models ──
class SubscriptionModel {
  final String status;
  final String startDate;
  final String endDate;
  SubscriptionModel({required this.status, required this.startDate, required this.endDate});
  factory SubscriptionModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionModel(status: j['status'], startDate: j['startDate'], endDate: j['endDate']);
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
    required this.fullName, required this.uniqueID, required this.grade,
    required this.busNumber, required this.driverName,
    required this.routeName, required this.stopName,
  });
  factory StudentInfoModel.fromJson(Map<String, dynamic> j) => StudentInfoModel(
    fullName:   j['fullName']   ?? '',
    uniqueID:   j['uniqueID']   ?? '',
    grade:      j['grade']      ?? '',
    busNumber:  j['busNumber']  ?? 'Not assigned',
    driverName: j['driverName'] ?? 'Not assigned',
    routeName:  j['routeName']  ?? 'Not assigned',
    stopName:   j['stopName']   ?? 'Not assigned',
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
  int    _userId  = 0;
  StudentInfoModel? _studentInfo;
  bool   _infoLoading = true;

  // ── Bus tracking ──
  LatLng _busLocation = const LatLng(24.7136, 46.6753);
  LatLng _myStop      = const LatLng(24.7200, 46.6800);
  String _eta         = 'Loading...';
  bool   _isConnected = false;
  Timer? _refreshTimer;
  final MapController _mapController = MapController();

  // ── Subscription ──
  SubscriptionModel? _subscription;
  bool _subscriptionLoading = true;

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
  // Debug — check what's saved in storage
  final userIdStr  = await _storage.read(key: 'userId')   ?? '0';
  final fullName   = await _storage.read(key: 'fullName') ?? '';
  final uniqueID   = await _storage.read(key: 'uniqueID') ?? '';

  print('🔑 userId from storage: $userIdStr');
  print('🔑 fullName from storage: $fullName');
  print('🔑 uniqueID from storage: $uniqueID');

  _userId = int.tryParse(userIdStr) ?? 0;

  if (_userId == 0) {
    print('⚠️ userId is 0 — login did not save userId correctly!');
    setState(() {
      _infoLoading         = false;
      _subscriptionLoading = false;
    });
    return;
  }

  await Future.wait([
    _loadStudentInfo(),
    _loadSubscription(),
  ]);

  _fetchBusLocation();
  _refreshTimer = Timer.periodic(
    const Duration(seconds: 5), (_) => _fetchBusLocation(),
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
    final location = await LocationService.getBusLocation();
    if (!mounted) return;

    if (location != null) {
      final newPos   = LatLng(location['latitude']!, location['longitude']!);
      final distance = const Distance().as(LengthUnit.Meter, newPos, _myStop);
      final etaMins  = (distance / 300).ceil(); // ~18 km/h speed

      setState(() {
        _busLocation = newPos;
        _eta         = etaMins <= 1 ? 'Arriving!' : '$etaMins min';
        _isConnected = true;
      });

      _mapController.move(_busLocation, 14.0);
    } else {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBusInfoCard(),
                  const SizedBox(height: 16),
                  _buildRouteCard(),
                  const SizedBox(height: 16),
                  _buildLiveTrackingCard(),
                  const SizedBox(height: 16),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                  const SizedBox(height: 16),
                  _buildNotificationsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER — Real name from DB ──
  Widget _buildHeader(BuildContext context) {
    final name = _studentInfo?.fullName ?? 'Loading...';
    final id   = _studentInfo?.uniqueID ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(children: [
              Icon(Icons.arrow_back_ios, color: Colors.white70, size: 14),
              SizedBox(width: 4),
              Text('Back to Home', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome,',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                    // ✅ Real name from database
                    _infoLoading
                        ? Container(width: 160, height: 30,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)))
                        : Text(name,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (id.isNotEmpty)
                      Text('ID: $id', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const Text('Track your bus and manage your schedule',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BUS INFO CARD — Real bus number, driver, ETA ──
  Widget _buildBusInfoCard() {
    final busNumber  = _studentInfo?.busNumber  ?? '...';
    final driverName = _studentInfo?.driverName ?? '...';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Bus Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          Row(children: [
            // ✅ Real bus number from DB
            Expanded(child: _infoBox('Bus Number', busNumber, const Color(0xFFF0F0FF), const Color(0xFF4F46E5))),
            const SizedBox(width: 12),
            // ✅ Real driver name from DB
            Expanded(child: _infoBox('Driver', driverName, const Color(0xFFF0FFF4), const Color(0xFF16A34A))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            // ✅ Real ETA from live location
            Expanded(child: _infoBox('ETA', _eta, const Color(0xFFFFF7ED), const Color(0xFFEA580C))),
            const SizedBox(width: 12),
            // ✅ Real stop name from DB
            Expanded(child: _infoBox('Next Stop', _studentInfo?.stopName ?? '...', const Color(0xFFFFF0F9), const Color(0xFFDB2777))),
          ]),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
      ]),
    );
  }

  // ── ROUTE CARD — Real route name from DB ──
  Widget _buildRouteCard() {
    final routeName = _studentInfo?.routeName ?? 'Loading...';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF4F46E5), size: 18),
            const SizedBox(width: 6),
            // ✅ Real route name from DB
            Expanded(
              child: Text('Route: $routeName',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ),
          ]),
          const SizedBox(height: 16),
          _routeStop(1, 'Main Street Station', '07:15 AM', isActive: true),
          _routeStop(2, 'Park Avenue Station', '07:25 AM'),
          _routeStop(3, 'Broadway Station', '07:35 AM'),
        ],
      ),
    );
  }

  Widget _routeStop(int num, String name, String time, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0F0FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3))
            : Border.all(color: Colors.transparent),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text('$num',
              style: TextStyle(color: isActive ? Colors.white : Colors.grey,
                  fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF1A1A2E) : const Color(0xFF6B7280))),
          Row(children: [
            Icon(Icons.access_time, size: 11, color: Colors.grey[400]),
            const SizedBox(width: 3),
            Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        ])),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(20)),
            child: const Text('Your Stop',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  // ── LIVE TRACKING CARD — Real GPS from driver ──
  Widget _buildLiveTrackingCard() {
    final busNum = _studentInfo?.busNumber ?? 'BUS';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Bus Tracking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Row(children: [
                // ✅ Real connection status
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: _isConnected ? const Color(0xFF16A34A) : Colors.orange,
                        shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(_isConnected ? 'Live' : 'Connecting...',
                    style: TextStyle(fontSize: 11,
                        color: _isConnected ? const Color(0xFF16A34A) : Colors.orange,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ Real OpenStreetMap with live bus location
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 240,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _busLocation,
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  // OpenStreetMap tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safeway',
                  ),
                  // Route line from bus to stop
                  PolylineLayer(polylines: [
                    Polyline(
                      points: [_busLocation, _myStop],
                      strokeWidth: 3.5,
                      color: const Color(0xFF4F46E5).withOpacity(0.7),
                    ),
                  ]),
                  // Markers
                  MarkerLayer(markers: [
                    // 🚌 Bus marker — moves in real time
                    Marker(
                      point: _busLocation,
                      width: 90, height: 48,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.5), blurRadius: 8)],
                          ),
                          child: Text(busNum,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.navigation, color: Colors.red, size: 20),
                      ]),
                    ),
                    // 📍 Student stop — fixed
                    Marker(
                      point: _myStop,
                      width: 80, height: 44,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Your Stop',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 20),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ETA badge + legend
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.access_time, color: Colors.white, size: 13),
                const SizedBox(width: 4),
                // ✅ Real ETA calculated from distance
                Text('ETA: $_eta',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.navigation, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            const Text('Bus', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(width: 12),
            const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 14),
            const SizedBox(width: 4),
            const Text('Your Stop', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ]),

          // Offline warning
          if (!_isConnected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.wifi_off, color: Color(0xFFEA580C), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Waiting for driver to start sharing location...',
                  style: TextStyle(fontSize: 11, color: Color(0xFFEA580C)),
                )),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ── SUBSCRIPTION CARD — Real status from DB ──
  Widget _buildSubscriptionCard() {
    if (_subscriptionLoading) {
      return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.credit_card_outlined, color: Color(0xFF4F46E5), size: 18), SizedBox(width: 8),
          Text('Subscription Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 12),
        Container(width: double.infinity, height: 80,
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
      ]));
    }

    if (_subscription == null) {
      return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.credit_card_outlined, color: Color(0xFF4F46E5), size: 18), SizedBox(width: 8),
          Text('Subscription Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3))),
          child: const Row(children: [
            Icon(Icons.warning_amber_outlined, color: Color(0xFFEA580C), size: 18), SizedBox(width: 8),
            Text('No subscription found. Contact admin.', style: TextStyle(fontSize: 13, color: Color(0xFFEA580C))),
          ])),
      ]));
    }

    // ✅ Real status from DB
    final status = _subscription!.status;
    final Color statusColor = status == 'PAID' ? const Color(0xFF16A34A) : status == 'EXPIRED' ? const Color(0xFFEA580C) : const Color(0xFFDC2626);
    final Color bgColor     = status == 'PAID' ? const Color(0xFFF0FFF4) : status == 'EXPIRED' ? const Color(0xFFFFF7ED) : const Color(0xFFFFF0F0);
    final IconData icon     = status == 'PAID' ? Icons.check_circle_outline : status == 'EXPIRED' ? Icons.timer_off_outlined : Icons.cancel_outlined;

    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.credit_card_outlined, color: Color(0xFF4F46E5), size: 18), SizedBox(width: 8),
        Text('Subscription Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: statusColor, size: 28), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Status', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 2),
            Text(status, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(height: 2),
            Text('Valid until: ${_subscription!.endDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ])),
        ]),
      ),
      if (status == 'UNPAID') ...[
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 14), SizedBox(width: 6),
            Expanded(child: Text('Your subscription is unpaid. Please contact your parent or school admin.', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
          ])),
      ],
      if (status == 'EXPIRED') ...[
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 14), SizedBox(width: 6),
            Expanded(child: Text('Your subscription has expired. Please renew with your school admin.', style: TextStyle(fontSize: 11, color: Color(0xFFEA580C)))),
          ])),
      ],
    ]));
  }

  // ── QUICK ACTIONS ──
  Widget _buildQuickActionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChangePickupStationScreen())),
            child: _actionButton(Icons.location_on_outlined, 'Change Pickup Station', const Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 10),
          _actionButton(Icons.send_outlined, 'Request Route Change', const Color(0xFF4F46E5)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.04),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18), const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  // ── NOTIFICATIONS ──
  Widget _buildNotificationsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF1A1A2E)),
            const SizedBox(width: 6),
            const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 14),
          _notifItem(icon: Icons.access_time, iconColor: const Color(0xFF4F46E5), borderColor: const Color(0xFF4F46E5),
              text: 'Bus ${_studentInfo?.busNumber ?? 'BUS'} arriving at ${_studentInfo?.stopName ?? 'your stop'} in 5 minutes',
              time: '', isUnread: true),
          const SizedBox(height: 10),
          _notifItem(icon: Icons.check_circle_outline, iconColor: const Color(0xFF16A34A), borderColor: const Color(0xFF16A34A),
              text: 'You have boarded the bus successfully', time: '15m ago'),
          const SizedBox(height: 10),
          _notifItem(icon: Icons.warning_amber_outlined, iconColor: const Color(0xFFEA580C), borderColor: const Color(0xFFEA580C),
              text: 'Bus ${_studentInfo?.busNumber ?? 'BUS'} delayed by 10 minutes due to traffic', time: '30m ago'),
        ],
      ),
    );
  }

  Widget _notifItem({required IconData icon, required Color iconColor, required Color borderColor, required String text, required String time, bool isUnread = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        color: Colors.grey[50],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 18), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ])),
        if (isUnread)
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle)),
      ]),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}