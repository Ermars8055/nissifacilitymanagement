import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/session/session_manager.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiClient.get('/Users');
      setState(() { users = data; isLoading = false; });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) context.go('/login');
  }

  void _showAddUserSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'Technician';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F3EC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFDDD5C8), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_add_rounded, color: Color(0xFF1E3D2F), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add Team Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                  ],
                ),
                const SizedBox(height: 24),
                _SheetField(controller: nameCtrl, label: 'FULL NAME', hint: 'e.g. John Smith', icon: Icons.person_outline_rounded),
                const SizedBox(height: 16),
                _SheetField(controller: emailCtrl, label: 'EMAIL ADDRESS', hint: 'name@company.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                const Text('ROLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C8278), letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: role,
                      isExpanded: true,
                      dropdownColor: const Color(0xFFF7F3EC),
                      style: const TextStyle(color: Color(0xFF1A1714), fontSize: 14),
                      items: ['Admin', 'Manager', 'Supervisor', 'Technician']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) => setSheet(() => role = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE8DF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4540)))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          setState(() => isLoading = true);
                          await ApiClient.post('/Users', {
                            'name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'role': role,
                          });
                          _fetchUsers();
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3D2F),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(child: Text('Create Member', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignBuildingSheet(dynamic user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F))),
    );

    List<dynamic> allBuildings = [];
    try {
      final clients = await ApiClient.get('/Hierarchy/clients');
      for (final client in clients) {
        final buildings = await ApiClient.get('/Hierarchy/buildings/${client['id']}');
        allBuildings.addAll(buildings);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);

    final selected = <String>{
      ...((user['buildingIds'] as List?)?.map((e) => e.toString()) ?? [])
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F3EC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFDDD5C8), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF1E3D2F), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Buildings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                        Text(user['name'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (allBuildings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No buildings found.', style: TextStyle(color: Color(0xFF8C8278)))),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: allBuildings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEDE7DD)),
                    itemBuilder: (_, i) {
                      final b = allBuildings[i];
                      final bId = b['id'].toString();
                      final isChecked = selected.contains(bId);
                      return CheckboxListTile(
                        value: isChecked,
                        onChanged: (v) => setSheet(() {
                          if (v == true) selected.add(bId); else selected.remove(bId);
                        }),
                        title: Text(b['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1714))),
                        subtitle: Text(b['location'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.business_outlined, color: Color(0xFF1E3D2F), size: 18),
                        ),
                        activeColor: const Color(0xFF1E3D2F),
                        checkColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await ApiClient.post('/Users/${user['id']}/buildings', selected.toList());
                  _fetchUsers();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3D2F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('Save Assignments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminCount = users.where((u) => u['role'] == 'Admin' || u['role'] == 'Super Admin').length;
    final session = SessionManager();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1714))),
                      Text(session.currentUser?['name'] ?? 'Administrator', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _signOut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B2020).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFF9B2020), size: 16),
                          SizedBox(width: 6),
                          Text('Sign Out', style: TextStyle(color: Color(0xFF9B2020), fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : RefreshIndicator(
                      onRefresh: _fetchUsers,
                      color: const Color(0xFF1E3D2F),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stat cards
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Team Members',
                                    value: users.length.toString(),
                                    icon: Icons.people_rounded,
                                    color: const Color(0xFF1E3D2F),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Admins',
                                    value: adminCount.toString(),
                                    icon: Icons.admin_panel_settings_rounded,
                                    color: const Color(0xFF6B3FA0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Section header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Team Members', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                                GestureDetector(
                                  onTap: _showAddUserSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(10)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 6),
                                        Text('Add User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (users.isEmpty)
                              _EmptyUsersState()
                            else
                              ...users.map((u) => _UserCard(user: u, onAssign: () => _showAssignBuildingSheet(u))),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onAssign;

  const _UserCard({required this.user, required this.onAssign});

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'super admin': return const Color(0xFF6B3FA0);
      case 'manager':     return const Color(0xFF1E5080);
      case 'supervisor':  return const Color(0xFF1E3D2F);
      default:            return const Color(0xFFA05A10);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final role = (user['role'] ?? 'Technician') as String;
    final rColor = _roleColor(role);
    final buildings = (user['buildings'] as List?)?.where((b) => b != null).join(', ') ?? '';
    final buildingsLabel = buildings.isNotEmpty ? buildings : 'No buildings assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: rColor.withValues(alpha: 0.12),
            child: Text(_initials(user['name'] ?? ''), style: TextStyle(color: rColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714))),
                const SizedBox(height: 2),
                Text(user['email'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: rColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rColor)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(buildingsLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278)), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAssign,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.business_outlined, color: Color(0xFF1E3D2F), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUsersState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
            child: const Icon(Icons.people_outline_rounded, size: 36, color: Color(0xFF1E3D2F)),
          ),
          const SizedBox(height: 16),
          const Text('No team members yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
          const SizedBox(height: 4),
          const Text('Add your first user to get started', style: TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _SheetField({required this.controller, required this.label, required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C8278), letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF1A1714), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: const Color(0xFF8C8278), size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: const Color(0xFFEEE8DF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3D2F), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
