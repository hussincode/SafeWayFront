import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safeway/services/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

class SafeWayColors {
  static const backgroundTop = Color(0xFF070708);
  static const backgroundMiddle = Color(0xFF101012);
  static const backgroundBottom = Color(0xFF18181B);

  static const primaryRed = Color(0xFFD32F2F);
  static const lightRed = Color(0xFFEF4444);
  static const darkRed = Color(0xFF991B1B);
  static const burgundy = Color(0xFF65171B);

  static const primaryText = Color(0xFFF5F5F5);
  static const secondaryText = Color(0xFFB8B8BC);
  static const mutedText = Color(0xFF77777D);

  static const glass = Color(0x14141414);
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class RouteModel {
  final int id;
  final String name;

  RouteModel({
    required this.id,
    required this.name,
  });

  factory RouteModel.fromJson(Map<String, dynamic> j) {
    return RouteModel(
      id: j['id'],
      name: j['name'],
    );
  }
}

class StationModel {
  final int id;
  final String name;

  StationModel({
    required this.id,
    required this.name,
  });

  factory StationModel.fromJson(Map<String, dynamic> j) {
    return StationModel(
      id: j['id'],
      name: j['name'],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class RequestRouteChangePage extends StatefulWidget {
  const RequestRouteChangePage({super.key});

  @override
  State<RequestRouteChangePage> createState() =>
      _RequestRouteChangePageState();
}

class _RequestRouteChangePageState extends State<RequestRouteChangePage>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();

  final TextEditingController _reasonController = TextEditingController();

  // Data
  List<RouteModel> _routes = [];
  List<StationModel> _stations = [];

  RouteModel? _selectedRoute;
  DateTime? _selectedDate;

  // UI state
  bool _loadingData = true;
  bool _submitting = false;

  String? _errorMessage;

  int _userId = 0;

  String _currentRoute = 'Route A · Downtown';

  late AnimationController _busAnimationController;
  late Animation<double> _busAnimation;

  bool get _canSubmit {
    return _selectedRoute != null &&
        _selectedDate != null &&
        _reasonController.text.trim().isNotEmpty &&
        !_submitting;
  }

  @override
  void initState() {
    super.initState();

    _busAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _busAnimation = Tween<double>(
      begin: -3,
      end: 3,
    ).animate(
      CurvedAnimation(
        parent: _busAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _reasonController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _busAnimationController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD DATA
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final userIdStr = await _storage.read(key: 'userId') ?? '0';

    _userId = int.tryParse(userIdStr) ?? 0;

    try {
      final results = await Future.wait([
        http.get(
          Uri.parse(
            '$apiBaseUrl/api/routechangerequests/routes',
          ),
        ),
        http.get(
          Uri.parse(
            '$apiBaseUrl/api/routechangerequests/stations',
          ),
        ),
        if (_userId != 0)
          http.get(
            Uri.parse(
              '$apiBaseUrl/api/auth/student-info/$_userId',
            ),
          ),
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

      if (routesRes.statusCode == 200 &&
          stationsRes.statusCode == 200) {
        final routesData = jsonDecode(routesRes.body) as List;
        final stationsData = jsonDecode(stationsRes.body) as List;

        setState(() {
          _routes = routesData
              .map(
                (e) => RouteModel.fromJson(e),
              )
              .toList();

          _stations = stationsData
              .map(
                (e) => StationModel.fromJson(e),
              )
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
          _errorMessage =
              'Network error. Check your connection.';
          _loadingData = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final stationId =
        _stations.isNotEmpty ? _stations.first.id : 1;

    try {
      final res = await http.post(
        Uri.parse(
          '$apiBaseUrl/api/routechangerequests',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': _userId,
          'newStationId': stationId,
          'newRouteId': _selectedRoute!.id,
          'effectiveDate':
              _selectedDate!.toIso8601String(),
          'reason':
              _reasonController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showSuccessDialog();
      } else {
        String message = 'Submission failed.';

        try {
          final body = jsonDecode(res.body);

          if (body is Map<String, dynamic> &&
              body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _errorMessage = message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network error. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATE PICKER
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: SafeWayColors.primaryRed,
              onPrimary: Colors.white,
              surface: Color(0xFF18181B),
              onSurface: SafeWayColors.primaryText,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF18181B),
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

  // ─────────────────────────────────────────────────────────────────────────
  // SUCCESS DIALOG
  // ─────────────────────────────────────────────────────────────────────────

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24),
          child: _GlassContainer(
            borderRadius: 28,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        SafeWayColors.primaryRed,
                        SafeWayColors.darkRed,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SafeWayColors.primaryRed
                            .withOpacity(0.3),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Request Submitted!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SafeWayColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Your request to change route to '
                  '"${_selectedRoute!.name}" has been '
                  'submitted for approval.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SafeWayColors.secondaryText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          SafeWayColors.darkRed,
                          SafeWayColors.primaryRed,
                        ],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
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

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          SafeWayColors.backgroundTop,
      body: Stack(
        children: [
          const _Background(),

          SafeArea(
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                22,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 30),

                  _buildHero(),

                  const SizedBox(height: 26),

                  _buildFormCard(),

                  const SizedBox(height: 18),

                  _buildSafetyText(),

                  const SizedBox(height: 18),

                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SafeWayColors.primaryRed,
                  SafeWayColors.darkRed,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: SafeWayColors.primaryRed
                      .withOpacity(0.28),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'SafeWay',
                style: TextStyle(
                  color: SafeWayColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'SMART SCHOOL BUS',
                style: TextStyle(
                  color: SafeWayColors.mutedText,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),

        _buildLiveBadge(),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: SafeWayColors.lightRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SafeWayColors.lightRed
                          .withOpacity(0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: SafeWayColors.lightRed,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [
                      SafeWayColors.lightRed,
                      SafeWayColors.primaryRed,
                    ],
                  ).createShader(bounds);
                },
                child: const Text(
                  'STUDENT REQUEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Change your\nroute safely.',
                style: TextStyle(
                  color: SafeWayColors.primaryText,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Choose the option that works best '
                'for your school day.',
                style: TextStyle(
                  color: SafeWayColors.secondaryText,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        AnimatedBuilder(
          animation: _busAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                _busAnimation.value,
              ),
              child: child,
            );
          },
          child: const _BusIllustration(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FORM CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFormCard() {
    return _GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(22),
      child: _loadingData
          ? const Padding(
              padding:
                  EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 25,
                      height: 25,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            SafeWayColors.lightRed,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading options...',
                      style: TextStyle(
                        color:
                            SafeWayColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROUTE CHANGE',
                  style: TextStyle(
                    color:
                        SafeWayColors.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Update your transportation details.',
                  style: TextStyle(
                    color:
                        SafeWayColors.mutedText,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 23),

                _buildSectionLabel(
                  'CURRENT ROUTE',
                ),

                const SizedBox(height: 8),

                _buildCurrentRouteBadge(),

                const SizedBox(height: 19),

                _buildSectionLabel(
                  'AVAILABLE ROUTES',
                ),

                const SizedBox(height: 8),

                _buildDropdown<RouteModel>(
                  hint: 'Select a route',
                  value: _selectedRoute,
                  items: _routes,
                  itemLabel: (route) =>
                      route.name,
                  onChanged: (value) {
                    setState(() {
                      _selectedRoute = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                _buildSectionLabel(
                  'EFFECTIVE DATE',
                ),

                const SizedBox(height: 8),

                _buildDateField(),

                const SizedBox(height: 18),

                _buildSectionLabel(
                  'REASON',
                ),

                const SizedBox(height: 8),

                _buildReasonField(),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 15),
                  _buildErrorBanner(),
                ],
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LABEL
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: SafeWayColors.secondaryText,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CURRENT ROUTE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCurrentRouteBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SafeWayColors.darkRed
                  .withOpacity(0.25),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: SafeWayColors.lightRed,
              size: 19,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              _currentRoute,
              style: const TextStyle(
                color: SafeWayColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const Icon(
            Icons.check_circle_rounded,
            color: SafeWayColors.lightRed,
            size: 18,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DROPDOWN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor:
              const Color(0xFF18181B),
          borderRadius:
              BorderRadius.circular(16),
          hint: Text(
            hint,
            style: const TextStyle(
              color: SafeWayColors.mutedText,
              fontSize: 14,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: SafeWayColors.secondaryText,
          ),
          style: const TextStyle(
            color: SafeWayColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items.map(
            (item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow:
                      TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: SafeWayColors.mutedText,
              size: 18,
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Choose effective date'
                    : '${_selectedDate!.day}/'
                        '${_selectedDate!.month}/'
                        '${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null
                      ? SafeWayColors.mutedText
                      : SafeWayColors.primaryText,
                  fontSize: 14,
                  fontWeight:
                      _selectedDate == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: SafeWayColors.mutedText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REASON
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildReasonField() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 3,
        style: const TextStyle(
          color: SafeWayColors.primaryText,
          fontSize: 14,
        ),
        cursorColor:
            SafeWayColors.lightRed,
        decoration: const InputDecoration(
          hintText:
              'Tell us a little more...',
          hintStyle: TextStyle(
            color: SafeWayColors.mutedText,
            fontSize: 14,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ERROR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            SafeWayColors.darkRed.withOpacity(0.18),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              SafeWayColors.lightRed.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: SafeWayColors.lightRed,
            size: 18,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: SafeWayColors.secondaryText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAFETY MESSAGE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSafetyText() {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            color: SafeWayColors.mutedText,
            size: 15,
          ),
          SizedBox(width: 6),
          Text(
            'Be safe.',
            style: TextStyle(
              color: SafeWayColors.mutedText,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT BUTTON
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final enabled = _canSubmit;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(17),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                SafeWayColors.darkRed,
                SafeWayColors.primaryRed,
              ],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: SafeWayColors.primaryRed
                          .withOpacity(0.25),
                      blurRadius: 22,
                      offset:
                          const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed:
                enabled ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.transparent,
              disabledBackgroundColor:
                  Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor:
                  Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(17),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        'Submit request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(
                        Icons
                            .arrow_forward_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS CONTAINER
// ─────────────────────────────────────────────────────────────────────────────

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({
    required this.child,
    required this.borderRadius,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.065),
            borderRadius:
                BorderRadius.circular(
              borderRadius,
            ),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.11),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.35),
                blurRadius: 35,
                offset:
                    const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SafeWayColors.backgroundTop,
            SafeWayColors.backgroundMiddle,
            SafeWayColors.backgroundBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Top right
          Positioned(
            top: -150,
            right: -130,
            child: _Glow(
              size: 330,
              color:
                  SafeWayColors.darkRed,
              opacity: 0.24,
            ),
          ),

          // Left middle
          Positioned(
            top: 220,
            left: -180,
            child: _Glow(
              size: 360,
              color:
                  SafeWayColors.burgundy,
              opacity: 0.19,
            ),
          ),

          // Bottom right
          Positioned(
            bottom: -180,
            right: -150,
            child: _Glow(
              size: 380,
              color:
                  SafeWayColors.primaryRed,
              opacity: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Glow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: 130,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUS ILLUSTRATION
// ─────────────────────────────────────────────────────────────────────────────

class _BusIllustration extends StatelessWidget {
  const _BusIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 60,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color:
                      SafeWayColors.primaryRed
                          .withOpacity(0.22),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          Positioned(
            top: 8,
            left: 7,
            right: 7,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(15),
                gradient:
                    const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SafeWayColors.primaryRed,
                    SafeWayColors.darkRed,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 9,
                    right: 18,
                    child: Row(
                      children: [
                        Expanded(
                          child: _BusWindow(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _BusWindow(),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Container(
                      width: 6,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.5),
                        borderRadius:
                            BorderRadius.circular(
                          2,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 4,
                    top: 26,
                    child: Container(
                      width: 4,
                      height: 8,
                      decoration:
                          BoxDecoration(
                        color:
                            SafeWayColors.lightRed,
                        borderRadius:
                            BorderRadius.circular(
                          3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SafeWayColors
                                .lightRed
                                .withOpacity(
                              0.8,
                            ),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 8,
            left: 17,
            child: _Wheel(),
          ),

          Positioned(
            bottom: 8,
            right: 17,
            child: _Wheel(),
          ),
        ],
      ),
    );
  }
}

class _BusWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 17,
      decoration: BoxDecoration(
        color: const Color(0xFF101012)
            .withOpacity(0.72),
        borderRadius:
            BorderRadius.circular(5),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.12),
          width: 0.5,
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF38383D),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}