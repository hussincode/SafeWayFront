import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:safeway/Pages/Parents/Parent_Dashboard.dart';
import 'package:safeway/Pages/Student/Dashboard.dart';
import 'package:safeway/Pages/Driver/DriverDashBoard.dart';
import 'package:safeway/services/auth_service.dart';
import 'package:safeway/Pages/Admin/AdminDashboard.dart';

// ...existing code...

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool rememberMe = true;
  bool hidePassword = true;
  bool isLoading = false;

  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // =========================================================
  // COLORS
  // =========================================================

  // Dark Background
  static const Color _bgTop = Color(0xFF070708);
  static const Color _bgMid = Color(0xFF101012);
  static const Color _bgBottom = Color(0xFF18181B);

  // School Red
  static const Color _accentRed = Color(0xFFD32F2F);
  static const Color _accentRedLight = Color(0xFFEF4444);
  static const Color _accentRedDark = Color(0xFF991B1B);

  // Secondary Red
  static const Color _accentBurgundy = Color(0xFF65171B);

  // Glass Effect
  static const Color _glassFill = Color(0x14FFFFFF);
  static const Color _glassBorder = Color(0x2AFFFFFF);

  // Inputs
  static const Color _inputFill = Color(0x0FFFFFFF);

  // Text
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFB8B8BC);
  static const Color _textMuted = Color(0xFF77777D);

  // Buttons
  static const Color _btnRedDark = Color(0xFF991B1B);
  static const Color _btnRed = Color(0xFFD32F2F);

  // =========================================================
  // ANIMATION CONTROLLERS
  // =========================================================

  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _handleSignIn() async {
    setState(() => isLoading = true);

    final result = await _authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final String role = result['role'];

      Widget destination;

      switch (role) {
        case 'Parent':
          destination = const ParentDashboardScreen();
          break;

        case 'Student':
          destination = const StudentDashboardScreen();
          break;

        case 'Driver':
          destination = const DriverDashboardScreen();
          break;

        case 'Admin':
          destination = const AdminDashboardScreen();
          break;

        default:
          destination = const StudentDashboardScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: _accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===================================================
          // BACKGROUND
          // ===================================================
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgTop, _bgMid, _bgBottom],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ===================================================
          // DECORATIVE GLOW
          // ===================================================
          Positioned(
            top: -80,
            right: -60,
            child: _buildGlow(_accentRedDark, 220),
          ),

          Positioned(
            top: 180,
            left: -90,
            child: _buildGlow(_accentBurgundy, 200),
          ),

          Positioned(
            bottom: -100,
            right: -50,
            child: _buildGlow(_accentRedDark, 240),
          ),

          // ===================================================
          // MAIN CONTENT
          // ===================================================
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 28,
                    left: 22,
                    right: 22,
                    bottom: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 26),

                        _buildHeroSection(),

                        const SizedBox(height: 26),

                        _buildLoginCard(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ANIMATED BUS
  // =========================================================

  Widget _buildAnimatedBus() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value * 0.45),
          child: child,
        );
      },
      child: SizedBox(
        width: 92,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // =================================================
            // BUS GLOW
            // =================================================
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accentRed.withOpacity(0.28), Colors.transparent],
                ),
              ),
            ),

            // =================================================
            // BUS BODY
            // =================================================
            Container(
              width: 68,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accentRed, _accentRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: _accentRed.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // =================================================
                  // WINDOWS
                  // =================================================
                  Positioned(
                    left: 9,
                    top: 8,
                    child: Container(
                      width: 50,
                      height: 17,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),

                  // =================================================
                  // LEFT WHEEL
                  // =================================================
                  Positioned(left: 10, bottom: -5, child: _busWheel()),

                  // =================================================
                  // RIGHT WHEEL
                  // =================================================
                  Positioned(right: 10, bottom: -5, child: _busWheel()),

                  // =================================================
                  // FRONT LIGHT
                  // =================================================
                  Positioned(
                    right: 4,
                    top: 22,
                    child: Container(
                      width: 4,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _accentRedLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUS WHEEL
  // =========================================================

  Widget _busWheel() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
      ),
    );
  }

  // =========================================================
  // HERO SECTION
  // =========================================================

  Widget _buildHeroSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ===================================================
        // TEXT SECTION
        // ===================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [_accentRedLight, _accentRed],
                  ).createShader(bounds);
                },
                child: const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Move together\nArrive safer.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'One calm place for every school day journey.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // ===================================================
        // BUS
        // ===================================================
        _buildAnimatedBus(),
      ],
    );
  }

  // =========================================================
  // GLOW
  // =========================================================

  Widget _buildGlow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.55), color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Row(
      children: [
        // ===================================================
        // BUS ICON
        // ===================================================
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_accentRed, _accentRedDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accentRed.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),

        const SizedBox(width: 12),

        // ===================================================
        // APP NAME
        // ===================================================
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'SafeWay',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: 0.2,
              ),
            ),

            Text(
              'SMART SCHOOL BUS',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ],
        ),

        const Spacer(),

        // ===================================================
        // LIVE NETWORK
        // ===================================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: _glassFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _accentRedLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentRedLight.withOpacity(0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              const Text(
                'LIVE NETWORK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _accentRedLight,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LOGIN CARD
  // =========================================================

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _glassFill,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _glassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // SAFEWAY ID
              // =================================================
              _fieldLabel('SAFEWAY ID'),

              const SizedBox(height: 8),

              _buildTextField(
                controller: emailController,
                hint: 'STU001',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 16),

              // =================================================
              // PASSWORD
              // =================================================
              _fieldLabel('PASSWORD'),

              const SizedBox(height: 8),

              _buildTextField(
                controller: passwordController,
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                obscureText: hidePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => hidePassword = !hidePassword);
                  },
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // REMEMBER ME + FORGOT ID
              // =================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() => rememberMe = !rememberMe);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: rememberMe,
                            activeColor: _accentRed,
                            side: const BorderSide(
                              color: _glassBorder,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (value) {
                              setState(() => rememberMe = value ?? false);
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          'Remember me',
                          style: TextStyle(fontSize: 13, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      // TODO: hook up forgot-ID flow
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot ID?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accentRedLight,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =================================================
              // SIGN IN BUTTON
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(
                      colors: [_btnRedDark, _btnRed],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _btnRedDark.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: isLoading ? null : _handleSignIn,
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),

                                  SizedBox(width: 8),

                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // SAFETY MESSAGE
              // =================================================
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 13, color: _textMuted),

                    const SizedBox(width: 5),

                    const Text(
                      'Be safe.',
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FIELD LABEL
  // =========================================================

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: _textSecondary,
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        cursorColor: _accentRedLight,
        style: const TextStyle(fontSize: 15, color: _textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _textMuted, size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
