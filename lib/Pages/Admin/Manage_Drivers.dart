import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safeway/Constant/Constant_Color.dart';
import 'package:safeway/services/admin_service.dart';

// ── DATA MODEL ──
class Driver {
  final String id;
  final String uniqueId; // for internal use, not from backend
  final String name;
  final String phone;
  final String busId;
  final String route;
  final String status; // 'Active' | 'Inactive'
  final String avatarInitials;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.busId,
    required this.route,
    required this.status,
    required this.avatarInitials,
    required this.uniqueId,
  });

  bool get isActive => status == 'Active';

  static Driver fromJson(Map<String, dynamic> json) {
    final rawDbId = (json['id'] ?? '').toString();
    final driverCode = (json['driverId'] ?? json['uniqueID'] ?? json['uniqueId'] ?? rawDbId).toString();
    final name = (json['fullName'] ?? json['full_name'] ?? '').toString();

    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Driver(
      id: driverCode.isEmpty ? rawDbId : driverCode,
      name: name,
      phone: (json['phone'] ?? '').toString(),
      busId: (json['busId'] ?? json['bus_id'] ?? json['busNumber'] ?? '').toString(),
      route: (json['route'] ?? json['routeName'] ?? '').toString(),
      status: (json['status'] ?? 'Active').toString(),
      avatarInitials: initials.isEmpty ? '??' : initials,
      uniqueId: rawDbId.isEmpty ? driverCode : rawDbId,
    );
  }
}

