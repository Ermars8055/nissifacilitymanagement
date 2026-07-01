import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/api_client.dart';

class RoomAssetsScreen extends StatefulWidget {
  final String buildingId;
  final String floorId;
  final String roomId;

  const RoomAssetsScreen({super.key, required this.buildingId, required this.floorId, required this.roomId});

  @override
  State<RoomAssetsScreen> createState() => _RoomAssetsScreenState();
}

class _RoomAssetsScreenState extends State<RoomAssetsScreen> {
  List<dynamic> assets = [];
  List<dynamic> subCategories = [];
  Map<String, String> parentNames = {};
  Map<String, List<dynamic>> groupedCategories = {};
  bool isLoading = true;
  String? roomName;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final assetsData = await ApiClient.get('/Assets/room/${widget.roomId}');
      final clients = await ApiClient.get('/Hierarchy/clients');
      final cId = clients.isNotEmpty ? clients.first['id'] : '';
      final catsData = await ApiClient.get('/Assets/categories/$cId');

      final parents = <dynamic>[];
      final subs = <dynamic>[];
      for (final c in catsData) {
        if (c['parentCategoryId'] == null) {
          parents.add(c);
        } else {
          subs.add(c);
        }
      }

      final pNames = <String, String>{};
      for (final p in parents) {
        pNames[p['id'].toString()] = p['name'].toString();
      }

      final grouped = <String, List<dynamic>>{};
      for (final cat in subs) {
        final pId = cat['parentCategoryId']?.toString() ?? 'Other';
        grouped.putIfAbsent(pId, () => []).add(cat);
      }

