import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class BuildingListScreen extends StatefulWidget {
  const BuildingListScreen({super.key});

  @override
  State<BuildingListScreen> createState() => _BuildingListScreenState();
}

class _BuildingListScreenState extends State<BuildingListScreen> {
  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  static const _gradients = [
    [Color(0xFF142B20), Color(0xFF2D6B4F)],
    [Color(0xFF1E3D2F), Color(0xFF3A7A5A)],
    [Color(0xFF1A2E40), Color(0xFF2D5A7A)],
    [Color(0xFF3A2810), Color(0xFFA05A10)],
    [Color(0xFF2B1A3A), Color(0xFF6B3FA0)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _buildings
          : _buildings.where((b) =>
              (b['name'] as String).toLowerCase().contains(q) ||
              (b['client'] as String).toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _fetchBuildings() async {
    setState(() => _isLoading = true);
    try {
      final role = SessionManager().currentRole;
      final isAdmin = role == 'Admin' || role == 'Super Admin' || role == 'Manager';
      final List<dynamic> all = [];

      if (isAdmin) {
        final clients = await ApiClient.get('/Hierarchy/clients');
        for (final client in clients) {
          final buildings = await ApiClient.get('/Hierarchy/buildings/${client['id']}');
          for (final b in buildings) {
            b['_clientName'] = client['name'] ?? '';
          }
          all.addAll(buildings);
        }
      } else {
        final user = SessionManager().currentUser;
        final ids = (user?['buildingIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
        for (final id in ids) {
          try {
            final b = await ApiClient.get('/Hierarchy/building/$id');
            all.add(b);
          } catch (_) {}
        }
      }

      final mapped = all.asMap().entries.map<Map<String, dynamic>>((entry) {
        final i = entry.key;
        final b = entry.value as Map<String, dynamic>;
        final score = (b['healthScore'] as num?)?.toInt() ?? 85;
        final gradient = _gradients[i % _gradients.length];
        return {
          'id': b['id'].toString(),
          'name': b['name'] ?? 'Unknown',
          'client': b['_clientName'] ?? b['clientName'] ?? '',
          'floors': '${b['floorCount'] ?? 0} Floors',
          'rooms': '${b['roomCount'] ?? 0} Rooms',
          'status': score >= 90 ? 'Optimal' : score >= 75 ? 'Good' : 'Needs Attention',
          'statusColor': score >= 90
              ? const Color(0xFF2D6B4F)
              : score >= 75
                  ? const Color(0xFFA05A10)
                  : const Color(0xFF9B2020),
          'score': score,
          'gradient': gradient,
        };
      }).toList();

      setState(() {
        _buildings = mapped;
        _filtered = mapped;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3D2F),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.business_rounded, color: Colors.white, size: 22),
                      ),
                      const Spacer(),
                      _HeaderIconBtn(
                        icon: Icons.search_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        children: [
                          _HeaderIconBtn(
                            icon: Icons.notifications_outlined,
                            onTap: () => context.push('/notifications'),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF9B2020),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Buildings',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage and monitor all properties.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
                  ),
                  const SizedBox(height: 16),
                  // Search + Add row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE8DF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search buildings...',
                              hintStyle: TextStyle(color: Color(0xFFAA9F94), fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF8C8278), size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3D2F),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Building Cards ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.business_outlined, size: 48, color: Color(0xFFDDD5C8)),
                              const SizedBox(height: 12),
                              Text(
                                _buildings.isEmpty ? 'No buildings found' : 'No results',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF8C8278)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchBuildings,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              return _BuildingCard(
                                building: _filtered[index],
                                onTap: () => context.go('/buildings/details/${_filtered[index]['id']}'),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Icon Button ────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEEE8DF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xFF4A4540), size: 22),
      ),
    );
  }
}

// ── Building Card ─────────────────────────────────────────────────────────────

class _BuildingCard extends StatelessWidget {
  final Map<String, dynamic> building;
  final VoidCallback onTap;

  const _BuildingCard({required this.building, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = building['statusColor'] as Color;
    final gradient    = building['gradient'] as List<Color>;
    final score       = building['score'] as int;

    // Score color
    final scoreColor = score >= 90
        ? const Color(0xFF2D6B4F)
        : score >= 75
            ? const Color(0xFFA05A10)
            : const Color(0xFF9B2020);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1714).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient header
              Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.12,
                        child: const Icon(Icons.location_city_rounded, size: 130, color: Colors.white),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              building['status'],
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Score badge
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: scoreColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scoreColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building['name'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${building['id']}  ·  ${building['client']}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _InfoChip(icon: Icons.layers_rounded, label: building['floors']),
                        const SizedBox(width: 20),
                        _InfoChip(icon: Icons.meeting_room_outlined, label: building['rooms']),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFDDD5C8), size: 24),
                      ],
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8C8278)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4540), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class HierarchyTreeView extends StatelessWidget {
  const HierarchyTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListView(
        shrinkWrap: true,
        children: const [
          ExpansionTile(
            leading: Icon(Icons.location_city),
            title: Text('Building (Acme HQ)'),
            initiallyExpanded: true,
            children: [
              ExpansionTile(
                leading: Icon(Icons.layers),
                title: Text('Floor 1'),
                children: [
                  ListTile(leading: Icon(Icons.meeting_room), title: Text('Room 101')),
                  ListTile(leading: Icon(Icons.meeting_room), title: Text('Room 102')),
                ],
              ),
              ExpansionTile(
                leading: Icon(Icons.layers),
                title: Text('Floor 2'),
                children: [
                  ListTile(leading: Icon(Icons.meeting_room), title: Text('Server Room')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
