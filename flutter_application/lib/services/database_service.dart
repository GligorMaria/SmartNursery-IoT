// lib/services/database_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_reading.dart';

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
}