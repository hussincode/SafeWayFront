import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';

class ChangePickupStationScreen extends StatefulWidget {
  const ChangePickupStationScreen({super.key});

  @override
  State<ChangePickupStationScreen> createState() =>
      _ChangePickupStationScreenState();
}

class _ChangePickupStationScreenState
    extends State<ChangePickupStationScreen> {
  String get baseUrl => apiBaseUrl;
  final _storage = const FlutterSecureStorage();

  // ── State ──
  List<Map<String, dynamic>> _stations = [];
  int?    _selectedStationId;
  String? _selectedStationName;
  DateTime? _selectedDate;
  bool _isLoading    = true;
  bool _isSubmitting = false;
  int  _userId       = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final userIdStr = await _storage.read(key: 'userId') ?? '0';
    _userId = int.tryParse(userIdStr) ?? 0;
    await _loadStations();
  }

  // ── Load stations from API ──
Future<void> _loadStations() async {
  try {
    print('📡 Fetching stations...');
    final res = await http.get(
      Uri.parse('$baseUrl/api/station/list'),
    );
    print('📡 Status: ${res.statusCode}');
    print('📡 Body: ${res.body}');

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      print('📡 Stations count: ${data.length}');
      setState(() {
        _stations = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      print('❌ Error: ${res.statusCode}');
      setState(() => _isLoading = false);
    }
  } catch (e) {
    print('❌ Exception: $e');
    setState(() => _isLoading = false);
  }
}

  // ── Pick date ──
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Submit request ──
  Future<void> _submitRequest() async {
    if (_selectedStationId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final body = {
        'userId':       _userId,
        'newStationId': _selectedStationId,
        if (_selectedDate != null)
          'effectiveDate': _selectedDate!.toIso8601String(),
      };

      final res = await http.post(
        Uri.parse('$baseUrl/api/station/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showErrorSnackbar(data['message'] ?? 'Something went wrong.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorSnackbar('Cannot connect to server.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FFF4), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Request Submitted!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            const Text(
              'Your request will be reviewed by the school administration. You\'ll receive a notification once it\'s approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Bus icon ──
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_bus_rounded,
                    color: Color(0xFF1A1A2E), size: 36),
              ),
              const SizedBox(height: 20),

              // ── Title ──
              const Text(
                'Change Pick-up Station',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your new pick-up station and date, then submit your request.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),

              // ── White card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Station dropdown ──
                    Row(
                      children: const [
                        Icon(Icons.location_on_outlined,
                            color: Color(0xFF4F46E5), size: 18),
                        SizedBox(width: 6),
                        Text('New Pick-up Station',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _isLoading
                        ? Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedStationId,
                                hint: const Text('Select a station',
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFF6B7280)),
                                items: _stations.map((s) {
                                  return DropdownMenuItem<int>(
                                    value: s['id'] as int,
                                    child: Text(s['name'] as String,
                                        style: const TextStyle(
                                            fontSize: 14, color: Color(0xFF1A1A2E))),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedStationId   = val;
                                    _selectedStationName = _stations
                                        .firstWhere((s) => s['id'] == val)['name'];
                                  });
                                },
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // ── Date picker ──
                    Row(
                      children: const [
                        Icon(Icons.calendar_today_outlined,
                            color: Color(0xFF4F46E5), size: 18),
                        SizedBox(width: 6),
                        Text('Effective Date (Optional)',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: Color(0xFF4F46E5), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _selectedDate == null
                                  ? 'Pick a date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDate == null
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Info box ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💡', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your request will be reviewed by the school administration. You\'ll receive a notification once it\'s approved.',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Request Change button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedStationId == null || _isSubmitting
                            ? null
                            : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Request Change',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedStationId == null
                                      ? const Color(0xFF9CA3AF)
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Cancel button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Footer ──
              const Text(
                'Need help? Contact the school office at (555) 123-4567',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}