import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/Pages/Login_page.dart';
import 'package:safeway/services/api_config.dart';
import 'package:safeway/pages/Driver/Delay alert screen.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class RouteStopStudentModel {
  final int    id;
  final String fullName;
  final String grade;
  final String paymentStatus;

  RouteStopStudentModel({
    required this.id,
    required this.fullName,
    required this.grade,
    required this.paymentStatus,
  });

  factory RouteStopStudentModel.fromJson(Map<String, dynamic> j) =>
      RouteStopStudentModel(
        id:            j['id'],
        fullName:      j['fullName'],
        grade:         j['grade']         ?? '',
        paymentStatus: j['paymentStatus'] ?? 'UNPAID',
      );
}

class RouteStopModel {
  final int    stopOrder;
  final String pickupTime;
  final int    stationId;
  final String stationName;
  final List<RouteStopStudentModel> students;

  RouteStopModel({
    required this.stopOrder,
    required this.pickupTime,
    required this.stationId,
    required this.stationName,
    required this.students,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> j) => RouteStopModel(
    stopOrder:   j['stopOrder'],
    pickupTime:  j['pickupTime'],
    stationId:   j['station']['id'],
    stationName: j['station']['name'],
    students: (j['students'] as List)
        .map((s) => RouteStopStudentModel.fromJson(s))
        .toList(),
  );
}

class DriverRouteModel {
  final String routeName;
  final String busNumber;
  final int    totalStops;
  final List<RouteStopModel> stops;

  DriverRouteModel({
    required this.routeName,
    required this.busNumber,
    required this.totalStops,
    required this.stops,
  });

  factory DriverRouteModel.fromJson(Map<String, dynamic> j) => DriverRouteModel(
    routeName:  j['routeName'],
    busNumber:  j['busNumber'],
    totalStops: j['totalStops'],
    stops: (j['stops'] as List)
        .map((s) => RouteStopModel.fromJson(s))
        .toList(),
  );
}

class DriverStudentModel {
  final int    id;
  final String fullName;
  final String grade;
  final String stopName;
  final String paymentStatus;

  DriverStudentModel({
    required this.id,
    required this.fullName,
    required this.grade,
    required this.stopName,
    required this.paymentStatus,
  });

  factory DriverStudentModel.fromJson(Map<String, dynamic> j) =>
      DriverStudentModel(
        id:            j['id'],
        fullName:      j['fullName'],
        grade:         j['grade']         ?? '',
        stopName:      j['stopName']      ?? 'Not assigned',
        paymentStatus: j['paymentStatus'] ?? 'UNPAID',
      );
}

class DriverInfoModel {
  final String fullName;
  final String uniqueID;
  final String busNumber;
  final String routeName;
  final int    totalStudents;
  final int    paidCount;
  final int    unpaidCount;
  final int    expiredCount;
  final List<DriverStudentModel> students;

  DriverInfoModel({
    required this.fullName,
    required this.uniqueID,
    required this.busNumber,
    required this.routeName,
    required this.totalStudents,
    required this.paidCount,
    required this.unpaidCount,
    required this.expiredCount,
    required this.students,
  });

  factory DriverInfoModel.fromJson(Map<String, dynamic> j) => DriverInfoModel(
    fullName:      j['fullName']      ?? '',
    uniqueID:      j['uniqueID']      ?? '',
    busNumber:     j['busNumber']     ?? 'Not assigned',
    routeName:     j['routeName']     ?? 'Not assigned',
    totalStudents: j['totalStudents'] ?? 0,
    paidCount:     j['paidCount']     ?? 0,
    unpaidCount:   j['unpaidCount']   ?? 0,
    expiredCount:  j['expiredCount']  ?? 0,
    students: (j['students'] as List)
        .map((s) => DriverStudentModel.fromJson(s))
        .toList(),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _storage = const FlutterSecureStorage();

  DriverInfoModel?  _driverInfo;
  DriverRouteModel? _driverRoute;
  bool _infoLoading  = true;
  bool _routeLoading = true;
  int  _userId       = 0;
  int  _activeStop   = 1;

  final Set<int> _confirmedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userIdStr = await _storage.read(key: 'userId') ?? '0';
    _userId = int.tryParse(userIdStr) ?? 0;
    if (_userId == 0) {
      setState(() { _infoLoading = false; _routeLoading = false; });
      return;
    }
    await Future.wait([_loadDriverInfo(), _loadDriverRoute()]);
  }

