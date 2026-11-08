import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:safeway/services/manage_routes_service.dart';

// ─────────────────────────────────────────────────────────────
//  SafeWay design system — dark glass + red accent
//  Identical tokens to Student_Man.dart / Manage_Drivers.dart
// ─────────────────────────────────────────────────────────────
class _Palette {
  static const bg = Color(0xFF070708);
  static const bg2 = Color(0xFF101012);
  static const surface = Color(0xFF18181B);

  static const red = Color(0xFFD32F2F);
  static const brightRed = Color(0xFFEF4444);
  static const darkRed = Color(0xFF991B1B);
  static const burgundy = Color(0xFF65171B);
  static const roseRed = Color(0xFFB0343B);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB8B8BC);
  static const textMuted = Color(0xFF77777D);

  static const glassFill = Color(0x14FFFFFF);
  static const glassFillSoft = Color(0x08FFFFFF);
  static const glassBorder = Color(0x2AFFFFFF);
  static const inputFill = Color(0x0FFFFFFF);
  static const divider = Color(0x1AFFFFFF);

  static const redGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [darkRed, red],
  );

  static const avatarColors = [
    brightRed,
    red,
    burgundy,
    roseRed,
    Color(0xFF8A8A90),
  ];
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
        Positioned(top: -110, right: -90, child: _glow(300, _Palette.red, 0.22)),
        Positioned(top: 300, left: -150, child: _glow(320, _Palette.burgundy, 0.32)),
        Positioned(
          bottom: -130,
          right: -110,
          child: _glow(300, _Palette.darkRed, 0.26),
        ),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
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
  final VoidCallback? onPressed;
  final bool expand;

  const _RedButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      decoration: BoxDecoration(
        gradient: _Palette.redGradient,
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
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
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _GhostButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _Palette.textSecondary, size: 15),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: _Palette.textSecondary,
                    fontWeight: FontWeight.w600,
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

// ── DATA MODELS ──────────────────────────────────────────────────────────────

class RouteModel {
  final int id;
  final String routeId;
  final String name;
  final String busId;
  final String driver;
  final List<String> drivers;
  final List<int> driverIds;
  final int stops;
  final String status;

  const RouteModel({
    required this.id,
    required this.routeId,
    required this.name,
    required this.busId,
    required this.driver,
    this.drivers = const [],
    this.driverIds = const [],
    required this.stops,
    required this.status,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory RouteModel.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] ?? 0;
    final int parsedId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawDrivers = j['drivers'];
    final List<String> parsedDrivers = rawDrivers is List
        ? rawDrivers.map((e) => e.toString()).toList()
        : [];

    final rawDriverIds = j['driverIds'];
    final List<int> parsedDriverIds = rawDriverIds is List
        ? rawDriverIds
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((id) => id > 0)
            .toList()
        : [];

    return RouteModel(
      id: parsedId,
      routeId: 'RT${parsedId.toString().padLeft(3, '0')}',
      name: (j['name'] ?? '').toString(),
      busId: (j['busId'] ?? 'Not assigned').toString(),
      driver: (j['driver'] ?? 'Not assigned').toString(),
      drivers: parsedDrivers,
      driverIds: parsedDriverIds,
      stops: int.tryParse((j['stops'] ?? '0').toString()) ?? 0,
      status: (j['status'] ?? 'Active').toString(),
    );
  }

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'RT';
  }
}

class DriverOption {
  final int id;
  final String name;
  final String busNumber;
  final int? currentRouteId;

  DriverOption({
    required this.id,
    required this.name,
    required this.busNumber,
    this.currentRouteId,
  });

  factory DriverOption.fromJson(Map<String, dynamic> j) {
    return DriverOption(
      id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
      name: (j['name'] ?? '').toString(),
      busNumber: (j['busNumber'] ?? 'No bus').toString(),
      currentRouteId: j['currentRouteId'] != null
          ? (j['currentRouteId'] is int
              ? j['currentRouteId']
              : int.tryParse(j['currentRouteId'].toString()))
          : null,
    );
  }
}

class BusStation {
  final String id;
  final String name;
  final String address;
  final int students;
  final String scheduledTime;
  final List<String> routes;

