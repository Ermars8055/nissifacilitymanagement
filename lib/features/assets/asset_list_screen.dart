import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  List<dynamic> assets = [];
  List<dynamic> filteredAssets = [];
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    setState(() => isLoading = true);
    final bId = SessionManager().selectedBuildingId ?? '';
    try {
      if (bId.isNotEmpty) {
        final bAssets = await ApiClient.get('/Assets/building/$bId');
        for (var a in bAssets) {
          a['buildingName'] = SessionManager().selectedBuildingName ?? 'Building';
        }
        setState(() {
          assets = bAssets;
          filteredAssets = bAssets;
          isLoading = false;
        });
      } else {
        final clients = await ApiClient.get('/Hierarchy/clients');
        if (clients.isNotEmpty) {
          List<dynamic> allAssets = [];
          for (var client in clients) {
            final buildings = await ApiClient.get('/Hierarchy/buildings/${client['id']}');
            for (var building in buildings) {
              final bAssets = await ApiClient.get('/Assets/building/${building['id']}');
              for (var a in bAssets) {
                a['buildingName'] = building['name'];
                allAssets.add(a);
              }
            }
          }
          setState(() {
            assets = allAssets;
            filteredAssets = allAssets;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterAssets(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      setState(() => filteredAssets = assets);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      filteredAssets = assets.where((a) {
        final name  = (a['name'] ?? '').toLowerCase();
        final cat   = (a['category']?['name'] ?? '').toLowerCase();
        final bldg  = (a['buildingName'] ?? '').toLowerCase();
        final room  = (a['room']?['name'] ?? '').toLowerCase();
        return name.contains(q) || cat.contains(q) || bldg.contains(q) || room.contains(q);
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':             return const Color(0xFF2D6B4F);
      case 'Needs Repair':       return const Color(0xFF9B2020);
      case 'Under Maintenance':  return const Color(0xFFA05A10);
      case 'Decommissioned':     return const Color(0xFF8C8278);
      default:                   return const Color(0xFF8C8278);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Active':             return Icons.check_circle_rounded;
      case 'Needs Repair':       return Icons.build_circle_rounded;
      case 'Under Maintenance':  return Icons.pending_rounded;
      case 'Decommissioned':     return Icons.cancel_rounded;
      default:                   return Icons.circle_outlined;
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
                        child: const Icon(Icons.devices_other_rounded, color: Colors.white, size: 22),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Assets',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filteredAssets.length} item${filteredAssets.length == 1 ? '' : 's'} found',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEE8DF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: _filterAssets,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1714)),
                      decoration: const InputDecoration(
                        hintText: 'Search by name, category, room...',
                        hintStyle: TextStyle(color: Color(0xFFAA9F94), fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF8C8278), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Asset List ────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : filteredAssets.isEmpty
                      ? _EmptyState(hasQuery: _searchQuery.isNotEmpty)
                      : RefreshIndicator(
                          onRefresh: _fetchAssets,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                            itemCount: filteredAssets.length,
                            itemBuilder: (context, i) {
                              final asset = filteredAssets[i];
                              final status = asset['status'] as String? ?? 'Active';
                              final statusColor = _statusColor(status);
                              final statusIcon  = _statusIcon(status);
                              final catName = asset['category']?['name'] as String? ?? 'Uncategorized';
                              final roomName = asset['room']?['name'] as String? ?? '';
                              final buildingName = asset['buildingName'] as String? ?? '';
                              final qrCode = asset['qrCode'] as String? ?? '';

                              return GestureDetector(
                                onTap: () => context.go('/assets/details/${asset['id']}'),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1A1714).withValues(alpha: 0.05),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        // Left accent
                                        Container(
                                          width: 5,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                            ),
                                          ),
                                        ),
                                        // Content
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Status + category
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: statusColor.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(statusIcon, size: 13, color: statusColor),
                                                          const SizedBox(width: 5),
                                                          Text(status, style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEEE8DF),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(catName, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4540), fontWeight: FontWeight.w600)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                // Asset name
                                                Text(
                                                  asset['name'] ?? 'Unknown Asset',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 10),
                                                // Location row
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF8C8278)),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        [buildingName, if (roomName.isNotEmpty) roomName].join('  ·  '),
                                                        style: const TextStyle(fontSize: 13, color: Color(0xFF4A4540)),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (qrCode.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.qr_code_rounded, size: 14, color: Color(0xFF8C8278)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        qrCode,
                                                        style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278), fontFamily: 'monospace'),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Actions column
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _ActionBtn(
                                                icon: Icons.qr_code_2_rounded,
                                                color: const Color(0xFF4A4540),
                                                onTap: () {},
                                              ),
                                              const SizedBox(height: 8),
                                              _ActionBtn(
                                                icon: Icons.arrow_forward_ios_rounded,
                                                color: const Color(0xFF1E3D2F),
                                                onTap: () => context.go('/assets/details/${asset['id']}'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
              child: const Icon(Icons.devices_other_rounded, size: 40, color: Color(0xFF2D6B4F)),
            ),
            const SizedBox(height: 18),
            Text(
              hasQuery ? 'No matching assets' : 'No assets yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1714)),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different search term'
                  : 'Assets registered in this building will appear here',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