      setState(() {
        assets = assetsData;
        subCategories = subs;
        parentNames = pNames;
        groupedCategories = grouped;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _fetchAssetsSilently() async {
    try {
      final data = await ApiClient.get('/Assets/room/${widget.roomId}');
      if (mounted) setState(() => assets = data);
    } catch (_) {}
  }

  Future<void> _generateAssetQR(Map<String, dynamic> category) async {
    final catName = category['name'].toString().toUpperCase().replaceAll(' ', '');
    final existingCount = assets.where((a) => a['categoryId'] == category['id']).length;
    final newNumber = existingCount + 1;
    final uniqueId = '$catName-${newNumber.toString().padLeft(3, '0')}';

    final payload = {
      'buildingId': widget.buildingId,
      'roomId': widget.roomId,
      'categoryId': category['id'],
      'name': '${category['name']} $newNumber',
      'qrCode': uniqueId,
      'serialNumber': 'SN-$uniqueId',
    };

    setState(() => assets.add({'id': 'temp-$uniqueId', ...payload, 'category': category}));
    if (mounted) Future.microtask(() => _showQRDialog(uniqueId, category['name']));

    try {
      await ApiClient.post('/Assets', payload);
      _fetchAssetsSilently();
    } catch (e) {
      if (mounted) {
        setState(() => assets.removeWhere((a) => a['id'] == 'temp-$uniqueId'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFF9B2020)),
        );
      }
    }
  }

  void _showQRDialog(String qrData, String categoryName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: const Text('Asset QR Generated', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1714))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD5C8), width: 2),
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 200),
              ),
            ),
            const SizedBox(height: 16),
            Text(qrData, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF1A1714))),
            const SizedBox(height: 4),
            Text(categoryName, style: const TextStyle(color: Color(0xFF8C8278), fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF2D6B4F), size: 16),
                  SizedBox(width: 6),
                  Text('Saved to database', style: TextStyle(color: Color(0xFF2D6B4F), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('Close', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4540), fontSize: 15))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending to printer...')));
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Print QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ],
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
        title: const Text('Room Assets', style: TextStyle(color: Color(0xFF1A1714), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded, color: Color(0xFF1E3D2F)),
            onPressed: () => context.push('/mapping/room-visual-map/${widget.roomId}'),
            tooltip: 'Visual Map',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF1E3D2F),
              child: CustomScrollView(
                slivers: [
                  // ── Existing Assets Section ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                      child: Row(
                        children: [
                          const Text('ASSETS IN THIS ROOM',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.2)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: assets.isEmpty ? const Color(0xFFEEE8DF) : const Color(0xFF1E3D2F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${assets.length}',
                                style: TextStyle(
                                  color: assets.isEmpty ? const Color(0xFF8C8278) : Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 12,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (assets.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
                        child: _EmptyAssetsCard(),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final a = assets[i];
                          return Padding(
                            padding: EdgeInsets.fromLTRB(18, i == 0 ? 12 : 6, 18, 0),
                            child: Dismissible(
                              key: Key(a['id'].toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B2020),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_rounded, color: Colors.white, size: 22),
                                    SizedBox(height: 4),
                                    Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    backgroundColor: Colors.white,
                                    title: const Text('Delete Asset', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                                    content: Text('Delete "${a['name']}"? This cannot be undone.', style: const TextStyle(color: Color(0xFF4A4540))),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8C8278)))),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFF9B2020), fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ) ?? false;
                              },
                              onDismissed: (_) async {
                                final id = a['id'].toString();
                                setState(() => assets.removeWhere((x) => x['id'].toString() == id));
                                try {
                                  await ApiClient.delete('/Assets/$id');
                                } catch (e) {
                                  _fetchAssetsSilently();
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFF9B2020)),
                                  );
                                }
                              },
                              child: GestureDetector(
                                onTap: () => context.push('/assets/details/${a['id']}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(11)),
                                        child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF1E3D2F), size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(a['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714))),
                                            const SizedBox(height: 2),
                                            Text(a['qrCode'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278), fontFamily: 'monospace')),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFDDD5C8)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: assets.length,
                      ),
                    ),

                  // ── Add New Asset Section ────────────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18, 28, 18, 10),
                      child: Row(
                        children: [
                          Icon(Icons.add_box_rounded, color: Color(0xFF1E3D2F), size: 18),
                          SizedBox(width: 8),
                          Text('ADD NEW ASSET',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3D2F), letterSpacing: 1.2)),
                          SizedBox(width: 6),
                          Text('— tap a category', style: TextStyle(fontSize: 11, color: Color(0xFF8C8278))),
                        ],
                      ),
                    ),
                  ),

                  if (subCategories.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 0, 18, 40),
                        child: Center(
                          child: Text('No categories found.\nRun seed-categories from backend.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF8C8278), fontSize: 14)),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, gi) {
                          final groupKey = groupedCategories.keys.toList()[gi];
                          final groupLabel = parentNames[groupKey] ?? 'Other';
                          final cats = groupedCategories[groupKey]!;

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(groupLabel.toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.2)),
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: cats.length,
                                  itemBuilder: (context, ci) {
                                    final cat = cats[ci];
                                    final count = assets.where((a) => a['categoryId'] == cat['id']).length;
                                    return GestureDetector(
                                      onTap: () => _generateAssetQR(Map<String, dynamic>.from(cat)),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFEEE8DF), width: 1.5),
                                          boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 38, height: 38,
                                              decoration: BoxDecoration(
                                                color: count > 0 ? const Color(0xFFEBF2ED) : const Color(0xFFEEE8DF),
                                                borderRadius: BorderRadius.circular(11),
                                              ),
                                              child: Icon(_iconForCategory(cat['name']), size: 20,
                                                  color: count > 0 ? const Color(0xFF1E3D2F) : const Color(0xFF8C8278)),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(cat['name'] ?? '',
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1A1714))),
                                            if (count > 0) ...[
                                              const SizedBox(height: 3),
                                              Text('$count added', style: const TextStyle(fontSize: 9, color: Color(0xFF2D6B4F), fontWeight: FontWeight.bold)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: groupedCategories.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('chair') || n.contains('sofa')) return Icons.chair_rounded;
    if (n.contains('table') || n.contains('desk')) return Icons.table_restaurant_rounded;
    if (n.contains('pc') || n.contains('server') || n.contains('laptop')) return Icons.computer_rounded;
    if (n.contains('monitor')) return Icons.monitor_rounded;
    if (n.contains('printer')) return Icons.print_rounded;
    if (n.contains('router') || n.contains('network') || n.contains('switch')) return Icons.router_rounded;
    if (n.contains('camera')) return Icons.videocam_rounded;
    if (n.contains('fire') || n.contains('extinguisher')) return Icons.fire_extinguisher_rounded;
    if (n.contains('smoke') || n.contains('alarm')) return Icons.sensors_rounded;
    if (n.contains('trash') || n.contains('bin')) return Icons.delete_outline_rounded;
    if (n.contains('soap') || n.contains('dispenser') || n.contains('towel')) return Icons.soap_rounded;
    if (n.contains('toilet') || n.contains('basin') || n.contains('wash')) return Icons.wc_rounded;
    if (n.contains('mirror')) return Icons.crop_portrait_rounded;
    if (n.contains('ac') || n.contains('conditioner') || n.contains('hvac') || n.contains('heater') || n.contains('fan') || n.contains('thermostat')) return Icons.ac_unit_rounded;
    if (n.contains('light') || n.contains('bulb') || n.contains('panel') || n.contains('outlet')) return Icons.lightbulb_outline_rounded;
    if (n.contains('elevator')) return Icons.elevator_rounded;
    if (n.contains('vending') || n.contains('microwave') || n.contains('fridge') || n.contains('coffee')) return Icons.kitchen_rounded;
    if (n.contains('projector') || n.contains('tv') || n.contains('screen')) return Icons.tv_rounded;
    if (n.contains('whiteboard')) return Icons.border_color_rounded;
    if (n.contains('phone')) return Icons.phone_rounded;
    if (n.contains('cabinet') || n.contains('shelf') || n.contains('bookshelf')) return Icons.inventory_2_rounded;
    if (n.contains('security') || n.contains('access')) return Icons.security_rounded;
    return Icons.category_rounded;
  }
}

class _EmptyAssetsCard extends StatelessWidget {
  const _EmptyAssetsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8DF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.inbox_rounded, color: Color(0xFF8C8278), size: 20),
          SizedBox(width: 10),
          Text('No assets yet — add one below', style: TextStyle(color: Color(0xFF8C8278), fontSize: 14)),
        ],
      ),
    );
  }
}
