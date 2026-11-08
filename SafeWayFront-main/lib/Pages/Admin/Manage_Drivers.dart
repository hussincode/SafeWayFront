import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:safeway/services/admin_service.dart';

// ─────────────────────────────────────────────────────────────
//  SafeWay design system — dark glass + red accent
//  (Identical design tokens and structure to Student_Man.dart)
// ─────────────────────────────────────────────────────────────
class _Palette {
  static const bg = Color(0xFF070708);
  static const bg2 = Color(0xFF101012);
  static const surface = Color(0xFF18181B);

  static const red = Color(0xFFD32F2F);
  static const brightRed = Color(0xFFEF4444);
  static const darkRed = Color(0xFF991B1B);
  static const burgundy = Color(0xFF65171B);
  static const roseRed = Color(0xFFB0343B);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB8B8BC);
  static const textMuted = Color(0xFF77777D);

  static const glassFill = Color(0x14FFFFFF);
  static const glassFillSoft = Color(0x08FFFFFF);
  static const glassBorder = Color(0x2AFFFFFF);
  static const inputFill = Color(0x0FFFFFFF);
  static const divider = Color(0x1AFFFFFF);

  static const redGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [darkRed, red],
  );

  static const avatarColors = [
    brightRed,
    red,
    burgundy,
    roseRed,
    Color(0xFF8A8A90),
  ];
}

