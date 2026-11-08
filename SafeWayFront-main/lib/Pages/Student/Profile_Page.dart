import 'package:flutter/material.dart';

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

    final first =
        parts.first.isNotEmpty ? parts.first[0] : '';

    final last =
        parts.length > 1 && parts.last.isNotEmpty
            ? parts.last[0]
            : '';

    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070708),
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildProfileCard(),

              const SizedBox(height: 24),

              _buildSectionTitle(),

              const SizedBox(height: 14),

              _buildInfoCard(),

              const SizedBox(height: 16),

              _buildPreferencesCard(),

              const SizedBox(height: 24),

              _buildLogoutButton(),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF991B1B),
                Color(0xFFD32F2F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F)
                    .withOpacity(0.22),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),

        const SizedBox(width: 13),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'SAFEWAY',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F)
                .withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD32F2F)
                  .withOpacity(0.18),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 7,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Text(
                'ACTIVE',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Profile Card
  // ─────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF65171B)
                .withOpacity(0.38),
            const Color(0xFF101012)
                .withOpacity(0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFD32F2F)
              .withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F)
                .withOpacity(0.08),
            blurRadius: 28,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF991B1B),
                  Color(0xFFD32F2F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F)
                      .withOpacity(0.22),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            fullName.isEmpty ? 'Student' : fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Student · SafeWay member',
            style: TextStyle(
              color: Color(0xFFB8B8BC),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Text(
              'ID: $uniqueID',
              style: const TextStyle(
                color: Color(0xFFE5E5E7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section Title
  // ─────────────────────────────────────────────

  Widget _buildSectionTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Student information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Student Information
  // ─────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoTile(
            icon: Icons.badge_outlined,
            title: 'Student ID',
            value: uniqueID,
          ),

          _divider(),

          _infoTile(
            icon: Icons.school_outlined,
            title: 'Grade',
            value: grade,
          ),

          _divider(),

          _infoTile(
            icon: Icons.directions_bus_outlined,
            title: 'Bus number',
            value: busNumber,
          ),

          _divider(),

          _infoTile(
            icon: Icons.alt_route_rounded,
            title: 'Route',
            value: routeName,
          ),

          _divider(),

          _infoTile(
            icon: Icons.location_on_outlined,
            title: 'Pickup station',
            value: stopName,
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFEF4444),
            size: 21,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF77777D),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not available' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE5E5E7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color: Colors.white.withOpacity(0.055),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Preferences
  // ─────────────────────────────────────────────

  Widget _buildPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          _preferenceTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Route updates are enabled',
          ),

          const SizedBox(height: 12),

          _preferenceTile(
            icon: Icons.shield_outlined,
            title: 'Privacy & safety',
            subtitle: 'Your transportation data is protected',
          ),
        ],
      ),
    );
  }

  Widget _preferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F)
                  .withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFEF4444),
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF77777D),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF55555A),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: onLogout,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF101012),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFFEF4444)
                .withOpacity(0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Color(0xFFEF4444),
              size: 19,
            ),
            SizedBox(width: 9),
            Text(
              'Sign out',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}