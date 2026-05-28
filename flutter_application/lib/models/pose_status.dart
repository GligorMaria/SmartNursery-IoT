// lib/models/pose_status.dart

class PoseStatus {
  final String position;     // SAFE | PRONE | SIDE | NO_MOTION | UNKNOWN
  final bool   danger;
  final String message;
  final int    secondsStill;
  final DateTime timestamp;

  const PoseStatus({
    required this.position,
    required this.danger,
    required this.message,
    required this.secondsStill,
    required this.timestamp,
  });

  factory PoseStatus.fromMap(Map<dynamic, dynamic> map) {
    return PoseStatus(
      position:     map['position']      as String? ?? 'UNKNOWN',
      danger:       map['danger']        as bool?   ?? false,
      message:      map['message']       as String? ?? '',
      secondsStill: map['seconds_still'] as int?    ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
    );
  }

  // Icon and color helpers used in the UI
  String get icon {
    switch (position) {
      case 'PRONE':     return '🚨';
      case 'SIDE':      return '⚠️';
      case 'NO_MOTION': return '⏱️';
      case 'SAFE':      return '✅';
      default:          return '❓';
    }
  }

  bool get isCritical => position == 'PRONE';
}