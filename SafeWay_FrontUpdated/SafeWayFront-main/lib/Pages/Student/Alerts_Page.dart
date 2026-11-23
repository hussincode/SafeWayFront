import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
    Color iconBgColor = const Color(0xFF65171B);
    Color iconTextColor = const Color(0xFFEF4444);

    if (type == 'bus') {
      iconData = Icons.directions_bus_rounded;
      iconBgColor = const Color(0xFF65171B);
      iconTextColor = const Color(0xFFEF4444);
    } else if (type == 'success') {
      iconData = Icons.check_circle_rounded;
      iconBgColor = const Color(0xFF65171B);
      iconTextColor = const Color(0xFFEF4444);
    } else if (type == 'warning' || type == 'error') {
      iconData = Icons.error_outline_rounded;
      iconBgColor = const Color(0xFF3A1719);
      iconTextColor = const Color(0xFFFF6B6B);
    } else {
      iconData = Icons.access_time_filled_rounded;
      iconBgColor = const Color(0xFF65171B);
      iconTextColor = const Color(0xFFEF4444);
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

  String _selectedFilter = 'All';

  static const Color _backgroundTop = Color(0xFF050506);
  static const Color _backgroundMid = Color(0xFF0C0C0F);
  static const Color _backgroundBottom = Color(0xFF151518);

  static const Color _surface = Color(0xFF18181B);

  static const Color _primaryRed = Color(0xFFD32F2F);
  static const Color _brightRed = Color(0xFFEF4444);
  static const Color _darkRed = Color(0xFF991B1B);
  static const Color _burgundy = Color(0xFF65171B);

  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFB8B8BC);
  static const Color _textMuted = Color(0xFF77777D);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final userIdStr = await _storage.read(key: 'userId') ?? '0';
      final userId = int.tryParse(userIdStr) ?? 0;

      if (userId == 0) {
        if (!mounted) return;

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

        final notifications = data
            .map(
              (j) => NotificationModel.fromJson(
                j as Map<String, dynamic>,
              ),
            )
            .toList();

        if (!mounted) return;

        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load notifications';
        });
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error connecting to server';
      });
    }
  }

  bool get _isBottomNavShown =>
      widget.showBottomNav ?? false;

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'All') {
      return _notifications;
    }

    return _notifications.where((notification) {
      final text =
          '${notification.title} ${notification.subtitle}'.toLowerCase();

      if (_selectedFilter == 'Bus') {
        return text.contains('bus') ||
            text.contains('driver') ||
            text.contains('vehicle');
      }

      if (_selectedFilter == 'Trip') {
        return text.contains('trip') ||
            text.contains('route') ||
            text.contains('pickup') ||
            text.contains('stop');
      }

      if (_selectedFilter == 'Alerts') {
        return text.contains('alert') ||
            text.contains('warning') ||
            text.contains('delay') ||
            text.contains('error');
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundTop,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _backgroundTop,
              _backgroundMid,
              _backgroundBottom,
            ],
            stops: [
              0.0,
              0.55,
              1.0,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -100,
              child: _redGlow(240),
            ),

            Positioned(
              bottom: 100,
              left: -140,
              child: _redGlow(260),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    _buildTopBar(_unreadCount),

                    const SizedBox(height: 22),

                    _buildIntroSection(),

                    const SizedBox(height: 22),

                    _buildFilterSection(),

                    const SizedBox(height: 18),

                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _redGlow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _darkRed.withOpacity(0.16),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withOpacity(0.12),
            blurRadius: 100,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(int unreadCount) {
    return Row(
      children: [
        if (!_isBottomNavShown)
          _glassIconButton(
            Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          )
        else
          const SizedBox(width: 46),

        const Expanded(
          child: Center(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        ),

        if (unreadCount > 0)
          GestureDetector(
            onTap: () {
              setState(() {
                for (final notification in _notifications) {
                  notification.isRead = true;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _burgundy.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primaryRed.withOpacity(0.20),
                ),
              ),
              child: const Text(
                'Mark all',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _brightRed,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 46),
      ],
    );
  }

  Widget _glassIconButton(
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.09),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: _burgundy.withOpacity(0.40),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _brightRed.withOpacity(0.16),
            ),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: _brightRed,
            size: 27,
          ),
        ),

        const SizedBox(width: 15),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stay updated',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Important updates about your bus, trips and journey.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    const filters = [
      'All',
      'Bus',
      'Trip',
      'Alerts',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? _primaryRed
                      : Colors.white.withOpacity(0.045),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected
                        ? _brightRed
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : _textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _brightRed,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        subtitle: _errorMessage!,
      );
    }

    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications',
        subtitle: _selectedFilter == 'All'
            ? 'You are all caught up.'
            : 'No $_selectedFilter notifications right now.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: _brightRed,
      backgroundColor: _surface,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];

          return _buildNotificationItem(
            notification,
            index,
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel item,
    int index,
  ) {
    final isLast =
        index == _filteredNotifications.length - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.isRead
                              ? Colors.white.withOpacity(0.06)
                              : _brightRed.withOpacity(0.45),
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 20,
                      ),
                    ),

                    if (!item.isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: _brightRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 18,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.isRead
                    ? Colors.white.withOpacity(0.035)
                    : _burgundy.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: item.isRead
                      ? Colors.white.withOpacity(0.06)
                      : _primaryRed.withOpacity(0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),

                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 7),

                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: _textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? _textMuted
                              : _brightRed,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Text(
                        item.isRead
                            ? 'Read'
                            : 'New notification',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: item.isRead
                              ? _textMuted
                              : _brightRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 30,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.045),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _burgundy.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: _brightRed,
                    size: 29,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _textMuted,
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