  Future<void> _loadDriverInfo() async {
    try {
      final res = await http.get(
          Uri.parse('$apiBaseUrl/api/auth/driver-info/$_userId'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _driverInfo  = DriverInfoModel.fromJson(jsonDecode(res.body));
          _infoLoading = false;
        });
      } else {
        setState(() => _infoLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _infoLoading = false);
    }
  }

  Future<void> _loadDriverRoute() async {
    try {
      final res = await http.get(
          Uri.parse('$apiBaseUrl/api/auth/driver-route/$_userId'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _driverRoute  = DriverRouteModel.fromJson(jsonDecode(res.body));
          _routeLoading = false;
        });
      } else {
        setState(() => _routeLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _routeLoading = false);
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
            child: (_infoLoading || _routeLoading)
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFDC2626)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBusInfoCard(),
                        const SizedBox(height: 16),
                        _buildRouteProgressCard(),
                        const SizedBox(height: 16),
                        _buildStudentsCard(),
                        const SizedBox(height: 16),
                        _buildQuickActionsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color bg, Color color) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(
          color: color, fontWeight: FontWeight.w600, fontSize: 14)),
    ]),
  );
}

  // ── HEADER ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final name = _driverInfo?.fullName ?? 'Loading...';
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
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
  onTap: () => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  ),
  child: const Row(children: [
    Icon(Icons.arrow_back_ios, color: Colors.white70, size: 14),
    SizedBox(width: 4),
    Text('Back to Home',
        style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                    _infoLoading
                        ? Container(width: 160, height: 30,
                            decoration: BoxDecoration(color: Colors.white24,
                                borderRadius: BorderRadius.circular(6)))
                        : Text(name,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Manage your route and student boarding',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.directions_bus_rounded,
                    color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BUS INFO CARD ─────────────────────────────────────────────────────────────
  Widget _buildBusInfoCard() {
    final busNumber     = _driverInfo?.busNumber     ?? '...';
    final routeName     = _driverInfo?.routeName     ?? '...';
    final totalStudents = _driverInfo?.totalStudents ?? 0;
    const capacity      = 40;
    final pct           = (totalStudents / capacity * 100).round();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bus Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _infoBox('Bus Number', busNumber,
                const Color(0xFFFFF7ED), const Color(0xFFEA580C))),
            const SizedBox(width: 12),
            Expanded(child: _infoBox('Route', routeName,
                const Color(0xFFF0F0FF), const Color(0xFF4F46E5))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _infoBox('Students', '$totalStudents',
                const Color(0xFFF0FFF4), const Color(0xFF16A34A))),
            const SizedBox(width: 12),
            Expanded(child: _infoBox('Capacity', '$totalStudents/$capacity',
                const Color(0xFFF0F0FF), const Color(0xFF4F46E5))),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bus Capacity',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              Text('$pct%',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalStudents / capacity,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }

  // ── ROUTE PROGRESS CARD ───────────────────────────────────────────────────────
  Widget _buildRouteProgressCard() {
    final stops = _driverRoute?.stops ?? [];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Route Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),

          if (stops.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Text('No route stops found.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ),
            )
          else
            ...stops.map((stop) {
              final isActive = stop.stopOrder == _activeStop;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: isActive && stop.students.isNotEmpty
                    ? _activeStopCard(stop)
                    : _normalStopCard(stop),
              );
            }),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                final totalStops = _driverRoute?.totalStops ?? 1;
                if (_activeStop < totalStops) {
                  setState(() => _activeStop++);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Route completed! All stops done.'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.location_on_outlined,
                  color: Colors.white, size: 18),
              label: const Text('Proceed to Next Station',
                  style: TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeStopCard(RouteStopModel stop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF16A34A).withOpacity(0.4)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(
                color: Color(0xFF16A34A), shape: BoxShape.circle),
            child: Center(child: Text('${stop.stopOrder}',
                style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(stop.stationName,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Row(children: [
                Icon(Icons.group_outlined,
                    size: 11, color: Colors.grey[500]),
                const SizedBox(width: 3),
                Text('${stop.students.length} student(s)',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
              ]),
            ]),
          ),
          Text(stop.pickupTime,
              style: const TextStyle(fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
        ]),

        const SizedBox(height: 10),

        ...stop.students.map((student) {
          final isConfirmed = _confirmedIds.contains(student.id);
          final statusColor = student.paymentStatus == 'PAID'
              ? const Color(0xFF16A34A)
              : student.paymentStatus == 'EXPIRED'
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFDC2626);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(student.fullName,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    Row(children: [
                      Text(student.grade,
                          style: const TextStyle(fontSize: 11,
                              color: Color(0xFF9CA3AF))),
                      const SizedBox(width: 8),
                      Text(student.paymentStatus,
                          style: TextStyle(fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                ),
                isConfirmed
                    ? const Row(children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 4),
                        Text('Confirmed',
                            style: TextStyle(color: Color(0xFF16A34A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ])
                    : GestureDetector(
                        onTap: () => setState(
                            () => _confirmedIds.add(student.id)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFD1D5DB)),
                          ),
                          child: const Text('Confirm',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151))),
                        ),
                      ),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _normalStopCard(RouteStopModel stop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD1D5DB))),
          child: Center(child: Text('${stop.stopOrder}',
              style: const TextStyle(color: Color(0xFF9CA3AF),
                  fontSize: 13, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(stop.stationName,
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
            Row(children: [
              Icon(Icons.group_outlined,
                  size: 11, color: Colors.grey[400]),
              const SizedBox(width: 3),
              Text('${stop.students.length} student(s)',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[400])),
            ]),
          ]),
        ),
        Text(stop.pickupTime,
            style: const TextStyle(fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── STUDENTS CARD ─────────────────────────────────────────────────────────────
  Widget _buildStudentsCard() {
    final students = _driverInfo?.students ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Students on My Bus',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F0FF),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${students.length} total',
                    style: const TextStyle(fontSize: 12,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Text('No students assigned to your bus yet.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
              ),
            )
          else
            ...students.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _studentRow(s))),
        ],
      ),
    );
  }

  Widget _studentRow(DriverStudentModel student) {
    final isPaid    = student.paymentStatus == 'PAID';
    final isExpired = student.paymentStatus == 'EXPIRED';
    final statusColor = isPaid
        ? const Color(0xFF16A34A)
        : isExpired
            ? const Color(0xFFEA580C)
            : const Color(0xFFDC2626);
    final isConfirmed = _confirmedIds.contains(student.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(student.fullName,
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Text(student.stopName,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Row(children: [
              Text(student.grade,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(student.paymentStatus,
                    style: TextStyle(fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),
        isConfirmed
            ? const Row(children: [
                Icon(Icons.check_circle,
                    color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 4),
                Text('Boarded',
                    style: TextStyle(color: Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ])
            : GestureDetector(
                onTap: () =>
                    setState(() => _confirmedIds.add(student.id)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFD1D5DB)),
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                ),
              ),
      ]),
    );
  }


  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────────
  Widget _buildQuickActionsCard() {
  return _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),

        // ── Send Delay Alert ──
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DelayAlertScreen(busNumber: 'BUS-101'),
            ),
          ),
          child: _actionButton(
            Icons.warning_amber_outlined,
            'Send Delay Alert',
            const Color(0xFFFFF7ED),
            const Color(0xFFEA580C),
          ),
        ),

        const SizedBox(height: 10),

        // ── Send Announcement ──
        GestureDetector(
          onTap: () {
            // TODO: Add announcement screen
          },
          child: _actionButton(
            Icons.send_outlined,
            'Send Announcement',
            const Color(0xFFF0F0FF),
            const Color(0xFF4F46E5),
          ),
        ),
      ],
    ),
  );
}
  // ── SHARED ────────────────────────────────────────────────────────────────────
  Widget _infoBox(String label, String value, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.bold, color: textColor)),
      ]),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}