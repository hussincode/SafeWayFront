import 'package:flutter/material.dart';

// ── DATA MODELS ──
class RouteModel {
  final String id;
  final String name;
  final String busId;
  final String driver;
  final int stops;
  final String status;

  const RouteModel({
    required this.id,
    required this.name,
    required this.busId,
    required this.driver,
    required this.stops,
    required this.status,
  });
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
}

// ── SCREEN ──
class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();

  String _searchQuery = '';
  String _filterQuery = '';

  // ── MOCK DATA ──
  final List<RouteModel> _allRoutes = const [
    RouteModel(id: 'RT-001', name: 'Route A - Downtown',  busId: 'BUS-101', driver: 'Michael Davis',  stops: 6, status: 'Active'),
    RouteModel(id: 'RT-002', name: 'Route B - Suburbs',   busId: 'BUS-102', driver: 'Sarah Wilson',   stops: 5, status: 'Active'),
    RouteModel(id: 'RT-003', name: 'Route C - Eastside',  busId: 'BUS-103', driver: 'James Carter',   stops: 7, status: 'Active'),
    RouteModel(id: 'RT-004', name: 'Route D - Westside',  busId: 'BUS-104', driver: 'Emily Hassan',   stops: 4, status: 'Inactive'),
    RouteModel(id: 'RT-005', name: 'Route E - Northside', busId: 'BUS-105', driver: 'Omar Khalil',    stops: 5, status: 'Active'),
  ];

  final List<BusStation> _stations = const [
    BusStation(id: 'ST-001', name: 'Main Street Station', address: '123 Main Street, Downtown',   students: 8,  scheduledTime: '07:15 AM', routes: ['Route A - Downtown', 'Route C - Eastside']),
    BusStation(id: 'ST-002', name: 'Oak Street Station',  address: '456 Oak Street, Suburbs',     students: 6,  scheduledTime: '07:30 AM', routes: ['Route B - Suburbs']),
    BusStation(id: 'ST-003', name: 'Park Avenue Stop',    address: '789 Park Ave, Eastside',      students: 12, scheduledTime: '07:45 AM', routes: ['Route C - Eastside', 'Route E - Northside']),
    BusStation(id: 'ST-004', name: 'Central Hub',         address: '10 Central Blvd, Midtown',    students: 15, scheduledTime: '07:00 AM', routes: ['Route A - Downtown', 'Route B - Suburbs']),
    BusStation(id: 'ST-005', name: 'North Gate Station',  address: '55 North Gate Rd, Northside', students: 5,  scheduledTime: '08:00 AM', routes: ['Route E - Northside']),
  ];

  List<RouteModel> get _filteredRoutes => _allRoutes.where((r) {
    final q = _searchQuery.toLowerCase();
    final matchSearch = q.isEmpty ||
        r.name.toLowerCase().contains(q) ||
        r.busId.toLowerCase().contains(q) ||
        r.driver.toLowerCase().contains(q);
    final matchFilter = _filterQuery.isEmpty ||
        r.name.toLowerCase().contains(_filterQuery.toLowerCase());
    return matchSearch && matchFilter;
  }).toList();

  // ── COLORS ──
  static const _green     = Color(0xFF16A34A);
  static const _greenDark = Color(0xFF15803D);
  static const _blue      = Color(0xFF3B5BDB);
  static const _blueDark  = Color(0xFF2F4AC0);
  static const _bg        = Color(0xFFF5F6FA);

  @override
  void dispose() {
    _searchController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRoutes;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(filtered.length),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    _buildSearchAndFilter(),
                    const SizedBox(height: 16),
                    _buildRouteRecordsCard(filtered),
                    const SizedBox(height: 20),
                    _buildStationsSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_green, _greenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.alt_route, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage Routes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                Text('$count routes • ${_stations.length} stations',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.account_circle_outlined, color: Colors.grey, size: 28),
          ),
        ],
      ),
    );
  }

  // ── ACTION BUTTONS ──
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _onExport,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Export'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _onAddRoute,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH & FILTER ──
  Widget _buildSearchAndFilter() {
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
          const Text('Search Routes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          _inputField(
            controller: _searchController,
            hint: 'Search by route name, bus, or driver...',
            icon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 14),
          const Text('Filter by Route',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          _inputField(
            controller: _filterController,
            hint: '',
            icon: Icons.filter_alt_outlined,
            onChanged: (v) => setState(() => _filterQuery = v),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required void Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }

  // ── ROUTE RECORDS CARD ──
  Widget _buildRouteRecordsCard(List<RouteModel> routes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Green header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_green, _greenDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Route Records',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Showing 1-${routes.length} of ${_allRoutes.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8F9FF),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('ROUTE NAME',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1.2))),
              Expanded(flex: 2, child: Text('STOPS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1.2))),
            ]),
          ),

          // Rows or empty state
          if (routes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.search_off_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text('Search to get info',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                ],
              ),
            )
          else
            ...routes.asMap().entries.map((e) => _buildRouteRow(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _buildRouteRow(RouteModel route, int index) {
    final isEven = index.isEven;
    final isActive = route.status == 'Active';

    return GestureDetector(
      onTap: () => _showRouteDetails(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : const Color(0xFFFAFAFF),
          border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _green.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.alt_route,
                        color: isActive ? _green : Colors.grey, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(route.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(route.id,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.directions_bus_outlined, size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(route.busId,
                              style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: _green),
                    const SizedBox(width: 4),
                    Text('${route.stops} stops',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                  ]),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(route.status,
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: isActive ? _green : Colors.grey,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUS STATIONS SECTION ──
  Widget _buildStationsSection() {
    return Column(
      children: [
        // Blue header banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blue, _blueDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bus Stations & Stops',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Manage all pickup and drop-off points',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('View All',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Station cards
        ..._stations.map((station) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildStationCard(station),
        )),
      ],
    );
  }

  Widget _buildStationCard(BusStation station) {
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
          // Station name row
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_outlined, color: _green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text(station.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // Students
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Students:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text('${station.students}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 6),

          // Scheduled Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scheduled Time:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(station.scheduledTime,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 10),

          // Routes tags
          Text('Routes:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: station.routes.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Text(r,
                  style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
          const SizedBox(height: 12),

          // Edit / Map buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditStation(station),
                  icon: const Icon(Icons.edit_outlined, size: 15, color: _green),
                  label: const Text('Edit', style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _green.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: _green.withOpacity(0.05),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMapStation(station),
                  icon: const Icon(Icons.map_outlined, size: 15, color: _blue),
                  label: const Text('Map', style: TextStyle(color: _blue, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _blue.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: _blue.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ACTIONS ──
  void _onExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting route data...'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onAddRoute() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRouteSheet(
        onAdd: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route added successfully'),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showRouteDetails(RouteModel route) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteDetailsSheet(route: route),
    );
  }

  void _showEditStation(BusStation station) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${station.name}'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showMapStation(BusStation station) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Map for ${station.name}'), behavior: SnackBarBehavior.floating),
    );
  }
}

// ── ROUTE DETAILS SHEET ──
class _RouteDetailsSheet extends StatelessWidget {
  final RouteModel route;
  const _RouteDetailsSheet({required this.route});

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final isActive = route.status == 'Active';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alt_route, color: _green, size: 32),
          ),
          const SizedBox(height: 12),
          Text(route.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(route.status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isActive ? _green : Colors.grey)),
          ),
          const SizedBox(height: 20),
          _row(Icons.badge_outlined,          'Route ID',  route.id),
          _row(Icons.directions_bus_outlined,  'Bus ID',    route.busId),
          _row(Icons.person_outline,           'Driver',    route.driver),
          _row(Icons.location_on_outlined,     'Stops',     '${route.stops} stops'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Edit Route'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _green, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        ]),
      ]),
    );
  }
}

// ── ADD ROUTE SHEET ──
class _AddRouteSheet extends StatefulWidget {
  final VoidCallback onAdd;
  const _AddRouteSheet({required this.onAdd});

  @override
  State<_AddRouteSheet> createState() => _AddRouteSheetState();
}

class _AddRouteSheetState extends State<_AddRouteSheet> {
  final _nameCtrl   = TextEditingController();
  final _busCtrl    = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _stopsCtrl  = TextEditingController();

  static const _green = Color(0xFF16A34A);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _busCtrl.dispose();
    _driverCtrl.dispose();
    _stopsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Add New Route',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            _field(_nameCtrl,   'Route Name',     Icons.alt_route_outlined),
            _field(_busCtrl,    'Bus ID',          Icons.directions_bus_outlined),
            _field(_driverCtrl, 'Driver Name',     Icons.person_outline),
            _field(_stopsCtrl,  'Number of Stops', Icons.location_on_outlined),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add Route', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
          filled: true,
          fillColor: const Color(0xFFF8F9FF),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green)),
        ),
      ),
    );
  }
}