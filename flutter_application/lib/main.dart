// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
 
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
 
/// Handle FCM messages while the app is terminated / in background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService().showLocalNotification(
    title: message.notification?.title ?? 'Baby Monitor Alert',
    body:  message.notification?.body  ?? '',
  );
}
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  // ── Firebase ──────────────────────────────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 
  // ── Local notifications channel (Android 8+) ──────────────────────────────
  await NotificationService().init();
 
  // ── Background FCM handler ────────────────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
 
  runApp(const BabyMonitorApp());
}
 
class BabyMonitorApp extends StatelessWidget {
  const BabyMonitorApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7EC8C8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}