import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/Pages/Parents/Live_Bus_Tracker.dart';
import 'package:safeway/Pages/login_page.dart';
import 'package:safeway/services/api_config.dart';

class ParentInfoModel {
  final String fullName;
  final String uniqueID;
  final int totalChildren;
  final int onBoard;
  final List<ChildModel> children;

  ParentInfoModel({
    required this.fullName,
    required this.uniqueID,
    required this.totalChildren,
    required this.onBoard,
    required this.children,
  });

  factory ParentInfoModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List? ?? const [];
    final children = rawChildren
        .whereType<Map>()
        .map((item) => ChildModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return ParentInfoModel(
      fullName: json['fullName']?.toString() ?? '',
      uniqueID: json['uniqueID']?.toString() ?? '',
      totalChildren:
          int.tryParse('${json['totalChildren'] ?? children.length}') ??
          children.length,
      onBoard: int.tryParse('${json['onBoard'] ?? 0}') ?? 0,
      children: children,
    );
  }
}

class ChildModel {
  final String name;
  final String route;
  final String busNumber;
  final String eta;
  final String pickupStation;
  final String subscription;
  final bool isOnBoard;
  final String? boardingNote;

  ChildModel({
    required this.name,
    required this.route,
    required this.busNumber,
    required this.eta,
    required this.pickupStation,
    required this.subscription,
    required this.isOnBoard,
    this.boardingNote,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
    name: json['name']?.toString() ?? '',
    route: json['route']?.toString() ?? 'Route pending',
    busNumber: json['busNumber']?.toString() ?? '--',
    eta: json['eta']?.toString() ?? '--',
    pickupStation: json['pickupStation']?.toString() ?? '--',
    subscription: json['subscription']?.toString() ?? 'UNPAID',
    isOnBoard: json['isOnBoard'] == true,
    boardingNote: json['boardingNote']?.toString(),
  );
}

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});
  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070708), Color(0xFF101012), Color(0xFF18181B)],
  );
  static const red = Color(0xFFD32F2F);
  static const lightRed = Color(0xFFEF4444);
  static const darkRed = Color(0xFF991B1B);
  static const burgundy = Color(0xFF65171B);
  static const primaryText = Color(0xFFF5F5F5);
  static const secondaryText = Color(0xFFB8B8BC);
  static const mutedText = Color(0xFF77777D);
  static const glass = Color(0x14141416);
  static const glassBorder = Color(0x2AFFFFFF);

  final storage = const FlutterSecureStorage();
  ParentInfoModel? parentInfo;
  bool isLoading = true;
  String? errorMessage;
  int selectedTab = 0;
  late final AnimationController busAnimation;

  @override
  void initState() {
    super.initState();
    busAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _loadParentInfo();
  }

  @override
  void dispose() {
    busAnimation.dispose();
    super.dispose();
  }

  Future<void> _loadParentInfo() async {
    try {
      final userId = int.tryParse(await storage.read(key: 'userId') ?? '') ?? 0;
      if (userId == 0) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'Please sign in again.';
          });
        }
        return;
      }
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/auth/parent-info/$userId'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          parentInfo = ParentInfoModel.fromJson(jsonDecode(response.body));
          errorMessage = null;
        });
      } else {
        setState(() => errorMessage = 'Unable to load your family details.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => errorMessage = 'Connection unavailable. Pull to retry.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _openTracker() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LiveBusTrackingScreen()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070708),
      body: Container(
        decoration: const BoxDecoration(gradient: background),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -130,
                right: -110,
                child: _AmbientGlow(color: darkRed, size: 300),
              ),
              const Positioned(
                top: 220,
                left: -170,
                child: _AmbientGlow(color: burgundy, size: 280),
              ),
              const Positioned(
                bottom: -170,
                right: -110,
                child: _AmbientGlow(color: darkRed, size: 320),
              ),
              Column(
                children: [
                  Expanded(child: _buildContent()),
                  _buildBottomNav(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: lightRed, strokeWidth: 2),
      );
    }
    return RefreshIndicator(
      color: lightRed,
      backgroundColor: const Color(0xFF18181B),
      onRefresh: _loadParentInfo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildHero(),
            const SizedBox(height: 24),
            if (errorMessage != null) ...[
              _buildError(),
              const SizedBox(height: 14),
            ],
            _buildOverview(),
            const SizedBox(height: 22),
            _sectionTitle('YOUR FAMILY', 'Every journey, in one calm place.'),
            const SizedBox(height: 14),
            if (parentInfo?.children.isNotEmpty == true)
              ...parentInfo!.children.map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildChildCard(child),
                ),
              )
            else
              _buildEmptyChildren(),
            const SizedBox(height: 8),
            _buildTrackerButton(),
            const SizedBox(height: 24),
            _sectionTitle('RECENT ALERTS', 'Stay close to every update.'),
            const SizedBox(height: 14),
            _buildAlertPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = parentInfo?.fullName ?? 'Parent';
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [red, darkRed]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: red.withOpacity(.3), blurRadius: 18)],
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'SafeWay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              Text(
                'SMART SCHOOL BUS',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
        _iconButton(Icons.notifications_none_rounded, _showNotifications),
        const SizedBox(width: 9),
        GestureDetector(
          onTap: _showProfile,
          child: _avatar(_initials(name), darkRed),
        ),
      ],
    );
  }

  Widget _buildHero() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WELCOME BACK',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: lightRed,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Move together\nArrive safer.',
              style: TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Good morning, ${parentInfo?.fullName ?? 'Parent'}.\nYour family route pulse is here.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      AnimatedBuilder(
        animation: busAnimation,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -4 * busAnimation.value),
          child: child,
        ),
        child: const _BusIllustration(),
      ),
    ],
  );

  Widget _buildOverview() {
    final total = parentInfo?.totalChildren ?? 0;
    final board = parentInfo?.onBoard ?? 0;
    final paid =
        parentInfo?.children
            .where((child) => child.subscription.toUpperCase() == 'PAID')
            .length ??
        0;
    return _glassCard(
      Row(
        children: [
          _stat('$total', 'children'),
          _divider(),
          _stat('$board', 'on board', accent: true),
          _divider(),
          _stat('$paid/$total', 'paid'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label, String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w800,
          color: lightRed,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: primaryText,
        ),
      ),
    ],
  );

  Widget _buildChildCard(ChildModel child) => _glassCard(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(_initials(child.name), red),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name.isEmpty ? 'Student' : child.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    child.route,
                    style: const TextStyle(fontSize: 12, color: mutedText),
                  ),
                ],
              ),
            ),
            _status(child.isOnBoard ? 'ON BOARD' : 'WAITING', child.isOnBoard),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              _metric(Icons.directions_bus_rounded, child.busNumber, 'bus'),
              _metric(Icons.schedule_rounded, child.eta, 'eta'),
              _metric(
                Icons.location_on_outlined,
                child.pickupStation,
                'pickup',
              ),
            ],
          ),
        ),
        if (child.boardingNote?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: lightRed, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  child.boardingNote!,
                  style: const TextStyle(fontSize: 12, color: secondaryText),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _buildEmptyChildren() => _glassCard(
    const Row(
      children: [
        Icon(Icons.family_restroom_rounded, color: mutedText),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'No children are linked to your account yet.',
            style: TextStyle(color: secondaryText),
          ),
        ),
      ],
    ),
  );

  Widget _buildTrackerButton() => GestureDetector(
    onTap: _openTracker,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [darkRed, red]),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: red.withOpacity(.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.near_me_rounded, color: Colors.white, size: 19),
          SizedBox(width: 9),
          Text(
            'Open live tracking',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
        ],
      ),
    ),
  );

  Widget _buildAlertPreview() {
    final hasChild = parentInfo?.children.isNotEmpty == true;
    final bus = hasChild ? parentInfo!.children.first.busNumber : 'Your family';
    return GestureDetector(
      onTap: _showNotifications,
      child: _glassCard(
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x331F0A0C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: lightRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasChild
                        ? '$bus route is ready to track'
                        : 'Your family updates will appear here',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to view notifications',
                    style: TextStyle(fontSize: 12, color: mutedText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: mutedText),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => _glassCard(
    Row(
      children: [
        const Icon(Icons.wifi_off_rounded, color: lightRed, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            errorMessage!,
            style: const TextStyle(fontSize: 12, color: secondaryText),
          ),
        ),
        TextButton(
          onPressed: _loadParentInfo,
          child: const Text('Retry', style: TextStyle(color: lightRed)),
        ),
      ],
    ),
  );

  Widget _buildBottomNav() => Container(
    margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xE6101012),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: glassBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _nav(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
        _nav(1, Icons.near_me_outlined, Icons.near_me_rounded, 'Track'),
        _nav(
          2,
          Icons.notifications_none_rounded,
          Icons.notifications_rounded,
          'Alerts',
        ),
        _nav(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
      ],
    ),
  );

  Widget _nav(int index, IconData icon, IconData activeIcon, String label) {
    final active = selectedTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => selectedTab = index);
        if (index == 1) _openTracker();
        if (index == 2) _showNotifications();
        if (index == 3) _showProfile();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: active ? 13 : 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: active ? const Color(0x331F0A0C) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 20,
              color: active ? lightRed : mutedText,
            ),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: lightRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showNotifications() async {
    setState(() => selectedTab = 2);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(storage: storage),
    );
  }

  void _showProfile() {
    setState(() => selectedTab = 3);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF18181B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: mutedText,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 22),
              _avatar(_initials(parentInfo?.fullName ?? 'Parent'), darkRed),
              const SizedBox(height: 10),
              Text(
                parentInfo?.fullName ?? 'Parent account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                parentInfo?.uniqueID ?? 'SafeWay parent',
                style: const TextStyle(fontSize: 12, color: mutedText),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheet);
                  _logout();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: glassBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: lightRed, size: 19),
                      SizedBox(width: 10),
                      Text(
                        'Sign out',
                        style: TextStyle(
                          color: lightRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: glass,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: glassBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.25),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: child,
      ),
    ),
  );
  Widget _iconButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: glass,
        shape: BoxShape.circle,
        border: Border.all(color: glassBorder),
      ),
      child: Icon(icon, color: primaryText, size: 20),
    ),
  );
  Widget _avatar(String label, Color color) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: lightRed.withOpacity(.55)),
    ),
    alignment: Alignment.center,
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
  );
  Widget _status(String label, bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: active ? const Color(0x331F0A0C) : const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: active ? darkRed : glassBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? lightRed : mutedText,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: active ? lightRed : mutedText,
          ),
        ),
      ],
    ),
  );
  Widget _metric(IconData icon, String value, String label) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: lightRed, size: 17),
        const SizedBox(height: 5),
        Text(
          value.isEmpty ? '--' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: mutedText)),
      ],
    ),
  );
  Widget _stat(String value, String label, {bool accent = false}) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accent ? lightRed : primaryText,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: mutedText)),
      ],
    ),
  );
  Widget _divider() => Container(width: 1, height: 32, color: glassBorder);
  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return (parts.length == 1
            ? parts.first[0]
            : '${parts.first[0]}${parts.last[0]}')
        .toUpperCase();
  }
}

