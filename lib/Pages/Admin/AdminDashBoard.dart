import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeway/Pages/Admin/Manage_Drivers.dart';
import 'package:safeway/Pages/Admin/Student_Man.dart' show ManageStudentsScreen;
import 'package:safeway/Pages/Admin/RecentActivitiesCard.dart';
import 'package:safeway/services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final MapController _mapController = MapController();
  final AdminService _adminService = AdminService();
  
  late Future<Map<String, dynamic>> _dashboardFuture;

  // Comes from the backend: /api/admin/dashboard-summary -> buses
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

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await _adminService.getDashboardSummary();
      
      final statsList = List<Map<String, dynamic>>.from(data['stats'] ?? []);

      // ── Student stat ──
      final studentStat = statsList.firstWhere(
        (item) => item['label']?.toString() == 'Total Students',
        orElse: () => {},
      );

      // ── Driver stat ──
      final driverStat = statsList.firstWhere(
        (item) => item['label']?.toString() == 'Total Drivers',
        orElse: () => {},
      );
  
      setState(() {
        _stats = statsList;
        _list = List<Map<String, dynamic>>.from(data['buses'] ?? []);
        _activities = List<Map<String, dynamic>>.from(data['activities'] ?? []);

        // Students
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
        _errorMessage = 'خطأ في تحميل البيانات: $e';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {

      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {

              return Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('حاول مرة أخرى'),
              ),
            ],
          ),
        ),
      );
    }

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
              // ── STUDENT CARD ──
              _buildStudentCard(),
              const SizedBox(height: 20),
              // ── DRIVER CARD ──
              _buildDriverCard(),
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
 

  // ── STUDENT CARD ──
  Widget _buildStudentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Students",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                _studentCount?.toString() ?? '0',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (_studentChange != null && _studentChange!.isNotEmpty)
                    ? _studentChange!
                    : 'Loading student trend...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            ],
          ),
          const Spacer(),
          SizedBox(
            width: 60,
            height: 32,
            child: CustomPaint(
                          painter: _StudentSparklinePainter(_studentTrend, color: const Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  // ── DRIVER CARD ──
  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Drivers",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                _driverCount?.toString() ?? '0',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
  (_driverChange != null && _driverChange!.isNotEmpty)
      ? _driverChange!
      : 'Loading driver trend...',
  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
),

            ],
          ),
          const Spacer(),
          SizedBox(
            width: 60,
            height: 32,
            child: CustomPaint(
              painter: _DriverSparklinePainter(_driverTrend, color: const Color(0xFF2563EB)),
            ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Bus Tracking',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Real-time locations',
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
                  child: Text('${_list.length} Active',

                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

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
                    markers: _list.map((bus) {

                      try {
                        Color busColor = _hexToColor(bus['color']?.toString() ?? '#4F46E5');
                        return Marker(
                          point: LatLng(
                            bus['latitude'] is double ? bus['latitude'] : double.tryParse(bus['latitude']?.toString() ?? '30.0472') ?? 30.0472,
                            bus['longitude'] is double ? bus['longitude'] : double.tryParse(bus['longitude']?.toString() ?? '31.2403') ?? 31.2403,
                          ),
                          width: 60, height: 36,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: busColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: busColor.withOpacity(0.5), blurRadius: 6)],
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.directions_bus, color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                (bus['id']?.toString() ?? 'BUS-000').replaceAll('BUS-', ''),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ),
                        );
                      } catch (e) {
                        return Marker(
                          point: const LatLng(30.0472, 31.2403),
                          width: 60, height: 36,
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
                  onTap: _refreshData,
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
      children: _list.map((bus) => Padding(

        padding: const EdgeInsets.only(bottom: 12),
        child: _busCard(bus),
      )).toList(),
    );
  }

  Widget _busCard(Map<String, dynamic> bus) {
    try {
      Color busColor = _hexToColor(bus['color']?.toString() ?? '#4F46E5');

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
                    color: busColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.directions_bus_rounded, color: busColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text(bus['id']?.toString() ?? 'BUS-000',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(bus['status']?.toString() ?? 'Active',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _busInfoRow(Icons.person_outline, 'Driver: ${bus['driver']?.toString() ?? 'Unknown'}'),
            const SizedBox(height: 4),
            _busInfoRow(Icons.alt_route_outlined, 'Route: ${bus['route']?.toString() ?? 'Unknown'}'),
            const SizedBox(height: 4),
            _busInfoRow(Icons.people_outline, 'Occupancy: ${bus['occupancy']?.toString() ?? '0/40'}'),
            const SizedBox(height: 4),
            _busInfoRow(Icons.location_on_outlined, 'Next: ${bus['nextStop']?.toString() ?? 'No Stop'}'),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('Error loading bus: $e'),
      );
    }
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDriversScreen()));
          }),
          const SizedBox(height: 10),
          _quickActionBtn(Icons.alt_route_outlined, 'Manage Routes', const Color(0xFFF0FFF4), const Color(0xFF16A34A), () {
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
    return const RecentActivitiesCard();
  }


  // ── HELPER METHODS ──
  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return const Color(0xFF3B82F6);
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
        return const Color(0xFF3B82F6);
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF3B82F6);
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


  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'group':
        return Icons.group_outlined;
      case 'directions_bus':
        return Icons.directions_bus_outlined;
      case 'person':
        return Icons.person_outline;
      case 'alt_route':
        return Icons.alt_route_outlined;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'access_time':
        return Icons.access_time;
      case 'location_on':
        return Icons.location_on_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.circle;
    }
  }
}

// ── PAINTERS ──
class _TrendLinePainter extends CustomPainter {
  final Color color;
  _TrendLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = ui.Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.2, size.width, size.height * 0.6);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StudentSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _StudentSparklinePainter(this.data, {this.color = const Color(0xFF3B82F6)});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = color;
    final minValue = data.reduce(min);
    final maxValue = data.reduce(max);
    final range = max(1, maxValue - minValue);
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
      canvas.drawCircle(Offset(x, y), 2.4, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _StudentSparklinePainter && oldDelegate.data != data;
  }
}

// ── DRIVER SPARKLINE PAINTER ──
class _DriverSparklinePainter extends CustomPainter {
  final List<double> trend;
  final Color color;

  _DriverSparklinePainter(this.trend, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = color;
    final path = ui.Path();

    // Defensive: prevent division by zero and issues when list length is 1.
    if (trend.isEmpty) {
      // Fallback curve
      path.moveTo(0, size.height * 0.7);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.2,
        size.width,
        size.height * 0.6,
      );
      canvas.drawPath(path, paint);
      return;
    }

    final minValue = trend.reduce(min);
    final maxValue = trend.reduce(max);
    final range = max(1.0, maxValue - minValue);

    final stepX = trend.length > 1 ? (size.width / (trend.length - 1)) : 0.0;

    for (int i = 0; i < trend.length; i++) {
      final x = i * stepX;
      final normalized = (trend[i] - minValue) / range;
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.4, dotPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _DriverSparklinePainter && oldDelegate.trend != trend;
  }
}
