import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class BuildingSelectionScreen extends StatefulWidget {
  const BuildingSelectionScreen({super.key});

  @override
  State<BuildingSelectionScreen> createState() => _BuildingSelectionScreenState();
}

class _BuildingSelectionScreenState extends State<BuildingSelectionScreen> {
  List<dynamic> assignedBuildings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedBuildings();
  }

  Future<void> _fetchAssignedBuildings() async {
    final user = SessionManager().currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }
    try {
      final buildings = await ApiClient.get('/Users/${user['id']}/buildings');
      setState(() { assignedBuildings = buildings; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _selectBuilding(dynamic building) {
    SessionManager().setBuilding(building['id'], building['name']);
    context.go('/dashboard');
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final userName = (user?['name'] ?? 'User') as String;
    final role = (user?['role'] ?? 'Technician') as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    // Top row: brand + logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.business_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('FacilityPro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                          ],
                        ),
                        GestureDetector(
                          onTap: () { SessionManager().clear(); context.go('/login'); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(10)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout_rounded, color: Color(0xFF9B2020), size: 15),
                                SizedBox(width: 6),
                                Text('Sign out', style: TextStyle(fontSize: 13, color: Color(0xFF9B2020), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Avatar
                    Container(
                      width: 68, height: 68,
                      decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          _initials(userName),
                          style: const TextStyle(color: Color(0xFF1E3D2F), fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Welcome back,', style: TextStyle(fontSize: 14, color: Color(0xFF8C8278))),
                    const SizedBox(height: 2),
                    Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(20)),
                      child: Text(role, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F))),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select a building to enter your workspace',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Building list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                : assignedBuildings.isEmpty
                    ? const _EmptyBuildingsState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: assignedBuildings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final building = assignedBuildings[index];
                          return GestureDetector(
                            onTap: () => _selectBuilding(building),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  // Forest green left accent bar
                                  Container(
                                    width: 5, height: 80,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E3D2F),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        bottomLeft: Radius.circular(20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.business_rounded, color: Color(0xFF1E3D2F), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          building['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1714)),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF8C8278)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                building['location'] ?? 'Location not specified',
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(10)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Enter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                        ],
                                      ),
                                    ),
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
    );
  }
}

class _EmptyBuildingsState extends StatelessWidget {
  const _EmptyBuildingsState();

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
                child: Icon(Icons.business_outlined, size: 40, color: Color(0xFF2D6B4F)),
              ),
            ),
            SizedBox(height: 20),
            Text('No buildings assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
            SizedBox(height: 8),
            Text(
              'Contact your administrator to get access to a building.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
            ),
          ],
        ),
      ),
    );
  }
}
