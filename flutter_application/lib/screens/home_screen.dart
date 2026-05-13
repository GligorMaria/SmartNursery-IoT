// lib/screens/home_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // Safe ranges (must match Python script)
  static const double _tempMin = 18;
  static const double _tempMax = 22;
  static const double _humMin  = 40;
  static const double _humMax  = 60;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _statusColor(String status) =>
      status == 'OK' ? const Color(0xFF4CAF7D) : const Color(0xFFE57373);

  String _tempLabel(double t) {
    if (t < _tempMin) return 'Too Cold';
    if (t > _tempMax) return 'Too Warm';
    return 'Just Right';
  }

  String _humLabel(double h) {
    if (h < _humMin) return 'Too Dry';
    if (h > _humMax) return 'Too Humid';
    return 'Perfect';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FA),
      body: SafeArea(
        child: StreamBuilder<SensorReading?>(
          stream: DatabaseService.instance.latestStream,
          builder: (context, latestSnap) {
            final latest = latestSnap.data;
            final isAlert = latest?.isAlert ?? false;

            return CustomScrollView(
              slivers: [
                // ── App bar ─────────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: const Color(0xFFF0F6FA),
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🍼 Baby Monitor',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2D4059),
                          ),
                        ),
                        Text(
                          'Room environment tracker',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF8FA3B1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Status banner ──────────────────────────────────────
                      _StatusBanner(
                        reading: latest,
                        pulse: _pulse,
                        isAlert: isAlert,
                        statusColor: latest != null
                            ? _statusColor(latest.status)
                            : const Color(0xFFB0BEC5),
                      ),
                      const SizedBox(height: 20),

                      // ── Metric cards ───────────────────────────────────────
                      if (latest != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.thermostat_rounded,
                                label: 'Temperature',
                                value: '${latest.temperature.toStringAsFixed(1)} °C',
                                sublabel: _tempLabel(latest.temperature),
                                color: _tempColor(latest.temperature),
                                minVal: _tempMin,
                                maxVal: _tempMax,
                                currentVal: latest.temperature,
                                unit: '°C',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.water_drop_rounded,
                                label: 'Humidity',
                                value: '${latest.humidity.toStringAsFixed(0)} %',
                                sublabel: _humLabel(latest.humidity),
                                color: _humColor(latest.humidity),
                                minVal: _humMin,
                                maxVal: _humMax,
                                currentVal: latest.humidity,
                                unit: '%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last updated: ${DateFormat('HH:mm:ss').format(latest.timestamp)}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF8FA3B1),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── History chart ──────────────────────────────────────
                      Text(
                        'History (last 20 readings)',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D4059),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HistoryChart(),

                      const SizedBox(height: 24),

                      // ── Safe-range reference ───────────────────────────────
                      const _SafeRangeCard(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _tempColor(double t) {
    if (t < _tempMin) return const Color(0xFF5BC0EB);   // cold blue
    if (t > _tempMax) return const Color(0xFFE57373);   // warm red
    return const Color(0xFF4CAF7D);                      // safe green
  }

  Color _humColor(double h) {
    if (h < _humMin) return const Color(0xFFF4A261);   // dry orange
    if (h > _humMax) return const Color(0xFF5BC0EB);   // damp blue
    return const Color(0xFF4CAF7D);
  }
}

// ── Status Banner ──────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final SensorReading? reading;
  final Animation<double> pulse;
  final bool isAlert;
  final Color statusColor;

  const _StatusBanner({
    required this.reading,
    required this.pulse,
    required this.isAlert,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: isAlert ? pulse : const AlwaysStoppedAnimation(1),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                reading == null
                    ? Icons.signal_wifi_off_rounded
                    : isAlert
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reading == null
                        ? 'Waiting for sensor…'
                        : isAlert
                            ? 'ALERT – Check the room!'
                            : 'All Good! 😊',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  if (reading != null)
                    Text(
                      reading!.message,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: const Color(0xFF5A7188),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Card ────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final String   sublabel;
  final Color    color;
  final double   minVal;
  final double   maxVal;
  final double   currentVal;
  final String   unit;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
    required this.minVal,
    required this.maxVal,
    required this.currentVal,
    required this.unit,
  });

  // Clamp progress to [0,1] for the gauge
  double get progress {
    final range = maxVal - minVal;
    // show middle of gauge as the "safe" zone; extend slightly beyond
    final extended = range * 1.5;
    final low = minVal - range * 0.25;
    return ((currentVal - low) / extended).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8FA3B1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2D4059),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.12),
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$minVal$unit',
                  style: GoogleFonts.nunito(
                      fontSize: 10, color: const Color(0xFFB0BEC5))),
              Text('$maxVal$unit',
                  style: GoogleFonts.nunito(
                      fontSize: 10, color: const Color(0xFFB0BEC5))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── History Chart ──────────────────────────────────────────────────────────────
class _HistoryChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SensorReading>>(
      stream: DatabaseService.instance.historyStream(),
      builder: (context, snap) {
        final readings = snap.data ?? [];

        if (readings.isEmpty) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text('No history yet',
                  style: GoogleFonts.nunito(color: const Color(0xFFB0BEC5))),
            ),
          );
        }

        final tempSpots = readings
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
            .toList();
        final humSpots = readings
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.humidity))
            .toList();

        return Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _legend(const Color(0xFFE57373), 'Temp (°C)'),
                  const SizedBox(width: 16),
                  _legend(const Color(0xFF5BC0EB), 'Humidity (%)'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFE8F0F5),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: const Color(0xFFB0BEC5)),
                          ),
                        ),
                      ),
                      bottomTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      _line(tempSpots, const Color(0xFFE57373)),
                      _line(humSpots,  const Color(0xFF5BC0EB)),
                    ],
                    // Safe zone bands
                    rangeAnnotations: RangeAnnotations(
                      horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(
                          y1: 18, y2: 22,
                          color: const Color(0xFF4CAF7D).withOpacity(0.08),
                        ),
                        HorizontalRangeAnnotation(
                          y1: 40, y2: 60,
                          color: const Color(0xFF5BC0EB).withOpacity(0.06),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.08),
        ),
      );

  Widget _legend(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(text,
          style: GoogleFonts.nunito(
              fontSize: 11, color: const Color(0xFF8FA3B1))),
    ],
  );
}

// ── Safe Range Reference Card ─────────────────────────────────────────────────
class _SafeRangeCard extends StatelessWidget {
  const _SafeRangeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5F5), Color(0xFFEEF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Safe Ranges for Baby',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D4059),
            ),
          ),
          const SizedBox(height: 12),
          _rangeRow(Icons.thermostat_rounded, 'Temperature',
              '18 °C – 22 °C', const Color(0xFFE57373)),
          const SizedBox(height: 8),
          _rangeRow(Icons.water_drop_rounded, 'Humidity',
              '40 % – 60 %', const Color(0xFF5BC0EB)),
          const SizedBox(height: 12),
          Text(
            'Based on AAP (American Academy of Pediatrics) recommendations.',
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: const Color(0xFF8FA3B1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeRow(IconData icon, String label, String range, Color color) =>
      Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5A7188))),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(range,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      );
}