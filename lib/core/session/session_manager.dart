import 'package:firebase_auth/firebase_auth.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;
  SessionManager._internal();

  Map<String, dynamic>? currentUser;
  String? selectedBuildingId;
  String? selectedBuildingName;
  User? firebaseUser;

  bool get isLoggedIn => currentUser != null && firebaseUser != null;

  String? get currentUserId => currentUser?['id'] as String?;
  String get currentRole => currentUser?['role'] as String? ?? '';
  bool get isAdmin => currentRole == 'Admin' || currentRole == 'Super Admin';

  void setUser(Map<String, dynamic> user) {
    currentUser = user;
  }

  void setFirebaseUser(User user) {
    firebaseUser = user;
  }

  void setBuilding(String id, String name) {
    selectedBuildingId = id;
    selectedBuildingName = name;
  }

  void clear() {
    currentUser = null;
    firebaseUser = null;
    selectedBuildingId = null;
    selectedBuildingName = null;
  }
}
