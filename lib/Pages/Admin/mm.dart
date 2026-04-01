import 'package:flutter/material.dart';
 
class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});
 
  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}
 
class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  // ── Colours ───────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFFF4F6FB);
  static const Color _card    = Colors.white;
  static const Color _border  = Color(0xFFE2E8F0);
  static const Color _muted   = Color(0xFF64748B);
  static const Color _text    = Color(0xFF1E293B);
  static const Color _primary = Color(0xFF3B5BDB);
  static const Color _green   = Color(0xFF16A34A);
  static const Color _red     = Color(0xFFDC2626);
  static const Color _orange  = Color(0xFFEA580C);
 
  // ── State ─────────────────────────────────────────────────────────────────
  String _search        = '';
  String _filterRoute   = 'All Routes';
  String _filterStatus  = 'All Status';
  final Set<int> _selected = {};
  bool _selectAll = false;
 
  final List<String> _routes   = ['All Routes', 'Route A - Downtown', 'Route B - Suburbs', 'Route C - Eastside'];
  final List<String> _statuses = ['All Status', 'Paid', 'Unpaid', 'Expired'];
 
  // ── Data ──────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _students = [
    {'id': 'S1',  'name': 'Emma Johnson',    'bus': 'BUS-101', 'route': 'Route A - Downtown', 'stop': 'Main Street Station',   'status': 'Paid',    'initials': 'EJ', 'color': Color(0xFF3B5BDB)},
    {'id': 'S2',  'name': 'Liam Smith',      'bus': 'BUS-101', 'route': 'Route A - Downtown', 'stop': 'Park Avenue Station',   'status': 'Paid',    'initials': 'LS', 'color': Color(0xFF0891B2)},
    {'id': 'S3',  'name': 'Olivia Brown',    'bus': 'BUS-102', 'route': 'Route B - Suburbs',  'stop': 'Oak Street Station',    'status': 'Unpaid',  'initials': 'OB', 'color': Color(0xFF7C3AED)},
    {'id': 'S4',  'name': 'Noah Williams',   'bus': 'BUS-101', 'route': 'Route A - Downtown', 'stop': 'Broadway Station',      'status': 'Paid',    'initials': 'NW', 'color': Color(0xFF059669)},
    {'id': 'S5',  'name': 'Ava Martinez',    'bus': 'BUS-102', 'route': 'Route B - Suburbs',  'stop': 'Maple Drive Station',   'status': 'Expired', 'initials': 'AM', 'color': Color(0xFFD97706)},
    {'id': 'S6',  'name': 'Ethan Garcia',    'bus': 'BUS-101', 'route': 'Route A - Downtown', 'stop': 'Main Street Station',   'status': 'Paid',    'initials': 'EG', 'color': Color(0xFF0F766E)},
    {'id': 'S7',  'name': 'Sophia Rodriguez','bus': 'BUS-103', 'route': 'Route C - Eastside',  'stop': 'Cedar Lane Station',   'status': 'Unpaid',  'initials': 'SR', 'color': Color(0xFFBE185D)},
    {'id': 'S8',  'name': 'Mason Lee',       'bus': 'BUS-103', 'route': 'Route C - Eastside',  'stop': 'Pine Street Station',  'status': 'Paid',    'initials': 'ML', 'color': Color(0xFF1D4ED8)},
    {'id': 'S9',  'name': 'Isabella Taylor', 'bus': 'BUS-101', 'route': 'Route B - Suburbs',  'stop': 'Oak Street Station',    'status': 'Paid',    'initials': 'IT', 'color': Color(0xFF7C3AED)},
    {'id': 'S10', 'name': 'James Anderson',  'bus': 'BUS-521', 'route': 'Route A - Downtown', 'stop': 'Park Avenue Station',   'status': 'Expired', 'initials': 'JA', 'color': Color(0xFF92400E)},
  ];
 
  List<Map<String, dynamic>> get _filtered {
    return _students.where((s) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
        (s['name'] as String).toLowerCase().contains(q) ||
        (s['id']   as String).toLowerCase().contains(q) ||
        (s['bus']  as String).toLowerCase().contains(q);
      final matchRoute  = _filterRoute  == 'All Routes'  || s['route']  == _filterRoute;
      final matchStatus = _filterStatus == 'All Status'  || s['status'] == _filterStatus;
      return matchSearch && matchRoute && matchStatus;
    }).toList();
  }
 
  int get _paidCount    => _students.where((s) => s['status'] == 'Paid').length;
  int get _unpaidCount  => _students.where((s) => s['status'] == 'Unpaid').length;
  int get _expiredCount => _students.where((s) => s['status'] == 'Expired').length;
 
  // ── Status helpers ────────────────────────────────────────────────────────
  Color _statusFg(String s) {
    if (s == 'Paid')    return _green;
    if (s == 'Unpaid')  return _red;
    return _orange;
  }
  Color _statusBg(String s) {
    if (s == 'Paid')    return const Color(0xFFF0FDF4);
    if (s == 'Unpaid')  return const Color(0xFFFEF2F2);
    return const Color(0xFFFFF7ED);
  }
  IconData _statusIcon(String s) {
    if (s == 'Paid')    return Icons.check_circle_outline_rounded;
    if (s == 'Unpaid')  return Icons.cancel_outlined;
    return Icons.access_time_rounded;
  }
 
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(),
                  const SizedBox(height: 16),
                  _buildTable(filtered),
                  const SizedBox(height: 20),
                  _buildSummaryCards(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 16, color: _muted),
            ),
          ),
          const SizedBox(width: 14),
          // Icon + title
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.people_rounded, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
              Text('${_students.length} students found', style: const TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
          const Spacer(),
          // Export button
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 14),
            label: const Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _text,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          // Add Student button
          ElevatedButton.icon(
            onPressed: () => _showAddStudentDialog(),
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: const Text('Add Student', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // FILTERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search Students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
                const SizedBox(height: 6),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 13, color: _text),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, or bus...',
                    hintStyle: const TextStyle(fontSize: 13, color: _muted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _muted),
                    filled: true, fillColor: _bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Filter by Route
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by Route', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
                const SizedBox(height: 6),
                _dropdown(_filterRoute, _routes, (v) => setState(() => _filterRoute = v!)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Filter by Status
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
                const SizedBox(height: 6),
                _dropdown(_filterStatus, _statuses, (v) => setState(() => _filterStatus = v!)),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _muted),
      style: const TextStyle(fontSize: 13, color: _text),
      decoration: InputDecoration(
        filled: true, fillColor: _bg,
        prefixIcon: const Icon(Icons.filter_list_rounded, size: 15, color: _muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // TABLE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTable(List<Map<String, dynamic>> filtered) {
    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3B5BDB), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Showing 1-${filtered.length} of ${filtered.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
 
          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
            child: Row(children: [
              SizedBox(width: 32, child: Checkbox(
                value: _selectAll,
                onChanged: (v) => setState(() {
                  _selectAll = v!;
                  _selected.clear();
                  if (v) _selected.addAll(List.generate(filtered.length, (i) => i));
                }),
                activeColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              )),
              const Expanded(flex: 3, child: _ColHeader('STUDENT')),
              const Expanded(flex: 2, child: _ColHeader('STUDENT ID')),
              const Expanded(flex: 3, child: _ColHeader('ROUTE')),
              const Expanded(flex: 3, child: _ColHeader('PICK-UP STATION')),
              const Expanded(flex: 2, child: _ColHeader('STATUS')),
              const Expanded(flex: 2, child: _ColHeader('ACTIONS')),
            ]),
          ),
 
          // Rows
          ...filtered.asMap().entries.map((e) => _tableRow(e.key, e.value)),
        ],
      ),
    );
  }
 
  Widget _tableRow(int idx, Map<String, dynamic> s) {
    final bool sel = _selected.contains(idx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? const Color(0xFFF5F7FF) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(width: 32, child: Checkbox(
            value: sel,
            onChanged: (v) => setState(() {
              if (v!) _selected.add(idx); else _selected.remove(idx);
            }),
            activeColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          )),
 
          // Student
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: (s['color'] as Color).withOpacity(0.15),
              child: Text(s['initials'] as String,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: s['color'] as Color)),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
              Row(children: [
                const Icon(Icons.directions_bus_rounded, size: 10, color: _muted),
                const SizedBox(width: 3),
                Text(s['bus'] as String, style: const TextStyle(fontSize: 10, color: _muted)),
              ]),
            ]),
          ])),
 
          // Student ID
          Expanded(flex: 2, child: Text(s['id'] as String,
            style: const TextStyle(fontSize: 13, color: _text, fontWeight: FontWeight.w500))),
 
          // Route
          Expanded(flex: 3, child: Text(s['route'] as String,
            style: const TextStyle(fontSize: 12, color: _muted))),
 
          // Stop
          Expanded(flex: 3, child: Row(children: [
            const Icon(Icons.location_on_rounded, size: 12, color: _muted),
            const SizedBox(width: 4),
            Flexible(child: Text(s['stop'] as String,
              style: const TextStyle(fontSize: 12, color: _muted), overflow: TextOverflow.ellipsis)),
          ])),
 
          // Status
          Expanded(flex: 2, child: _statusPill(s['status'] as String)),
 
          // Actions
          Expanded(flex: 2, child: Row(children: [
            _actionBtn(Icons.edit_rounded, _primary, const Color(0xFFEEF2FF), () => _showEditDialog(s)),
            const SizedBox(width: 8),
            _actionBtn(Icons.delete_rounded, _red, const Color(0xFFFEF2F2), () => _confirmDelete(s)),
          ])),
        ],
      ),
    );
  }
 
  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBg(status), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusFg(status).withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_statusIcon(status), size: 12, color: _statusFg(status)),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusFg(status))),
      ]),
    );
  }
 
  Widget _actionBtn(IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _summaryCard('Paid Subscriptions',   _paidCount.toString(),    _green,  Icons.check_circle_rounded,  const Color(0xFFF0FDF4))),
        const SizedBox(width: 16),
        Expanded(child: _summaryCard('Unpaid Subscriptions', _unpaidCount.toString(),  _red,    Icons.cancel_rounded,         const Color(0xFFFEF2F2))),
        const SizedBox(width: 16),
        Expanded(child: _summaryCard('Expired Subscriptions',_expiredCount.toString(), _orange, Icons.access_time_rounded,    const Color(0xFFFFF7ED))),
      ],
    );
  }
 
  Widget _summaryCard(String label, String value, Color color, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: color, height: 1)),
          ]),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }
 
  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════════════════════════════════════════
  void _showAddStudentDialog() {
    final nameC = TextEditingController();
    final idC   = TextEditingController();
    String selRoute  = 'Route A - Downtown';
    String selStatus = 'Paid';
    String selBus    = 'BUS-101';
 
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogField('Full Name', nameC, 'e.g. John Doe'),
              const SizedBox(height: 12),
              _dialogField('Student ID', idC, 'e.g. S11'),
              const SizedBox(height: 12),
              _dialogDropdown('Bus', selBus, ['BUS-101','BUS-102','BUS-103','BUS-521'], (v) => setS(() => selBus = v!)),
              const SizedBox(height: 12),
              _dialogDropdown('Route', selRoute, ['Route A - Downtown','Route B - Suburbs','Route C - Eastside'], (v) => setS(() => selRoute = v!)),
              const SizedBox(height: 12),
              _dialogDropdown('Status', selStatus, ['Paid','Unpaid','Expired'], (v) => setS(() => selStatus = v!)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
            ElevatedButton(
              onPressed: () {
                if (nameC.text.isEmpty || idC.text.isEmpty) return;
                final initials = nameC.text.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
                setState(() {
                  _students.add({
                    'id': idC.text.trim(), 'name': nameC.text.trim(), 'bus': selBus,
                    'route': selRoute, 'stop': 'Main Street Station', 'status': selStatus,
                    'initials': initials, 'color': _primary,
                  });
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
 
  void _showEditDialog(Map<String, dynamic> s) {
    String selStatus = s['status'] as String;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit — ${s['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
          content: SizedBox(
            width: 340,
            child: _dialogDropdown('Subscription Status', selStatus, ['Paid','Unpaid','Expired'], (v) => setS(() => selStatus = v!)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
            ElevatedButton(
              onPressed: () {
                setState(() => s['status'] = selStatus);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
 
  void _confirmDelete(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
        content: Text('Are you sure you want to remove ${s['name']}?', style: const TextStyle(color: _muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
            onPressed: () { setState(() => _students.remove(s)); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: _red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
 
  Widget _dialogField(String label, TextEditingController c, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
      const SizedBox(height: 5),
      TextField(
        controller: c,
        style: const TextStyle(fontSize: 13, color: _text),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: _muted, fontSize: 13),
          filled: true, fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ]);
  }
 
  Widget _dialogDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        value: value, onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: _text),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _muted),
        decoration: InputDecoration(
          filled: true, fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      ),
    ]);
  }
}
 
// ── Const helper widgets ─────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
      color: Color(0xFF64748B), letterSpacing: 0.4));
}