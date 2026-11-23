import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:safeway/Pages/Login_page.dart';
import 'package:safeway/services/api_config.dart';
import 'package:safeway/pages/Driver/Delay alert screen.dart';
import 'package:safeway/pages/Driver/Send_Announcement_Screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class RouteStopStudentModel {
  final int id;
  final String fullName;
  final String grade;
  final String paymentStatus;

  RouteStopStudentModel({
    required this.id,
    required this.fullName,
    required this.grade,
    required this.paymentStatus,
  });

  factory RouteStopStudentModel.fromJson(Map<String, dynamic> j) {
    return RouteStopStudentModel(
      id: j['id'],
      fullName: j['fullName'] ?? '',
      grade: j['grade'] ?? '',
      paymentStatus: j['paymentStatus'] ?? 'UNPAID',
    );
  }
}

class RouteStopModel {
  final int stopOrder;
  final String pickupTime;
  final int stationId;
  final String stationName;
  final List<RouteStopStudentModel> students;

  RouteStopModel({
    required this.stopOrder,
    required this.pickupTime,
    required this.stationId,
    required this.stationName,
    required this.students,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> j) {
    return RouteStopModel(
      stopOrder: j['stopOrder'],
      pickupTime: j['pickupTime'] ?? '',
      stationId: j['station']['id'],
      stationName: j['station']['name'] ?? '',
      students: (j['students'] as List)
          .map(
            (s) => RouteStopStudentModel.fromJson(Map<String, dynamic>.from(s)),
          )
          .toList(),
    );
  }
}

class DriverRouteModel {
  final String routeName;
  final String busNumber;
  final int totalStops;
  final List<RouteStopModel> stops;

  DriverRouteModel({
    required this.routeName,
    required this.busNumber,
    required this.totalStops,
    required this.stops,
  });

