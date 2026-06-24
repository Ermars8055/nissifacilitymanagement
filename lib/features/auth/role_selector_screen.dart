import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final fetchedUsers = await ApiClient.get('/Users');
      setState(() { users = fetchedUsers; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _loginAsUser(dynamic user) {
    SessionManager().setUser(user);
    if (user['role'] == 'Admin' || user['role'] == 'Super Admin') {
      context.go('/admin-dashboard');
    } else {
      context.go('/select-building');
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':      return const Color(0xFF6B3FA0);
      case 'manager':    return const Color(0xFF1E5080);
      case 'supervisor': return const Color(0xFF1E3D2F);
      default:           return const Color(0xFFA05A10);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF1E3D2F),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.people_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Who\'s logging in?',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select your profile to enter the workspace',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                : users.isEmpty
                    ? const _EmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              children: [
                                const Text(
                                  'AVAILABLE PROFILES',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.1),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    '${users.length} users',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E3D2F), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: users.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final role = (user['role'] ?? 'Technician') as String;
                                final rColor = _roleColor(role);
                                return GestureDetector(
                                  onTap: () => _loginAsUser(user),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52, height: 52,
                                          decoration: BoxDecoration(
                                            color: rColor.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _initials(user['name'] ?? ''),
                                              style: TextStyle(color: rColor, fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'] ?? 'Unknown',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(user['email'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: rColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(10)),
                                          child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C8278), size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 88, height: 88,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
                child: Icon(Icons.people_outline_rounded, size: 40, color: Color(0xFF2D6B4F)),
              ),
            ),
            SizedBox(height: 18),
            Text('No users found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
            SizedBox(height: 8),
            Text(
              'Make sure the backend is running and seeded.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
            ),
          ],
        ),
      ),
    );
  }
}
