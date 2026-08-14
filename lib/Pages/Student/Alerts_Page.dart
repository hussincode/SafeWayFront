import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/Constant/Constant_Color.dart';
import 'package:safeway/services/api_config.dart';

class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String time;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.time,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? 'info';
    IconData iconData = Icons.notifications_none_rounded;
    Color iconBgColor = AppColors.lightMint;
    Color iconTextColor = AppColors.accentGreen;

    if (type == 'bus') {
      iconData = Icons.directions_bus_rounded;
      iconBgColor = AppColors.lightMint;
      iconTextColor = AppColors.accentGreen;
    } else if (type == 'success') {
      iconData = Icons.check_circle_rounded;
      iconBgColor = AppColors.lightMint;
      iconTextColor = AppColors.accentGreen;
    } else if (type == 'warning' || type == 'error') {
      iconData = Icons.error_outline_rounded;
      iconBgColor = const Color(0xFFFDE8E8);
      iconTextColor = Colors.redAccent;
    } else {
      iconData = Icons.access_time_filled_rounded;
      iconBgColor = AppColors.lightMint;
      iconTextColor = AppColors.accentGreen;
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: iconData,
      iconBg: iconBgColor,
      iconColor: iconTextColor,
      time: json['time'] ?? 'Recently',
      isRead: json['isRead'] ?? false,
    );
  }
}

class AlertsPage extends StatefulWidget {
  final bool? showBottomNav;
  final Widget? bottomNavigationBar;

  const AlertsPage({
    super.key,
    this.showBottomNav,
    this.bottomNavigationBar,
  });

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final _storage = const FlutterSecureStorage();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final userIdStr = await _storage.read(key: 'userId') ?? '0';
      final userId = int.tryParse(userIdStr) ?? 0;

      if (userId == 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/notifications/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notifications = data
              .map((j) => NotificationModel.fromJson(j))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load notifications';
        });
      }
    } catch (e) {
      print('Fetch notifications error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error connecting to server';
        });
      }
    }
  }

  bool get _isBottomNavShown => widget.showBottomNav ?? false;

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.softBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // App Bar / Top Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isBottomNavShown)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 42),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    if (unreadCount > 0)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            for (var n in _notifications) {
                              n.isRead = true;
                            }
                          });
                        },
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 42),
                  ],
                ),
                const SizedBox(height: 28),

                // Title Section
                const Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "You're in\nthe loop",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 24),

                // Content View
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGreen,
                          ),
                        )
                      : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : _notifications.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications yet.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchNotifications,
                          color: AppColors.accentGreen,
                          child: ListView.separated(
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: item.isRead
                                      ? Colors.white
                                      : const Color(0xFFF9FAF8),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: item.isRead
                                        ? Colors.transparent
                                        : AppColors.accentGreen.withOpacity(
                                            0.3,
                                          ),
                                    width: 1.5,
                                  ),
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
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: item.iconBg,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        color: item.iconColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: item.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.bold,
                                              color: AppColors.darkNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.subtitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