  factory DriverRouteModel.fromJson(Map<String, dynamic> j) {
    return DriverRouteModel(
      routeName: j['routeName'] ?? '',
      busNumber: j['busNumber'] ?? '',
      totalStops: j['totalStops'] ?? 0,
      stops: (j['stops'] as List)
          .map((s) => RouteStopModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class DriverStudentModel {
  final int id;
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

  factory DriverStudentModel.fromJson(Map<String, dynamic> j) {
    return DriverStudentModel(
      id: j['id'],
      fullName: j['fullName'] ?? '',
      grade: j['grade'] ?? '',
      stopName: j['stopName'] ?? 'Not assigned',
      paymentStatus: j['paymentStatus'] ?? 'UNPAID',
    );
  }
}

class DriverInfoModel {
  final String fullName;
  final String uniqueID;
  final String busNumber;
  final String routeName;
  final int totalStudents;
  final int paidCount;
  final int unpaidCount;
  final int expiredCount;
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

  factory DriverInfoModel.fromJson(Map<String, dynamic> j) {
    return DriverInfoModel(
      fullName: j['fullName'] ?? '',
      uniqueID: j['uniqueID'] ?? '',
      busNumber: j['busNumber'] ?? 'Not assigned',
      routeName: j['routeName'] ?? 'Not assigned',
      totalStudents: j['totalStudents'] ?? 0,
      paidCount: j['paidCount'] ?? 0,
      unpaidCount: j['unpaidCount'] ?? 0,
      expiredCount: j['expiredCount'] ?? 0,
      students: (j['students'] as List)
          .map((s) => DriverStudentModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _storage = const FlutterSecureStorage();

  DriverInfoModel? _driverInfo;
  DriverRouteModel? _driverRoute;

  bool _infoLoading = true;
  bool _routeLoading = true;

  int _userId = 0;
  int _activeStop = 1;

  final Set<int> _confirmedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // API
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final userIdStr = await _storage.read(key: 'userId') ?? '0';

    _userId = int.tryParse(userIdStr) ?? 0;

    if (_userId == 0) {
      if (mounted) {
        setState(() {
          _infoLoading = false;
          _routeLoading = false;
        });
      }
      return;
    }

    await Future.wait([_loadDriverInfo(), _loadDriverRoute()]);
  }

  Future<void> _loadDriverInfo() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/driver-info/$_userId'),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _driverInfo = DriverInfoModel.fromJson(jsonDecode(res.body));
          _infoLoading = false;
        });
      } else {
        setState(() {
          _infoLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _infoLoading = false;
        });
      }
    }
  }

  Future<void> _loadDriverRoute() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/driver-route/$_userId'),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _driverRoute = DriverRouteModel.fromJson(jsonDecode(res.body));
          _routeLoading = false;
        });
      } else {
        setState(() {
          _routeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routeLoading = false;
        });
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070708),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: (_infoLoading || _routeLoading)
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD32F2F),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD32F2F),
                      backgroundColor: const Color(0xFF18181B),
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(),

                            const SizedBox(height: 18),

                            _buildBusInfoCard(),

                            const SizedBox(height: 16),

                            _buildRouteProgressCard(),

                            const SizedBox(height: 16),

                            _buildStudentsCard(),

                            const SizedBox(height: 16),

                            _buildQuickActionsCard(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF070708),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF101012),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DRIVER DASHBOARD',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _driverInfo?.fullName ?? 'Driver',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFD32F2F).withOpacity(0.18),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WELCOME
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildWelcomeCard() {
    final name = _driverInfo?.fullName ?? 'Driver';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF65171B).withOpacity(0.34),
            const Color(0xFF101012).withOpacity(0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.07),
            blurRadius: 25,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF991B1B), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.20),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your route and student boarding.',
                  style: TextStyle(
                    color: Color(0xFFB8B8BC),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUS INFO
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBusInfoCard() {
    final busNumber = _driverInfo?.busNumber ?? '...';

    final routeName = _driverInfo?.routeName ?? '...';

    final totalStudents = _driverInfo?.totalStudents ?? 0;

    const capacity = 40;

    final rawPercentage = totalStudents / capacity;

    final percentage = rawPercentage.clamp(0.0, 1.0);

    final pct = (rawPercentage * 100).round();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            icon: Icons.directions_bus_outlined,
            title: 'Bus Information',
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  'BUS NUMBER',
                  busNumber,
                  Icons.directions_bus_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox('ROUTE', routeName, Icons.alt_route_rounded),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  'STUDENTS',
                  '$totalStudents',
                  Icons.groups_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  'CAPACITY',
                  '$totalStudents/$capacity',
                  Icons.event_seat_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BUS CAPACITY',
                style: TextStyle(
                  color: Color(0xFF77777D),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Color(0xFFB8B8BC),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD32F2F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFEF4444), size: 17),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF77777D),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE5E5E7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ROUTE PROGRESS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildRouteProgressCard() {
    final stops = _driverRoute?.stops ?? [];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.route_outlined, title: 'Route Progress'),

          const SizedBox(height: 18),

          if (stops.isEmpty)
            _emptyState(Icons.route_outlined, 'No route stops found.')
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

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final totalStops = _driverRoute?.totalStops ?? 1;

                if (_activeStop < totalStops) {
                  setState(() {
                    _activeStop++;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Route completed! All stops done.'),
                      backgroundColor: Color(0xFF991B1B),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Proceed to Next Station',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeStopCard(RouteStopModel stop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF65171B).withOpacity(0.25),
            const Color(0xFF18181B),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${stop.stopOrder}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.stationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 12,
                          color: Color(0xFF77777D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stop.students.length} student(s)',
                          style: const TextStyle(
                            color: Color(0xFF77777D),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Text(
                stop.pickupTime,
                style: const TextStyle(
                  color: Color(0xFFB8B8BC),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (stop.students.isNotEmpty) ...[
            const SizedBox(height: 12),

            ...stop.students.map((student) => _routeStudentRow(student)),
          ],
        ],
      ),
    );
  }

  Widget _routeStudentRow(RouteStopStudentModel student) {
    final isConfirmed = _confirmedIds.contains(student.id);

    final statusColor = _paymentColor(student.paymentStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      color: Color(0xFFE5E5E7),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        student.grade,
                        style: const TextStyle(
                          color: Color(0xFF77777D),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        student.paymentStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isConfirmed)
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Confirmed',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () {
                  setState(() {
                    _confirmedIds.add(student.id);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD32F2F).withOpacity(0.18),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _normalStopCard(RouteStopModel stop) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Center(
              child: Text(
                '${stop.stopOrder}',
                style: const TextStyle(
                  color: Color(0xFF77777D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.stationName,
                  style: const TextStyle(
                    color: Color(0xFFE5E5E7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 11,
                      color: Color(0xFF55555A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stop.students.length} student(s)',
                      style: const TextStyle(
                        color: Color(0xFF66666B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Text(
            stop.pickupTime,
            style: const TextStyle(
              color: Color(0xFF77777D),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STUDENTS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStudentsCard() {
    final students = _driverInfo?.students ?? [];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardTitle(
                  icon: Icons.groups_outlined,
                  title: 'Students on My Bus',
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${students.length} TOTAL',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (students.isEmpty)
            _emptyState(
              Icons.groups_outlined,
              'No students assigned to your bus yet.',
            )
          else
            ...students.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _studentRow(student),
              ),
            ),
        ],
      ),
    );
  }

  Widget _studentRow(DriverStudentModel student) {
    final isConfirmed = _confirmedIds.contains(student.id);

    final statusColor = _paymentColor(student.paymentStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE5E5E7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  student.stopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF77777D),
                    fontSize: 10.5,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Text(
                      student.grade,
                      style: const TextStyle(
                        color: Color(0xFF77777D),
                        fontSize: 9.5,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        student.paymentStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (isConfirmed)
            const Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFFEF4444),
                  size: 19,
                ),
                SizedBox(height: 3),
                Text(
                  'BOARDED',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () {
                setState(() {
                  _confirmedIds.add(student.id);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD32F2F).withOpacity(0.18),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildQuickActionsCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.flash_on_outlined, title: 'Quick Actions'),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DelayAlertScreen(
                    busNumber: _driverInfo?.busNumber ?? 'BUS-101',
                  ),
                ),
              );
            },
            child: _actionButton(
              icon: Icons.warning_amber_outlined,
              label: 'Send Delay Alert',
            ),
          ),

          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SendAnnouncementScreen(
                    busNumber: _driverInfo?.busNumber ?? 'BUS-101',
                  ),
                ),
              );
            },
            child: _actionButton(
              icon: Icons.send_outlined,
              label: 'Send Announcement',
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE5E5E7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF55555A),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHARED UI
  // ───────────────────────────────────────────────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFEF4444), size: 19),
        ),

        const SizedBox(width: 11),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF55555A), size: 28),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF77777D), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _paymentColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF4ADE80);

      case 'EXPIRED':
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFFEF4444);
    }
  }
}
