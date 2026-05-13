// lib/firebase_options.dart
//
// ─── HOW TO GENERATE THIS FILE ────────────────────────────────────────────────
//
// 1. Install the FlutterFire CLI once:
//      dart pub global activate flutterfire_cli
//
// 2. Log in to Firebase:
//      firebase login
//
// 3. In your project root run:
//      flutterfire configure
//
//    Select your Firebase project and platforms (Android / iOS).
//    FlutterFire will create this file automatically and also patch:
//      • android/app/google-services.json
//      • ios/Runner/GoogleService-Info.plist
//
// ─── PLACEHOLDER (replace with generated output) ──────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Replace values below with your real Firebase project config ────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'YOUR_WEB_API_KEY',
    appId:             'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId:         'YOUR_PROJECT_ID',
    databaseURL:       'https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com',
    storageBucket:     'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'YOUR_ANDROID_API_KEY',
    appId:             'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId:         'YOUR_PROJECT_ID',
    databaseURL:       'https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com',
    storageBucket:     'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'YOUR_IOS_API_KEY',
    appId:             'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId:         'YOUR_PROJECT_ID',
    databaseURL:       'https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com',
    storageBucket:     'YOUR_PROJECT_ID.appspot.com',
    iosBundleId:       'com.example.flutterApplication',
  );
}