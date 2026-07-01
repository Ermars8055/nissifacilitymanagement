import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

import 'building_3d_viewer_web.dart' if (dart.library.io) 'building_3d_viewer_stub.dart';

class Building3DViewerScreen extends StatefulWidget {
  final String buildingId;
  const Building3DViewerScreen({super.key, required this.buildingId});

  @override
  State<Building3DViewerScreen> createState() => _Building3DViewerScreenState();
}

class _Building3DViewerScreenState extends State<Building3DViewerScreen> {
  bool isLoading = true;
  Map<String, dynamic>? building;
  // All assets keyed by floorId
  final Map<String, List<dynamic>> _floorAssets = {};
  String? _webViewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webViewId = registerBuildingIframe(_onEngineMessage);
    }
    _fetchAll();
  }

  void _onEngineMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['type'] == 'engine_ready') {
        _sendBuildingToEngine();
      } else if (data['type'] == 'asset_moved') {
        // Save position back to backend
        final id = data['id'] as String;
        final x = (data['x'] as num).toDouble();
        final z = (data['z'] as num).toDouble();
        _saveAssetPosition(id, x, z);
      }
    } catch (_) {}
  }

  Future<void> _fetchAll() async {
    try {
      // 1. Fetch full building structure (floors + rooms)
      final bld = await ApiClient.get('/Hierarchy/building/${widget.buildingId}/full');

      // 2. For each floor, fetch assets
      final floors = (bld['floors'] as List<dynamic>? ?? []);
      final Map<String, List<dynamic>> assetMap = {};
      for (final floor in floors) {
        final floorId = floor['id'] as String;
        final rooms = (floor['rooms'] as List<dynamic>? ?? []);
        final List<dynamic> allAssets = [];
        for (final room in rooms) {
          try {
            final roomAssets = await ApiClient.get('/Assets/room/${room['id']}');
            allAssets.addAll(roomAssets);
          } catch (_) {}
        }
        assetMap[floorId] = allAssets;
      }

      setState(() {
        building = bld;
        _floorAssets.addAll(assetMap);
        isLoading = false;
      });
      _sendBuildingToEngine();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load building: $e')),
        );
      }
    }
  }

  void _sendBuildingToEngine() {
    if (!kIsWeb || _webViewId == null || building == null) return;
    sendToBuildingIframe(
      _webViewId!,
      jsonEncode({'type': 'load_building', 'data': building}),
    );
    // Inject placed assets after a short delay to let engine parse the building
    Future.delayed(const Duration(milliseconds: 500), _injectAssets);
  }

  void _injectAssets() {
    if (!kIsWeb || _webViewId == null) return;
    final floors = (building?['floors'] as List<dynamic>? ?? []);
    for (final floor in floors) {
      final floorId = floor['id'] as String;
      final assets = _floorAssets[floorId] ?? [];
      for (final asset in assets) {
        if (asset['assetPosX'] != null && asset['assetPosY'] != null) {
          sendToBuildingIframe(
            _webViewId!,
            jsonEncode({
              'type': 'add_asset',
              'id': asset['id'],
              'name': asset['name'],
              'floorId': floorId,
              'x': asset['assetPosX'],
              'z': asset['assetPosY'],
            }),
          );
        }
      }
    }
  }

  Future<void> _saveAssetPosition(String assetId, double x, double z) async {
    try {
      await ApiClient.put('/Assets/$assetId/position', {'assetPosX': x, 'assetPosY': z});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111827),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final floorCount = (building?['floors'] as List?)?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text(
          building?['name'] != null ? '${building!['name']} — $floorCount-Floor Stack' : '3D Building',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: kIsWeb && _webViewId != null
          ? LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: HtmlElementView(viewType: _webViewId!),
              ),
            )
          : const Center(
              child: Text(
                'Building 3D Stack is available on the Web Dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
    );
  }
}
