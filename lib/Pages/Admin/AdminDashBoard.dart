import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeway/Constant/Constant_Color.dart';
import 'package:safeway/Pages/Admin/Manage_Drivers.dart';
import 'package:safeway/Pages/Admin/Route_Man.dart' show ManageRoutesScreen;
import 'package:safeway/Pages/Admin/Student_Man.dart' show ManageStudentsScreen;
import 'package:safeway/Pages/Admin/RecentActivitiesCard.dart';
import 'package:safeway/services/admin_service.dart';
import 'package:safeway/services/map_service.dart';

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
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

        _studentCount = int.tryParse(studentStat['value']?.toString() ?? '') ?? 0;
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
    return _list.where((b) => (b['status']?.toString() ?? '').toLowerCase() == _busFilter.toLowerCase()).toList();
  }

  MapThemeMode _mapTheme = MapThemeMode.voyager;

  void _fitAllBuses() {
    if (_list.isEmpty) return;
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (var bus in _list) {
      double lat = bus['latitude'] is double
          ? bus['latitude']
          : double.tryParse(bus['latitude']?.toString() ?? '30.0472') ?? 30.0472;
      double lng = bus['longitude'] is double
          ? bus['longitude']
          : double.tryParse(bus['longitude']?.toString() ?? '31.2403') ?? 31.2403;
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
      return Scaffold(
        backgroundColor: AppColors.bgGradientStart,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentGreen),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.bgGradientStart,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[400]),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.softBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShadcnHeader(),
                const SizedBox(height: 20),

                // ── STATS METRICS GRID ──
                _buildStatsGrid(),
                const SizedBox(height: 20),

                // ── SHADCN CHARTS SECTION ──
                _buildShadcnChartsCard(),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. HEADER BAR (SHADCN STYLE) ──
  Widget _buildShadcnHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.badgeDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Manage buses, routes, drivers & system activity',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.refresh_rounded, color: AppColors.darkNavy, size: 20),
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
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
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
                iconColor: AppColors.accentGreen,
                iconBg: AppColors.badgeBg,
                trend: _driverTrend,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Active Buses',
                value: '${_list.length}',
                change: '${_list.where((b) => b['status'] == 'Active').length} on duty',
                icon: Icons.alt_route_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
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
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF3E8FF),
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
    required Color iconColor,
    required Color iconBg,
    required List<double> trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              SizedBox(
                width: 45,
                height: 24,
                child: CustomPaint(
                  painter: _StudentSparklinePainter(trend, color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 3. SHADCN CHARTS CARD ──
  Widget _buildShadcnChartsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppColors.accentGreen, size: 20),
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
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const Text(
                      'Weekly trips and route utilization analytics',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shadcn Tabs header
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _chartTabController,
              indicator: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                  ),
                ],
              ),
              labelColor: AppColors.darkNavy,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              children: [
                // Tab 1: Area Line Chart
                _buildAreaChart(),
                // Tab 2: Bar Chart
                _buildFleetBarChart(),
              ],
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
            painter: _ShadcnAreaChartPainter(
              data: _weeklyRides,
              labels: _weekDays,
              lineColor: AppColors.accentGreen,
              fillColor: AppColors.badgeBg.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays
              .map((d) => Text(
                    d,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ))
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
            painter: _ShadcnBarChartPainter(
              data: counts,
              labels: routes,
              barColor: AppColors.darkNavy,
              accentColor: AppColors.accentGreen,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: routes
              .map((r) => Text(
                    r,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── 4. LIVE TRACKING MAP ──
  Widget _buildLiveTrackingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined, color: Colors.white, size: 18),
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_list.length} buses currently transmitting location',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_list.where((b) => b['status'] == 'Active').length} Active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
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
                            : double.tryParse(bus['latitude']?.toString() ?? '30.0472') ?? 30.0472;
                        double lng = bus['longitude'] is double
                            ? bus['longitude']
                            : double.tryParse(bus['longitude']?.toString() ?? '31.2403') ?? 31.2403;
                        String busCode = bus['id']?.toString() ?? 'BUS-101';
                        bool isLive = (bus['status']?.toString() ?? 'Active').toLowerCase() == 'active';

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inputBg.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
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
                      Icon(Icons.center_focus_strong_rounded, size: 14, color: AppColors.accentGreen),
                      SizedBox(width: 4),
                      Text(
                        'Center Fleet',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGreen,
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
                      Icon(Icons.sync_rounded, size: 14, color: AppColors.accentGreen),
                      SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGreen,
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
    );
  }

  Widget _mapThemePill(MapThemeMode mode, String label) {
    final isSelected = _mapTheme == mode;
    return GestureDetector(
      onTap: () => setState(() => _mapTheme = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkNavy : AppColors.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── 5. FLEET OVERVIEW SECTION ──
  Widget _buildFleetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.darkNavy : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? Colors.white : AppColors.textSecondary,
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
                child: Text('No buses match the filter.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            )
          else
            Column(
              children: _filteredBuses.map((bus) => _buildShadcnBusCard(bus)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildShadcnBusCard(Map<String, dynamic> bus) {
    Color busColor = _hexToColor(bus['color']?.toString() ?? '#2E7D5B');
    String status = bus['status']?.toString() ?? 'Active';
    bool isActive = status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(Icons.directions_bus_rounded, color: busColor, size: 20),
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
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.badgeBg : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.accentGreen : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        bus['driver']?.toString() ?? 'Unassigned',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.alt_route_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        bus['route']?.toString() ?? 'No route',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                bus['occupancy']?.toString() ?? '0/40',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.widgets_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Admin Management Actions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
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
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageStudentsScreen()),
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
                  color: AppColors.accentGreen,
                  bg: AppColors.badgeBg,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageDriversScreen()),
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
                  color: const Color(0xFFD97706),
                  bg: const Color(0xFFFEF3C7),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageRoutesScreen()),
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
                  color: const Color(0xFF7C3AED),
                  bg: const Color(0xFFF3E8FF),
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
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
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
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Icon(Icons.arrow_forward_rounded, color: color.withOpacity(0.7), size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

  // ── HELPERS ──
  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return AppColors.accentGreen;
    }
    try {
      final buffer = StringBuffer();
      String hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        buffer.write('ff');
        buffer.write(hex);
      } else if (hex.length == 8) {
        buffer.write(hex);
      } else {
        return AppColors.accentGreen;
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return AppColors.accentGreen;
    }
  }

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

// ── CUSTOM SHADCN AREA CHART PAINTER ──
class _ShadcnAreaChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color fillColor;

  _ShadcnAreaChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = max(1.0, maxVal - minVal);
    final stepX = size.width / (data.length - 1);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = AppColors.divider.withOpacity(0.5)
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

    // Draw area fill
    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw data point dots
    final dotPaint = Paint()..color = AppColors.darkNavy;
    final outerDotPaint = Paint()..color = Colors.white;
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

// ── CUSTOM SHADCN BAR CHART PAINTER ──
class _ShadcnBarChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> labels;
  final Color barColor;
  final Color accentColor;

  _ShadcnBarChartPainter({
    required this.data,
    required this.labels,
    required this.barColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(max).toDouble();
    final barWidth = size.width / (data.length * 2);

    final gridPaint = Paint()
      ..color = AppColors.divider.withOpacity(0.5)
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

      final barPaint = Paint()
        ..color = (i % 2 == 0) ? barColor : accentColor;
      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── SPARKLINE PAINTER ──
class _StudentSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _StudentSparklinePainter(this.data, {required this.color});

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
