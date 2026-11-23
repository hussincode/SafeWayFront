import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:safeway/services/admin_service.dart';

// ─────────────────────────────────────────────────────────────
//  SafeWay design system — dark glass + red accent
//  (same tokens as the login page / dashboards)
// ─────────────────────────────────────────────────────────────
class _Palette {
  static const red = Color(0xFFD32F2F);
  static const brightRed = Color(0xFFEF4444);
  static const darkRed = Color(0xFF991B1B);
  static const burgundy = Color(0xFF65171B);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB8B8BC);
  static const textMuted = Color(0xFF77777D);

  static const glassFill = Color(0x14FFFFFF);
  static const glassFillSoft = Color(0x08FFFFFF);
  static const glassBorder = Color(0x2AFFFFFF);
  static const divider = Color(0x1AFFFFFF);

  static const redGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [darkRed, red],
  );
}

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
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: _Palette.redGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _Palette.red.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                              fontWeight: FontWeight.w800,
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
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Refresh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    border: Border(
                      bottom: BorderSide(color: _Palette.divider),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'TYPE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'BUS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _Palette.brightRed,
                            ),
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
                                        color: _Palette.brightRed,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _RetryButton(onTap: _loadActivities),
                                  ],
                                ),
                              ),
                            )
                          : _activities.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No activities found',
                                    style: TextStyle(
                                      color: _Palette.textMuted,
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

                                    final type =
                                        (map['type'] ?? map['Type'] ?? 'Activity')
                                            .toString();
                                    final details = (map['details'] ??
                                            map['Details'] ??
                                            '')
                                        .toString();
                                    final bus =
                                        (map['bus'] ?? map['Bus'] ?? '')
                                            .toString();
                                    final iconName = (map['icon'] ??
                                            map['Icon'] ??
                                            '')
                                        .toString();
                                    final colorHex = (map['color'] ??
                                            map['Color'] ??
                                            '')
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
        border: Border(
          bottom: BorderSide(color: _Palette.divider),
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
                color: _Palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _Palette.red.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _Palette.red.withOpacity(0.3)),
              ),
              child: Text(
                bus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: _Palette.brightRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Row icon/type colors are driven by the backend ('color' field per
  // activity) so different event types stay visually distinguishable —
  // this logic is unchanged, only the fallback tone now matches the
  // SafeWay red identity instead of green.
  Color _hexToColor(String hexString) {
    if (hexString.isEmpty) {
      return _Palette.brightRed;
    }
    try {
      final hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('ff$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return _Palette.brightRed;
    } catch (_) {
      return _Palette.brightRed;
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

/// Small red-gradient retry button used in the error state.
class _RetryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _Palette.redGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _Palette.red.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Try again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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