import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/Constant/Constant_Color.dart';
import 'package:safeway/services/api_config.dart';

// ── Models ──────────────────────────────────────────────────────────────────
class RouteModel {
  final int id;
  final String name;
  RouteModel({required this.id, required this.name});
  factory RouteModel.fromJson(Map<String, dynamic> j) =>
      RouteModel(id: j['id'], name: j['name']);
}

class StationModel {
  final int id;
  final String name;
  StationModel({required this.id, required this.name});
  factory StationModel.fromJson(Map<String, dynamic> j) =>
      StationModel(id: j['id'], name: j['name']);
}

// ── Page ─────────────────────────────────────────────────────────────────────
class RequestRouteChangePage extends StatefulWidget {
  const RequestRouteChangePage({super.key});

  @override
  State<RequestRouteChangePage> createState() => _RequestRouteChangePageState();
}

class _RequestRouteChangePageState extends State<RequestRouteChangePage> {
  final _storage = const FlutterSecureStorage();
  final TextEditingController _reasonController = TextEditingController();

  // data
  List<RouteModel> _routes = [];
  List<StationModel> _stations = [];
  RouteModel? _selectedRoute;
  DateTime? _selectedDate;

  // ui state
  bool _loadingData = true;
  bool _submitting = false;
  String? _errorMessage;
  int _userId = 0;
  String _currentRoute = 'Route A · Downtown';

  bool get _canSubmit =>
      _selectedRoute != null &&
      _selectedDate != null &&
      _reasonController.text.trim().isNotEmpty &&
      !_submitting;

  @override
  void initState() {
    super.initState();
    _loadData();
    _reasonController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── Load userId + routes + student info ─────────────────────────────────
  Future<void> _loadData() async {
    final userIdStr = await _storage.read(key: 'userId') ?? '0';
    _userId = int.tryParse(userIdStr) ?? 0;

    try {
      final results = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/routechangerequests/routes')),
        http.get(Uri.parse('$apiBaseUrl/api/routechangerequests/stations')),
        if (_userId != 0)
          http.get(Uri.parse('$apiBaseUrl/api/auth/student-info/$_userId')),
      ]);

      if (!mounted) return;

      final routesRes = results[0];
      final stationsRes = results[1];

      if (results.length > 2 && results[2].statusCode == 200) {
        final infoData = jsonDecode(results[2].body);
        final curRoute = infoData['routeName'] ?? '';
        if (curRoute.toString().isNotEmpty) {
          _currentRoute = curRoute.toString();
        }
      }

      if (routesRes.statusCode == 200) {
        final routesData = jsonDecode(routesRes.body) as List;
        final stationsData = jsonDecode(stationsRes.body) as List;
        setState(() {
          _routes = routesData.map((e) => RouteModel.fromJson(e)).toList();
          _stations = stationsData
              .map((e) => StationModel.fromJson(e))
              .toList();
          _loadingData = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load routes from server.';
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Check your connection.';
          _loadingData = false;
        });
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final stationId = _stations.isNotEmpty ? _stations.first.id : 1;

    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/routechangerequests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'newStationId': stationId,
          'newRouteId': _selectedRoute!.id,
          'effectiveDate': _selectedDate!.toIso8601String(),
          'reason': _reasonController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage =
              jsonDecode(res.body)['message'] ?? 'Submission failed.';
        });
      }
    } catch (_) {
      if (mounted)
        setState(() => _errorMessage = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accentGreen,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Success dialog ────────────────────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.badgeBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Request Submitted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your request to change route to "${_selectedRoute!.name}" '
              'effective ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
              'has been submitted for approval.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 24),
              _buildFormCard(),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Requests are reviewed by admin within 24 hours.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Widget ────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.darkNavy,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'STUDENT REQUEST',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: AppColors.accentGreen,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Request route change',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the option that works best for your school day.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Form Card Widget ─────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFAF7F2,
        ), // Soft warm off-white container matching screenshot
        borderRadius: BorderRadius.circular(24),
      ),
      child: _loadingData
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.accentGreen),
                  SizedBox(height: 16),
                  Text(
                    'Loading options...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('CURRENT ROUTE'),
                const SizedBox(height: 8),
                _buildCurrentRouteBadge(),
                const SizedBox(height: 20),
                _buildSectionLabel('AVAILABLE OPTIONS'),
                const SizedBox(height: 8),
                _buildDropdown<RouteModel>(
                  hint: 'Route',
                  value: _selectedRoute,
                  items: _routes,
                  itemLabel: (r) => r.name,
                  onChanged: (val) => setState(() => _selectedRoute = val),
                ),
                const SizedBox(height: 20),
                _buildSectionLabel('Effective Date'),
                const SizedBox(height: 8),
                _buildDateField(),
                const SizedBox(height: 20),
                _buildSectionLabel('REASON (REQUIRED)'),
                const SizedBox(height: 8),
                _buildReasonField(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(),
                ],
              ],
            ),
    );
  }

  // ── UI Components ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildCurrentRouteBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFEC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.swap_horiz_rounded,
            color: AppColors.accentGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _currentRoute,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textPrimary,
          ),
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _selectedDate == null
              ? 'Pick up Date'
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: _selectedDate == null
                ? FontWeight.normal
                : FontWeight.w600,
            color: _selectedDate == null
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 3,
        style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Tell us a little more...',
          hintStyle: TextStyle(fontSize: 14.5, color: AppColors.textMuted),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12.5, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSubmit ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkNavy,
          disabledBackgroundColor: AppColors.darkNavy.withOpacity(0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Submit request',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }
}
