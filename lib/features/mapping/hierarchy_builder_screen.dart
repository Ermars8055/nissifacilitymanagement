import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class HierarchyBuilderScreen extends StatefulWidget {
  final String? initialClientId;
  const HierarchyBuilderScreen({super.key, this.initialClientId});

  @override
  State<HierarchyBuilderScreen> createState() => _HierarchyBuilderScreenState();
}

class _HierarchyBuilderScreenState extends State<HierarchyBuilderScreen> {
  bool isLoading = true;

  String? selectedClient;
  String? selectedBuilding;
  
  List<dynamic> clients = [];
  List<dynamic> buildings = [];
  List<dynamic> floors = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiClient.get('/Hierarchy/clients');
      setState(() {
        clients = data;
        if (clients.isNotEmpty) {
          selectedClient = widget.initialClientId ?? clients.first['id'];
          _fetchBuildings();
        } else {
          isLoading = false;
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load clients: $e');
    }
  }

  Future<void> _fetchBuildings() async {
    if (selectedClient == null) return;
    setState(() => isLoading = true);
    try {
      final data = await ApiClient.get('/Hierarchy/buildings/$selectedClient');
      setState(() {
        buildings = data;
        if (buildings.isNotEmpty) {
          selectedBuilding = buildings.first['id'];
          _fetchFloors();
        } else {
          selectedBuilding = null;
          floors = [];
          isLoading = false;
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load buildings: $e');
    }
  }

  Future<void> _fetchFloors() async {
    if (selectedBuilding == null) {
      setState(() { floors = []; isLoading = false; });
      return;
    }
    setState(() => isLoading = true);
    try {
      final data = await ApiClient.get('/Hierarchy/floors/$selectedBuilding');
      setState(() {
        floors = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load floors: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1714)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Hierarchy Builder',
          style: TextStyle(color: Color(0xFF1A1714), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hierarchy saved successfully!')),
              );
              context.pop();
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF2D6B4F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: isLoading && clients.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6B4F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Map Facilities to Checklists', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                  const SizedBox(height: 8),
                  const Text('Configure the building structure and assign inspection templates to floors or spaces.', style: TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                  const SizedBox(height: 24),
                  
                  // Step 1: Select Client & Building
                  _buildSectionHeader('1', 'Facility Context'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business_center_rounded, size: 18, color: Color(0xFF6B7280)),
                            const SizedBox(width: 8),
                            const Text('Client', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                            const Spacer(),
                            DropdownButton<String>(
                              value: selectedClient,
                              underline: const SizedBox(),
                              items: clients.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                              onChanged: (v) {
                                setState(() {
                                  selectedClient = v;
                                });
                                _fetchBuildings();
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.location_city_rounded, size: 18, color: Color(0xFF6B7280)),
                            const SizedBox(width: 8),
                            const Text('Building', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                            const Spacer(),
                            if (buildings.isEmpty)
                              const Text('No buildings found', style: TextStyle(color: Color(0xFF9CA3AF)))
                            else
                              Row(
                                children: [
                                  DropdownButton<String>(
                                    value: selectedBuilding,
                                    underline: const SizedBox(),
                                    items: buildings.map((b) => DropdownMenuItem(value: b['id'] as String, child: Text(b['name'] as String))).toList(),
                                    onChanged: (v) {
                                      setState(() => selectedBuilding = v);
                                      _fetchFloors();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  if (selectedBuilding != null)
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/building-3d/$selectedBuilding'),
                                      icon: const Icon(Icons.business, size: 16),
                                      label: const Text('View 3D Stack'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2D6B4F),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Step 2: Manage Floors
                  Row(
                    children: [
                      _buildSectionHeader('2', 'Floor Mapping'),
                      const Spacer(),
                      if (isLoading && clients.isNotEmpty) 
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2D6B4F)))
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adding floors will be available soon.')));
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Floor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6B4F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (floors.isEmpty && !isLoading)
                    Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.layers_clear_rounded, size: 48, color: Color(0xFFDDD5C8)),
                          SizedBox(height: 16),
                          Text('No floors configured', style: TextStyle(color: Color(0xFF8C8278), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  else
                    ...floors.map((floor) => _buildFloorNode(floor)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: Color(0xFF2D6B4F), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
      ],
    );
  }

  Widget _buildFloorNode(dynamic floor) {
    final checklists = floor['checklistMappings'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
        title: Row(
          children: [
            const Icon(Icons.layers_rounded, color: Color(0xFF2D6B4F), size: 20),
            const SizedBox(width: 12),
            Text(floor['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEE8DF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${checklists.length} Checklists', style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8F6F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned Checklists', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8C8278))),
                const SizedBox(height: 8),
                if (checklists.isEmpty)
                   const Text('No checklists assigned', style: TextStyle(color: Color(0xFF8C8278), fontSize: 13))
                else
                  ...checklists.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outlined, size: 16, color: Color(0xFF2D6B4F)),
                        const SizedBox(width: 8),
                        Text(c['checklistName'] ?? 'Unknown', style: const TextStyle(fontSize: 13, color: Color(0xFF1A1714), fontWeight: FontWeight.w500)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unlink feature coming soon.'))); },
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFE53E3E)),
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checklist templates coming soon.'))); },
                    icon: const Icon(Icons.add_link_rounded, size: 14),
                    label: const Text('Attach Checklist Template'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2D6B4F)),
                      foregroundColor: const Color(0xFF2D6B4F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/mapping/floor-plan-editor/${floor['id']}');
                    },
                    icon: const Icon(Icons.map_rounded, size: 14),
                    label: const Text('Edit Floor Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3D2F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
