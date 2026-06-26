import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class FloorManagementScreen extends StatefulWidget {
  final String buildingId;
  const FloorManagementScreen({super.key, required this.buildingId});

  @override
  State<FloorManagementScreen> createState() => _FloorManagementScreenState();
}

class _FloorManagementScreenState extends State<FloorManagementScreen> {
  List<dynamic> floors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFloors();
  }

  Future<void> _fetchFloors() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiClient.get('/Hierarchy/floors/${widget.buildingId}');
      setState(() { floors = data; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddFloorSheet() {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
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
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.layers_rounded, color: Color(0xFF1E3D2F), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text('Add New Floor', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('FLOOR NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.1)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1A1714), fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. Ground Floor, Floor 1',
                  hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
                  prefixIcon: const Icon(Icons.layers_outlined, color: Color(0xFF8C8278), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFEEE8DF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E3D2F), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4540), fontSize: 15))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        if (nameController.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        setState(() => isLoading = true);
                        try {
                          await ApiClient.post('/Hierarchy/floors', {'buildingId': widget.buildingId, 'name': nameController.text.trim()});
                          _fetchFloors();
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Add Floor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1714)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Manage Floors', style: TextStyle(color: Color(0xFF1A1714), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _showAddFloorSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Add Floor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
          : floors.isEmpty
              ? _EmptyState(label: 'No floors yet', sub: 'Add your first floor to start mapping rooms and assets.', icon: Icons.layers_outlined, onAdd: _showAddFloorSheet, addLabel: 'Add First Floor')
              : RefreshIndicator(
                  onRefresh: _fetchFloors,
                  color: const Color(0xFF1E3D2F),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    itemCount: floors.length,
                    itemBuilder: (context, i) {
                      final floor = floors[i];
                      return Dismissible(
                        key: Key(floor['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B2020),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                              SizedBox(height: 4),
                              Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: Colors.white,
                              title: const Text('Delete Floor', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                              content: Text('Delete "${floor['name']}"? All rooms and assets on this floor will also be removed.', style: const TextStyle(color: Color(0xFF4A4540))),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8C8278)))),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFF9B2020), fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) async {
                          final id = floor['id'].toString();
                          setState(() => floors.removeWhere((f) => f['id'].toString() == id));
                          try {
                            await ApiClient.delete('/Hierarchy/floor/$id');
                          } catch (e) {
                            _fetchFloors();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e'), backgroundColor: const Color(0xFF9B2020)),
                            );
                          }
                        },
                        child: GestureDetector(
                          onTap: () => context.push('/buildings/details/${widget.buildingId}/floors/${floor['id']}/rooms'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(14)),
                                    child: Center(
                                      child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F), fontSize: 18)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(floor['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1714))),
                                        if ((floor['qrCode'] ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.qr_code_rounded, size: 13, color: Color(0xFF8C8278)),
                                              const SizedBox(width: 4),
                                              Text(floor['qrCode'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278), fontFamily: 'monospace')),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFDDD5C8), size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final VoidCallback onAdd;
  final String addLabel;

  const _EmptyState({required this.label, required this.sub, required this.icon, required this.onAdd, required this.addLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: const Color(0xFF2D6B4F)),
            ),
            const SizedBox(height: 18),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1714))),
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278))),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(addLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
