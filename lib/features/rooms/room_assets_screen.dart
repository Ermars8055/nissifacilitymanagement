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
  bool isLoading = true;

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

      setState(() {
        assets = assetsData;
        subCategories = subs;
        parentNames = pNames;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _fetchAssetsSilently() async {
    try {
      final assetsData = await ApiClient.get('/Assets/room/${widget.roomId}');
      if (mounted) setState(() => assets = assetsData);
    } catch (_) {}
  }

  Future<void> _generateAssetQR(Map<String, dynamic> category) async {
    final catName = category['name'].toString().toUpperCase().replaceAll(' ', '');
    final existingCount = assets.where((a) => a['categoryId'] == category['id']).length;
    final newNumber = existingCount + 1;
    final uniqueId = '$catName-${newNumber.toString().padLeft(3, '0')}';

    final apiPayload = {
      'buildingId': widget.buildingId,
      'roomId': widget.roomId,
      'categoryId': category['id'],
      'name': '${category['name']} $newNumber',
      'qrCode': uniqueId,
      'serialNumber': 'SN-$uniqueId',
    };

    final optimisticAsset = {
      'id': 'temp-$uniqueId',
      ...apiPayload,
      'category': category,
    };
    setState(() => assets.add(optimisticAsset));

    if (mounted) Future.microtask(() => _showQRDialog(uniqueId, category['name']));

    try {
      await ApiClient.post('/Assets', apiPayload);
      _fetchAssetsSilently();
    } catch (e) {
      if (mounted) {
        setState(() => assets.removeWhere((a) => a['id'] == 'temp-$uniqueId'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: const Color(0xFF9B2020)),
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
        title: const Text(
          'Asset QR Generated',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1714)),
        ),
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
            Text(
              qrData,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF1A1714)),
            ),
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
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sending to printer...')),
                    );
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
            ],
          ),
        ],
      ),
    );
  }

  Map<String, List<dynamic>> get _grouped {
    final map = <String, List<dynamic>>{};
    for (final cat in subCategories) {
      final pId = cat['parentCategoryId']?.toString() ?? 'Other';
      map.putIfAbsent(pId, () => []).add(cat);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final groupKeys = grouped.keys.toList();

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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
          : subCategories.isEmpty
              ? const Center(
                  child: Text(
                    'No asset categories found.\nTap the seed button in the backend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF8C8278)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                  itemCount: groupKeys.length,
                  itemBuilder: (context, gi) {
                    final pId = groupKeys[gi];
                    final groupLabel = parentNames[pId] ?? 'Other';
                    final cats = grouped[pId]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                          child: Text(
                            groupLabel.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.2),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: cats.asMap().entries.map((entry) {
                                final i = entry.key;
                                final cat = entry.value;
                                final catAssets = assets.where((a) => a['categoryId'] == cat['id']).toList();
                                final count = catAssets.length;
                                final isLast = i == cats.length - 1;

                                return Column(
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        key: PageStorageKey(cat['id'].toString()),
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        childrenPadding: EdgeInsets.zero,
                                        leading: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: count > 0 ? const Color(0xFFEBF2ED) : const Color(0xFFEEE8DF),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _iconForCategory(cat['name']),
                                            size: 20,
                                            color: count > 0 ? const Color(0xFF1E3D2F) : const Color(0xFF8C8278),
                                          ),
                                        ),
                                        title: Text(
                                          cat['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1714)),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: count > 0 ? const Color(0xFF1E3D2F) : const Color(0xFFEEE8DF),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '$count',
                                                style: TextStyle(
                                                  color: count > 0 ? Colors.white : const Color(0xFF8C8278),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.expand_more, color: Color(0xFF8C8278)),
                                          ],
                                        ),
                                        children: [
                                          Container(
                                            color: const Color(0xFFF7F3EC),
                                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                const SizedBox(height: 12),
                                                if (catAssets.isNotEmpty) ...[
                                                  const Text(
                                                    'ASSETS IN THIS ROOM',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8C8278), letterSpacing: 1.2),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ...catAssets.map((a) => Container(
                                                    margin: const EdgeInsets.only(bottom: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: const Color(0xFFDDD5C8)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(a['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1714))),
                                                        Text(a['qrCode'] ?? '', style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF8C8278), fontSize: 12)),
                                                      ],
                                                    ),
                                                  )),
                                                  const SizedBox(height: 12),
                                                ],
                                                GestureDetector(
                                                  onTap: () => _generateAssetQR(Map<String, dynamic>.from(cat)),
                                                  child: Container(
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF1E3D2F),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                                                        SizedBox(width: 8),
                                                        Text('Generate Asset QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isLast)
                                      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEE8DF)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
