import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';
import 'package:safeway/services/admin_service.dart';

// ─────────────────────────────────────────────────────────────
//  SafeWay design system — dark glass + red accent
//  (same tokens as the login page / dashboards)
// ─────────────────────────────────────────────────────────────
class _Palette {
  static const bg = Color(0xFF070708);
  static const bg2 = Color(0xFF101012);
  static const surface = Color(0xFF18181B);

  static const red = Color(0xFFD32F2F);
  static const brightRed = Color(0xFFEF4444);
  static const darkRed = Color(0xFF991B1B);
  static const burgundy = Color(0xFF65171B);
  static const roseRed = Color(0xFFB0343B); // used to distinguish "expired"

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

  // Rotation used only to visually tell students' avatars apart —
  // all inside the red / neutral family, no new hues introduced.
  static const avatarColors = [
    brightRed,
    red,
    burgundy,
    roseRed,
    Color(0xFF8A8A90), // neutral gray, for extra spread
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

class StudentRecord {
  final int id;
  final String fullName;
  final String uniqueID;
  final String busNumber;
  final String routeName;
  final String grade;
  final String subscriptionStatus;

  StudentRecord({
    required this.id,
    required this.fullName,
    required this.uniqueID,
    required this.busNumber,
    required this.routeName,
    required this.grade,
    required this.subscriptionStatus,
  });

  factory StudentRecord.fromJson(Map<String, dynamic> j) => StudentRecord(
    id: j['id'] ?? 0,
    fullName: j['fullName'] ?? '',
    uniqueID: j['uniqueID'] ?? '',
    busNumber: j['busNumber'] ?? 'Not assigned',
    routeName: j['routeName'] ?? 'Not assigned',
    grade: j['grade'] ?? '',
    subscriptionStatus: j['subscriptionStatus'] ?? 'UNPAID',
  );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<StudentRecord> _allStudents = [];
  List<StudentRecord> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  final String _filterRoute = '';
  final String _filterStatus = '';

  final _searchCtrl = TextEditingController();

  // Unique routes and statuses for filter dropdowns
  List<String> get _routes =>
      _allStudents.map((s) => s.routeName).toSet().toList()..sort();
  List<String> get _statuses => ['PAID', 'UNPAID', 'EXPIRED'];

  int get _paidCount =>
      _allStudents.where((s) => s.subscriptionStatus == 'PAID').length;
  int get _unpaidCount =>
      _allStudents.where((s) => s.subscriptionStatus == 'UNPAID').length;
  int get _expiredCount =>
      _allStudents.where((s) => s.subscriptionStatus == 'EXPIRED').length;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/api/admin/students'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _allStudents = data.map((e) => StudentRecord.fromJson(e)).toList();
          _filtered = List.from(_allStudents);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _allStudents.where((s) {
        final q = _searchQuery.toLowerCase();
        final matchSearch =
            q.isEmpty ||
            s.fullName.toLowerCase().contains(q) ||
            s.uniqueID.toLowerCase().contains(q) ||
            s.busNumber.toLowerCase().contains(q);
        final matchRoute = _filterRoute.isEmpty || s.routeName == _filterRoute;
        final matchStatus =
            _filterStatus.isEmpty || s.subscriptionStatus == _filterStatus;
        return matchSearch && matchRoute && matchStatus;
      }).toList();
    });
  }

  Color _avatarColor(String initials) {
    final colors = _Palette.avatarColors;
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return _Palette.textPrimary;
      case 'EXPIRED':
        return _Palette.roseRed;
      default:
        return _Palette.brightRed;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'PAID':
        return Colors.white.withOpacity(0.10);
      case 'EXPIRED':
        return _Palette.roseRed.withOpacity(0.16);
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
                        onRefresh: _loadStudents,
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
                              _buildStudentTable(),
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
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _Palette.bg2,
        border: Border(bottom: BorderSide(color: _Palette.divider)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _Palette.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: _Palette.redGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _Palette.red.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Students',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Palette.textPrimary,
                  ),
                ),
                Text(
                  '${_allStudents.length} students found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Keeping this method only if you still need the old export card UI.
  // Currently unused (replaced by the top-row OutlinedButton / ElevatedButton).
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
            ).showSnackBar(const SnackBar(content: Text('Exporting...'))),
          ),
          const SizedBox(width: 8),
          _RedButton(
            label: 'Add Student',
            icon: Icons.add,
            onPressed: () => _showAddStudentDialog(),
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
          // Search
          const Text(
            'Search Students',
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
                hintText: 'Search by name, ID, or bus...',
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

  // ── STUDENT TABLE ─────────────────────────────────────────────────────────────
  Widget _buildStudentTable() {
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
                              'Student Records',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Showing ${_filtered.length} of ${_allStudents.length} students',
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
                          'STUDENT',
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
                          'SUBSCRIPTION',
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
                        'No students match your filters.',
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
                    itemBuilder: (_, i) => _buildStudentRow(_filtered[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRow(StudentRecord s) {
    final color = _avatarColor(s.initials);

    return InkWell(
      onTap: () => _showStudentDetail(s),
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
                        s.initials,
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
                          s.fullName,
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
                                s.busNumber,
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
                s.routeName,
                style: const TextStyle(
                  fontSize: 13,
                  color: _Palette.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Subscription status
            Expanded(
              flex: 3,
              child: Text(
                s.subscriptionStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(s.subscriptionStatus),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Edit & Delete Action Buttons
            SizedBox(
              width: 76,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: _Palette.textSecondary),
                    tooltip: 'Edit student',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    onPressed: () => _showEditStudentDialog(s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: _Palette.brightRed),
                    tooltip: 'Delete student',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    onPressed: () => _confirmDeleteStudent(s),
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
          label: 'Paid Subscriptions',
          count: _paidCount,
          color: _Palette.textPrimary,
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          label: 'Unpaid Subscriptions',
          count: _unpaidCount,
          color: _Palette.brightRed,
          icon: Icons.cancel_outlined,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          label: 'Expired Subscriptions',
          count: _expiredCount,
          color: _Palette.roseRed,
          icon: Icons.timer_off_outlined,
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

  // ── STUDENT DETAIL BOTTOM SHEET ───────────────────────────────────────────────
  void _showStudentDetail(StudentRecord s) {
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
                        color: _avatarColor(s.initials).withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatarColor(s.initials).withOpacity(0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          s.initials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _avatarColor(s.initials),
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
                            s.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _Palette.textPrimary,
                            ),
                          ),
                          Text(
                            'ID: ${s.uniqueID}',
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
                        color: _statusBg(s.subscriptionStatus),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor(
                            s.subscriptionStatus,
                          ).withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        s.subscriptionStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(s.subscriptionStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _detailRow(
                  Icons.directions_bus_outlined,
                  'Bus Number',
                  s.busNumber,
                ),
                _detailRow(Icons.alt_route_outlined, 'Route', s.routeName),
                _detailRow(
                  Icons.school_outlined,
                  'Grade',
                  s.grade.isEmpty ? 'N/A' : s.grade,
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
                          _confirmDeleteStudent(s);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RedButton(
                        label: 'Edit Student',
                        icon: Icons.edit_outlined,
                        expand: true,
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditStudentDialog(s);
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

  Future<void> _confirmDeleteStudent(StudentRecord s) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _Palette.glassBorder),
        ),
        title: const Text(
          'Delete Student',
          style: TextStyle(
            color: _Palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${s.fullName}?',
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
        content: Text('Deleting student...'),
        backgroundColor: _Palette.darkRed,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final adminService = AdminService();
      await adminService.deleteStudent(id: s.id);
      await _loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: _Palette.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete student: $e'),
            backgroundColor: _Palette.darkRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditStudentDialog(StudentRecord s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStudentSheet(
        student: s,
        onEdit: (fullName, uniqueID, busNumber, routeName, grade, status) async {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updating student...'),
              backgroundColor: _Palette.darkRed,
              behavior: SnackBarBehavior.floating,
            ),
          );

          try {
            final adminService = AdminService();
            await adminService.updateStudent(
              id: s.id,
              fullName: fullName,
              uniqueID: uniqueID,
              busNumber: busNumber,
              routeName: routeName,
              grade: grade,
              subscriptionStatus: status,
            );

            await _loadStudents();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student updated successfully'),
                  backgroundColor: _Palette.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update student: $e'),
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

  // ── ADD STUDENT BOTTOM SHEET (like Add Driver) ────────────────────────────
  void _showAddStudentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStudentSheet(
        onAdd: (fullName, uniqueID, busNumber, routeName, grade) async {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding student...'),
              backgroundColor: _Palette.darkRed,
              behavior: SnackBarBehavior.floating,
            ),
          );

          try {
            final adminService = AdminService();
            await adminService.addStudent(
              fullName: fullName,
              uniqueID: uniqueID,
              busNumber: busNumber,
              routeName: routeName,
              grade: grade,
            );

            await _loadStudents();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student added successfully'),
                  backgroundColor: _Palette.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add student: $e'),
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

class _AddStudentSheet extends StatefulWidget {
  final Future<void> Function(
    String fullName,
    String uniqueID,
    String busNumber,
    String routeName,
    String grade,
  )
  onAdd;

  const _AddStudentSheet({required this.onAdd});

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  final _fullNameController = TextEditingController();
  final _uniqueIdController = TextEditingController();
  final AdminService _adminService = AdminService();

  final List<String> _gradeOptions = ['Grade 10', 'Grade 11', 'Grade 12'];
  List<String> _busOptions = [];
  List<String> _routeOptions = [];

  String? _selectedGrade;
  String? _selectedBusNumber;
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
    _uniqueIdController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });

    try {
      final results = await Future.wait([
        _adminService.getBuses(),
        _adminService.getRoutes(),
      ]);

      final buses = results[0];
      final routes = results[1];

      setState(() {
        _busOptions = buses
            .map((e) => e['id']?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
        _routeOptions = routes
            .map((e) => e['name']?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
        _busOptions.sort();
        _routeOptions.sort();

        if (_gradeOptions.isNotEmpty && _selectedGrade == null) {
          _selectedGrade = _gradeOptions.first;
        }

        if (_busOptions.isNotEmpty && _selectedBusNumber == null) {
          _selectedBusNumber = _busOptions.first;
        }

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
    final uniqueID = _uniqueIdController.text.trim();
    final busNumber = _selectedBusNumber?.trim() ?? '';
    final routeName = _selectedRouteName?.trim() ?? '';
    final grade = _selectedGrade?.trim() ?? '';

    if (fullName.isEmpty ||
        uniqueID.isEmpty ||
        busNumber.isEmpty ||
        routeName.isEmpty ||
        grade.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill required fields'),
          backgroundColor: _Palette.darkRed,
        ),
      );
      return;
    }

    await widget.onAdd(fullName, uniqueID, busNumber, routeName, grade);
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
                            'Loading buses and routes...',
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
                        'Add New Student',
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
                        _uniqueIdController,
                        'UniqueID',
                        Icons.badge_outlined,
                      ),
                      _dropdownField(
                        label: 'Grade',
                        value: _selectedGrade,
                        icon: Icons.school_outlined,
                        items: _gradeOptions,
                        onChanged: (value) =>
                            setState(() => _selectedGrade = value),
                      ),
                      _dropdownField(
                        label: 'Bus Number',
                        value: _selectedBusNumber,
                        icon: Icons.directions_bus_outlined,
                        items: _busOptions,
                        onChanged: (value) =>
                            setState(() => _selectedBusNumber = value),
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
                        label: 'Add Student',
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

// ── EDIT STUDENT BOTTOM SHEET ─────────────────────────────────────────────
class _EditStudentSheet extends StatefulWidget {
  final StudentRecord student;
  final Future<void> Function(
    String fullName,
    String uniqueID,
    String busNumber,
    String routeName,
    String grade,
    String status,
  ) onEdit;

  const _EditStudentSheet({
    required this.student,
    required this.onEdit,
  });

  @override
  State<_EditStudentSheet> createState() => _EditStudentSheetState();
}

class _EditStudentSheetState extends State<_EditStudentSheet> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _uniqueIdController;
  final AdminService _adminService = AdminService();

  final List<String> _gradeOptions = ['Grade 10', 'Grade 11', 'Grade 12'];
  final List<String> _statusOptions = ['PAID', 'UNPAID', 'EXPIRED'];
  List<String> _busOptions = [];
  List<String> _routeOptions = [];

  String? _selectedGrade;
  String? _selectedBusNumber;
  String? _selectedRouteName;
  String? _selectedStatus;

  bool _loadingOptions = true;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.student.fullName);
    _uniqueIdController = TextEditingController(text: widget.student.uniqueID);

    _selectedGrade = widget.student.grade.isNotEmpty && _gradeOptions.contains(widget.student.grade)
        ? widget.student.grade
        : _gradeOptions.first;

    _selectedStatus = _statusOptions.contains(widget.student.subscriptionStatus)
        ? widget.student.subscriptionStatus
        : 'UNPAID';

    _loadDropdownOptions();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _uniqueIdController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });

    try {
      final results = await Future.wait([
        _adminService.getBuses(),
        _adminService.getRoutes(),
      ]);

      final buses = results[0];
      final routes = results[1];

      setState(() {
        _busOptions = buses
            .map((e) => e['id']?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
        _routeOptions = routes
            .map((e) => e['name']?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
        _busOptions.sort();
        _routeOptions.sort();

        if (widget.student.busNumber.isNotEmpty &&
            widget.student.busNumber != 'Not assigned' &&
            !_busOptions.contains(widget.student.busNumber)) {
          _busOptions.insert(0, widget.student.busNumber);
        }
        if (widget.student.routeName.isNotEmpty &&
            widget.student.routeName != 'Not assigned' &&
            !_routeOptions.contains(widget.student.routeName)) {
          _routeOptions.insert(0, widget.student.routeName);
        }

        _selectedBusNumber = widget.student.busNumber.isNotEmpty &&
                widget.student.busNumber != 'Not assigned' &&
                _busOptions.contains(widget.student.busNumber)
            ? widget.student.busNumber
            : (_busOptions.isNotEmpty ? _busOptions.first : null);

        _selectedRouteName = widget.student.routeName.isNotEmpty &&
                widget.student.routeName != 'Not assigned' &&
                _routeOptions.contains(widget.student.routeName)
            ? widget.student.routeName
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
    final uniqueID = _uniqueIdController.text.trim();
    final busNumber = _selectedBusNumber?.trim() ?? widget.student.busNumber;
    final routeName = _selectedRouteName?.trim() ?? widget.student.routeName;
    final grade = _selectedGrade?.trim() ?? widget.student.grade;
    final status = _selectedStatus?.trim() ?? widget.student.subscriptionStatus;

    if (fullName.isEmpty || uniqueID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill required fields'),
          backgroundColor: _Palette.darkRed,
        ),
      );
      return;
    }

    await widget.onEdit(fullName, uniqueID, busNumber, routeName, grade, status);
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
                          'Edit Student',
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
                          _uniqueIdController,
                          'UniqueID',
                          Icons.badge_outlined,
                        ),
                        _dropdownField(
                          label: 'Grade',
                          value: _selectedGrade,
                          icon: Icons.school_outlined,
                          items: _gradeOptions,
                          onChanged: (value) =>
                              setState(() => _selectedGrade = value),
                        ),
                        _dropdownField(
                          label: 'Bus Number',
                          value: _selectedBusNumber,
                          icon: Icons.directions_bus_outlined,
                          items: _busOptions,
                          onChanged: (value) =>
                              setState(() => _selectedBusNumber = value),
                        ),
                        _dropdownField(
                          label: 'Route Name',
                          value: _selectedRouteName,
                          icon: Icons.alt_route_outlined,
                          items: _routeOptions,
                          onChanged: (value) =>
                              setState(() => _selectedRouteName = value),
                        ),
                        _dropdownField(
                          label: 'Subscription Status',
                          value: _selectedStatus,
                          icon: Icons.card_membership_outlined,
                          items: _statusOptions,
                          onChanged: (value) =>
                              setState(() => _selectedStatus = value),
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