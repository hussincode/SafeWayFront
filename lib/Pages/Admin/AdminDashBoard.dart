import 'package:flutter/material.dart';
 
// ─── Models ───────────────────────────────────────────────────────────────────
 
class RecentActivity {
  final String name;
  final String busInfo;
  final String action;
  final String timeAgo;
  final Color avatarColor;
 
  const RecentActivity({
    required this.name,
    required this.busInfo,
    required this.action,
    required this.timeAgo,
    required this.avatarColor,
  });
}
 
// ─── Admin Dashboard Screen ───────────────────────────────────────────────────
 
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
 
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
 
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF3B82F6);
  static const Color _green     = Color(0xFF16A34A);
  static const Color _orange    = Color(0xFFEA580C);
  static const Color _purple    = Color(0xFF7C3AED);
  static const Color _bgGrey    = Color(0xFFF3F4F6);
  static const Color _cardBg    = Colors.white;
  static const Color _textDark  = Color(0xFF111827);
  static const Color _textGrey  = Color(0xFF6B7280);
  static const Color _border    = Color(0xFFE5E7EB);
 
  int _selectedIndex = 0;
 
  final List<RecentActivity> _activities = [
    RecentActivity(
      name: 'Emma Johnson',
      busInfo: 'Bus #12',
      action: 'attendant',
      timeAgo: '2m ago',
      avatarColor: Color(0xFF3B82F6),
    ),
    RecentActivity(
      name: 'Liam Smith',
      busInfo: 'Bus #8',
      action: 'Left',
      timeAgo: '5m ago',
      avatarColor: Color(0xFF10B981),
    ),
    RecentActivity(
      name: 'Olivia Brown',
      busInfo: 'Bus #3',
      action: 'attendant',
      timeAgo: '8m ago',
      avatarColor: Color(0xFFF59E0B),
    ),
    RecentActivity(
      name: 'Noah Davis',
      busInfo: 'Bus #12',
      action: 'Left',
      timeAgo: '12m ago',
      avatarColor: Color(0xFFEF4444),
    ),
  ];
 
  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(),
                  const SizedBox(height: 18),
                  _buildQuickActions(),
                  const SizedBox(height: 18),
                  _buildLiveTracking(),
                  const SizedBox(height: 18),
                  _buildRecentActivity(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
 
  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 16,
        right: 16,
        bottom: 18,
      ),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SchoolBus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Track & Manage',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Notification bell
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 22),
          ),
        ],
      ),
    );
  }
 
  // ── Overview Section ───────────────────────────────────────────────────────
  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.people_outline,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: _primary,
                value: '1,245',
                label: 'Total Students',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                icon: Icons.directions_bus_outlined,
                iconBg: const Color(0xFFECFDF5),
                iconColor: _green,
                value: '38',
                label: 'Active Buses',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.attach_money,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: _orange,
                value: '127',
                label: 'Unpaid Students',
              ),
            ),
            const SizedBox(width: 12),
            // Empty card or another stat
            Expanded(
              child: _statCard(
                icon: Icons.attach_money,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: _orange,
                value: '127',
                label: 'Unpaid Students',
                showAction: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
 
  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    bool showAction = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (showAction)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money,
                      color: Colors.white, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: _textGrey)),
        ],
      ),
    );
  }
 
  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _quickAction(
              icon: Icons.person_add_outlined,
              label: 'Add Driver',
              color: _primary,
              bg: const Color(0xFFEFF6FF),
              onTap: () => _showSnack('Add Driver tapped'),
            ),
            _quickAction(
              icon: Icons.add_circle_outline,
              label: 'Add Student',
              color: _green,
              bg: const Color(0xFFECFDF5),
              onTap: () => _showSnack('Add Student tapped'),
            ),
            _quickAction(
              icon: Icons.route_outlined,
              label: 'Create Route',
              color: _purple,
              bg: const Color(0xFFF5F3FF),
              onTap: () => _showSnack('Create Route tapped'),
            ),
          ],
        ),
      ],
    );
  }
 
  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textDark)),
        ],
      ),
    );
  }
 
  // ── Live Tracking ──────────────────────────────────────────────────────────
  Widget _buildLiveTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Live Tracking',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textDark)),
            Text('38 buses active',
                style:
                    const TextStyle(fontSize: 12, color: _textGrey)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFE2E8F0),
            image: const DecorationImage(
              // Map placeholder — replace with FlutterMap widget
              image: NetworkImage(
                'https://tile.openstreetmap.org/12/2048/1360.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Overlay gradient for readability
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Live badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text('Live',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showSnack('Opening all buses...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View All Buses',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
 
  // ── Recent Activity ────────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textDark)),
            GestureDetector(
              onTap: () => _showSnack('View all activities'),
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 13,
                      color: _primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: _activities
                .asMap()
                .entries
                .map((e) => _activityRow(e.value, e.key == _activities.length - 1))
                .toList(),
          ),
        ),
      ],
    );
  }
 
  Widget _activityRow(RecentActivity activity, bool isLast) {
    final bool isScanned = activity.action == 'Scanned';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar circle with initials
              CircleAvatar(
                radius: 20,
                backgroundColor: activity.avatarColor.withOpacity(0.15),
                child: Text(
                  activity.name[0],
                  style: TextStyle(
                      color: activity.avatarColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textDark)),
                    const SizedBox(height: 2),
                    Text(activity.busInfo,
                        style: const TextStyle(
                            fontSize: 12, color: _textGrey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isScanned
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.action,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isScanned ? _green : _orange),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(activity.timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: _textGrey)),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 14),
      ],
    );
  }
 
  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'icon': Icons.map_outlined, 'activeIcon': Icons.map, 'label': 'Routes'},
      {
        'icon': Icons.people_outline,
        'activeIcon': Icons.people,
        'label': 'Students'
      },
      {
        'icon': Icons.payment_outlined,
        'activeIcon': Icons.payment,
        'label': 'Payments'
      },
    ];
 
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final bool active = idx == _selectedIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? _primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                        color: active ? _primary : _textGrey,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active ? _primary : _textGrey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
 
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}