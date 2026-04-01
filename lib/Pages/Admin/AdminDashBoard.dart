import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
 
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
 
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
 
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ── Simulated live bus positions ──────────────────────────────────────────
  LatLng _bus101 = const LatLng(30.060, 31.225);
  LatLng _bus102 = const LatLng(30.055, 31.240);
  Timer? _mapTimer;
  int _selectedNav = 0;
 
  final List<Map<String, dynamic>> _activities = [
    {'type': 'Boarding', 'details': 'Emma Schneider', 'bus': 'BUS-101', 'location': 'Main Street Station', 'time': '6 mins ago', 'color': Color(0xFF16A34A)},
    {'type': 'Boarding', 'details': 'Liam Smith',     'bus': 'BUS-101', 'location': 'Park Avenue Station','time': '15 mins ago','color': Color(0xFF16A34A)},
    {'type': 'Delay',    'details': 'System Event',   'bus': 'BUS-102', 'location': 'Oak Street Station',  'time': '30 mins ago','color': Color(0xFFEA580C)},
    {'type': 'Dropoff',  'details': 'Oliver Brown',   'bus': 'BUS-102', 'location': 'School Main Gate',    'time': '38 mins ago','color': Color(0xFF64748B)},
    {'type': 'Alert',    'details': 'System Event',   'bus': 'BUS-101', 'location': 'Route A — Downtown',  'time': '1 hour ago', 'color': Color(0xFFDC2626)},
  ];
 
  @override
  void initState() {
    super.initState();
    // Animate buses slightly every 4 s to mimic live tracking
    _mapTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        _bus101 = LatLng(_bus101.latitude  + 0.0002, _bus101.longitude + 0.0001);
        _bus102 = LatLng(_bus102.latitude  - 0.0001, _bus102.longitude + 0.0002);
      });
    });
  }
 
  @override
  void dispose() {
    _mapTimer?.cancel();
    super.dispose();
  }
 
  // ── Colours ───────────────────────────────────────────────────────────────
  static const Color _navy   = Color(0xFF1A1F5E);
  static const Color _navyA  = Color(0xFF2D3494);
  static const Color _primary= Color(0xFF3B5BDB);
  static const Color _bg     = Color(0xFFF4F6FB);
  static const Color _card   = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted  = Color(0xFF64748B);
  static const Color _text   = Color(0xFF1E293B);
  static const Color _green  = Color(0xFF16A34A);
  static const Color _orange = Color(0xFFEA580C);
  static const Color _red    = Color(0xFFDC2626);
  static const Color _purple = Color(0xFF7C3AED);
 
  // ── Nav items ─────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _navItems = [
    {'label': 'Dashboard',        'icon': Icons.dashboard_rounded},
    {'label': 'Manage Students',  'icon': Icons.people_rounded},
    {'label': 'Manage Drivers',   'icon': Icons.drive_eta_rounded},
    {'label': 'Manage Routes',    'icon': Icons.route_rounded},
    {'label': 'View Reports',     'icon': Icons.bar_chart_rounded},
    {'label': 'Notifications',    'icon': Icons.notifications_rounded},
    {'label': 'Settings',         'icon': Icons.settings_rounded},
  ];
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 20),
                        _buildMiddleRow(),
                        const SizedBox(height: 20),
                        _buildActivityCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // SIDEBAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: _navy,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('SafeWay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3)),
                    Text('Admin Portal', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
 
          // Nav
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                _navLabel('Main'),
                ..._navItems.take(5).toList().asMap().entries.map((e) => _navItem(e.key, e.value)),
                _navLabel('System'),
                ..._navItems.skip(5).toList().asMap().entries.map((e) => _navItem(e.key + 5, e.value)),
              ],
            ),
          ),
 
          // Sign out
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12))),
            padding: const EdgeInsets.all(10),
            child: _navItem(-1, {'label': 'Sign Out', 'icon': Icons.logout_rounded}),
          ),
        ],
      ),
    );
  }
 
  Widget _navLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
    child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );
 
  Widget _navItem(int index, Map<String, dynamic> item) {
    final bool active = index == _selectedNav;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _navyA : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(item['icon'] as IconData, color: active ? Colors.white : Colors.white54, size: 16),
            const SizedBox(width: 10),
            Text(item['label'] as String,
              style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Admin Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
              Text('SafeWay Management System', style: TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
          const Spacer(),
 
          // Date
          Row(
            children: const [
              Icon(Icons.calendar_today_rounded, size: 13, color: _muted),
              SizedBox(width: 5),
              Text('Sat, Mar 29 — 02:23 PM', style: TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
          const SizedBox(width: 12),
 
          // Notification bell
          _iconBtn(Icons.notifications_rounded, badge: '3'),
          const SizedBox(width: 8),
          _iconBtn(Icons.info_outline_rounded),
          const SizedBox(width: 12),
 
          // User chip
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: _primary,
                  child: const Text('AU', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Admin User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                    Text('Administrator', style: TextStyle(fontSize: 10, color: _muted)),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _iconBtn(IconData icon, {String? badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _card, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _muted),
        ),
        if (badge != null)
          Positioned(
            top: -3, right: -3,
            child: Container(
              width: 14, height: 14,
              decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
              child: Center(child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))),
            ),
          ),
      ],
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    final stats = [
      {'label': 'Total Students', 'value': '3',  'change': '↑ +12% this month', 'up': true,  'color': _primary, 'icon': Icons.people_rounded,       'bgColor': const Color(0xFFEEF2FF)},
      {'label': 'Active Buses',   'value': '2',  'change': 'All operational',    'up': false, 'color': _green,   'icon': Icons.directions_bus_rounded, 'bgColor': const Color(0xFFF0FDF4)},
      {'label': 'Total Drivers',  'value': '2',  'change': 'All active',         'up': false, 'color': _orange,  'icon': Icons.drive_eta_rounded,      'bgColor': const Color(0xFFFFF7ED)},
      {'label': "Today's Trips",  'value': '24', 'change': 'On schedule',        'up': true,  'color': _purple,  'icon': Icons.access_time_rounded,    'bgColor': const Color(0xFFF5F3FF)},
    ];
    return Row(
      children: stats.map((s) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: s == stats.last ? 0 : 16),
          child: _statCard(s),
        ),
      )).toList(),
    );
  }
 
  Widget _statCard(Map<String, dynamic> s) {
    final Color color = s['color'] as Color;
    final Color bgColor = s['bgColor'] as Color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s['label'] as String, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(s['value'] as String, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color, height: 1)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s['change'] as String,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: (s['up'] as bool) ? _green : _muted)),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(s['icon'] as IconData, color: color, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // MIDDLE ROW  (Map  |  Quick Actions + Alerts)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMiddleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map card (flex 3)
        Expanded(flex: 3, child: _buildMapCard()),
        const SizedBox(width: 16),
        // Right column (flex 2)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildAlertsCard(),
            ],
          ),
        ),
      ],
    );
  }
 
  // ── Map card ──────────────────────────────────────────────────────────────
  Widget _buildMapCard() {
    return _cardWrapper(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.location_on_rounded, size: 15, color: _primary),
              const SizedBox(width: 6),
              const Text('Live Bus Tracking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
            ]),
            const SizedBox(height: 2),
            const Text('Real-time locations', style: TextStyle(fontSize: 11, color: _muted)),
          ]),
          _pill('2 Active', _green, const Color(0xFFF0FDF4)),
        ],
      ),
      child: Column(
        children: [
          // FlutterMap
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 230,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(30.057, 31.232),
                  initialZoom: 13.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safeway',
                  ),
                  MarkerLayer(markers: [
                    _busMarker(_bus101, 'BUS-101'),
                    _busMarker(_bus102, 'BUS-102'),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Bus summary cards
          Row(
            children: [
              Expanded(child: _busSummaryCard('BUS-101', 'Michael Davis', 'Route A — Downtown', '15/22', 'Main Street Station', '3 min')),
              const SizedBox(width: 12),
              Expanded(child: _busSummaryCard('BUS-102', 'Sarah Wilson',  'Route B — Suburbs',  '12/18', 'Oak Street Station',   '6 min')),
            ],
          ),
        ],
      ),
    );
  }
 
  Marker _busMarker(LatLng pos, String label) {
    return Marker(
      point: pos,
      width: 60, height: 60,
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: _text, borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
 
  Widget _busSummaryCard(String busId, String driver, String route, String students, String nextStop, String eta) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _border), borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.directions_bus_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 5),
              Text(busId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
            ]),
            _pill('Active', _green, const Color(0xFFF0FDF4), fontSize: 10),
          ]),
          const SizedBox(height: 8),
          _busInfoRow(Icons.person_rounded,        driver),
          _busInfoRow(Icons.location_on_rounded,   route),
          _busInfoRow(Icons.people_rounded,         'Students: $students'),
          const SizedBox(height: 6),
          Text('Next: $nextStop ($eta)', style: const TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }
 
  Widget _busInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: _muted),
          const SizedBox(width: 5),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: _muted), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
 
  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Manage Students', 'icon': Icons.people_rounded,       'color': _primary, 'bg': const Color(0xFFEEF2FF)},
      {'label': 'Manage Drivers',  'icon': Icons.drive_eta_rounded,    'color': _green,   'bg': const Color(0xFFF0FDF4)},
      {'label': 'Manage Routes',   'icon': Icons.route_rounded,        'color': _orange,  'bg': const Color(0xFFFFF7ED)},
      {'label': 'View Reports',    'icon': Icons.bar_chart_rounded,    'color': _purple,  'bg': const Color(0xFFF5F3FF)},
    ];
    return _cardWrapper(
      header: const Text('⚡  Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
      child: Column(
        children: actions.map((a) {
          final Color color = a['color'] as Color;
          final Color bg    = a['bg'] as Color;
          return GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _card, border: Border.all(color: _border), borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(a['icon'] as IconData, color: color, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a['label'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text))),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
 
  // ── Alerts ────────────────────────────────────────────────────────────────
  Widget _buildAlertsCard() {
    return _cardWrapper(
      header: const Text('🔔  Active Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
      child: Column(
        children: [
          _alertItem(isRed: true,  title: '🚌  Bus Delay',    body: 'BUS-102 delayed by 10 minutes on Route B', time: '30 mins ago'),
          const SizedBox(height: 10),
          _alertItem(isRed: false, title: '💳  Unpaid Fees',  body: '1 student has unpaid subscription this month', time: '1 hour ago'),
        ],
      ),
    );
  }
 
  Widget _alertItem({required bool isRed, required String title, required String body, required String time}) {
    final Color borderColor = isRed ? _red   : _orange;
    final Color bgColor     = isRed ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED);
    final Color titleColor  = isRed ? _red   : _orange;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: titleColor)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(fontSize: 11, color: _muted, height: 1.4)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVITY TABLE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActivityCard() {
    return _cardWrapper(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('📋  Recent Activities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
            SizedBox(height: 2),
            Text('Latest system events', style: TextStyle(fontSize: 11, color: _muted)),
          ]),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
              child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary)),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
            child: Row(children: const [
              Expanded(flex: 2, child: _TableHeader('TYPE')),
              Expanded(flex: 2, child: _TableHeader('DETAILS')),
              Expanded(flex: 2, child: _TableHeader('BUS')),
              Expanded(flex: 3, child: _TableHeader('LOCATION')),
              Expanded(flex: 2, child: _TableHeader('TIME')),
            ]),
          ),
          // Rows
          ..._activities.map((a) => _activityRow(a)),
          // Load more
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              child: const Center(
                child: Text('Load More Activities ↓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _activityRow(Map<String, dynamic> a) {
    final Color c = a['color'] as Color;
    final String type = a['type'] as String;
    final String bus  = a['bus'] as String;
 
    Color busBg, busFg;
    if (bus == 'BUS-101') { busBg = const Color(0xFFEEF2FF); busFg = _primary; }
    else if (type == 'Delay') { busBg = const Color(0xFFFFF7ED); busFg = _orange; }
    else { busBg = const Color(0xFFF8FAFC); busFg = const Color(0xFF475569); }
 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(children: [
        Expanded(flex: 2, child: Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
        ])),
        Expanded(flex: 2, child: Text(a['details'] as String, style: const TextStyle(fontSize: 12, color: _text))),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: busBg, borderRadius: BorderRadius.circular(20)),
          child: Text(bus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: busFg)),
        )),
        Expanded(flex: 3, child: Text(a['location'] as String, style: const TextStyle(fontSize: 12, color: _muted))),
        Expanded(flex: 2, child: Text(a['time'] as String, style: const TextStyle(fontSize: 12, color: _muted))),
      ]),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _cardWrapper({required Widget header, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
            child: header,
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
 
  Widget _pill(String text, Color fg, Color bg, {double fontSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
 
// ── Tiny const widget for table headers ─────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5));
}