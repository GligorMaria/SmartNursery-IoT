// lib/screens/home_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';
import '../services/database_service.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // Safe ranges
  static const double _tempMin = 18;
  static const double _tempMax = 22;
  static const double _humMin  = 40;
  static const double _humMax  = 60;

  // Theme Palette - Soft & Elegant Pastels
  static const Color _bgPink = Color(0xFFFFF2F5);       // Strawberry milk backdrop
  static const Color _textDark = Color(0xFF6D4C57);     // Cozy deep cocoa/rose brown
  static const Color _textMuted = Color(0xFFBCA6AC);    // Soft dusty rose gray
  static const Color _accentPink = Color(0xFFFFB7C5);   // Sweet bubblegum pink
  static const Color _softWhite = Color(0xFFFFFFFF);    // Clean marshmallow white
  
  // Status Colors
  static const Color _statusGreen = Color(0xFFA8D5BA);  // Soft sage green
  static const Color _statusOrange = Color(0xFFFFCDA3); // Soft peach
  static const Color _statusRed = Color(0xFFFF9AA2);    // Soft pastel coral red

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.98, end: 1.02).animate(
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
      status == 'OK' ? _statusGreen : _statusRed;

  String _tempLabel(double t) {
    if (t < _tempMin) return 'Brrr, too chilly ❄️';
    if (t > _tempMax) return 'A bit too warm ☀️';
    if (t >= 20 && t <= 21) return 'Perfectly cozy ✨';
    return 'Just right 🥰';
  }

  String _humLabel(double h) {
    if (h < _humMin) return 'A little dry 🍃';
    if (h > _humMax) return 'Too humid ☁️';
    return 'Sweet & comfortable 💧';
  }

  Color _tempColor(double t) {
    if (t < _tempMin) return const Color(0xFFB3E5FC); // Soft pastel blue
    if (t > _tempMax) return _statusRed;
    return _statusGreen;
  }

  Color _humColor(double h) {
    if (h < _humMin) return _statusOrange;
    if (h > _humMax) return const Color(0xFFB3E5FC);
    return _statusGreen;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPink,
      body: SafeArea(
        child: StreamBuilder<SensorReading?>(
          stream: DatabaseService.instance.latestStream,
          builder: (context, latestSnap) {
            final latest = latestSnap.data;
            final isAlert = latest?.isAlert ?? false;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App bar ─────────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: _bgPink,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 110,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _softWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _accentPink.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.child_care_rounded,
                            color: _textDark,
                            size: 24,
                          ),
                          tooltip: 'Live Camera',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CameraScreen()),
                          ),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sweet Dreams',
                          style: GoogleFonts.quicksand(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nursery Nest Environment Tracker',
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Status banner ──────────────────────────────────────
                      _StatusBanner(
                        reading: latest,
                        pulse: _pulse,
                        isAlert: isAlert,
                        statusColor: latest != null
                            ? _statusColor(latest.status)
                            : _textMuted,
                        accentPink: _accentPink,
                        softWhite: _softWhite,
                        textDark: _textDark,
                        textMuted: _textMuted,
                      ),
                      const SizedBox(height: 24),

                      // ── Metric cards ───────────────────────────────────────
                      if (latest != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.wb_twighlight,
                                label: 'Temperature',
                                value: '${latest.temperature.toStringAsFixed(1)}°C',
                                sublabel: _tempLabel(latest.temperature),
                                color: _tempColor(latest.temperature),
                                minVal: _tempMin,
                                maxVal: _tempMax,
                                currentVal: latest.temperature,
                                unit: '°C',
                                textDark: _textDark,
                                textMuted: _textMuted,
                                softWhite: _softWhite,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.opacity_rounded,
                                label: 'Humidity',
                                value: '${latest.humidity.toStringAsFixed(0)}%',
                                sublabel: _humLabel(latest.humidity),
                                color: _humColor(latest.humidity),
                                minVal: _humMin,
                                maxVal: _humMax,
                                currentVal: latest.humidity,
                                unit: '%',
                                textDark: _textDark,
                                textMuted: _textMuted,
                                softWhite: _softWhite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Last cuddle check: ${DateFormat('HH:mm:ss').format(latest.timestamp)}',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              color: _textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── History chart ──────────────────────────────────────
                      Text(
                        'Nursery Trends (Last 20 Logged)',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HistoryChart(
                        textMuted: _textMuted,
                        softWhite: _softWhite,
                        bgPink: _bgPink,
                        tempColor: _statusRed,
                        humColor: const Color(0xFFB3E5FC),
                      ),

                      const SizedBox(height: 28),

                      // ── Safe-range reference ───────────────────────────────
                      _SafeRangeCard(
                        textDark: _textDark,
                        textMuted: _textMuted,
                        softWhite: _softWhite,
                        statusRed: _statusRed,
                      ),
                      const SizedBox(height: 32),
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
}

// ── Status Banner ──────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final SensorReading? reading;
  final Animation<double> pulse;
  final bool isAlert;
  final Color statusColor;
  final Color accentPink;
  final Color softWhite;
  final Color textDark;
  final Color textMuted;

  const _StatusBanner({
    required this.reading,
    required this.pulse,
    required this.isAlert,
    required this.statusColor,
    required this.accentPink,
    required this.softWhite,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: isAlert ? pulse : const AlwaysStoppedAnimation(1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: softWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentPink.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  reading == null 
                      ? '😴' 
                      : isAlert 
                          ? '🍼' 
                          : '👼',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reading == null
                        ? 'Connecting cradle...'
                        : isAlert
                            ? 'Little love needs you!'
                            : 'Sleeping soundly...',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reading == null ? 'Syncing background environment data' : reading!.message,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
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
  final Color    textDark;
  final Color    textMuted;
  final Color    softWhite;

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
    required this.textDark,
    required this.textMuted,
    required this.softWhite,
  });

  double get progress {
    final range = maxVal - minVal;
    final extended = range * 1.5;
    final low = minVal - range * 0.25;
    return ((currentVal - low) / extended).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.8), size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textDark.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$minVal$unit',
                  style: GoogleFonts.quicksand(
                      fontSize: 10, fontWeight: FontWeight.w500, color: textMuted)),
              Text('$maxVal$unit',
                  style: GoogleFonts.quicksand(
                      fontSize: 10, fontWeight: FontWeight.w500, color: textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── History Chart ──────────────────────────────────────────────────────────────
class _HistoryChart extends StatelessWidget {
  final Color textMuted;
  final Color softWhite;
  final Color bgPink;
  final Color tempColor;
  final Color humColor;

  const _HistoryChart({
    required this.textMuted,
    required this.softWhite,
    required this.bgPink,
    required this.tempColor,
    required this.humColor,
  });

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
              color: softWhite,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text('Cradle is preparing stats... 🧸',
                  style: GoogleFonts.quicksand(color: textMuted, fontWeight: FontWeight.w500)),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: softWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: textMuted.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _legend(tempColor, 'Temp'),
                  const SizedBox(width: 16),
                  _legend(humColor, 'Humidity'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: bgPink,
                        strokeWidth: 1.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: GoogleFonts.quicksand(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: textMuted),
                          ),
                        ),
                      ),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      _line(tempSpots, tempColor),
                      _line(humSpots, humColor),
                    ],
                    rangeAnnotations: RangeAnnotations(
                      horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(
                          y1: 18, y2: 22,
                          color: tempColor.withOpacity(0.04),
                        ),
                        HorizontalRangeAnnotation(
                          y1: 40, y2: 60,
                          color: humColor.withOpacity(0.04),
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
        barWidth: 3.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.05),
        ),
      );

  Widget _legend(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(text,
          style: GoogleFonts.quicksand(
              fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
    ],
  );
}

// ── Safe Range Reference Card ─────────────────────────────────────────────────
class _SafeRangeCard extends StatelessWidget {
  final Color textDark;
  final Color textMuted;
  final Color softWhite;
  final Color statusRed;

  const _SafeRangeCard({
    required this.textDark,
    required this.textMuted,
    required this.softWhite,
    required this.statusRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textMuted.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🧸 Nursery Guide',
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _rangeRow('Temperature', '18°C – 22°C', statusRed),
          const SizedBox(height: 10),
          _rangeRow('Humidity', '40% – 60%', const Color(0xFFB3E5FC)),
          const SizedBox(height: 16),
          Text(
            'Pediatric guidelines favor mild settings to secure a sound, restful sleep.',
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeRow(String label, String range, Color color) =>
      Row(
        children: [
          Text(label,
              style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(range,
                style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textDark)),
          ),
        ],
      );
}