import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class StudentRecord {
  final int    id;
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
    id:                 j['id']                 ?? 0,
    fullName:           j['fullName']            ?? '',
    uniqueID:           j['uniqueID']            ?? '',
    busNumber:          j['busNumber']           ?? 'Not assigned',
    routeName:          j['routeName']           ?? 'Not assigned',
    grade:              j['grade']               ?? '',
    subscriptionStatus: j['subscriptionStatus']  ?? 'UNPAID',
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
  List<StudentRecord> _allStudents    = [];
  List<StudentRecord> _filtered       = [];
  bool                _loading        = true;
  String              _searchQuery    = '';
  String              _filterRoute    = '';
  String              _filterStatus   = '';

  final _searchCtrl = TextEditingController();

  // Unique routes and statuses for filter dropdowns
  List<String> get _routes =>
      _allStudents.map((s) => s.routeName).toSet().toList()..sort();
  List<String> get _statuses => ['PAID', 'UNPAID', 'EXPIRED'];

  int get _paidCount    => _allStudents.where((s) => s.subscriptionStatus == 'PAID').length;
  int get _unpaidCount  => _allStudents.where((s) => s.subscriptionStatus == 'UNPAID').length;
  int get _expiredCount => _allStudents.where((s) => s.subscriptionStatus == 'EXPIRED').length;

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
      final res = await http.get(
          Uri.parse('$apiBaseUrl/api/admin/students'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _allStudents = data.map((e) => StudentRecord.fromJson(e)).toList();
          _filtered    = List.from(_allStudents);
          _loading     = false;
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
        final matchSearch = q.isEmpty ||
            s.fullName.toLowerCase().contains(q) ||
            s.uniqueID.toLowerCase().contains(q) ||
            s.busNumber.toLowerCase().contains(q);
        final matchRoute  = _filterRoute.isEmpty  || s.routeName == _filterRoute;
        final matchStatus = _filterStatus.isEmpty || s.subscriptionStatus == _filterStatus;
        return matchSearch && matchRoute && matchStatus;
      }).toList();
    });
  }

  Color _avatarColor(String initials) {
    const colors = [
      Color(0xFF4F46E5), Color(0xFF16A34A), Color(0xFFEA580C),
      Color(0xFFDB2777), Color(0xFF0891B2), Color(0xFF7C3AED),
      Color(0xFFCA8A04), Color(0xFFDC2626),
    ];
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':    return const Color(0xFF16A34A);
      case 'EXPIRED': return const Color(0xFFEA580C);
      default:        return const Color(0xFFDC2626);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'PAID':    return const Color(0xFFDCFCE7);
      case 'EXPIRED': return const Color(0xFFFFF7ED);
      default:        return const Color(0xFFFFF0F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF4F46E5)))
                : RefreshIndicator(
                    onRefresh: _loadStudents,
                    color: const Color(0xFF4F46E5),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 16,
      ),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios,
                size: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.people_alt_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage Students',
                    style: TextStyle(fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                Text('${_allStudents.length} students found',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          // Export button
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exporting...'))),
            icon: const Icon(Icons.upload_outlined, size: 14),
            label: const Text('Export',
                style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          // Add Student button
          ElevatedButton.icon(
            onPressed: () => _showAddStudentDialog(),
            icon: const Icon(Icons.add, size: 14, color: Colors.white),
            label: const Text('Add Student',
                style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTERS CARD ─────────────────────────────────────────────────────────────
  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          const Text('Search Students',
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _searchQuery = v;
              _applyFilters();
            },
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name, ID, or bus...',
              hintStyle: const TextStyle(
                  fontSize: 13, color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search,
                  color: Color(0xFF9CA3AF), size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _applyFilters();
                      },
                      child: const Icon(Icons.close,
                          color: Color(0xFF9CA3AF), size: 16))
                  : null,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF4F46E5), width: 1.5)),
            ),
          ),

          const SizedBox(height: 14),

          // Filter by Route
          const Text('Filter by Route',
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          _buildDropdownFilter(
            hint: 'All Routes',
            value: _filterRoute.isEmpty ? null : _filterRoute,
            items: _routes,
            onChanged: (v) {
              _filterRoute = v ?? '';
              _applyFilters();
            },
          ),

          const SizedBox(height: 14),

          // Filter by Status
          const Text('Filter by Status',
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          _buildDropdownFilter(
            hint: 'All Statuses',
            value: _filterStatus.isEmpty ? null : _filterStatus,
            items: _statuses,
            onChanged: (v) {
              _filterStatus = v ?? '';
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(children: [
            const Icon(Icons.filter_list,
                size: 16, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Text(hint,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF9CA3AF), size: 18),
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint,
                  style: const TextStyle(color: Color(0xFF9CA3AF))),
            ),
            ...items.map((item) =>
                DropdownMenuItem(value: item, child: Text(item))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── STUDENT TABLE ─────────────────────────────────────────────────────────────
  Widget _buildStudentTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Records',
                    style: TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Showing 1-${_filtered.length} of ${_filtered.length}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // Column labels
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(children: const [
              Expanded(flex: 5,
                  child: Text('STUDENT',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5))),
              Expanded(flex: 3,
                  child: Text('STUDENT ID',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5))),
              Expanded(flex: 4,
                  child: Text('ROUTE',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5))),
            ]),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Rows
          if (_filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No students match your filters.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF9CA3AF))),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (_, i) => _buildStudentRow(_filtered[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(StudentRecord s) {
    final color = _avatarColor(s.initials);

    return InkWell(
      onTap: () => _showStudentDetail(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar + name + bus
            Expanded(
              flex: 5,
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(s.initials,
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(s.fullName,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    Row(children: [
                      Icon(Icons.directions_bus_outlined,
                          size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(s.busNumber,
                          style: TextStyle(fontSize: 10,
                              color: Colors.grey[400])),
                    ]),
                  ]),
                ),
              ]),
            ),

            // Student ID
            Expanded(
              flex: 3,
              child: Text(s.uniqueID,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF374151))),
            ),

            // Route
            Expanded(
              flex: 4,
              child: Text(s.routeName,
                  style: const TextStyle(fontSize: 12,
                      color: Color(0xFF6B7280))),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY CARDS ─────────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Column(children: [
      _summaryCard(
        label: 'Paid Subscriptions',
        count: _paidCount,
        color: const Color(0xFF16A34A),
        icon: Icons.check_circle_outline_rounded,
      ),
      const SizedBox(height: 12),
      _summaryCard(
        label: 'Unpaid Subscriptions',
        count: _unpaidCount,
        color: const Color(0xFFDC2626),
        icon: Icons.cancel_outlined,
      ),
      const SizedBox(height: 12),
      _summaryCard(
        label: 'Expired Subscriptions',
        count: _expiredCount,
        color: const Color(0xFFEA580C),
        icon: Icons.timer_off_outlined,
      ),
    ]);
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(fontSize: 28,
                    fontWeight: FontWeight.bold, color: color)),
          ]),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }

  // ── STUDENT DETAIL BOTTOM SHEET ───────────────────────────────────────────────
  void _showStudentDetail(StudentRecord s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: _avatarColor(s.initials).withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Center(child: Text(s.initials,
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _avatarColor(s.initials)))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.fullName,
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text('ID: ${s.uniqueID}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _statusBg(s.subscriptionStatus),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(s.subscriptionStatus,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(s.subscriptionStatus))),
            ),
          ]),
          const SizedBox(height: 20),
          _detailRow(Icons.directions_bus_outlined, 'Bus Number', s.busNumber),
          _detailRow(Icons.alt_route_outlined, 'Route', s.routeName),
          _detailRow(Icons.school_outlined, 'Grade', s.grade.isEmpty ? 'N/A' : s.grade),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B7280))),
        Text(value,
            style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
      ]),
    );
  }

  // ── ADD STUDENT DIALOG ────────────────────────────────────────────────────────
  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Student',
            style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: const Text(
            'Add student functionality coming soon.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }
}