// ── SCREEN ──
class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _routeFilterController = TextEditingController();

  String _searchQuery = '';
  String _routeFilter = '';

  final AdminService _adminService = AdminService();

  bool _loading = true;
  String? _error;

  List<Driver> _allDrivers = const [];

  @override
  void initState() {
    super.initState();
    _fetchDrivers();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _routeFilterController.addListener(() {
      setState(() => _routeFilter = _routeFilterController.text);
    });
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await _adminService.getDrivers();
      final list = (raw).map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();

      setState(() {
        _allDrivers = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Driver> get _filteredDrivers {
    return _allDrivers.where((d) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.id.toLowerCase().contains(q) ||
          d.busId.toLowerCase().contains(q);

      final matchesRoute = _routeFilter.isEmpty ||
          d.route.toLowerCase().contains(_routeFilter.toLowerCase());

      return matchesSearch && matchesRoute;
    }).toList();
  }

  int get _activeCount => _allDrivers.where((d) => d.isActive).length;
  int get _inactiveCount => _allDrivers.where((d) => !d.isActive).length;
  int get _totalDrivers => _allDrivers.length;

  static const _orange = AppColors.accentGreen;
  static const _orangeDark = AppColors.darkNavy;
  static const _green = AppColors.badgeDot;
  static const _grey = AppColors.textMuted;
  static const _bg = AppColors.bgGradientStart;

  @override
  void dispose() {
    _searchController.dispose();
    _routeFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDrivers;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Failed to load drivers', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchDrivers,
                            style: ElevatedButton.styleFrom(backgroundColor: _orange),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
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
                              _buildDriverRecordsCard(filtered),
                              const SizedBox(height: 16),
                              _buildStatCard('Active Drivers', _activeCount, _green, Icons.check_circle_outline),
                              const SizedBox(height: 12),
                              _buildStatCard('Inactive Drivers', _inactiveCount, _grey, Icons.cancel_outlined),
                              const SizedBox(height: 12),
                              _buildStatCard('Total Buses', _totalDrivers, _orange, Icons.directions_bus_outlined),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_orange, _orangeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Drivers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                ),
                Text('$count drivers found', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
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
            onPressed: _onAddDriver,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Driver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
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

  void _onExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting driver data...'),
        backgroundColor: _orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onAddDriver() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDriverSheet(
        onAdd: (name, busNumber, phone, routeName) async {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding driver...'),
              backgroundColor: _orange,
              behavior: SnackBarBehavior.floating,
            ),
          );

          try {
            await _adminService.addDriver(
              fullName: name,
              busNumber: busNumber,
              phone: phone,
              routeName: routeName,
            );
            await _fetchDrivers();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver added successfully'),
                  backgroundColor: _green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add driver: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
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
          const Text(
            'Search Drivers',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, ID, bus, or email...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
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
                borderSide: const BorderSide(color: _orange),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Filter by Route',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _routeFilterController,
            decoration: InputDecoration(
              hintText: '',
              prefixIcon: Icon(Icons.filter_alt_outlined, color: Colors.grey[400], size: 20),
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
                borderSide: const BorderSide(color: _orange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DRIVER RECORDS CARD ──
  Widget _buildDriverRecordsCard(List<Driver> drivers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_orange, _orangeDark], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Driver Records', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Showing 1-${drivers.length} of ${_allDrivers.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8F9FF),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DRIVER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1.2),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CONTACT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
          if (drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.search_off_outlined, size: 48, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 12),
                  Text('Search to get info', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                ],
              ),
            )
          else
            ...drivers.asMap().entries.map((entry) => _buildDriverRow(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _buildDriverRow(Driver driver, int index) {
    final isEven = index.isEven;

    return GestureDetector(
      onTap: () => _showDriverDetails(driver),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : const Color(0xFFFAFAFF),
          border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: driver.isActive
                            ? [const Color(0xFFFF9800), const Color(0xFFF57C00)]
                            : [Colors.grey.shade400, Colors.grey.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        driver.avatarInitials,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: driver.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            driver.status,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: driver.isActive ? _green : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(driver.phone.isEmpty ? '—' : driver.phone, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_bus_outlined, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(driver.busId, style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Edit driver',
              icon: const Icon(Icons.edit_outlined, color: AppColors.darkNavy, size: 20),
              onPressed: () => _openEditDriverSheet(driver),
            ),
            IconButton(
              tooltip: 'Delete driver',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDeleteDriver(driver),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverDetails(Driver driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DriverDetailsSheet(
        driver: driver,
        onRefresh: _fetchDrivers,
      ),
    );
  }

  void _openEditDriverSheet(Driver driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditDriverSheet(
        driver: driver,
        onUpdated: _fetchDrivers,
      ),
    );
  }

  Future<void> _confirmDeleteDriver(Driver driver) async {
    final int? driverDbId = int.tryParse(driver.uniqueId) ?? int.tryParse(driver.id);
    if (driverDbId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid driver id'), backgroundColor: Colors.red),
      );
      return;
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete driver'),
        content: Text('Are you sure you want to delete ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _adminService.deleteDriver(id: driverDbId);
      await _fetchDrivers();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver deleted successfully'), backgroundColor: _green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete driver: $e'), backgroundColor: Colors.red),
      );
    }
  }


  // ── STAT CARDS ──
  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(value.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
        ],
      ),
    );
  }
}

// ── DRIVER DETAILS BOTTOM SHEET ──
class _DriverDetailsSheet extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onRefresh;
  const _DriverDetailsSheet({required this.driver, this.onRefresh});

  static const _orange = Color(0xFFFF9800);
  static const _green = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_orange, Color(0xFFF57C00)]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(driver.avatarInitials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Text(driver.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: driver.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                driver.status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: driver.isActive ? _green : Colors.grey),
              ),
            ),
            const SizedBox(height: 14),
            _detailRow(Icons.phone_outlined, 'Phone', driver.phone.isEmpty ? '—' : driver.phone),
            _detailRow(Icons.directions_bus_outlined, 'Bus ID', driver.busId.isEmpty ? 'BUS-101' : driver.busId),
            _detailRow(Icons.alt_route_outlined, 'Route', driver.route.isEmpty ? 'Route A - Downtown' : driver.route),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _EditDriverSheet(
                          driver: driver,
                          onUpdated: onRefresh,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Edit Driver'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: _orange, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── EDIT DRIVER BOTTOM SHEET ──
class _EditDriverSheet extends StatefulWidget {
  final Driver driver;
  final VoidCallback? onUpdated;
  const _EditDriverSheet({required this.driver, this.onUpdated});

  @override
  State<_EditDriverSheet> createState() => _EditDriverSheetState();
}

class _EditDriverSheetState extends State<_EditDriverSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _busIdController = TextEditingController();

  final AdminService _adminService = AdminService();

  List<String> _availableRoutes = [
    'Route A - Downtown',
    'Route B - North Side',
    'Route C - East District',
    'Route D - West End',
    'Route E - South Gate',
  ];
  String? _selectedRoute;
  bool _loadingRoutes = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.driver.name;
    _phoneController.text = widget.driver.phone;
    _busIdController.text = widget.driver.busId;
    _selectedRoute = widget.driver.route.isNotEmpty ? widget.driver.route : null;
    _loadSystemRoutes();
  }

  Future<void> _loadSystemRoutes() async {
    try {
      final routesData = await _adminService.getRoutes();
      final routeNames = routesData
          .map((r) => (r['name'] ?? r['routeName'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      if (routeNames.isNotEmpty && mounted) {
        setState(() {
          _availableRoutes = routeNames;
          if (_selectedRoute == null || !_availableRoutes.contains(_selectedRoute)) {
            _selectedRoute = _availableRoutes.first;
          }
          _loadingRoutes = false;
        });
      } else {
        if (mounted) setState(() => _loadingRoutes = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRoutes = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _busIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final busId = _busIdController.text.trim();
    final routeName = _selectedRoute ?? '';

    if (fullName.isEmpty || busId.isEmpty || routeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    if (phone.isNotEmpty && phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be exactly 11 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final driverId = int.tryParse(widget.driver.uniqueId) ?? int.tryParse(widget.driver.id);
      if (driverId == null) {
        throw Exception('Invalid driver id: ${widget.driver.id}');
      }

      await _adminService.updateDriver(
        id: driverId,
        fullName: fullName,
        busNumber: busId,
        phone: phone,
        routeName: routeName,
      );

      widget.onUpdated?.call();

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver updated successfully'), backgroundColor: AppColors.accentGreen),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update driver: $e'), backgroundColor: Colors.red),
      );
    }
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
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Driver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 16),
            _field(_nameController, 'Full Name', Icons.person_outline),
            _phoneField(_phoneController, 'Phone Number (11 digits max)'),
            _field(_busIdController, 'Bus Number', Icons.directions_bus_outlined),
            _routeDropdown(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            borderSide: const BorderSide(color: AppColors.accentGreen),
          ),
        ),
      ),
    );
  }

  Widget _phoneField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.phone,
        maxLength: 11,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400], size: 18),
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
            borderSide: const BorderSide(color: AppColors.accentGreen),
          ),
        ),
      ),
    );
  }

  Widget _routeDropdown() {
    if (_selectedRoute != null && !_availableRoutes.contains(_selectedRoute)) {
      _availableRoutes.add(_selectedRoute!);
    }
    if (_selectedRoute == null && _availableRoutes.isNotEmpty) {
      _selectedRoute = _availableRoutes.first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedRoute,
        decoration: InputDecoration(
          hintText: 'Select System Route',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.alt_route_outlined, color: Colors.grey[400], size: 18),
          filled: true,
          fillColor: const Color(0xFFF8F9FF),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
            borderSide: const BorderSide(color: AppColors.accentGreen),
          ),
        ),
        items: _availableRoutes.map((routeName) {
          return DropdownMenuItem<String>(
            value: routeName,
            child: Text(
              routeName,
              style: const TextStyle(fontSize: 13, color: AppColors.darkNavy, fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedRoute = val;
          });
        },
      ),
    );
  }
}

