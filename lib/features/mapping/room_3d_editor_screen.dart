import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

// Web-only imports
import 'room_3d_editor_web.dart' if (dart.library.io) 'room_3d_editor_stub.dart';

class Room3DEditorScreen extends StatefulWidget {
  final String roomId;
  const Room3DEditorScreen({super.key, required this.roomId});

  @override
  State<Room3DEditorScreen> createState() => _Room3DEditorScreenState();
}

class _Room3DEditorScreenState extends State<Room3DEditorScreen> {
  bool isLoading = true;
  List<dynamic> assets = [];
  Map<String, dynamic>? room;

  // The view ID registered for HtmlElementView (web only)
  String? _webViewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webViewId = registerEditorIframe(_onEngineMessageReceived);
    }
    _fetchRoomData();
  }

  /// Called by the web iframe bridge when the JS engine sends a message
  void _onEngineMessageReceived(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['type'] == 'engine_ready') {
        _injectAllPlacedAssets();
      } else if (data['type'] == 'asset_moved') {
        final id = data['id'] as String;
        // JS sends Three.js world coordinates (-10 to 10). Convert to Flutter (0 to 400/300)
        final double x = ((data['x'] as num).toDouble() + 10) * 20;
        final double z = ((data['z'] as num).toDouble() + 10) * 15;
        _updateAssetPosition(id, x, z);
        setState(() {
          final a = assets.firstWhere((a) => a['id'] == id, orElse: () => null);
          if (a != null) {
            a['assetPosX'] = x;
            a['assetPosY'] = z;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRoomData() async {
    try {
      final roomData = await ApiClient.get('/Hierarchy/rooms/single/${widget.roomId}');
      final assetData = await ApiClient.get('/Assets/room/${widget.roomId}');
      setState(() {
        room = roomData;
        assets = assetData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load 3D data: $e')));
      }
    }
  }

  void _injectAllPlacedAssets() {
    final placed = assets.where((a) => a['assetPosX'] != null && a['assetPosY'] != null);
    for (final asset in placed) {
      _sendToEngine(asset['id'], asset['name'], asset['assetPosX'], asset['assetPosY']);
    }
  }

  void _sendToEngine(String id, String name, double x, double z) {
    if (kIsWeb) {
      sendMessageToIframe(_webViewId!, jsonEncode({'type': 'add_asset', 'id': id, 'name': name, 'x': x, 'z': z}));
    }
  }

  Future<void> _updateAssetPosition(String assetId, double x, double z) async {
    try {
      await ApiClient.put('/Assets/$assetId/position', {'assetPosX': x, 'assetPosY': z});
    } catch (_) {}
  }

  void _placeAssetAtCenter(Map<String, dynamic> asset) {
    const double cx = 200, cz = 150;
    _sendToEngine(asset['id'], asset['name'], cx, cz);
    _updateAssetPosition(asset['id'], cx, cz);
    setState(() {
      asset['assetPosX'] = cx;
      asset['assetPosY'] = cz;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111827),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final unplaced = assets.where((a) => a['assetPosX'] == null || a['assetPosY'] == null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text(
          room != null ? '${room!['name']} — 3D View' : '3D Spatial Editor',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 3D Canvas (takes all available space)
          Expanded(
            child: kIsWeb && _webViewId != null
                ? HtmlElementView(viewType: _webViewId!)
                : const Center(
                    child: Text(
                      'This 3D view is available on the Web dashboard.\nAPK build coming soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
          ),

          // Unplaced assets tray
          Container(
            constraints: const BoxConstraints(maxHeight: 130),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              border: Border(top: BorderSide(color: Color(0xFF374151))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Text(
                    'TAP to drop asset into 3D room',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: unplaced.isEmpty
                      ? const Center(
                          child: Text(
                            '✓  All assets are placed in the room',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: unplaced.length,
                          itemBuilder: (context, i) {
                            final a = unplaced[i];
                            return GestureDetector(
                              onTap: () => _placeAssetAtCenter(a),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 110,
                                margin: const EdgeInsets.only(right: 10, bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF374151), Color(0xFF1F2937)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF4B5563)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.view_in_ar, color: Color(0xFF6366f1), size: 22),
                                    const SizedBox(height: 6),
                                    Text(
                                      a['name'],
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
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
          ),
        ],
      ),
    );
  }
}
