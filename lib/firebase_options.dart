// File generated manually from Firebase console config.
// To add Android/iOS: register those apps in Firebase console,
// download google-services.json / GoogleService-Info.plist,
// then run: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Android is not configured yet. Register an Android app in the '
          'Firebase console and run: flutterfire configure',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS is not configured yet. Register an iOS app in the '
          'Firebase console and run: flutterfire configure',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS is not configured yet.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDivkXjJ-4Urn-2hephYWU_dWHOrK20Q78',
    appId: '1:1021610120973:web:2d3f388326fc60fbb90244',
    messagingSenderId: '1021610120973',
    projectId: 'facilitypro-3f693',
    authDomain: 'facilitypro-3f693.firebaseapp.com',
    storageBucket: 'facilitypro-3f693.firebasestorage.app',
    measurementId: 'G-DXLF4SLNTB',
  );
}