// ── ADD DRIVER BOTTOM SHEET ──
class _AddDriverSheet extends StatefulWidget {
  final Future<void> Function(String fullName, String busNumber, String phone, String routeName) onAdd;
  const _AddDriverSheet({required this.onAdd});

  @override
  State<_AddDriverSheet> createState() => _AddDriverSheetState();
}

class _AddDriverSheetState extends State<_AddDriverSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _busIdController = TextEditingController();

  final AdminService _adminService = AdminService();

  List<String> _availableRoutes = [
    'Route A - Downtown',
    'Route B - North Side',
    'Route C - East District',
    'Route D - West End',
    'Route E - South Gate',
  ];
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _loadSystemRoutes();
  }

  Future<void> _loadSystemRoutes() async {
    try {
      final routesData = await _adminService.getRoutes();
      final routeNames = routesData
          .map((r) => (r['name'] ?? r['routeName'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      if (routeNames.isNotEmpty && mounted) {
        setState(() {
          _availableRoutes = routeNames;
          if (_selectedRoute == null || !_availableRoutes.contains(_selectedRoute)) {
            _selectedRoute = _availableRoutes.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _busIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Full Name'), backgroundColor: Colors.red),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be exactly 11 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await widget.onAdd(
      name,
      _busIdController.text.trim(),
      phone,
      _selectedRoute ?? (_availableRoutes.isNotEmpty ? _availableRoutes.first : 'Route A - Downtown'),
    );
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
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New Driver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 16),
            _field(_nameController, 'Full Name', Icons.person_outline),
            _phoneField(_phoneController, 'Phone Number (11 digits max)'),
            _field(_busIdController, 'Bus Number (e.g. BUS-101)', Icons.directions_bus_outlined),
            _routeDropdown(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add Driver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            borderSide: const BorderSide(color: AppColors.accentGreen),
          ),
        ),
      ),
    );
  }

  Widget _phoneField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.phone,
        maxLength: 11,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400], size: 18),
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
            borderSide: const BorderSide(color: AppColors.accentGreen),
          ),
        ),
      ),
    );
  }

  Widget _routeDropdown() {
    if (_selectedRoute != null && !_availableRoutes.contains(_selectedRoute)) {
      _availableRoutes.add(_selectedRoute!);
    }
    if (_selectedRoute == null && _availableRoutes.isNotEmpty) {
      _selectedRoute = _availableRoutes.first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedRoute,
        decoration: InputDecoration(
          hintText: 'Select System Route',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.alt_route_outlined, color: Colors.grey[400], size: 18),
          filled: true,
          fillColor: const Color(0xFFF8F9FF),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
            borderSide: const BorderSide(color: AppColors.accentGreen),
          ),
        ),
        items: _availableRoutes.map((routeName) {
          return DropdownMenuItem<String>(
            value: routeName,
            child: Text(
              routeName,
              style: const TextStyle(fontSize: 13, color: AppColors.darkNavy, fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedRoute = val;
          });
        },
      ),
    );
  }
}