// ─────────────────────────────────────────────────────────────
//  Shared visual primitives
// ─────────────────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  Widget _glow(double size, Color color, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Palette.bg2, _Palette.bg, _Palette.surface],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(top: -110, right: -90, child: _glow(300, _Palette.red, 0.22)),
        Positioned(top: 300, left: -150, child: _glow(320, _Palette.burgundy, 0.32)),
        Positioned(
          bottom: -130,
          right: -110,
          child: _glow(300, _Palette.darkRed, 0.26),
        ),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
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
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_Palette.glassFill, _Palette.glassFillSoft],
              ),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  const _RedButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      decoration: BoxDecoration(
        gradient: _Palette.redGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _Palette.red.withOpacity(0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _GhostButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _Palette.textSecondary, size: 15),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: _Palette.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

// ── Models ───────────────────────────────────────────────────────────────────

class Driver {
  final int id;
  final String driverId;
  final String name;
  final String phone;
  final String busId;
  final String route;
  final String status;

  const Driver({
    required this.id,
    required this.driverId,
    required this.name,
    required this.phone,
    required this.busId,
    required this.route,
    required this.status,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory Driver.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] ?? j['driverId'] ?? 0;
    final int parsedId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    return Driver(
      id: parsedId,
      driverId: (j['driverId'] ?? j['uniqueId'] ?? 'DRV$parsedId').toString(),
      name: (j['fullName'] ?? j['name'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      busId: (j['busId'] ?? 'Not assigned').toString(),
      route: (j['route'] ?? 'Not assigned').toString(),
      status: (j['status'] ?? 'Active').toString(),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  List<Driver> _allDrivers = [];
  List<Driver> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';

  final _searchCtrl = TextEditingController();
  final AdminService _adminService = AdminService();

  int get _activeCount => _allDrivers.where((d) => d.isActive).length;
  int get _inactiveCount => _allDrivers.where((d) => !d.isActive).length;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDrivers() async {
    try {
      final raw = await _adminService.getDrivers();
      if (!mounted) return;
      final list = raw.map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _allDrivers = list;
        _filtered = List.from(_allDrivers);
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      final q = _searchQuery.toLowerCase();
      _filtered = _allDrivers.where((d) {
        return q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            d.driverId.toLowerCase().contains(q) ||
            d.busId.toLowerCase().contains(q) ||
            d.route.toLowerCase().contains(q) ||
            d.phone.toLowerCase().contains(q);
      }).toList();
    });
  }

  Color _avatarColor(String initials) {
    if (initials.isEmpty || initials == '?') return _Palette.avatarColors[0];
    final colors = _Palette.avatarColors;
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return _Palette.textPrimary;
      case 'INACTIVE':
        return _Palette.textMuted;
      default:
        return _Palette.brightRed;
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.white.withOpacity(0.10);
      case 'INACTIVE':
        return Colors.white.withOpacity(0.04);
      default:
        return _Palette.brightRed.withOpacity(0.16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _Palette.brightRed,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchDrivers,
                        color: _Palette.brightRed,
                        backgroundColor: _Palette.surface,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExportButton(),
                              const SizedBox(height: 16),
                              _buildFiltersCard(),
                              const SizedBox(height: 16),
                              _buildDriverTable(),
                              const SizedBox(height: 16),
                              _buildSummaryCards(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Palette.bg2,
        border: Border(bottom: BorderSide(color: _Palette.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: _Palette.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Manage Drivers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  Text(
                    'View and manage all driver accounts and bus assignments',
                    style: TextStyle(
                      fontSize: 11,
                      color: _Palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _GhostButton(
              label: 'Export',
              icon: Icons.upload_outlined,
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Exporting driver data...'))),
            ),
            const SizedBox(width: 8),
            _RedButton(
              label: 'Add Driver',
              icon: Icons.add,
              onPressed: () => _showAddDriverDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return _Glass(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GhostButton(
            label: 'Export',
            icon: Icons.upload_outlined,
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Exporting driver data...'))),
          ),
          const SizedBox(width: 8),
          _RedButton(
            label: 'Add Driver',
            icon: Icons.add,
            onPressed: () => _showAddDriverDialog(),
          ),
        ],
      ),
    );
  }

  // ── FILTERS CARD ─────────────────────────────────────────────────────────────
  Widget _buildFiltersCard() {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Drivers',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _Palette.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              style: const TextStyle(fontSize: 14, color: _Palette.textPrimary),
              cursorColor: _Palette.brightRed,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, bus, or route...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: _Palette.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: _Palette.textMuted,
                  size: 18,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                        child: const Icon(
                          Icons.close,
                          color: _Palette.textMuted,
                          size: 16,
                        ),
                      )
                    : null,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DRIVER TABLE ─────────────────────────────────────────────────────────────
  Widget _buildDriverTable() {
    final r = BorderRadius.circular(20);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: _Palette.redGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _Palette.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver Records',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Showing ${_filtered.length} of ${_allDrivers.length} drivers',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                          child: const Text(
                            'Clear search',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Column labels
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'DRIVER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'ROUTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(
                          'ACTIONS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _Palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: _Palette.divider),

                // Rows
                if (_filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No drivers match your filters.',
                        style: TextStyle(fontSize: 13, color: _Palette.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: _Palette.divider),
                    itemBuilder: (_, i) => _buildDriverRow(_filtered[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverRow(Driver d) {
    final color = _avatarColor(d.initials);

    return InkWell(
      onTap: () => _showDriverDetail(d),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar + name + bus
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text(
                        d.initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _Palette.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_bus_outlined,
                              size: 10,
                              color: _Palette.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                d.busId,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _Palette.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Route
            Expanded(
              flex: 3,
              child: Text(
                d.route,
                style: const TextStyle(
                  fontSize: 13,
                  color: _Palette.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status badge
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(d.status),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusColor(d.status).withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    d.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(d.status),
                    ),
                  ),
                ),
              ),
            ),

            // Actions: Edit and Delete
            SizedBox(
              width: 76,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: _Palette.textSecondary),
                    tooltip: 'Edit driver',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    onPressed: () => _showEditDriverDialog(d),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: _Palette.brightRed),
                    tooltip: 'Delete driver',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    onPressed: () => _confirmDeleteDriver(d),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY CARDS ─────────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Column(
      children: [
        _summaryCard(
          label: 'Active Drivers',
          count: _activeCount,
          color: _Palette.textPrimary,
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          label: 'Inactive Drivers',
          count: _inactiveCount,
          color: _Palette.roseRed,
          icon: Icons.cancel_outlined,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          label: 'Total Drivers',
          count: _allDrivers.length,
          color: _Palette.brightRed,
          icon: Icons.directions_bus_outlined,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_Palette.glassFill, _Palette.glassFillSoft],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _Palette.glassBorder),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: color),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _Palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── DRIVER DETAIL BOTTOM SHEET ───────────────────────────────────────────────
  void _showDriverDetail(Driver d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.bg2.withOpacity(0.94),
              border: const Border(top: BorderSide(color: _Palette.glassBorder)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _avatarColor(d.initials).withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatarColor(d.initials).withOpacity(0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          d.initials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _avatarColor(d.initials),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _Palette.textPrimary,
                            ),
                          ),
                          Text(
                            'ID: ${d.driverId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _Palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(d.status),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor(d.status).withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        d.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(d.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _detailRow(
                  Icons.directions_bus_outlined,
                  'Bus Number',
                  d.busId,
                ),
                _detailRow(Icons.alt_route_outlined, 'Route', d.route),
                _detailRow(
                  Icons.phone_outlined,
                  'Phone',
                  d.phone.isEmpty ? 'N/A' : d.phone,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GhostButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteDriver(d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RedButton(
                        label: 'Edit Driver',
                        icon: Icons.edit_outlined,
                        expand: true,
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditDriverDialog(d);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _Palette.textMuted),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: _Palette.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDriver(Driver d) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _Palette.glassBorder),
        ),
        title: const Text(
          'Delete Driver',
          style: TextStyle(
            color: _Palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${d.name}?',
          style: const TextStyle(color: _Palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _Palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: _Palette.brightRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting driver...'),
        backgroundColor: _Palette.darkRed,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await _adminService.deleteDriver(id: d.id);
      await _fetchDrivers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver deleted successfully'),
            backgroundColor: _Palette.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete driver: $e'),
            backgroundColor: _Palette.darkRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddDriverDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDriverSheet(
        onAdd: (fullName, busNumber, phone, routeName) async {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding driver...'),
              backgroundColor: _Palette.darkRed,
              behavior: SnackBarBehavior.floating,
            ),
          );

          try {
            await _adminService.addDriver(
              fullName: fullName,
              busNumber: busNumber,
              phone: phone,
              routeName: routeName,
            );

            await _fetchDrivers();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver added successfully'),
                  backgroundColor: _Palette.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add driver: $e'),
                  backgroundColor: _Palette.darkRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditDriverDialog(Driver d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditDriverSheet(
        driver: d,
        onEdit: (fullName, busNumber, phone, routeName) async {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updating driver...'),
              backgroundColor: _Palette.darkRed,
              behavior: SnackBarBehavior.floating,
            ),
          );

          try {
            await _adminService.updateDriver(
              id: d.id,
              fullName: fullName,
              busNumber: busNumber,
              phone: phone,
              routeName: routeName,
            );

            await _fetchDrivers();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver updated successfully'),
                  backgroundColor: _Palette.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update driver: $e'),
                  backgroundColor: _Palette.darkRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ── ADD DRIVER BOTTOM SHEET ─────────────────────────────────────────────────
class _AddDriverSheet extends StatefulWidget {
  final Future<void> Function(
    String fullName,
    String busNumber,
    String phone,
    String routeName,
  ) onAdd;

  const _AddDriverSheet({required this.onAdd});

  @override
  State<_AddDriverSheet> createState() => _AddDriverSheetState();
}

class _AddDriverSheetState extends State<_AddDriverSheet> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _busNumberController = TextEditingController();
  final AdminService _adminService = AdminService();

  List<String> _routeOptions = [];
  String? _selectedRouteName;

  bool _loadingOptions = true;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _loadDropdownOptions();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _busNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });

    try {
      final routes = await _adminService.getRoutes();

      setState(() {
        _routeOptions = routes
            .map((e) => e['name']?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
        _routeOptions.sort();

        if (_routeOptions.isNotEmpty && _selectedRouteName == null) {
          _selectedRouteName = _routeOptions.first;
        }

        _loadingOptions = false;
      });
    } catch (e) {
      setState(() {
        _optionsError = e.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final busNumber = _busNumberController.text.trim();
    final routeName = _selectedRouteName?.trim() ?? '';

    if (fullName.isEmpty || busNumber.isEmpty || routeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields (Name, Phone, Bus Number, Route)'),
          backgroundColor: _Palette.darkRed,
        ),
      );
      return;
    }

    await widget.onAdd(fullName, busNumber, phone, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.bg2.withOpacity(0.94),
              border: const Border(
                top: BorderSide(color: _Palette.glassBorder),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: _loadingOptions
                ? const SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _Palette.brightRed),
                          SizedBox(height: 16),
                          Text(
                            'Loading routes...',
                            style: TextStyle(color: _Palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : _optionsError != null
                ? SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Failed to load routes.',
                            style: TextStyle(
                              color: _Palette.brightRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _optionsError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _Palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _RedButton(
                            label: 'Retry',
                            onPressed: _loadDropdownOptions,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Add New Driver',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _Palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(
                        _fullNameController,
                        'Full Name',
                        Icons.person_outline,
                      ),
                      _field(
                        _phoneController,
                        'Phone Number',
                        Icons.phone_outlined,
                      ),
                      _field(
                        _busNumberController,
                        'Bus Number (e.g. BUS-105)',
                        Icons.directions_bus_outlined,
                      ),
                      _dropdownField(
                        label: 'Route Name',
                        value: _selectedRouteName,
                        icon: Icons.alt_route_outlined,
                        items: _routeOptions,
                        onChanged: (value) =>
                            setState(() => _selectedRouteName = value),
                      ),
                      const SizedBox(height: 16),
                      _RedButton(
                        label: 'Add Driver',
                        onPressed: _submit,
                        expand: true,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Palette.glassBorder),
        ),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: _Palette.textPrimary, fontSize: 14),
          cursorColor: _Palette.brightRed,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _Palette.textMuted),
            prefixIcon: Icon(icon, color: _Palette.textMuted, size: 18),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Palette.glassBorder),
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 13, color: _Palette.textMuted),
            prefixIcon: Icon(icon, color: _Palette.textMuted, size: 18),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: _Palette.bg2,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: _Palette.textMuted,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: _Palette.textPrimary,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _Palette.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

// ── EDIT DRIVER BOTTOM SHEET ────────────────────────────────────────────────
class _EditDriverSheet extends StatefulWidget {
  final Driver driver;
  final Future<void> Function(
    String fullName,
    String busNumber,
    String phone,
    String routeName,
  ) onEdit;

  const _EditDriverSheet({
    required this.driver,
    required this.onEdit,
  });

  @override
  State<_EditDriverSheet> createState() => _EditDriverSheetState();
}

class _EditDriverSheetState extends State<_EditDriverSheet> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _busNumberController;
  final AdminService _adminService = AdminService();

  List<String> _routeOptions = [];
  String? _selectedRouteName;

  bool _loadingOptions = true;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.driver.name);
    _phoneController = TextEditingController(text: widget.driver.phone);
    _busNumberController = TextEditingController(
      text: widget.driver.busId != 'Not assigned' ? widget.driver.busId : '',
    );

    _loadDropdownOptions();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _busNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });

    try {
      final routes = await _adminService.getRoutes();

      setState(() {
        _routeOptions = routes
            .map((e) => e['name']?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
        _routeOptions.sort();

        if (widget.driver.route.isNotEmpty &&
            widget.driver.route != 'Not assigned' &&
            !_routeOptions.contains(widget.driver.route)) {
          _routeOptions.insert(0, widget.driver.route);
        }

        _selectedRouteName = widget.driver.route.isNotEmpty &&
                widget.driver.route != 'Not assigned' &&
                _routeOptions.contains(widget.driver.route)
            ? widget.driver.route
            : (_routeOptions.isNotEmpty ? _routeOptions.first : null);

        _loadingOptions = false;
      });
    } catch (e) {
      setState(() {
        _optionsError = e.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final busNumber = _busNumberController.text.trim();
    final routeName = _selectedRouteName?.trim() ?? widget.driver.route;

    if (fullName.isEmpty || busNumber.isEmpty || routeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: _Palette.darkRed,
        ),
      );
      return;
    }

    await widget.onEdit(fullName, busNumber, phone, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.bg2.withOpacity(0.94),
              border: const Border(
                top: BorderSide(color: _Palette.glassBorder),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: _loadingOptions
                ? const SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _Palette.brightRed),
                          SizedBox(height: 16),
                          Text(
                            'Loading options...',
                            style: TextStyle(color: _Palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : _optionsError != null
                ? SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Failed to load options.',
                            style: TextStyle(
                              color: _Palette.brightRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _optionsError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _Palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _RedButton(
                            label: 'Retry',
                            onPressed: _loadDropdownOptions,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Edit Driver',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _Palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          _fullNameController,
                          'Full Name',
                          Icons.person_outline,
                        ),
                        _field(
                          _phoneController,
                          'Phone Number',
                          Icons.phone_outlined,
                        ),
                        _field(
                          _busNumberController,
                          'Bus Number',
                          Icons.directions_bus_outlined,
                        ),
                        _dropdownField(
                          label: 'Route Name',
                          value: _selectedRouteName,
                          icon: Icons.alt_route_outlined,
                          items: _routeOptions,
                          onChanged: (value) =>
                              setState(() => _selectedRouteName = value),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _GhostButton(
                                label: 'Cancel',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _RedButton(
                                label: 'Save Changes',
                                onPressed: _submit,
                                expand: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Palette.glassBorder),
        ),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: _Palette.textPrimary, fontSize: 14),
          cursorColor: _Palette.brightRed,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _Palette.textMuted),
            prefixIcon: Icon(icon, color: _Palette.textMuted, size: 18),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Palette.glassBorder),
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 13, color: _Palette.textMuted),
            prefixIcon: Icon(icon, color: _Palette.textMuted, size: 18),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: _Palette.bg2,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: _Palette.textMuted,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: _Palette.textPrimary,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _Palette.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}