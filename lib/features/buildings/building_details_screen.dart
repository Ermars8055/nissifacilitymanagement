import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class BuildingDetailsScreen extends StatefulWidget {
  final String buildingId;
  const BuildingDetailsScreen({super.key, required this.buildingId});

  @override
  State<BuildingDetailsScreen> createState() => _BuildingDetailsScreenState();
}

class _BuildingDetailsScreenState extends State<BuildingDetailsScreen> {
  Map<String, dynamic>? building;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBuilding();
  }

  Future<void> _fetchBuilding() async {
    try {
      final data = await ApiClient.get('/Hierarchy/building/${widget.buildingId}');
      setState(() { building = data; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F))),
      );
    }

    if (building == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F3EC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Building Details'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('Building not found.', style: TextStyle(fontSize: 16, color: Color(0xFF8C8278)))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: CustomScrollView(
        slivers: [
          // Forest green collapsible header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1E3D2F),
            leading: context.canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                building!['name'] ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF142B20), Color(0xFF1E3D2F), Color(0xFF2D6B4F)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.location_city_rounded, size: 90, color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(22),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _InfoRow(label: 'Location',     value: building!['location'] ?? '—', icon: Icons.location_on_outlined),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                      _InfoRow(label: 'Total Floors', value: (building!['floors'] ?? 0).toString(), icon: Icons.layers_rounded),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                      _InfoRow(label: 'Status',       value: building!['status'] ?? 'Active', icon: Icons.info_outline_rounded),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                const Text('Quick Actions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _QuickAction(icon: Icons.layers_rounded,     label: 'Manage Floors', color: const Color(0xFF1E3D2F), onTap: () => context.go('/buildings/details/${widget.buildingId}/floors'))),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(icon: Icons.inventory_2_rounded, label: 'View Assets',   color: const Color(0xFF1E5080), onTap: () => context.push('/assets'))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _QuickAction(icon: Icons.assignment_rounded,    label: 'Tasks',      color: const Color(0xFF2D6B4F), onTap: () => context.push('/tasks'))),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(icon: Icons.report_problem_rounded, label: 'Complaints', color: const Color(0xFF9B2020), onTap: () => context.push('/complaints'))),
                  ],
                ),

                const SizedBox(height: 26),
                
                const Text('Visual Map', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.push('/hierarchy-builder'),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3D2F),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CustomPaint(painter: _IsometricBuildingPainter()),
                          ),
                        ),
                        const Positioned(
                          bottom: 20,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Explore Floor Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(height: 4),
                              Text('View 2D layouts and asset maps', style: TextStyle(color: Color(0xFFA3B8A8), fontSize: 13)),
                            ],
                          ),
                        ),
                        const Positioned(
                          top: 20,
                          right: 20,
                          child: Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                const Text('Building Health', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 0.96,
                              strokeWidth: 6,
                              backgroundColor: const Color(0xFFEEE8DF),
                              color: const Color(0xFF2D6B4F),
                            ),
                            const Text('96%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Overall Health: Excellent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1714))),
                            SizedBox(height: 5),
                            Text('Based on unresolved complaints and missed inspections.', style: TextStyle(fontSize: 13, color: Color(0xFF8C8278), height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF1E3D2F), size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278), fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1714))),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _IsometricBuildingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw isometric floors
    for (int i = 0; i < 3; i++) {
      paint.color = i == 2 ? const Color(0xFF10B981).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1);
      final path = Path();
      double startY = size.height - (i * 25) - 40;
      double startX = size.width / 2;
      
      path.moveTo(startX, startY);
      path.lineTo(startX + 80, startY - 40);
      path.lineTo(startX, startY - 80);
      path.lineTo(startX - 80, startY - 40);
      path.close();
      
      canvas.drawPath(path, paint);
      
      paint.style = PaintingStyle.stroke;
      paint.color = i == 2 ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.3);
      paint.strokeWidth = 2;
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