  const BusStation({
    required this.id,
    required this.name,
    required this.address,
    required this.students,
    required this.scheduledTime,
    required this.routes,
  });

  factory BusStation.fromJson(Map<String, dynamic> j) {
    return BusStation(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      students: int.tryParse((j['students'] ?? '0').toString()) ?? 0,
      scheduledTime: (j['scheduledTime'] ?? '').toString(),
      routes: (j['routes'] as List<dynamic>? ?? []).map((x) => x.toString()).toList(),
    );
  }
}

// ── SCREEN ───────────────────────────────────────────────────────────────────

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  final _manageRoutesService = ManageRoutesService();

  List<RouteModel> _allRoutes = [];
  List<RouteModel> _filtered = [];
  List<BusStation> _stations = [];
  bool _loading = true;
  String _searchQuery = '';

  final _searchCtrl = TextEditingController();

  int get _activeCount => _allRoutes.where((r) => r.isActive).length;
  int get _inactiveCount => _allRoutes.where((r) => !r.isActive).length;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _manageRoutesService.fetchRoutes(),
        _manageRoutesService.fetchStations(),
      ]);

      if (!mounted) return;

      final routes = results[0]
          .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final stations = results[1]
          .map((e) => BusStation.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _allRoutes = routes;
        _stations = stations;
        _filtered = List.from(_allRoutes);
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      final q = _searchQuery.toLowerCase();
      _filtered = _allRoutes.where((r) {
        return q.isEmpty ||
            r.name.toLowerCase().contains(q) ||
            r.routeId.toLowerCase().contains(q) ||
            r.busId.toLowerCase().contains(q) ||
            r.driver.toLowerCase().contains(q);
      }).toList();
    });
  }

  Color _avatarColor(String initials) {
    if (initials.isEmpty) return _Palette.avatarColors[0];
    final colors = _Palette.avatarColors;
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _Palette.textPrimary;
      case 'inactive':
        return _Palette.textMuted;
      default:
        return _Palette.brightRed;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.white.withOpacity(0.10);
      case 'inactive':
        return Colors.white.withOpacity(0.04);
      default:
        return _Palette.brightRed.withOpacity(0.16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _Palette.brightRed,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: _Palette.brightRed,
                        backgroundColor: _Palette.surface,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExportButton(),
                              const SizedBox(height: 16),
                              _buildFiltersCard(),
                              const SizedBox(height: 16),
                              _buildRouteTable(),
                              const SizedBox(height: 16),
                              _buildSummaryCards(),
                              const SizedBox(height: 20),
                              _buildStationsSection(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _Palette.bg2,
        border: Border(bottom: BorderSide(color: _Palette.divider)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _Palette.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: _Palette.redGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _Palette.red.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Routes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Palette.textPrimary,
                  ),
                ),
                Text(
                  '${_allRoutes.length} routes • ${_stations.length} stations',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── EXPORT / ADD BUTTONS CARD ─────────────────────────────────────────────
  Widget _buildExportButton() {
    return _Glass(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GhostButton(
            label: 'Export',
            icon: Icons.upload_outlined,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exporting route data...')),
            ),
          ),
          const SizedBox(width: 8),
          _RedButton(
            label: 'Add Route',
            icon: Icons.add,
            onPressed: () => _showAddRouteDialog(),
          ),
        ],
      ),
    );
  }

  // ── FILTERS CARD ─────────────────────────────────────────────────────────────
  Widget _buildFiltersCard() {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Routes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _Palette.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              style: const TextStyle(fontSize: 14, color: _Palette.textPrimary),
              cursorColor: _Palette.brightRed,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, bus, or driver...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: _Palette.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: _Palette.textMuted,
                  size: 18,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                        child: const Icon(
                          Icons.close,
                          color: _Palette.textMuted,
                          size: 16,
                        ),
                      )
                    : null,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ROUTE TABLE ───────────────────────────────────────────────────────────────
  Widget _buildRouteTable() {
    final r = BorderRadius.circular(20);
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
                // Table header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: _Palette.redGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _Palette.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Route Records',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Showing ${_filtered.length} of ${_allRoutes.length} routes',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                          child: const Text(
                            'Clear search',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Column labels
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'ROUTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'STOPS / DRIVER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(
                          'ACTIONS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: _Palette.divider),

                // Rows
                if (_filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No routes match your search.',
                        style: TextStyle(fontSize: 13, color: _Palette.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: _Palette.divider),
                    itemBuilder: (_, i) => _buildRouteRow(_filtered[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteRow(RouteModel route) {
    final color = _avatarColor(route.initials);

    return InkWell(
      onTap: () => _showRouteDetail(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar + name + route ID
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.alt_route,
                        color: color,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _Palette.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_bus_outlined,
                              size: 10,
                              color: _Palette.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                route.busId,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _Palette.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stops + driver
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: _Palette.brightRed,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${route.stops} stops',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _Palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    route.driver,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _Palette.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(route.status),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusColor(route.status).withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    route.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(route.status),
                    ),
                  ),
                ),
              ),
            ),

            // Actions: Edit and Delete
            SizedBox(
              width: 76,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: _Palette.textSecondary),
                    tooltip: 'Edit route',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    onPressed: () => _showEditRouteDialog(route),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: _Palette.brightRed),
                    tooltip: 'Delete route',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    onPressed: () => _confirmDeleteRoute(route),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY CARDS ─────────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Column(
      children: [
        _summaryCard(
          label: 'Active Routes',
          count: _activeCount,
          color: _Palette.textPrimary,
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          label: 'Inactive Routes',
          count: _inactiveCount,
          color: _Palette.roseRed,
          icon: Icons.cancel_outlined,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          label: 'Total Routes',
          count: _allRoutes.length,
          color: _Palette.brightRed,
          icon: Icons.alt_route_outlined,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_Palette.glassFill, _Palette.glassFillSoft],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _Palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Icon(icon, color: color, size: 22),
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

  // ── BUS STATIONS SECTION ─────────────────────────────────────────────────────
  Widget _buildStationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF3C0D10), _Palette.burgundy],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _Palette.burgundy.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus Stations & Stops',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'All pickup and drop-off points',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${_stations.length} stations',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_stations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No stations found.',
                style: TextStyle(color: _Palette.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildStationCard(_stations[i]),
          ),
      ],
    );
  }

  Widget _buildStationCard(BusStation station) {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF3C0D10), _Palette.burgundy],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _Palette.textPrimary,
                      ),
                    ),
                    Text(
                      station.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Palette.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${station.students} students',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  Text(
                    station.scheduledTime,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _Palette.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (station.routes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: _Palette.divider),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: station.routes.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _Palette.red.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _Palette.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    r,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _Palette.brightRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: _GhostButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit ${station.name}')),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: _GhostButton(
                    label: 'Map',
                    icon: Icons.map_outlined,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Map for ${station.name}')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── DETAIL BOTTOM SHEET ───────────────────────────────────────────────────────
  void _showRouteDetail(RouteModel route) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.bg2.withOpacity(0.94),
              border: const Border(top: BorderSide(color: _Palette.glassBorder)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _Palette.redGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _Palette.red.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.alt_route, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _Palette.textPrimary,
                            ),
                          ),
                          Text(
                            'ID: ${route.routeId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _Palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBg(route.status),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor(route.status).withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        route.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(route.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _detailRow(Icons.directions_bus_outlined, 'Bus ID', route.busId),
                _detailRow(Icons.person_outline, 'Driver', route.driver),
                _detailRow(
                  Icons.location_on_outlined,
                  'Stops',
                  '${route.stops} stop${route.stops == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GhostButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteRoute(route);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: _RedButton(
                          label: 'Edit Route',
                          icon: Icons.edit_outlined,
                          expand: true,
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditRouteDialog(route);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _Palette.textMuted),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: _Palette.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _Palette.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── DELETE CONFIRM ────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteRoute(RouteModel route) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _Palette.glassBorder),
        ),
        title: const Text(
          'Delete Route',
          style: TextStyle(
            color: _Palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${route.name}"?',
          style: const TextStyle(color: _Palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _Palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: _Palette.brightRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await _manageRoutesService.deleteRoute(route.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route "${route.name}" deleted successfully'),
          backgroundColor: _Palette.darkRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete route: $e'),
          backgroundColor: _Palette.darkRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── ADD ROUTE ─────────────────────────────────────────────────────────────────
  void _showAddRouteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRouteSheet(
        onAdd: (name, driverIds, driverNames, stops) async {
          Navigator.pop(context);
          try {
            await _manageRoutesService.addRoute(
              name: name,
              driverIds: driverIds,
              driverNames: driverNames,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Route "$name" added successfully'),
                backgroundColor: _Palette.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _loadData();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add route: $e'),
                backgroundColor: _Palette.darkRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  // ── EDIT ROUTE ────────────────────────────────────────────────────────────────
  void _showEditRouteDialog(RouteModel route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditRouteSheet(
        route: route,
        onEdit: (name, driverIds, driverNames, stops) async {
          Navigator.pop(context);
          try {
            await _manageRoutesService.updateRoute(
              route.id,
              name: name,
              driverIds: driverIds,
              driverNames: driverNames,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Route "$name" updated successfully'),
                backgroundColor: _Palette.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _loadData();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update route: $e'),
                backgroundColor: _Palette.darkRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}

// ── ADD ROUTE BOTTOM SHEET ────────────────────────────────────────────────────
class _AddRouteSheet extends StatefulWidget {
  final void Function(
    String name,
    List<int> driverIds,
    List<String> driverNames,
    String stops,
  ) onAdd;

  const _AddRouteSheet({required this.onAdd});

  @override
  State<_AddRouteSheet> createState() => _AddRouteSheetState();
}

class _AddRouteSheetState extends State<_AddRouteSheet> {
  final _nameCtrl = TextEditingController();
  final _stopsCtrl = TextEditingController();
  final _manageRoutesService = ManageRoutesService();

  List<DriverOption> _allDrivers = [];
  final Set<int> _selectedDriverIds = {};
  bool _loadingDrivers = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stopsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    try {
      final raw = await _manageRoutesService.fetchDrivers();
      if (!mounted) return;
      setState(() {
        _allDrivers = raw
            .map((e) => DriverOption.fromJson(e as Map<String, dynamic>))
            .toList();
        _loadingDrivers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDrivers = false);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route name is required'),
          backgroundColor: _Palette.darkRed,
        ),
      );
      return;
    }

    final selectedNames = _allDrivers
        .where((d) => _selectedDriverIds.contains(d.id))
        .map((d) => d.name)
        .toList();

    widget.onAdd(
      name,
      _selectedDriverIds.toList(),
      selectedNames,
      _stopsCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.bg2.withOpacity(0.94),
              border: const Border(top: BorderSide(color: _Palette.glassBorder)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add New Route',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set route name and choose the driver(s)',
                    style: TextStyle(fontSize: 13, color: _Palette.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _glassField(
                    controller: _nameCtrl,
                    hint: 'Route Name (e.g. Route F - Campus)',
                    icon: Icons.alt_route_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDriverSelector(
                    allDrivers: _allDrivers,
                    selectedDriverIds: _selectedDriverIds,
                    onToggle: (id) {
                      setState(() {
                        if (_selectedDriverIds.contains(id)) {
                          _selectedDriverIds.remove(id);
                        } else {
                          _selectedDriverIds.add(id);
                        }
                      });
                    },
                    loading: _loadingDrivers,
                  ),
                  const SizedBox(height: 12),
                  _glassField(
                    controller: _stopsCtrl,
                    hint: 'Number of Stops (optional)',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _RedButton(
                      label: 'Add Route',
                      icon: Icons.add,
                      expand: true,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── EDIT ROUTE BOTTOM SHEET ───────────────────────────────────────────────────
class _EditRouteSheet extends StatefulWidget {
  final RouteModel route;
  final void Function(
    String name,
    List<int> driverIds,
    List<String> driverNames,
    String stops,
  ) onEdit;

  const _EditRouteSheet({required this.route, required this.onEdit});

  @override
  State<_EditRouteSheet> createState() => _EditRouteSheetState();
}

class _EditRouteSheetState extends State<_EditRouteSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _stopsCtrl;
  final _manageRoutesService = ManageRoutesService();

  List<DriverOption> _allDrivers = [];
  final Set<int> _selectedDriverIds = {};
  bool _loadingDrivers = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.route.name);
    _stopsCtrl = TextEditingController(text: '${widget.route.stops}');
    _selectedDriverIds.addAll(widget.route.driverIds);
    _loadDrivers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stopsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    try {
      final raw = await _manageRoutesService.fetchDrivers();
      if (!mounted) return;
      setState(() {
        _allDrivers = raw
            .map((e) => DriverOption.fromJson(e as Map<String, dynamic>))
            .toList();

        // Also check by name matching if driverIds was empty
        if (_selectedDriverIds.isEmpty && widget.route.drivers.isNotEmpty) {
          for (final d in _allDrivers) {
            if (widget.route.drivers.contains(d.name)) {
              _selectedDriverIds.add(d.id);
            }
          }
        }

        _loadingDrivers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDrivers = false);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route name is required'),
          backgroundColor: _Palette.darkRed,
        ),
      );
      return;
    }

    final selectedNames = _allDrivers
        .where((d) => _selectedDriverIds.contains(d.id))
        .map((d) => d.name)
        .toList();

    widget.onEdit(
      name,
      _selectedDriverIds.toList(),
      selectedNames,
      _stopsCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.bg2.withOpacity(0.94),
              border: const Border(top: BorderSide(color: _Palette.glassBorder)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Route',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.route.name,
                    style: const TextStyle(fontSize: 13, color: _Palette.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _glassField(
                    controller: _nameCtrl,
                    hint: 'Route Name',
                    icon: Icons.alt_route_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDriverSelector(
                    allDrivers: _allDrivers,
                    selectedDriverIds: _selectedDriverIds,
                    onToggle: (id) {
                      setState(() {
                        if (_selectedDriverIds.contains(id)) {
                          _selectedDriverIds.remove(id);
                        } else {
                          _selectedDriverIds.add(id);
                        }
                      });
                    },
                    loading: _loadingDrivers,
                  ),
                  const SizedBox(height: 12),
                  _glassField(
                    controller: _stopsCtrl,
                    hint: 'Number of Stops',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _RedButton(
                      label: 'Save Changes',
                      icon: Icons.check,
                      expand: true,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── DRIVER MULTI-SELECT SELECTOR ──────────────────────────────────────────────
Widget _buildDriverSelector({
  required List<DriverOption> allDrivers,
  required Set<int> selectedDriverIds,
  required void Function(int driverId) onToggle,
  required bool loading,
}) {
  if (loading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.glassBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _Palette.brightRed,
          ),
        ),
      ),
    );
  }

  if (allDrivers.isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _Palette.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.glassBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: _Palette.textMuted),
          SizedBox(width: 8),
          Text(
            'No drivers available in system',
            style: TextStyle(color: _Palette.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _Palette.inputFill,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selectedDriverIds.isNotEmpty
            ? _Palette.roseRed.withOpacity(0.5)
            : _Palette.glassBorder,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_outlined, size: 16, color: _Palette.textSecondary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Assign Drivers (Choose one or many)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _Palette.textPrimary,
                ),
              ),
            ),
            if (selectedDriverIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _Palette.brightRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _Palette.brightRed.withOpacity(0.4)),
                ),
                child: Text(
                  '${selectedDriverIds.length} selected',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _Palette.brightRed,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allDrivers.map((driver) {
            final isSelected = selectedDriverIds.contains(driver.id);
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onToggle(driver.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [_Palette.burgundy, _Palette.darkRed],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _Palette.brightRed
                        : Colors.white.withOpacity(0.12),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _Palette.red.withOpacity(0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.person_outline,
                      size: 15,
                      color: isSelected ? Colors.white : _Palette.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : _Palette.textPrimary,
                      ),
                    ),
                    if (driver.busNumber.isNotEmpty && driver.busNumber != 'No bus') ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${driver.busNumber})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white.withOpacity(0.85)
                              : _Palette.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// ── GLASS TEXT FIELD HELPER ───────────────────────────────────────────────────
Widget _glassField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  void Function(String)? onChanged,
}) {
  return Container(
    decoration: BoxDecoration(
      color: _Palette.inputFill,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _Palette.glassBorder),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: _Palette.textPrimary, fontSize: 14),
      cursorColor: _Palette.brightRed,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _Palette.textMuted),
        prefixIcon: Icon(icon, color: _Palette.textMuted, size: 18),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );
}