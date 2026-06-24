import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class RoomManagementScreen extends StatefulWidget {
  final String buildingId;
  final String floorId;

  const RoomManagementScreen({super.key, required this.buildingId, required this.floorId});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  List<dynamic> rooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiClient.get('/Hierarchy/rooms/${widget.floorId}');
      setState(() { rooms = data; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddRoomSheet() {
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
                    child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF1E3D2F), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text('Add New Room', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('ROOM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.1)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1A1714), fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. Conference Room A, Server Room',
                  hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
                  prefixIcon: const Icon(Icons.meeting_room_outlined, color: Color(0xFF8C8278), size: 20),
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
                          await ApiClient.post('/Hierarchy/rooms', {
                            'floorId': widget.floorId,
                            'name': nameController.text.trim(),
                          });
                          _fetchRooms();
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Add Room', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15))),
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
        title: const Text('Manage Rooms', style: TextStyle(color: Color(0xFF1A1714), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _showAddRoomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Add Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
          : rooms.isEmpty
              ? _EmptyState(
                  label: 'No rooms yet',
                  sub: 'Add rooms to this floor to start tracking assets.',
                  icon: Icons.meeting_room_outlined,
                  onAdd: _showAddRoomSheet,
                  addLabel: 'Add First Room',
                )
              : RefreshIndicator(
                  onRefresh: _fetchRooms,
                  color: const Color(0xFF1E3D2F),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, i) {
                      final room = rooms[i];
                      final assetCount = (room['assets'] as List?)?.length ?? 0;
                      return GestureDetector(
                        onTap: () => context.push(
                          '/buildings/details/${widget.buildingId}/floors/${widget.floorId}/rooms/${room['id']}/assets',
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(11)),
                                    child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF1E3D2F), size: 18),
                                  ),
                                  if (assetCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(8)),
                                      child: Text('$assetCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D6B4F))),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                room['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF8C8278)),
                                  const SizedBox(width: 4),
                                  Text('$assetCount asset${assetCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

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
