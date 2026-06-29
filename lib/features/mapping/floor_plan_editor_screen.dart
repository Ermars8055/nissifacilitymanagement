import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class FloorPlanEditorScreen extends StatefulWidget {
  final String floorId;
  const FloorPlanEditorScreen({super.key, required this.floorId});

  @override
  State<FloorPlanEditorScreen> createState() => _FloorPlanEditorScreenState();
}

class _FloorPlanEditorScreenState extends State<FloorPlanEditorScreen> {
  bool isLoading = true;
  Map<String, dynamic>? floor;
  List<dynamic> rooms = [];
  
  double canvasWidth = 800;
  double canvasHeight = 600;

  @override
  void initState() {
    super.initState();
    _fetchFloorPlan();
  }

  Future<void> _fetchFloorPlan() async {
    try {
      final data = await ApiClient.get('/Hierarchy/floors/${widget.floorId}/floorplan');
      setState(() {
        floor = data;
        rooms = data['rooms'] ?? [];
        canvasWidth = (data['canvasWidth'] as num?)?.toDouble() ?? 800.0;
        canvasHeight = (data['canvasHeight'] as num?)?.toDouble() ?? 600.0;
        if (canvasWidth == 0) canvasWidth = 800;
        if (canvasHeight == 0) canvasHeight = 600;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load floor plan: $e')));
      }
    }
  }

  Future<void> _updateRoomPosition(String roomId, double x, double y, double width, double height) async {
    try {
      await ApiClient.put('/Hierarchy/rooms/$roomId/position', {
        'posX': x,
        'posY': y,
        'width': width,
        'height': height,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save position: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (floor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Floor Plan Editor')),
        body: const Center(child: Text('Floor not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('${floor!['name']} - Editor'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchFloorPlan();
            },
          )
        ],
      ),
      body: Column(
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
                    'Drag rooms to position them. Resize handles coming soon.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 5.0,
              child: Container(
                width: canvasWidth,
                height: canvasHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      size: Size(canvasWidth, canvasHeight),
                      painter: GridPainter(),
                    ),
                    // Rooms
                    ...rooms.map((room) {
                      final double x = (room['posX'] as num?)?.toDouble() ?? 0;
                      final double y = (room['posY'] as num?)?.toDouble() ?? 0;
                      double w = (room['width'] as num?)?.toDouble() ?? 120;
                      double h = (room['height'] as num?)?.toDouble() ?? 80;
                      if (w == 0) w = 120;
                      if (h == 0) h = 80;

                      return Positioned(
                        left: x,
                        top: y,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              room['posX'] = x + details.delta.dx;
                              room['posY'] = y + details.delta.dy;
                            });
                          },
                          onPanEnd: (details) {
                            _updateRoomPosition(room['id'], room['posX'], room['posY'], w, h);
                          },
                          onDoubleTap: () {
                            context.push('/mapping/room-visual-map/${room['id']}');
                          },
                          child: Container(
                            width: w,
                            height: h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4), // Light green for OK
                              border: Border.all(color: const Color(0xFF16A34A), width: 2),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    room['name'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${(room['assets'] as List?)?.length ?? 0} Assets',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Double-tap to open', style: TextStyle(color: Color(0xFF166534), fontSize: 9)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    const double step = 40;
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
