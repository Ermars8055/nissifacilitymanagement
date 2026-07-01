import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class RoomVisualMapScreen extends StatefulWidget {
  final String roomId;
  const RoomVisualMapScreen({super.key, required this.roomId});

  @override
  State<RoomVisualMapScreen> createState() => _RoomVisualMapScreenState();
}

class _RoomVisualMapScreenState extends State<RoomVisualMapScreen> {
  bool isLoading = true;
  List<dynamic> assets = [];
  Map<String, dynamic>? room;

  // Assuming a fixed room canvas size for now, or we can fetch it if room has width/height
  double roomWidth = 400;
  double roomHeight = 300;

  @override
  void initState() {
    super.initState();
    _fetchRoomData();
  }

  Future<void> _fetchRoomData() async {
    try {
      // 1. Fetch room details (for width, height, and name)
      final roomData = await ApiClient.get('/Hierarchy/rooms/single/${widget.roomId}');
      
      // 2. Fetch assets inside the room
      final assetData = await ApiClient.get('/Assets/room/${widget.roomId}');
      
      setState(() {
        room = roomData;
        assets = assetData;
        
        // Dynamically size the room canvas based on real dimensions
        roomWidth = (roomData['width'] as num?)?.toDouble() ?? 400.0;
        roomHeight = (roomData['height'] as num?)?.toDouble() ?? 300.0;
        
        if (roomWidth == 0) roomWidth = 400;
        if (roomHeight == 0) roomHeight = 300;

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load room data: $e')));
      }
    }
  }

  Future<void> _updateAssetPosition(String assetId, double x, double y) async {
    try {
      await ApiClient.put('/Assets/$assetId/position', {
        'assetPosX': x,
        'assetPosY': y,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save position: $e')));
      }
    }
  }

  void _showAssetDetails(dynamic asset) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 32, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(asset['qrCode'] ?? '', style: const TextStyle(color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.push('/assets/details/${asset['id']}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D2F),
                  ),
                  child: const Text('View Full Details', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Separate placed vs unplaced assets
    final placedAssets = assets.where((a) => a['assetPosX'] != null && a['assetPosY'] != null).toList();
    final unplacedAssets = assets.where((a) => a['assetPosX'] == null || a['assetPosY'] == null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(room != null ? '${room!['name']} - Interior' : 'Room Visual Map', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF6B7280), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag unplaced assets from the list below onto the room canvas.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Room Canvas
          Expanded(
            flex: 3,
            child: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 3.0,
                child: DragTarget<Map<String, dynamic>>(
                  onAcceptWithDetails: (details) {
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    // Simplify: Just place it near the center for now if dropped anywhere
                    // A proper implementation would use details.offset and convert to local coordinates
                    
                    final asset = details.data;
                    setState(() {
                      asset['assetPosX'] = 100.0; // dummy drop pos
                      asset['assetPosY'] = 100.0;
                    });
                    _updateAssetPosition(asset['id'], 100.0, 100.0);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: roomWidth,
                      height: roomHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(roomWidth, roomHeight),
                            painter: RoomGridPainter(),
                          ),
                          ...placedAssets.map((asset) {
                            final double x = (asset['assetPosX'] as num).toDouble();
                            final double y = (asset['assetPosY'] as num).toDouble();
                            return Positioned(
                              left: x,
                              top: y,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    asset['assetPosX'] = x + details.delta.dx;
                                    asset['assetPosY'] = y + details.delta.dy;
                                  });
                                },
                                onPanEnd: (details) {
                                  _updateAssetPosition(asset['id'], asset['assetPosX'], asset['assetPosY']);
                                },
                                onTap: () => _showAssetDetails(asset),
                                child: _AssetPin(name: asset['name']),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }
                ),
              ),
            ),
          ),
          
          // Unplaced Assets Drawer
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Unplaced Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: unplacedAssets.isEmpty
                      ? const Center(child: Text('All assets placed!', style: TextStyle(color: Color(0xFF6B7280))))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: unplacedAssets.length,
                          itemBuilder: (context, index) {
                            final asset = unplacedAssets[index];
                            return Draggable<Map<String, dynamic>>(
                              data: asset,
                              feedback: Material(
                                color: Colors.transparent,
                                child: _AssetPin(name: asset['name'], isDragging: true),
                              ),
                              childWhenDragging: Opacity(opacity: 0.3, child: _UnplacedAssetCard(asset: asset)),
                              child: _UnplacedAssetCard(asset: asset),
                            );
                          },
                        ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AssetPin extends StatelessWidget {
  final String name;
  final bool isDragging;
  const _AssetPin({required this.name, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            boxShadow: isDragging ? [const BoxShadow(color: Colors.black26, blurRadius: 8)] : [],
          ),
          child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}

class _UnplacedAssetCard extends StatelessWidget {
  final dynamic asset;
  const _UnplacedAssetCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded, color: Color(0xFF6B7280)),
          const SizedBox(height: 8),
          Text(
            asset['name'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class RoomGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    const double step = 20;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
