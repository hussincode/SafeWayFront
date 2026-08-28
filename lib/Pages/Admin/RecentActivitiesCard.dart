import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:safeway/Constant/Constant_Color.dart';
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
    return Container(
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent System Activities',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Real-time operational events & alerts',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _loadActivities,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.inputBg.withOpacity(0.6),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'EVENT TYPE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
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
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'BUS ID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content List
          SizedBox(
            height: 280,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentGreen, strokeWidth: 2),
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
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadActivities,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkNavy,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Try again', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      )
                : _activities.isEmpty
                    ? const Center(
                        child: Text(
                          'No recent activities recorded',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _activities.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.divider,
                        ),
                        itemBuilder: (context, index) {
                          final item = _activities[index];
                          final map = item is Map<String, dynamic> ? item : _decodeDynamicToMap(item);

                          final type = (map['type'] ?? map['Type'] ?? 'Activity').toString();
                          final details = (map['details'] ?? map['Details'] ?? '').toString();
                          final bus = (map['bus'] ?? map['Bus'] ?? 'N/A').toString();
                          final iconName = (map['icon'] ?? map['Icon'] ?? '').toString();
                          final colorHex = (map['color'] ?? map['Color'] ?? '').toString();

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
    );
  }

  Map<String, dynamic> _decodeDynamicToMap(dynamic item) {
    if (item == null) return const {};
    if (item is Map<String, dynamic>) return item;
    if (item is String) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
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
      color: AppColors.cardBg,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  bus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.bold,
                  ),
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
      return AppColors.accentGreen;
    }
    try {
      final hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('ff$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return AppColors.accentGreen;
    } catch (_) {
      return AppColors.accentGreen;
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
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
