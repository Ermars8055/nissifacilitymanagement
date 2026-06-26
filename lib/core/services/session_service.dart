import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

/// Holds the worker's current attendance session state in memory.
class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? _sessionId;
  DateTime? _expiresAt;
  bool _hasSession = false;
  double? _lastDistanceMetres;

  bool get hasSession => _hasSession && (_expiresAt?.isAfter(DateTime.now()) ?? false);
  String? get sessionId => _sessionId;
  double? get lastDistanceMetres => _lastDistanceMetres;
  DateTime? get expiresAt => _expiresAt;

  /// Called after a successful POST /Sessions/start response.
  void setSession(Map<String, dynamic> response) {
    _sessionId = response['sessionId'] as String?;
    _lastDistanceMetres = (response['distanceMetres'] as num?)?.toDouble();
    final expiresStr = response['expiresAt'] as String?;
    _expiresAt = expiresStr != null ? DateTime.parse(expiresStr) : null;
    _hasSession = true;
    notifyListeners();
  }

  /// Restore session from server on app restart.
  Future<void> restore(String workerId) async {
    try {
      final data = await ApiClient.get('/Sessions/active/$workerId') as Map<String, dynamic>;
      if (data['hasSession'] == true) {
        _sessionId = data['sessionId'] as String?;
        final expiresStr = data['expiresAt'] as String?;
        _expiresAt = expiresStr != null ? DateTime.parse(expiresStr) : null;
        _hasSession = true;
        notifyListeners();
      }
    } catch (_) {
      // No session or network error — stay as-is
    }
  }

  void clear() {
    _sessionId = null;
    _expiresAt = null;
    _hasSession = false;
    _lastDistanceMetres = null;
    notifyListeners();
  }
}
