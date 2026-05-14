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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDLHwHo17J_osaRlH4Jftvtkzd7vPhjaIM',   // ← Config tab → apiKey
    appId:             '1:941631958102:web:8d1580671b3b847ff3dff7', // ← deja il stii!
    messagingSenderId: '941631958102',              // ← deja il stii!
    projectId:         'smartnursery-iot',          // ← deja il stii!
    databaseURL:       'https://smartnursery-iot-default-rtdb.firebaseio.com',
    storageBucket:     'smartnursery-iot.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyAg47MzORudIwdcxbztObrcUf6IjXjjpz4', // current_key
    appId:             '1:941631958102:android:d33a169f736ffa69f3dff7', // mobilesdk_app_id
    messagingSenderId: '941631958102',
    projectId:         'smartnursery-iot',
    databaseURL:       'https://smartnursery-iot-default-rtdb.firebaseio.com',
    storageBucket:     'smartnursery-iot.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyBOTg2Uk_s80GkAcCVY8K_2f-MaNPqtsfE', // API_KEY
    appId:             '1:941631958102:ios:f4c1e54feb142ecbf3dff7', // GOOGLE_APP_ID
    messagingSenderId: '941631958102',
    projectId:         'smartnursery-iot',
    databaseURL:       'https://smartnursery-iot-default-rtdb.firebaseio.com',
    storageBucket:     'smartnursery-iot.appspot.com',
    iosBundleId:       'com.example.flutterApplication',
  );
}

/*
  apiKey: "AIzaSyDLHwHo17J_osaRlH4Jftvtkzd7vPhjaIM",
  authDomain: "smartnursery-iot-53f11.firebaseapp.com",
  databaseURL: "https://smartnursery-iot-53f11-default-rtdb.firebaseio.com",
  projectId: "smartnursery-iot-53f11",
  storageBucket: "smartnursery-iot-53f11.firebasestorage.app",
  messagingSenderId: "941631958102",
  appId: "1:941631958102:web:8d1580671b3b847ff3dff7",
  measurementId: "G-NPML45TQW1"
 */