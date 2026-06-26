import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/Users');
      setState(() {
        _users = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_add_rounded, color: Color(0xFF1E3D2F), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Team Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ]),
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
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(14)),
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
                        setState(() => _isLoading = true);
                        await ApiClient.post('/Users', {
                          'name': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'role': role,
                        });
                        _fetchUsers();
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Create Member', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                    ),
                  ),
                ]),
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
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.business_rounded, color: Color(0xFF1E3D2F), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Assign Buildings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                    Text(user['name'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                  ]),
                ),
              ]),
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
                      return CheckboxListTile(
                        value: selected.contains(bId),
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
                  decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('Save Assignments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUser(dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text('Remove User', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
        content: Text('Remove ${user['name']} from the system?', style: const TextStyle(color: Color(0xFF4A4540))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8C8278)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Color(0xFF9B2020), fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _users.removeWhere((u) => u['id'] == user['id']));
    try {
      await ApiClient.delete('/Users/${user['id']}');
    } catch (_) {
      _fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminCount = _users.where((u) => u['role'] == 'Admin' || u['role'] == 'Super Admin').length;

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
                  const Text('Team Members', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showAddUserSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stat row
            if (!_isLoading && _users.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(
                  children: [
                    _StatChip(label: 'Total', value: _users.length.toString(), color: const Color(0xFF1E3D2F)),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Admins', value: adminCount.toString(), color: const Color(0xFF6B3FA0)),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Workers', value: (_users.length - adminCount).toString(), color: const Color(0xFFA05A10)),
                  ],
                ),
              ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : _users.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
                              child: const Icon(Icons.people_outline_rounded, size: 36, color: Color(0xFF1E3D2F)),
                            ),
                            const SizedBox(height: 16),
                            const Text('No team members yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                            const SizedBox(height: 4),
                            const Text('Add your first user to get started', style: TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchUsers,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
                            itemCount: _users.length,
                            itemBuilder: (_, i) => _UserCard(
                              user: _users[i],
                              onAssign: () => _showAssignBuildingSheet(_users[i]),
                              onDelete: () => _deleteUser(_users[i]),
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

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
      ]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onAssign, required this.onDelete});

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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: rColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rColor)),
                  ),
                  if (buildings.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(buildings, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278)), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAssign,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.business_outlined, color: Color(0xFF1E3D2F), size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF9B2020).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFF9B2020), size: 18),
            ),
          ),
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
