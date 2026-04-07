import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeway/Pages/Admin/Student_Man.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final MapController _mapController = MapController();

  // Fake bus locations for demo
  final List<Map<String, dynamic>> _buses = [
    {
      'id': 'BUS-101',
      'driver': 'Michael Davis',
      'route': 'Route A - Downtown',
      'occupancy': '18/40',
      'nextStop': 'Main Street Station (5 min)',
      'status': 'Active',
      'lat': 30.0444,
      'lng': 31.2357,
      'color': const Color(0xFF4F46E5),
    },
    {
      'id': 'BUS-102',
      'driver': 'Sarah Wilson',
      'route': 'Route B - Suburbs',
      'occupancy': '12/35',
      'nextStop': 'Oak Street Station (8 min)',
      'status': 'Active',
      'lat': 30.0500,
      'lng': 31.2450,
      'color': const Color(0xFF16A34A),
    },
  ];

  final List<Map<String, dynamic>> _activities = [
    {'type': 'Boarding', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF16A34A), 'details': 'Emma Johnson', 'bus': 'BUS-101'},
    {'type': 'Boarding', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF16A34A), 'details': 'Liam Smith', 'bus': 'BUS-101'},
    {'type': 'Delay', 'icon': Icons.access_time, 'color': const Color(0xFFF59E0B), 'details': 'System Event', 'bus': 'BUS-102'},
    {'type': 'Dropoff', 'icon': Icons.location_on_outlined, 'color': const Color(0xFF3B82F6), 'details': 'Olivia Brown', 'bus': 'BUS-102'},
    {'type': 'Alert', 'icon': Icons.warning_amber_outlined, 'color': const Color(0xFFEF4444), 'details': 'System Event', 'bus': 'BUS-101'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildLiveTrackingCard(),
              const SizedBox(height: 20),
              _buildBusList(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildRecentActivities(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Text('Welcome back, Admin',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  // ── STATS GRID ──
  Widget _buildStatsGrid() {
    final stats = [
      {
        'label': 'Total Students',
        'value': '3',
        'sub': '+12% this month',
        'subColor': const Color(0xFF16A34A),
        'icon': Icons.group_outlined,
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF3B82F6),
        'borderColor': const Color(0xFF3B82F6),
      },
      {
        'label': 'Active Buses',
        'value': '2',
        'sub': 'All operational',
        'subColor': const Color(0xFF6B7280),
        'icon': Icons.directions_bus_outlined,
        'iconBg': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFF59E0B),
        'borderColor': const Color(0xFFF59E0B),
      },
      {
        'label': 'Total Drivers',
        'value': '2',
        'sub': 'All active',
        'subColor': const Color(0xFF16A34A),
        'icon': Icons.person_outline,
        'iconBg': const Color(0xFFF0FFF4),
        'iconColor': const Color(0xFF16A34A),
        'borderColor': const Color(0xFF16A34A),
      },
      {
        'label': "Today's Trips",
        'value': '24',
        'sub': 'On schedule',
        'subColor': const Color(0xFF8B5CF6),
        'icon': Icons.alt_route_outlined,
        'iconBg': const Color(0xFFF5F3FF),
        'iconColor': const Color(0xFF8B5CF6),
        'borderColor': const Color(0xFF8B5CF6),
      },
    ];

    return Column(
      children: stats.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _statCard(s),
      )).toList(),
    );
  }

  Widget _statCard(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: s['borderColor'] as Color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['label'] as String,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 4),
                Text(s['value'] as String,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(
                    (s['subColor'] as Color) == const Color(0xFF16A34A)
                        ? Icons.trending_up
                        : (s['subColor'] as Color) == const Color(0xFF8B5CF6)
                            ? Icons.show_chart
                            : Icons.circle,
                    size: 14,
                    color: s['subColor'] as Color,
                  ),
                  const SizedBox(width: 4),
                  Text(s['sub'] as String,
                      style: TextStyle(fontSize: 12, color: s['subColor'] as Color, fontWeight: FontWeight.w500)),
                ]),
              ],
            ),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: s['iconBg'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s['icon'] as IconData, color: s['iconColor'] as Color, size: 24),
          ),
        ],
      ),
    );
  }

  // ── LIVE TRACKING ──
  Widget _buildLiveTrackingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Bus Tracking',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Real-time locations',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('2 Active',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Map
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(30.0472, 31.2403),
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safeway',
                  ),
                  MarkerLayer(
                    markers: _buses.map((bus) => Marker(
                      point: LatLng(bus['lat'] as double, bus['lng'] as double),
                      width: 60, height: 36,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: bus['color'] as Color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: (bus['color'] as Color).withOpacity(0.5), blurRadius: 6)],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.directions_bus, color: Colors.white, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            (bus['id'] as String).replaceAll('BUS-', ''),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Legend + Refresh
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _legendItem(const Color(0xFFF59E0B), 'Active Bus'),
                const SizedBox(width: 16),
                _legendItem(const Color(0xFF3B82F6), 'Bus Stop'),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {}),
                  child: Row(children: [
                    const Icon(Icons.refresh, size: 14, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 4),
                    const Text('Refresh Map',
                        style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
    ]);
  }

  // ── BUS LIST ──
  Widget _buildBusList() {
    return Column(
      children: _buses.map((bus) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _busCard(bus),
      )).toList(),
    );
  }

  Widget _busCard(Map<String, dynamic> bus) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (bus['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_bus_rounded, color: bus['color'] as Color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(bus['id'] as String,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Active',
                    style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _busInfoRow(Icons.person_outline, 'Driver: ${bus['driver']}'),
          const SizedBox(height: 4),
          _busInfoRow(Icons.alt_route_outlined, 'Route: ${bus['route']}'),
          const SizedBox(height: 4),
          _busInfoRow(Icons.people_outline, 'Occupancy: ${bus['occupancy']}'),
          const SizedBox(height: 4),
          _busInfoRow(Icons.location_on_outlined, 'Next: ${bus['nextStop']}'),
        ],
      ),
    );
  }

  Widget _busInfoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 13, color: Colors.grey[400]),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ),
    ]);
  }

  // ── QUICK ACTIONS ──
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bolt, color: Color(0xFF1A1A2E), size: 18),
            SizedBox(width: 6),
            Text('Quick Actions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ]),
          const SizedBox(height: 14),
          _quickActionBtn(Icons.group_outlined, 'Manage Students', const Color(0xFFEFF6FF), const Color(0xFF3B82F6), () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsScreen()));
          }),
          const SizedBox(height: 10),
          _quickActionBtn(Icons.person_outline, 'Manage Drivers', const Color(0xFFFEF3C7), const Color(0xFFF59E0B), () {
            // Navigate to driver management screen
          }),
          const SizedBox(height: 10),
          _quickActionBtn(Icons.alt_route_outlined, 'Manage Routes', const Color(0xFFF0FFF4), const Color(0xFF16A34A), () {
            // Navigate to route management screen
          }),
        ],
      ),
    );
  }

  Widget _quickActionBtn(IconData icon, String label, Color bg, Color color, void Function()? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ),
          Icon(Icons.arrow_outward, color: color, size: 16),
        ]),
      ),
    );
  }

  // ── RECENT ACTIVITIES ──
  Widget _buildRecentActivities() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Recent Activities',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Latest system events',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('View All',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8F9FF),
            child: const Row(children: [
              Expanded(flex: 2, child: Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1))),
              Expanded(flex: 3, child: Text('DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1))),
              Expanded(flex: 2, child: Text('BUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1))),
            ]),
          ),

          // Activity rows
          ..._activities.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : const Color(0xFFFAFAFF),
                border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(children: [
                Expanded(flex: 2, child: Row(children: [
                  Icon(a['icon'] as IconData, color: a['color'] as Color, size: 16),
                  const SizedBox(width: 6),
                  Flexible(child: Text(a['type'] as String,
                      style: TextStyle(fontSize: 12, color: a['color'] as Color, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis)),
                ])),
                Expanded(flex: 3, child: Text(a['details'] as String,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
                Expanded(flex: 2, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(a['bus'] as String,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                )),
              ]),
            );
          }),

          // Load more
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: const Text('Load More Activities →',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}