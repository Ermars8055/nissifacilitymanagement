import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client_wrapper.dart';

/// An entry in the offline queue
class QueuedRequest {
  final String method;   // 'PUT' | 'POST'
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime queuedAt;

  QueuedRequest({
    required this.method,
    required this.endpoint,
    required this.data,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
    'method': method,
    'endpoint': endpoint,
    'data': data,
    'queuedAt': queuedAt.toIso8601String(),
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    method: json['method'] as String,
    endpoint: json['endpoint'] as String,
    data: (json['data'] as Map).cast<String, dynamic>(),
    queuedAt: DateTime.parse(json['queuedAt'] as String),
  );
}

class OfflineQueue {
  static const _key = 'offline_queue';
  static final OfflineQueue _instance = OfflineQueue._();
  factory OfflineQueue() => _instance;
  OfflineQueue._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Call once from main() or app startup
  void init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      if (_isOnline && wasOffline) {
        // Just came back online — flush the queue
        flushQueue();
      }
    });

    // Check initial state
    Connectivity().checkConnectivity().then((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    });
  }

  Future<void> enqueue(String method, String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    list.add(QueuedRequest(
      method: method,
      endpoint: endpoint,
      data: data,
      queuedAt: DateTime.now(),
    ).toJson());
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<int> get queueLength async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    return (jsonDecode(raw) as List).length;
  }

  Future<void> flushQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    final list = (jsonDecode(raw) as List)
        .map((e) => QueuedRequest.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    if (list.isEmpty) return;

    final failed = <QueuedRequest>[];
    for (final req in list) {
      try {
        if (req.method == 'PUT') {
          await ApiClientWrapper.put(req.endpoint, req.data);
        } else if (req.method == 'POST') {
          await ApiClientWrapper.post(req.endpoint, req.data);
        }
      } catch (_) {
        failed.add(req); // keep failed ones in queue
      }
    }

    await prefs.setString(_key, jsonEncode(failed.map((r) => r.toJson()).toList()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
