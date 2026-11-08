import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';

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

class ChangePickupStationScreen extends StatefulWidget {
  const ChangePickupStationScreen({super.key});

  @override
  State<ChangePickupStationScreen> createState() =>
      _ChangePickupStationScreenState();
}

class _ChangePickupStationScreenState extends State<ChangePickupStationScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final TextEditingController _reasonController = TextEditingController();

  List<StationModel> _stations = [];
  List<RouteModel> _routes = [];

  StationModel? _selectedStation;
  RouteModel? _selectedRoute;

  DateTime? _selectedDate;

  bool _loadingData = true;
  bool _submitting = false;

  String? _errorMessage;

  int _userId = 0;

  String _currentPickup = 'Imperial Park';

  bool get _canSubmit =>
      _selectedStation != null && _selectedDate != null && !_submitting;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loadingData = true;
        _errorMessage = null;
      });

      final userIdString = await _storage.read(key: 'userId');

      _userId = int.tryParse(userIdString ?? '') ?? 0;

      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/routechangerequests/stations')),
        http.get(Uri.parse('$apiBaseUrl/api/routechangerequests/routes')),
        if (_userId != 0)
          http.get(Uri.parse('$apiBaseUrl/api/auth/student-info/$_userId')),
      ]);

      final stationsResponse = responses[0];
      final routesResponse = responses[1];

      if (stationsResponse.statusCode == 200) {
        final data = jsonDecode(stationsResponse.body);

        _stations = (data as List)
            .map((e) => StationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (routesResponse.statusCode == 200) {
        final data = jsonDecode(routesResponse.body);

        _routes = (data as List)
            .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (_userId != 0 && responses.length > 2) {
        final infoResponse = responses[2];

        if (infoResponse.statusCode == 200) {
          final infoData = jsonDecode(infoResponse.body);

          if (infoData['stopName'] != null) {
            _currentPickup = infoData['stopName'].toString();
          }
        }
      }

      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
          _errorMessage = 'Failed to load data. Please try again.';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    try {
      setState(() {
        _submitting = true;
        _errorMessage = null;
      });

      final routeId =
          _selectedRoute?.id ?? (_routes.isNotEmpty ? _routes.first.id : null);

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/routechangerequests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'newStationId': _selectedStation!.id,
          'newRouteId': routeId,
          'effectiveDate': _selectedDate!.toIso8601String(),
          'reason': _reasonController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _submitting = false;
          });

          _showSuccessDialog();
        }
      } else {
        String message = 'Submission failed.';

        try {
          final data = jsonDecode(response.body);

          if (data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _submitting = false;
            _errorMessage = message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD32F2F),
              onPrimary: Colors.white,
              surface: Color(0xFF18181B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD32F2F).withOpacity(0.12),
                    border: Border.all(
                      color: const Color(0xFFD32F2F).withOpacity(0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFFEF4444),
                    size: 38,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Request Submitted!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your pickup station change request has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB8B8BC),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070708),
      body: SafeArea(
        child: _loadingData
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
              )
            : RefreshIndicator(
                color: const Color(0xFFD32F2F),
                backgroundColor: const Color(0xFF18181B),
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopHeader(),

                      const SizedBox(height: 30),

                      _buildPageIntro(),

                      const SizedBox(height: 24),

                      _buildCurrentPickup(),

                      const SizedBox(height: 14),

                      _buildFormCard(),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(),
                      ],

                      const SizedBox(height: 24),

                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF101012),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STUDENT REQUEST',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Change pickup station',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF65171B).withOpacity(0.30),
            const Color(0xFF101012).withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.08),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_location_alt_rounded,
              color: Color(0xFFEF4444),
              size: 27,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update your pickup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Choose a new station and the date when the change should take effect.',
                  style: TextStyle(
                    color: Color(0xFFB8B8BC),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPickup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFFB8B8BC),
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT PICKUP',
                  style: TextStyle(
                    color: Color(0xFF77777D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _currentPickup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'CURRENT',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEW PICKUP DETAILS',
            style: TextStyle(
              color: Color(0xFF77777D),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 18),

          _buildFieldLabel('Pickup station', Icons.location_on_outlined),

          const SizedBox(height: 8),

          _buildDropdown(),

          const SizedBox(height: 20),

          _buildFieldLabel('Effective date', Icons.calendar_today_outlined),

          const SizedBox(height: 8),

          _buildDateField(),

          const SizedBox(height: 20),

          _buildFieldLabel('Reason', Icons.notes_rounded),

          const SizedBox(height: 8),

          _buildReasonField(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFEF4444)),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE5E5E7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: DropdownButtonFormField<StationModel>(
        initialValue: _selectedStation,
        dropdownColor: const Color(0xFF18181B),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF77777D),
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.place_outlined,
            color: Color(0xFF77777D),
            size: 21,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
        hint: const Text(
          'Select pickup station',
          style: TextStyle(color: Color(0xFF77777D), fontSize: 13),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        items: _stations.map((station) {
          return DropdownMenuItem<StationModel>(
            value: station,
            child: Text(station.name),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedStation = value;
          });
        },
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF77777D),
              size: 21,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Select effective date'
                    : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null
                      ? const Color(0xFF77777D)
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: _selectedDate == null
                      ? FontWeight.w400
                      : FontWeight.w500,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF55555A),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return TextField(
      controller: _reasonController,
      maxLines: 4,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      cursorColor: const Color(0xFFEF4444),
      decoration: InputDecoration(
        hintText: 'Tell us why you need to change your pickup station...',
        hintStyle: const TextStyle(
          color: Color(0xFF5F5F65),
          fontSize: 12.5,
          height: 1.4,
        ),
        filled: true,
        fillColor: const Color(0xFF18181B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.2),
        ),
        contentPadding: const EdgeInsets.all(15),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF991B1B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _canSubmit ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          disabledBackgroundColor: const Color(0xFF2A2A2D),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF66666B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 19),
                  const SizedBox(width: 9),
                  const Text(
                    'Submit Request',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
