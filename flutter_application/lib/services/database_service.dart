// lib/services/database_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_reading.dart';

import '../models/pose_status.dart';   // ← new
 
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
 
  final DatabaseReference _root = FirebaseDatabase.instance.ref('baby_monitor');
 
  // ── Temperature / humidity (existing) ─────────────────────────────────────
  Stream<SensorReading?> get latestStream =>
      _root.child('latest').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return null;
        return SensorReading.fromMap(data as Map<dynamic, dynamic>);
      });
 
  Stream<List<SensorReading>> historyStream({int limit = 20}) =>
      _root
          .child('readings')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .onValue
          .map((event) {
        final snap = event.snapshot.value;
        if (snap == null) return [];
        final map = snap as Map<dynamic, dynamic>;
        final list = map.values
            .map((v) => SensorReading.fromMap(v as Map<dynamic, dynamic>))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return list;
      });
 
  // ── ML Pose status (new) ────────────────────────────────────────────────────
  Stream<PoseStatus?> get poseStream =>
      _root.child('pose_status').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return null;
        return PoseStatus.fromMap(data as Map<dynamic, dynamic>);
      });
 
  // ── ML Alert (new) ─────────────────────────────────────────────────────────
  Stream<bool> get mlAlertStream =>
      _root.child('ml_alert').onValue.map((event) {
        final data = event.snapshot.value as Map?;
        return data?['active'] == true;
      });
 
  // Clear alert after user acknowledges it
  Future<void> clearMlAlert() =>
      _root.child('ml_alert').update({'active': false});
}

/*
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  final DatabaseReference _root =
      FirebaseDatabase.instance.ref('baby_monitor');

  // ── Latest reading (real-time stream) ─────────────────────────────────────
  Stream<SensorReading?> get latestStream =>
      _root.child('latest').onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return null;
        return SensorReading.fromMap(data as Map<dynamic, dynamic>);
      });

  // ── Last N readings for the history chart ─────────────────────────────────
  Stream<List<SensorReading>> historyStream({int limit = 20}) =>
      _root
          .child('readings')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .onValue
          .map((event) {
        final snap = event.snapshot.value;
        if (snap == null) return [];

        final map = snap as Map<dynamic, dynamic>;
        final list = map.values
            .map((v) => SensorReading.fromMap(v as Map<dynamic, dynamic>))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return list;
      });
}*/