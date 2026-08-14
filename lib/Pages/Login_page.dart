import 'package:flutter/material.dart';
import 'package:safeway/Constant/Constant_Color.dart';
import 'package:safeway/Pages/Parents/Parent_Dashboard.dart';
import 'package:safeway/Pages/Student/Dashboard.dart';
import 'package:safeway/Pages/Driver/DriverDashBoard.dart';
import 'package:safeway/services/auth_service.dart';
import 'package:safeway/Pages/Admin/AdminDashBoard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = true;
  bool hidePassword = true;
  bool isLoading = false;

  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.softBackground),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 32,
                  left: 20,
                  right: 20,
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
                      const SizedBox(height: 28),
                      _buildHeroSection(),
                      const SizedBox(height: 28),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Logo + brand name + "LIVE NETWORK" badge
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.darkNavy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'SafeWay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'SMART SCHOOL BUS',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.badgeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.badgeDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE NETWORK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // "Welcome back" + headline + bus illustration + supporting text
  Widget _buildHeroSection() {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        Positioned(
          right: -100,
          top: -40,
          child: Image.asset('assets/images/buc.png', height: 230, width: 230),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Move together\nArrive safer.',
              style: TextStyle(
                fontSize: 32,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 70), // reserves space behind the bus art
            const Text(
              'One calm place for every school day journey.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('SAFEWAY ID'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: emailController,
            hint: 'STU001',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _fieldLabel('PASSWORD'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: passwordController,
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            obscureText: hidePassword,
            suffixIcon: IconButton(
              icon: Icon(
                hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => hidePassword = !hidePassword),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => rememberMe = !rememberMe),
                child: Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: AppColors.accentGreen,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) =>
                          setState(() => rememberMe = value ?? false),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: hook up your forgot-ID flow
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
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
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Be safe.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