class _NotificationsSheet extends StatefulWidget {
  final FlutterSecureStorage storage;
  const _NotificationsSheet({required this.storage});
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final id = await widget.storage.read(key: 'userId') ?? '0';
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/notifications/user/$id'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List? ?? [];
        setState(() {
          notifications = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * .72,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF77777D),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 22),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'NOTIFICATIONS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "You're in the loop",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF5F5F5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEF4444),
                      strokeWidth: 2,
                    ),
                  )
                : notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(color: Color(0xFF77777D)),
                    ),
                  )
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _notificationTile(notifications[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2AFFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? 'SafeWay update',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['subtitle']?.toString() ??
                      item['message']?.toString() ??
                      '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8B8BC),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['time']?.toString() ?? 'Recently',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF77777D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusIllustration extends StatelessWidget {
  const _BusIllustration();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 86,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x66D32F2F), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            top: 14,
            child: Container(
              width: 72,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFF991B1B)],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [
                  BoxShadow(color: Color(0x99D32F2F), blurRadius: 14),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 7,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        for (var index = 0; index < 3; index++)
                          Expanded(
                            child: Container(
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x55FFFFFF),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(bottom: -4, left: 10, child: _wheel()),
                  Positioned(bottom: -4, right: 10, child: _wheel()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _wheel() => Container(
    width: 13,
    height: 13,
    decoration: BoxDecoration(
      color: const Color(0xFF101012),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF77777D), width: 2),
    ),
  );
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientGlow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(.24), color.withOpacity(0)],
        ),
      ),
    ),
  );
}
