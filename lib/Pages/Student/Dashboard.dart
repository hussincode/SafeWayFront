import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';
import 'package:safeway/services/location_service.dart';

// ── Subscription Model ──
class SubscriptionModel {
  final String status;
  final String startDate;
  final String endDate;

  SubscriptionModel({
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      status:    json['status'],
      startDate: json['startDate'],
      endDate:   json['endDate'],
    );
  }
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {

  // ── Bus tracking state ──
  LatLng _busLocation = const LatLng(24.7136, 46.6753);
  String _eta = 'Loading...';
  bool _isConnected = true;
  Timer? _refreshTimer;
  final MapController _mapController = MapController();
  final LatLng _myStop = const LatLng(24.7200, 46.6800);

  // ── Subscription state ──
  SubscriptionModel? _subscription;
  bool _subscriptionLoading = true;

  // ── TODO: Replace 2 with real userId from login/storage ──
  final int _userId = 2;

  @override
  void initState() {
    super.initState();
    _fetchBusLocation();
    _loadSubscription();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchBusLocation();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Fetch bus location ──
  Future<void> _fetchBusLocation() async {
    final location = await LocationService.getBusLocation();
    if (!mounted) return;

    if (location != null) {
      final newPos = LatLng(location['latitude']!, location['longitude']!);
      final distance = const Distance().as(LengthUnit.Meter, newPos, _myStop);
      final etaMinutes = (distance / 300).ceil();

      setState(() {
        _busLocation = newPos;
        _eta = etaMinutes <= 1 ? 'Arriving!' : '$etaMinutes min';
        _isConnected = true;
      });

      _mapController.move(_busLocation, 14.0);
    } else {
      setState(() => _isConnected = false);
    }
  }

  // ── Fetch subscription from API ──
  Future<void> _loadSubscription() async {
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
        // Log status so we can diagnose why it fails (e.g. 404 / 500)
        // ignore: avoid_print
        print('Subscription API failed: ${res.statusCode} ${res.body}');
        setState(() => _subscriptionLoading = false);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Subscription API error: $e');
      if (mounted) setState(() => _subscriptionLoading = false);
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

  // ── HEADER ──
  Widget _buildHeader(BuildContext context) {
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
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios, color: Colors.white70, size: 14),
                SizedBox(width: 4),
                Text('Back to Home', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text('Emma Johnson',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Track your bus and manage\nyour schedule',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                ],
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

  // ── BUS INFO CARD ──
  Widget _buildBusInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Bus Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoBox('Bus Number', 'BUS-101', const Color(0xFFF0F0FF), const Color(0xFF4F46E5))),
              const SizedBox(width: 12),
              Expanded(child: _infoBox('Driver', 'Michael Davis', const Color(0xFFF0FFF4), const Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _infoBox('ETA', _eta, const Color(0xFFFFF7ED), const Color(0xFFEA580C))),
              const SizedBox(width: 12),
              Expanded(child: _infoBox('Next Stop', 'Main Street\nStation', const Color(0xFFFFF0F9), const Color(0xFFDB2777))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  // ── ROUTE CARD ──
  Widget _buildRouteCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Color(0xFF4F46E5), size: 18),
              SizedBox(width: 6),
              Text('Route: Route A - Downtown',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
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
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$num',
                  style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF1A1A2E) : const Color(0xFF6B7280))),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Your Stop',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ── LIVE TRACKING CARD ──
  Widget _buildLiveTrackingCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Bus Tracking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected ? const Color(0xFF16A34A) : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(_isConnected ? 'Live' : 'Offline',
                      style: TextStyle(
                          fontSize: 11,
                          color: _isConnected ? const Color(0xFF16A34A) : Colors.red,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _busLocation,
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safeway',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_busLocation, _myStop],
                        strokeWidth: 3.0,
                        color: const Color(0xFF4F46E5).withOpacity(0.7),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _busLocation,
                        width: 80, height: 44,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.4), blurRadius: 6)],
                              ),
                              child: const Text('BUS-101',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            const Icon(Icons.navigation, color: Colors.red, size: 18),
                          ],
                        ),
                      ),
                      Marker(
                        point: _myStop,
                        width: 80, height: 44,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Your Stop',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                            const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text('ETA: $_eta',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.navigation, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              const Text('Bus', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(width: 12),
              const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 14),
              const SizedBox(width: 4),
              const Text('Your Stop', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
          if (!_isConnected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Color(0xFFEA580C), size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Cannot reach server. Showing last known location.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFEA580C)))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── DYNAMIC SUBSCRIPTION CARD ──
  Widget _buildSubscriptionCard() {

    // Loading skeleton
    if (_subscriptionLoading) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.credit_card_outlined, color: Color(0xFF4F46E5), size: 18),
              SizedBox(width: 8),
              Text('Subscription Status',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          ],
        ),
      );
    }

    // No subscription found
    if (_subscription == null) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.credit_card_outlined, color: Color(0xFF4F46E5), size: 18),
              SizedBox(width: 8),
              Text('Subscription Status',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_outlined, color: Color(0xFFEA580C), size: 18),
                SizedBox(width: 8),
                Text('No subscription found. Contact admin.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFEA580C))),
              ]),
            ),
          ],
        ),
      );
    }

    // ── Real data ──
    final status = _subscription!.status;

    final Color statusColor = status == 'PAID'
        ? const Color(0xFF16A34A)
        : status == 'EXPIRED'
            ? const Color(0xFFEA580C)
            : const Color(0xFFDC2626);

    final Color bgColor = status == 'PAID'
        ? const Color(0xFFF0FFF4)
        : status == 'EXPIRED'
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFFFF0F0);

    final IconData statusIcon = status == 'PAID'
        ? Icons.check_circle_outline
        : status == 'EXPIRED'
            ? Icons.timer_off_outlined
            : Icons.cancel_outlined;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.credit_card_outlined, color: Color(0xFF4F46E5), size: 18),
            SizedBox(width: 8),
            Text('Subscription Status',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Status', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      Text(status, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor)),
                      const SizedBox(height: 2),
                      Text('Valid until: ${_subscription!.endDate}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // UNPAID warning
          if (status == 'UNPAID') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 14),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Your subscription is unpaid. Please contact your parent or school admin.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                )),
              ]),
            ),
          ],

          // EXPIRED warning
          if (status == 'EXPIRED') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 14),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Your subscription has expired. Please renew it with your school admin.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFEA580C)),
                )),
              ]),
            ),
          ],
        ],
      ),
    );
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
          _actionButton(Icons.location_on_outlined, 'Change Pickup Station', const Color(0xFF4F46E5)),
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  // ── NOTIFICATIONS ──
  Widget _buildNotificationsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF1A1A2E)),
              const SizedBox(width: 6),
              const Text('Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _notifItem(
            icon: Icons.access_time, iconColor: const Color(0xFF4F46E5), borderColor: const Color(0xFF4F46E5),
            text: 'Bus BUS-101 arriving at Main Street Station in 5 minutes', time: '', isUnread: true,
          ),
          const SizedBox(height: 10),
          _notifItem(
            icon: Icons.check_circle_outline, iconColor: const Color(0xFF16A34A), borderColor: const Color(0xFF16A34A),
            text: 'Liam Smith boarded the bus at Park Avenue Station', time: '15m ago',
          ),
          const SizedBox(height: 10),
          _notifItem(
            icon: Icons.warning_amber_outlined, iconColor: const Color(0xFFEA580C), borderColor: const Color(0xFFEA580C),
            text: 'BUS-101 delayed by 10 minutes due to traffic', time: '30m ago',
          ),
        ],
      ),
    );
  }

  Widget _notifItem({
    required IconData icon, required Color iconColor, required Color borderColor,
    required String text, required String time, bool isUnread = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        color: Colors.grey[50],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ],
            ),
          ),
          if (isUnread)
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  // ── SHARED CARD ──
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}