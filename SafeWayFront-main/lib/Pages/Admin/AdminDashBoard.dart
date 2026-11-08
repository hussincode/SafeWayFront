import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeway/Pages/Admin/Manage_Drivers.dart';
import 'package:safeway/Pages/Admin/Route_Man.dart' show ManageRoutesScreen;
import 'package:safeway/Pages/Admin/Student_Man.dart' show ManageStudentsScreen;
import 'package:safeway/Pages/Admin/RecentActivitiesCard.dart';
import 'package:safeway/services/admin_service.dart';
import 'package:safeway/services/map_service.dart';

// ─────────────────────────────────────────────────────────────
//  SafeWay design system — dark glass + red accent
//  (same tokens as the login page / student dashboard)
// ─────────────────────────────────────────────────────────────
class _Palette {
  static const bg = Color(0xFF070708);
  static const bg2 = Color(0xFF101012);
  static const surface = Color(0xFF18181B);

  static const red = Color(0xFFD32F2F);
  static const brightRed = Color(0xFFEF4444);
  static const darkRed = Color(0xFF991B1B);
  static const burgundy = Color(0xFF65171B);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB8B8BC);
  static const textMuted = Color(0xFF77777D);

  static const glassFill = Color(0x14FFFFFF); // white @ 8%
  static const glassFillSoft = Color(0x08FFFFFF);
  static const glassBorder = Color(0x2AFFFFFF); // white @ 16%
  static const divider = Color(0x1AFFFFFF);

  static const redGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [darkRed, red],
  );

  // A small rotation of accent tones, all inside the red/neutral family,
  // used only to tell stat cards apart from one another.
  static const accentA = brightRed;
  static const accentB = red;
  static const accentC = burgundy;
  static const accentD = Color(0xFFB0343B); // muted rose-red
}

