import 'package:flutter/material.dart';
import 'package:safeway/Constant/Constant_Color.dart';

class ProfilePage extends StatelessWidget {
  final String fullName;
  final String uniqueID;
  final String grade;
  final String busNumber;
  final String routeName;
  final String stopName;
  final Widget? bottomNavigationBar;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.fullName,
    required this.uniqueID,
    required this.grade,
    required this.busNumber,
    required this.routeName,
    required this.stopName,
    required this.onLogout,
    this.bottomNavigationBar,
  });

  String get _initials {
    final full = fullName.trim();
    if (full.isEmpty) return '?';
    final parts = full.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F0),
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD98B72),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName.isEmpty ? 'Student' : fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14181C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Student · SafeWay member',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Section label ──
              const Text(
                'ACCOUNT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your preferences',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14181C),
                ),
              ),
              const SizedBox(height: 16),

              // ── Preference tiles ──
              _prefTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'On for route updates',
              ),
              const SizedBox(height: 14),
              _prefTile(
                icon: Icons.shield_outlined,
                title: 'Privacy & safety',
                subtitle: 'Your route data is protected',
              ),

              const SizedBox(height: 32),

              // ── Sign out ──
              GestureDetector(
                onTap: onLogout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFE8734F),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sign out of preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8734F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prefTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentGreen, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14181C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 18),
        ],
      ),
    );
  }
}
