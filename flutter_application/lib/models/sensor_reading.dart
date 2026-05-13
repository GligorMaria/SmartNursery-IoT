// lib/models/sensor_reading.dart

class SensorReading {
  final double temperature;
  final double humidity;
  final String status;   // 'OK' | 'ALERT'
  final String message;
  final DateTime timestamp;

  const SensorReading({
    required this.temperature,
    required this.humidity,
    required this.status,
    required this.message,
    required this.timestamp,
  });

  bool get isAlert => status == 'ALERT';

  factory SensorReading.fromMap(Map<dynamic, dynamic> map) {
    return SensorReading(
      temperature: (map['temperature'] as num).toDouble(),
      humidity:    (map['humidity']    as num).toDouble(),
      status:       map['status']  as String? ?? 'OK',
      message:      map['message'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'temperature': temperature,
    'humidity':    humidity,
    'status':      status,
    'message':     message,
    'timestamp':   timestamp.millisecondsSinceEpoch,
  };
}