// ─────────────────────────────────────────────────────────────
//  Shared visual primitives
// ─────────────────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  Widget _glow(double size, Color color, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Palette.bg2, _Palette.bg, _Palette.surface],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -100,
          child: _glow(320, _Palette.red, 0.22),
        ),
        Positioned(
          top: 260,
          left: -160,
          child: _glow(340, _Palette.burgundy, 0.34),
        ),
        Positioned(
          bottom: -140,
          right: -120,
          child: _glow(320, _Palette.darkRed, 0.28),
        ),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glow;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          if (glow)
            BoxShadow(
              color: _Palette.red.withOpacity(0.12),
              blurRadius: 28,
              spreadRadius: -6,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_Palette.glassFill, _Palette.glassFillSoft],
              ),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _RedButton({required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _Palette.redGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _Palette.red.withOpacity(0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final AdminService _adminService = AdminService();

  late Future<Map<String, dynamic>> _dashboardFuture;
  late TabController _chartTabController;

  // Backend data
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _stats = [];

  int? _studentCount;
  String? _studentChange;
  List<double> _studentTrend = [];

  int? _driverCount;
  String? _driverChange;
  List<double> _driverTrend = [];

  bool _isLoading = true;
  String? _errorMessage;
  String _busFilter = 'All'; // 'All', 'Active', 'Idle'

  // Weekly Activity Chart Data (Shadcn style)
  final List<double> _weeklyRides = [120, 185, 240, 210, 310, 290, 350];
  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _chartTabController = TabController(length: 2, vsync: this);
    _dashboardFuture = _loadDashboardData();
  }

  @override
  void dispose() {
    _chartTabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await _adminService.getDashboardSummary();
      final statsList = List<Map<String, dynamic>>.from(data['stats'] ?? []);

      final studentStat = statsList.firstWhere(
        (item) => item['label']?.toString() == 'Total Students',
        orElse: () => {},
      );

      final driverStat = statsList.firstWhere(
        (item) => item['label']?.toString() == 'Total Drivers',
        orElse: () => {},
      );

      setState(() {
        _stats = statsList;
        _list = List<Map<String, dynamic>>.from(data['buses'] ?? []);
        _activities = List<Map<String, dynamic>>.from(data['activities'] ?? []);

        _studentCount =
            int.tryParse(studentStat['value']?.toString() ?? '') ?? 0;
        _studentChange = studentStat['sub']?.toString();
        _studentTrend = _generateStudentTrend(_studentCount ?? 0);

        _driverCount = int.tryParse(driverStat['value']?.toString() ?? '') ?? 0;
        _driverChange = driverStat['sub']?.toString();
        _driverTrend = _generateDriverTrend(_driverCount ?? 0);

        _isLoading = false;
      });
      return data;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dashboard data: $e';
        _isLoading = false;
      });
      return {};
    }
  }

  void _refreshData() {
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
  }

  List<Map<String, dynamic>> get _filteredBuses {
    if (_busFilter == 'All') return _list;
    return _list
        .where(
          (b) =>
              (b['status']?.toString() ?? '').toLowerCase() ==
              _busFilter.toLowerCase(),
        )
        .toList();
  }

  MapThemeMode _mapTheme = MapThemeMode.dark;

  void _fitAllBuses() {
    if (_list.isEmpty) return;
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (var bus in _list) {
      double lat = bus['latitude'] is double
          ? bus['latitude']
          : double.tryParse(bus['latitude']?.toString() ?? '30.0472') ??
                30.0472;
      double lng = bus['longitude'] is double
          ? bus['longitude']
          : double.tryParse(bus['longitude']?.toString() ?? '31.2403') ??
                31.2403;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    double centerLat = (minLat + maxLat) / 2;
    double centerLng = (minLng + maxLng) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 13.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _Palette.bg,
        body: Stack(
          children: [
            Positioned.fill(child: _AmbientBackground()),
            Center(child: CircularProgressIndicator(color: _Palette.brightRed)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _Palette.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: _AmbientBackground()),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: _Palette.brightRed.withOpacity(0.9),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _Palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RedButton(
                      label: 'Try Again',
                      icon: Icons.refresh_rounded,
                      onPressed: _refreshData,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // ── STATS METRICS GRID ──
                  _buildStatsGrid(),
                  const SizedBox(height: 20),

                  // ── CHARTS SECTION ──
                  _buildChartsCard(),
                  const SizedBox(height: 20),

                  // ── LIVE TRACKING MAP ──
                  _buildLiveTrackingCard(),
                  const SizedBox(height: 20),

                  // ── FLEET OVERVIEW SECTION ──
                  _buildFleetSection(),
                  const SizedBox(height: 20),

                  // ── QUICK ACTIONS GRID ──
                  _buildQuickActions(),
                  const SizedBox(height: 20),

                  // ── RECENT ACTIVITIES ──
                  _buildRecentActivities(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. HEADER BAR ──
  Widget _buildHeader() {
    return _Glass(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: _Palette.redGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _Palette.red.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Admin Control Center',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _Palette.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _Palette.red.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _Palette.red.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _Palette.brightRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _Palette.brightRed.withOpacity(0.7),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w700,
                              color: _Palette.brightRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Manage buses, routes, drivers & system activity',
                  style: TextStyle(fontSize: 12, color: _Palette.textSecondary),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _refreshData,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _Palette.glassFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Palette.glassBorder),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: _Palette.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. STATS METRICS GRID ──
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Total Students',
                value: _studentCount?.toString() ?? '0',
                change: _studentChange ?? '+12% this month',
                icon: Icons.group_outlined,
                accent: _Palette.accentA,
                trend: _studentTrend,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Total Drivers',
                value: _driverCount?.toString() ?? '0',
                change: _driverChange ?? '+2 new drivers',
                icon: Icons.directions_bus_outlined,
                accent: _Palette.accentB,
                trend: _driverTrend,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Active Buses',
                value: '${_list.length}',
                change:
                    '${_list.where((b) => b['status'] == 'Active').length} on duty',
                icon: Icons.alt_route_rounded,
                accent: _Palette.accentD,
                trend: [10, 12, 14, 13, _list.length.toDouble()],
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'On-Time Rate',
                value: '98.4%',
                change: '+1.2% improvement',
                icon: Icons.verified_outlined,
                accent: _Palette.accentC,
                trend: [94, 95, 96, 97, 98.4],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color accent,
    required List<double> trend,
  }) {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              SizedBox(
                width: 45,
                height: 24,
                child: CustomPaint(
                  painter: _SparklinePainter(trend, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: _Palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _Palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: const TextStyle(fontSize: 11, color: _Palette.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 3. CHARTS CARD ──
  Widget _buildChartsCard() {
    return _Glass(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.red.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _Palette.red.withOpacity(0.35)),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: _Palette.brightRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bus Analytics & Activity Trends',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _Palette.textPrimary,
                      ),
                    ),
                    const Text(
                      'Weekly trips and route utilization analytics',
                      style: TextStyle(
                        fontSize: 11,
                        color: _Palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs header
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: TabBar(
              controller: _chartTabController,
              indicator: BoxDecoration(
                gradient: _Palette.redGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _Palette.red.withOpacity(0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: _Palette.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Weekly Rides'),
                Tab(text: 'Fleet Distribution'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 180,
            child: TabBarView(
              controller: _chartTabController,
              children: [_buildAreaChart(), _buildFleetBarChart()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChart() {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _AreaChartPainter(
              data: _weeklyRides,
              labels: _weekDays,
              lineColor: _Palette.brightRed,
              fillColor: _Palette.red.withOpacity(0.18),
              gridColor: _Palette.divider,
              dotColor: _Palette.bg,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays
              .map(
                (d) => Text(
                  d,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _Palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFleetBarChart() {
    final routes = ['R-01', 'R-02', 'R-03', 'R-04', 'R-05'];
    final counts = [42, 38, 55, 30, 48];

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarChartPainter(
              data: counts,
              labels: routes,
              barColor: _Palette.darkRed,
              accentColor: _Palette.brightRed,
              gridColor: _Palette.divider,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: routes
              .map(
                (r) => Text(
                  r,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _Palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ── 4. LIVE TRACKING MAP ──
  Widget _buildLiveTrackingCard() {
    final r = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_Palette.glassFill, _Palette.glassFillSoft],
              ),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: _Palette.redGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Bus Fleet Tracking',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _Palette.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_list.length} buses currently transmitting location',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _Palette.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _Palette.red.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _Palette.red.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          '${_list.where((b) => b['status'] == 'Active').length} Active',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _Palette.brightRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ClipRRect(
                  child: SizedBox(
                    height: 240,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(30.0472, 31.2403),
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapService.getTileUrl(_mapTheme),
                          subdomains: MapService.subdomains,
                          userAgentPackageName: 'com.example.safeway',
                        ),
                        MarkerLayer(
                          markers: _list.map((bus) {
                            try {
                              double lat = bus['latitude'] is double
                                  ? bus['latitude']
                                  : double.tryParse(
                                          bus['latitude']?.toString() ??
                                              '30.0472',
                                        ) ??
                                        30.0472;
                              double lng = bus['longitude'] is double
                                  ? bus['longitude']
                                  : double.tryParse(
                                          bus['longitude']?.toString() ??
                                              '31.2403',
                                        ) ??
                                        31.2403;
                              String busCode =
                                  bus['id']?.toString() ?? 'BUS-101';
                              bool isLive =
                                  (bus['status']?.toString() ?? 'Active')
                                      .toLowerCase() ==
                                  'active';

                              return Marker(
                                point: LatLng(lat, lng),
                                width: 80,
                                height: 70,
                                child: MapService.buildBusMarker(
                                  busCode: busCode,
                                  isLive: isLive,
                                ),
                              );
                            } catch (e) {
                              return Marker(
                                point: const LatLng(30.0472, 31.2403),
                                width: 60,
                                height: 36,
                                child: Container(),
                              );
                            }
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    children: [
                      _mapThemePill(MapThemeMode.voyager, 'Voyager'),
                      const SizedBox(width: 4),
                      _mapThemePill(MapThemeMode.light, 'Light'),
                      const SizedBox(width: 4),
                      _mapThemePill(MapThemeMode.dark, 'Dark'),
                      const Spacer(),
                      InkWell(
                        onTap: _fitAllBuses,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.center_focus_strong_rounded,
                              size: 14,
                              color: _Palette.brightRed,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Center Fleet',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _Palette.brightRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _refreshData,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              size: 14,
                              color: _Palette.brightRed,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _Palette.brightRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapThemePill(MapThemeMode mode, String label) {
    final isSelected = _mapTheme == mode;
    return GestureDetector(
      onTap: () => setState(() => _mapTheme = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          gradient: isSelected ? _Palette.redGradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: _Palette.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _Palette.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── 5. FLEET OVERVIEW SECTION ──
  Widget _buildFleetSection() {
    return _Glass(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Bus Fleet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _Palette.textPrimary,
                ),
              ),
              // Filter chips
              Row(
                children: ['All', 'Active', 'Idle'].map((filter) {
                  final selected = _busFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _busFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? _Palette.redGradient : null,
                        color: selected ? null : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? null
                            : Border.all(color: _Palette.glassBorder),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : _Palette.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_filteredBuses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No buses match the filter.',
                  style: TextStyle(color: _Palette.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Column(
              children: _filteredBuses
                  .map((bus) => _buildBusCard(bus))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    String status = bus['status']?.toString() ?? 'Active';
    bool isActive = status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _Palette.red.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.red.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: _Palette.brightRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bus['id']?.toString() ?? 'BUS-000',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _Palette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _Palette.red.withOpacity(0.16)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? _Palette.red.withOpacity(0.35)
                              : _Palette.glassBorder,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? _Palette.brightRed
                              : _Palette.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: _Palette.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        bus['driver']?.toString() ?? 'Unassigned',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _Palette.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.alt_route_outlined,
                      size: 12,
                      color: _Palette.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        bus['route']?.toString() ?? 'No route',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _Palette.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Occupancy',
                style: TextStyle(fontSize: 10, color: _Palette.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                bus['occupancy']?.toString() ?? '0/40',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _Palette.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 6. QUICK ACTIONS GRID ──
  Widget _buildQuickActions() {
    return _Glass(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _Palette.redGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.widgets_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Admin Management Actions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _Palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  title: 'Manage Students',
                  subtitle: 'Students & bus stops',
                  icon: Icons.group_outlined,
                  accent: _Palette.accentA,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageStudentsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionButton(
                  title: 'Manage Drivers',
                  subtitle: 'Drivers & bus assign',
                  icon: Icons.directions_bus_outlined,
                  accent: _Palette.accentB,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageDriversScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  title: 'Manage Routes',
                  subtitle: 'Routes & stations',
                  icon: Icons.alt_route_outlined,
                  accent: _Palette.accentD,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageRoutesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionButton(
                  title: 'System Logs',
                  subtitle: 'Recent system logs',
                  icon: Icons.history_rounded,
                  accent: _Palette.accentC,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accent, size: 16),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: accent.withOpacity(0.8),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _Palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: _Palette.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── 7. RECENT ACTIVITIES ──
  Widget _buildRecentActivities() {
    return const RecentActivitiesCard();
  }

  // ── HELPERS (unchanged logic) ──
  List<double> _generateStudentTrend(int studentCount) {
    if (studentCount <= 0) return [0, 0, 0, 0, 0];
    return [
      max(0, studentCount - 12).toDouble(),
      max(0, studentCount - 8).toDouble(),
      max(0, studentCount - 5).toDouble(),
      max(0, studentCount - 2).toDouble(),
      studentCount.toDouble(),
    ];
  }

  List<double> _generateDriverTrend(int driverCount) {
    if (driverCount <= 0) return [0, 0, 0, 0, 0];
    return [
      max(0, driverCount - 3).toDouble(),
      max(0, driverCount - 2).toDouble(),
      max(0, driverCount - 1).toDouble(),
      driverCount.toDouble(),
      (driverCount + 1).toDouble(),
    ];
  }
}

// ── CUSTOM AREA CHART PAINTER ──
class _AreaChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color dotColor;

  _AreaChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = max(1.0, maxVal - minVal);
    final stepX = size.width / (data.length - 1);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = ui.Path();
    final fillPath = ui.Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = (data[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 20)) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    final outerDotPaint = Paint()..color = dotColor;
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = (data[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 20)) - 10;

      canvas.drawCircle(Offset(x, y), 5, outerDotPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── CUSTOM BAR CHART PAINTER ──
class _BarChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> labels;
  final Color barColor;
  final Color accentColor;
  final Color gridColor;

  _BarChartPainter({
    required this.data,
    required this.labels,
    required this.barColor,
    required this.accentColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(max).toDouble();
    final barWidth = size.width / (data.length * 2);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < data.length; i++) {
      final x = (i * 2 + 0.5) * barWidth;
      final heightFactor = data[i] / maxVal;
      final barHeight = heightFactor * (size.height - 20);
      final y = size.height - barHeight;

      final RRect barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );

      final barPaint = Paint()..color = (i % 2 == 0) ? barColor : accentColor;
      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── SPARKLINE PAINTER ──
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter(this.data, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minValue = data.reduce(min);
    final maxValue = data.reduce(max);
    final range = max(1.0, maxValue - minValue);
    final stepX = size.width / (data.length - 1);

    final path = ui.Path();

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = (data[i] - minValue) / range;
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
