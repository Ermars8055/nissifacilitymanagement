import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/session/session_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'super admin': return const Color(0xFF6B3FA0);
      case 'manager':     return const Color(0xFF1E5080);
      case 'supervisor':  return const Color(0xFF1E3D2F);
      default:            return const Color(0xFFA05A10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final user = session.currentUser ?? {};
    final name = user['name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final role = user['role'] as String? ?? 'Field Worker';
    final building = session.selectedBuildingName ?? 'All Buildings';
    final initials = _initials(name);
    final rColor = _roleColor(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1714)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    // Avatar card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF142B20), Color(0xFF2D6B4F)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D6B4F),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
                            ),
                            child: Center(
                              child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: rColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: rColor.withValues(alpha: 0.6)),
                            ),
                            child: Text(role, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Info rows
                    _InfoCard(children: [
                      _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
                      _Divider(),
                      _InfoRow(icon: Icons.business_outlined, label: 'Building', value: building),
                      _Divider(),
                      _InfoRow(icon: Icons.admin_panel_settings_outlined, label: 'Role', value: role),
                    ]),

                    const SizedBox(height: 16),

                    // App info
                    _InfoCard(children: [
                      _InfoRow(icon: Icons.info_outline_rounded, label: 'App Version', value: 'v1.0.0'),
                      _Divider(),
                      _InfoRow(icon: Icons.security_outlined, label: 'Auth', value: 'Google SSO'),
                    ]),

                    const SizedBox(height: 16),

                    // Change Building (non-admin only)
                    if (!session.isAdmin)
                      GestureDetector(
                        onTap: () => context.go('/select-building'),
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3D2F).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1E3D2F).withValues(alpha: 0.22)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business_outlined, color: Color(0xFF1E3D2F), size: 20),
                              SizedBox(width: 10),
                              Text('Change Building', style: TextStyle(color: Color(0xFF1E3D2F), fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Sign out
                    GestureDetector(
                      onTap: () async {
                        await AuthService().signOut();
                        if (context.mounted) context.go('/login');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B2020).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF9B2020).withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Color(0xFF9B2020), size: 20),
                            SizedBox(width: 10),
                            Text('Sign Out', style: TextStyle(color: Color(0xFF9B2020), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF1E3D2F), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278), fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : '—', style: const TextStyle(fontSize: 14, color: Color(0xFF1A1714), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 18), color: const Color(0xFFF0EAE2));
}
