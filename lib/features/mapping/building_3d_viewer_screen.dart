import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  WebViewController? _mobileWebViewController;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webViewId = registerBuildingIframe(_onEngineMessage);
    } else {
      _mobileWebViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF111827))
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            _onEngineMessage(message.message);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _mobileWebViewController?.runJavaScript('''
                window.parent.postMessage = function(message, targetOrigin) {
                  FlutterChannel.postMessage(message);
                };
                window.postMessage = function(message, targetOrigin) {
                  if (typeof message === 'string') {
                    FlutterChannel.postMessage(message);
                  }
                };
              ''');
            },
          ),
        )
        ..loadRequest(Uri.parse('https://management.ermarscastar.in/3d-web/building_3d_viewer.html'));
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
    if (building == null) return;
    
    final msg = jsonEncode({'type': 'load_building', 'data': building});
    if (kIsWeb && _webViewId != null) {
      sendToBuildingIframe(_webViewId!, msg);
    } else if (!kIsWeb && _mobileWebViewController != null) {
      _mobileWebViewController?.runJavaScript("window.dispatchEvent(new MessageEvent('message', {data: $msg}));");
    }

    // Inject placed assets after a short delay to let engine parse the building
    Future.delayed(const Duration(milliseconds: 500), _injectAssets);
  }

  void _injectAssets() {
    final floors = (building?['floors'] as List<dynamic>? ?? []);
    for (final floor in floors) {
      final floorId = floor['id'] as String;
      final assets = _floorAssets[floorId] ?? [];
      for (final asset in assets) {
        final msg = jsonEncode({
          'type': 'add_asset',
          'id': asset['id'],
          'name': asset['name'],
          'floorId': floorId,
          'x': asset['assetPosX'],
          'z': asset['assetPosY'],
        });
        
        if (kIsWeb && _webViewId != null) {
          sendToBuildingIframe(_webViewId!, msg);
        } else if (!kIsWeb && _mobileWebViewController != null) {
          _mobileWebViewController?.runJavaScript("window.dispatchEvent(new MessageEvent('message', {data: $msg}));");
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
          : _mobileWebViewController != null
              ? WebViewWidget(controller: _mobileWebViewController!)
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
