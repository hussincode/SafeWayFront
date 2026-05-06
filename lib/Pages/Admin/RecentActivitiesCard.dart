import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:safeway/services/admin_service.dart';

class RecentActivitiesCard extends StatefulWidget {
  const RecentActivitiesCard({super.key});

  @override
  State<RecentActivitiesCard> createState() => _RecentActivitiesCardState();
}

class _RecentActivitiesCardState extends State<RecentActivitiesCard> {
  final AdminService _adminService = AdminService();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminService.getActivities();
      setState(() {
        _activities = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load activities: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Activities',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Latest system events',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadActivities,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFF8F9FF),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'TYPE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'DETAILS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'BUS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              // NOTE: This card is shown inside a SingleChildScrollView in AdminDashboard,
              // which provides unbounded height constraints. Using Expanded/Column with
              // non-zero flex inside an unbounded parent will throw:
              // "RenderFlex children have non-zero flex but incoming height constraints are unbounded".
              SizedBox(
                height: 300,
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _loadActivities,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _activities.isEmpty
                            ? const Center(
                                child: Text(
                                  'No activities found',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _activities.length,
                                itemBuilder: (context, index) {
                                  final item = _activities[index];

                                  final map = item is Map<String, dynamic>
                                      ? item
                                      : _decodeDynamicToMap(item);

                                  final type = (map['type'] ?? map['Type'] ?? 'Activity')
                                      .toString();
                                  final details =
                                      (map['details'] ?? map['Details'] ?? '')
                                          .toString();
                                  final bus = (map['bus'] ?? map['Bus'] ?? '')
                                      .toString();
                                  final iconName = (map['icon'] ?? map['Icon'] ?? '')
                                      .toString();
                                  final colorHex = (map['color'] ?? map['Color'] ?? '')
                                      .toString();

                                  final rowColor = _hexToColor(colorHex);

                                  return _activityRow(
                                    type: type,
                                    details: details,
                                    bus: bus,
                                    color: rowColor,
                                    icon: _iconDataFromName(iconName),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _decodeDynamicToMap(dynamic item) {
    if (item == null) return const {};
    if (item is Map<String, dynamic>) return item;
    if (item is String) {
      final decoded = jsonDecode(item);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return const {};
  }

  Widget _activityRow({
    required String type,
    required String details,
    required String bus,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              details,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexString) {
    if (hexString.isEmpty) {
      return const Color(0xFF16A34A);
    }
    try {
      final hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('ff$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return const Color(0xFF16A34A);
    } catch (_) {
      return const Color(0xFF16A34A);
    }
  }

  IconData _iconDataFromName(String iconName) {
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
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}

