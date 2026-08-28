import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safeway/Constant/Constant_Color.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/Pages/Parents/Live_Bus_Tracker.dart';
import 'package:safeway/services/api_config.dart';
import 'package:safeway/Pages/login_page.dart';

// ── Parent Info Model ──
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

  factory ParentInfoModel.fromJson(Map<String, dynamic> j) => ParentInfoModel(
    fullName: j['fullName'] ?? '',
    uniqueID: j['uniqueID'] ?? '',
    totalChildren: j['totalChildren'] ?? 0,
    onBoard: j['onBoard'] ?? 0,
    children: (j['children'] as List)
        .map((c) => ChildModel.fromJson(c))
        .toList(),
  );
}

// ── Child Model ──
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

  factory ChildModel.fromJson(Map<String, dynamic> j) => ChildModel(
    name: j['name'] ?? '',
    route: j['route'] ?? '',
    busNumber: j['busNumber'] ?? '',
    eta: j['eta'] ?? '',
    pickupStation: j['pickupStation'] ?? '',
    subscription: j['subscription'] ?? 'UNPAID',
    isOnBoard: j['isOnBoard'] ?? false,
    boardingNote: j['boardingNote'],
  );
}

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _storage = const FlutterSecureStorage();

  ParentInfoModel? _parentInfo;
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadParentInfo();
  }

  Future<void> _loadParentInfo() async {
    try {
      final userIdStr = await _storage.read(key: 'userId') ?? '0';
      final userId = int.tryParse(userIdStr) ?? 0;

      if (userId == 0) {
        setState(() => _isLoading = false);
        return;
      }

      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/parent-info/$userId'),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _parentInfo = ParentInfoModel.fromJson(jsonDecode(res.body));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('ParentInfo error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.softBackground),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGreen,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 18),

                            if (_parentInfo != null &&
                                _parentInfo!.children.isNotEmpty)
                              ..._parentInfo!.children.map(
                                (child) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildChildCard(child),
                                ),
                              )
                            else
                              _buildEmptyChildrenCard(),

                            _buildViewLiveMapButton(),
                            const SizedBox(height: 24),

                            _buildSectionLabel('AT A GLANCE'),
                            const SizedBox(height: 4),
                            const Text(
                              'Family pulse',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildFamilyPulseRow(),
                            const SizedBox(height: 24),

                            _buildSectionLabel('RECENT ALERTS'),
                            const SizedBox(height: 4),
                            const Text(
                              'Stay in the loop',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildAlertCard(
                              icon: Icons.access_time_rounded,
                              iconBg: const Color(0xFFDCEBFF),
                              iconColor: const Color(0xFF2979FF),
                              title: 'Bus BUS-101 arriving in 5 minutes',
                              subtitle: 'Main Street Station',
                            ),
                            const SizedBox(height: 12),
                            _buildAlertCard(
                              icon: Icons.check_rounded,
                              iconBg: AppColors.lightMint,
                              iconColor: AppColors.accentGreen,
                              title: 'Liam Smith boarded the bus',
                              subtitle: 'Park Avenue Station · 16m ago',
                            ),
                            const SizedBox(height: 12),
                            _buildAlertCard(
                              icon: Icons.error_outline_rounded,
                              iconBg: const Color(0xFFFFF3D6),
                              iconColor: const Color(0xFFF59E0B),
                              title: 'BUS-101 delayed by 10 minutes',
                              subtitle: 'Due to traffic · 31m ago',
                            ),
                          ],
                        ),
                      ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader() {
    final name = _parentInfo?.fullName ?? 'Loading...';
    final initials = _initialsFrom(name);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GOOD MORNING',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hi, $name',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Here is your family route pulse.",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _roundIconButton(Icons.notifications_none_rounded, onTap: () {}),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
            );
          },
          child: _avatarCircle(label: initials, bg: const Color(0xFFF08A5D)),
        ),
      ],
    );
  }

  String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _roundIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _avatarCircle({required String label, required Color bg}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---------------- CHILD CARD ----------------

  Widget _buildEmptyChildrenCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          'No children linked to your account.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatarCircle(
                label: _initialsFrom(child.name),
                bg: const Color(0xFFF3B6A0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      child.route,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                child.isOnBoard ? 'ON BOARD' : 'NOT BOARDED',
                active: child.isOnBoard,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _infoItem(
                icon: Icons.directions_bus_rounded,
                title: child.busNumber,
                subtitle: 'Bus',
              ),
              _infoItem(
                icon: Icons.access_time_rounded,
                title: child.eta,
                subtitle: 'Arriving',
              ),
              _infoItem(
                icon: Icons.location_on_outlined,
                title: child.pickupStation,
                subtitle: 'Pickup',
              ),
              _infoItem(
                icon: Icons.check_circle_outline_rounded,
                title: child.subscription,
                subtitle: 'Subscription',
              ),
            ],
          ),
          if (child.boardingNote != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightMint.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      child.boardingNote!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.badgeBg : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.badgeDot : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.accentGreen : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.accentGreen),
          const SizedBox(height: 6),
          Text(
            title.isEmpty ? '--' : title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------- VIEW LIVE MAP BUTTON ----------------

  Widget _buildViewLiveMapButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LiveBusTrackingScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.darkNavy,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'View live map',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.near_me_rounded, size: 16, color: AppColors.accentGreen),
          ],
        ),
      ),
    );
  }

  // ---------------- SECTION LABEL ----------------

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
        color: AppColors.accentGreen,
      ),
    );
  }

  // ---------------- FAMILY PULSE ----------------

  Widget _buildFamilyPulseRow() {
    final total = _parentInfo?.totalChildren ?? 0;
    final onBoard = _parentInfo?.onBoard ?? 0;
    final paidCount =
        _parentInfo?.children.where((c) => c.subscription == 'PAID').length ??
        0;
    final paidPct = total == 0 ? 0 : ((paidCount / total) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _pulseStat(value: '$total', label: 'Child${total == 1 ? '' : 'ren'}'),
          _pulseDivider(),
          _pulseStat(
            value: '$onBoard',
            label: 'On board',
            valueColor: AppColors.accentGreen,
          ),
          _pulseDivider(),
          _pulseStat(value: '$paidPct%', label: 'Paid'),
        ],
      ),
    );
  }

  Widget _pulseDivider() {
    return Container(width: 1, height: 34, color: AppColors.divider);
  }

  Widget _pulseStat({
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ---------------- ALERTS ----------------

  Widget _buildAlertCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ---------------- BOTTOM NAV ----------------

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
          _navItem(1, Icons.near_me_outlined, Icons.near_me, 'Track'),
          _navItem(
            2,
            Icons.notifications_none_rounded,
            Icons.notifications_rounded,
            'Alerts',
          ),
          _navItem(
            3,
            Icons.person_outline_rounded,
            Icons.person_rounded,
            'Profile',
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LiveBusTrackingScreen()),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 550),
        curve: Curves.fastOutSlowIn,
        padding: active
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? AppColors.lightMint : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastLinearToSlowEaseIn,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Icon(
                  active ? activeIcon : icon,
                  key: ValueKey(active ? activeIcon : icon),
                  size: 22,
                  color: AppColors.accentGreen,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
