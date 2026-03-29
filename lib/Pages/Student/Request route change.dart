import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';

// ── Models ──────────────────────────────────────────────────────────────────
class StationModel {
  final int id;
  final String name;
  StationModel({required this.id, required this.name});
  factory StationModel.fromJson(Map<String, dynamic> j) =>
      StationModel(id: j['id'], name: j['name']);
}

class RouteModel {
  final int id;
  final String name;
  RouteModel({required this.id, required this.name});
  factory RouteModel.fromJson(Map<String, dynamic> j) =>
      RouteModel(id: j['id'], name: j['name']);
}

// ── Page ─────────────────────────────────────────────────────────────────────
class RequestRouteChangePage extends StatefulWidget {
  const RequestRouteChangePage({super.key});

  @override
  State<RequestRouteChangePage> createState() => _RequestRouteChangePageState();
}

class _RequestRouteChangePageState extends State<RequestRouteChangePage> {
  final _storage = const FlutterSecureStorage();

  // data
  List<StationModel> _stations = [];
  List<RouteModel>   _routes   = [];
  StationModel?      _selectedStation;
  RouteModel?        _selectedRoute;
  DateTime?          _selectedDate;

  // ui state
  bool    _loadingData  = true;
  bool    _submitting   = false;
  String? _errorMessage;
  int     _userId       = 0;

  bool get _canSubmit =>
      _selectedStation != null &&
      _selectedRoute   != null &&
      _selectedDate    != null &&
      !_submitting;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load userId + stations + routes in parallel ──────────────────────────
  Future<void> _loadData() async {
    final userIdStr = await _storage.read(key: 'userId') ?? '0';
    _userId = int.tryParse(userIdStr) ?? 0;

    try {
      final results = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/routechangerequests/stations')),
        http.get(Uri.parse('$apiBaseUrl/api/routechangerequests/routes')),
      ]);

      if (!mounted) return;

      final stationsRes = results[0];
      final routesRes   = results[1];

      if (stationsRes.statusCode == 200 && routesRes.statusCode == 200) {
        final stationsData = jsonDecode(stationsRes.body) as List;
        final routesData   = jsonDecode(routesRes.body)   as List;
        setState(() {
          _stations    = stationsData.map((e) => StationModel.fromJson(e)).toList();
          _routes      = routesData.map((e) => RouteModel.fromJson(e)).toList();
          _loadingData = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data from server.';
          _loadingData  = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Check your connection.';
          _loadingData  = false;
        });
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() { _submitting = true; _errorMessage = null; });

    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/routechangerequests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId':        _userId,
          'newStationId':  _selectedStation!.id,
          'newRouteId':    _selectedRoute!.id,
          'effectiveDate': _selectedDate!.toIso8601String(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = jsonDecode(res.body)['message'] ?? 'Submission failed.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFFC107),
            onPrimary: Colors.black87,
            onSurface: Colors.black87,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Color(0xFFF0FFF4), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline,
                color: Color(0xFF16A34A), size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Request Submitted!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text(
            'Your request to change to\n"${_selectedStation!.name}"\n'
            'on route "${_selectedRoute!.name}"\n'
            'effective ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
            'has been submitted for approval.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFDDE8F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08),
                    blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _loadingData
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(children: [
                            CircularProgressIndicator(color: Color(0xFFFFC107)),
                            SizedBox(height: 16),
                            Text('Loading stations and routes...',
                                style: TextStyle(color: Colors.black45, fontSize: 13)),
                          ]),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoBanner(),
                            const SizedBox(height: 22),
                            _buildLabel('Select Pickup Station'),
                            const SizedBox(height: 8),
                            _buildDropdown<StationModel>(
                              hint: 'Choose a station',
                              value: _selectedStation,
                              items: _stations,
                              itemLabel: (s) => s.name,
                              onChanged: (val) =>
                                  setState(() => _selectedStation = val),
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Select New Route'),
                            const SizedBox(height: 8),
                            _buildDropdown<RouteModel>(
                              hint: 'Choose a route',
                              value: _selectedRoute,
                              items: _routes,
                              itemLabel: (r) => r.name,
                              onChanged: (val) =>
                                  setState(() => _selectedRoute = val),
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Effective Date'),
                            const SizedBox(height: 8),
                            _buildDateField(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              _buildErrorBanner(),
                            ],
                            const SizedBox(height: 24),
                            _buildSubmitButton(),
                            const SizedBox(height: 10),
                            _buildCancelButton(),
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

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeader() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          color: Color(0xFFFFC107),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.swap_horiz_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Request Route Change',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3)),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child:
                const Icon(Icons.close, color: Colors.black54, size: 22),
          ),
        ]),
      );

  Widget _buildInfoBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FB),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
              left: BorderSide(color: Color(0xFF3B82F6), width: 3)),
        ),
        child: const Text(
          'Select your new pickup station, route, and effective date. '
          'Your request will be reviewed by the admin.',
          style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF2563EB),
              height: 1.45),
        ),
      );

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.black87));

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: Text(hint,
                style: const TextStyle(
                    fontSize: 14.5, color: Colors.black38)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.black54),
            style: const TextStyle(
                fontSize: 14.5, color: Colors.black87),
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _buildDateField() => GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.black45),
            const SizedBox(width: 10),
            Text(
              _selectedDate == null
                  ? 'Pick a date...'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                  fontSize: 14.5,
                  color: _selectedDate == null
                      ? Colors.black38
                      : Colors.black87),
            ),
          ]),
        ),
      );

  Widget _buildErrorBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFDC2626).withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_errorMessage!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFDC2626)))),
        ]),
      );

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.disabled)
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFFFFC107)),
            foregroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.disabled)
                    ? Colors.black38
                    : Colors.black87),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black54))
              : const Text('Request Change',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _buildCancelButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: const BorderSide(
                color: Color(0xFFE2E8F0), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );
}