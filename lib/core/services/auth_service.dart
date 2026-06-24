import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../network/api_client.dart';
import '../session/session_manager.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web: Firebase handles the OAuth popup natively — no meta tag needed
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // Mobile: use google_sign_in package
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return 'Sign-in cancelled.';
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final email = userCredential.user?.email;
      if (email == null) return 'Could not retrieve email from Google account.';

      // Look up backend user profile by email
      try {
        final backendUser = await ApiClient.get('/Users/by-email?email=${Uri.encodeComponent(email)}');
        SessionManager().setUser(backendUser);
        SessionManager().setFirebaseUser(userCredential.user!);
        return null; // success
      } catch (_) {
        await _auth.signOut();
        return 'Your account has not been set up yet. Please contact your administrator.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Authentication failed.';
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    SessionManager().clear();
  }
}
