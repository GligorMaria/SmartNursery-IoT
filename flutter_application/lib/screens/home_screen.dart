
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

  // Theme Palette - Harmonized Yellow & Cream Tones
  static const Color _bgLight       = Color(0xFFFFFDE7); // Creamy light backdrop
  static const Color _panelBg       = Color(0xFFFFF9C4); // Soft sunshine panel fill
  static const Color _textDark      = Color(0xFF4E342E); // Deep espresso brown for professional text
  static const Color _textMuted     = Color(0xFF8D6E63); // Warm cocoa brown
  static const Color _brightYellow  = Color(0xFFFBC02D); // Deep golden accent yellow
  static const Color _pastelYellow  = Color(0xFFFFF59D); // Cute soft pastel yellow for interactive accents
  
  // Font Colors mimicking the image bubble text look within our yellow scheme
  static const Color _bubbleTextFill = Color(0xFFFFE082); // Bubble candy yellow center
  static const Color _bubbleText3D   = Color(0xFF5D4037); // Deep structural 3D shadow block

  // Status Colors
  static const Color _statusGreen   = Color(0xFF9CCC65); 
  static const Color _statusOrange  = Color(0xFFFFB74D); 
  static const Color _statusRed     = Color(0xFFEF5350); 

  // Clean aesthetic quotes array
  final List<String> _quotes = [
    "Ten little fingers, ten perfect toes, fill our hearts with love that overflows.",
    "Dream big, little star. The universe is waiting to see your golden light."
  ];

  late final Stream<DateTime> _clockStream;

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

    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) => status == 'OK' ? _statusGreen : _statusRed;

  String _tempLabel(double t) {
    if (t < _tempMin) return 'Chilly ❄️';
    if (t > _tempMax) return 'Warm ☀️';
    return 'Cozy ✨';
  }

  String _humLabel(double h) {
    if (h < _humMin) return 'Dry 🍃';
    if (h > _humMax) return 'Humid ☁️';
    return 'Sweet 💧';
  }

  Color _tempColor(double t) {
    if (t < _tempMin) return const Color(0xFF29B6F6);
    if (t > _tempMax) return _statusRed;
    return _statusGreen;
  }

  Color _humColor(double h) {
    if (h < _humMin) return _statusOrange;
    if (h > _humMax) return const Color(0xFF29B6F6);
    return _statusGreen;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: StreamBuilder<SensorReading?>(
          stream: DatabaseService.instance.latestStream,
          builder: (context, latestSnap) {
            final latest = latestSnap.data;
            final isAlert = latest?.isAlert ?? false;

            return SizedBox(
              height: screenHeight,
              child: Row(
                children: [
                  // ── LEFT SIDE: PANELS & DATA (60% Width) ──────────────────────────
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Center-aligned Panel-less Fredoka Title
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                'Bibino',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fredoka(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: _bubbleTextFill,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.white,
                                      offset: Offset(-1, -1),
                                      blurRadius: 0,
                                    ),
                                    const Shadow(
                                      color: _bubbleText3D,
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                    ),
                                    const Shadow(
                                      color: _bubbleText3D,
                                      offset: Offset(4, 4),
                                      blurRadius: 0,
                                    ),
                                    Shadow(
                                      color: _bubbleText3D.withOpacity(0.3),
                                      offset: const Offset(6, 6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NURSERY NEST ENVIRONMENT MONITOR',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.quicksand(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _textMuted,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Status Banner
                          _StatusBanner(
                            reading: latest,
                            pulse: _pulse,
                            isAlert: isAlert,
                            statusColor: latest != null ? _statusColor(latest.status) : _textMuted,
                            brightYellow: _brightYellow,
                            panelBg: _panelBg,
                            textDark: _textDark,
                            textMuted: _textMuted,
                          ),
                          const SizedBox(height: 16),

                          // Metrics (Temperature & Humidity)
                          if (latest != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    icon: Icons.wb_twighlight,
                                    label: 'Temp',
                                    value: '${latest.temperature.toStringAsFixed(1)}°C',
                                    sublabel: _tempLabel(latest.temperature),
                                    color: _tempColor(latest.temperature),
                                    minVal: _tempMin,
                                    maxVal: _tempMax,
                                    currentVal: latest.temperature,
                                    unit: '°C',
                                    textDark: _textDark,
                                    textMuted: _textMuted,
                                    panelBg: _panelBg,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                    panelBg: _panelBg,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),

                          // ── Seamless Aesthetic Quote View with Bees! ──
                          _AestheticBeeQuoteView(
                            quotes: _quotes,
                            textDark: _textDark,
                          ),
                          const SizedBox(height: 20),

                          // Chart Visualizer
                          Expanded(
                            child: _HistoryChart(
                              textMuted: _textMuted,
                              panelBg: _panelBg,
                              bgLight: _bgLight,
                              tempColor: _statusRed,
                              humColor: const Color(0xFF29B6F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── RIGHT SIDE: VISUAL UTILITIES & CUTE BEAR (40% Width) ──────────
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _panelBg.withOpacity(0.5),
                        border: Border(left: BorderSide(color: _brightYellow.withOpacity(0.3), width: 2)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Column(
                        children: [
                          // Top Window Element: Big Clock Circle Container
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = constraints.maxHeight < constraints.maxWidth 
                                    ? constraints.maxHeight * 0.9 
                                    : constraints.maxWidth * 0.9;
                                return Center(
                                  child: Container(
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      color: _panelBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _brightYellow, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _brightYellow.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: StreamBuilder<DateTime>(
                                      stream: _clockStream,
                                      initialData: DateTime.now(),
                                      builder: (context, snapshot) {
                                        final now = snapshot.data!;
                                        return FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildClockSegment(DateFormat('HH').format(now)),
                                              _buildClockSeparator(),
                                              _buildClockSegment(DateFormat('mm').format(now)),
                                              _buildClockSeparator(),
                                              _buildClockSegment(DateFormat('ss').format(now)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Bottom Window Element: Bear holding the Small Cute Pastel Camera Button
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final containerSize = constraints.maxHeight < constraints.maxWidth 
                                    ? constraints.maxHeight * 0.95 
                                    : constraints.maxWidth * 0.95;
                                
                                return Center(
                                  child: SizedBox(
                                    width: containerSize,
                                    height: containerSize,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Bear frame
                                        Positioned(
                                          bottom: 10,
                                          child: _CuteBearGraphic(size: containerSize * 0.85),
                                        ),
                                        // Camera button
                                        Positioned(
                                          right: containerSize * 0.04,
                                          top: containerSize * 0.28,
                                          child: GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const CameraScreen()),
                                            ),
                                            child: Container(
                                              width: containerSize * 0.28,
                                              height: containerSize * 0.28,
                                              decoration: BoxDecoration(
                                                color: _pastelYellow,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: _textDark, width: 3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _textDark.withOpacity(0.15),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ],
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.videocam_rounded,
                                                  color: _textDark,
                                                  size: containerSize * 0.14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClockSegment(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: _pastelYellow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brightYellow.withOpacity(0.4),
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Text(
        text,
        style: GoogleFonts.fredoka(
          fontSize: 38,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          shadows: [
            Shadow(
              color: _brightYellow.withOpacity(0.5),
              offset: const Offset(2, 2),
            )
          ]
        ),
      ),
    );
  }

  Widget _buildClockSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: _brightYellow, shape: BoxShape.circle)),
          const SizedBox(height: 12),
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: _brightYellow, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

// ── Custom Built-in Bear UI Vector ─────────────────────────────────────────────
class _CuteBearGraphic extends StatelessWidget {
  final double size;
  const _CuteBearGraphic({required this.size});

  @override
  Widget build(BuildContext context) {
    final Color bearBrown = const Color(0xFF916A4C);
    final Color innerTan = const Color(0xFFEED0B1);
    final Color lineBorder = const Color(0xFF331D12);
    final Color pacifierBlue = const Color(0xFF81D4FA);

    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Ear
          Positioned(
            left: size * 0.16,
            top: size * 0.08,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: bearBrown,
                shape: BoxShape.circle,
                border: Border.all(color: lineBorder, width: 3),
              ),
              child: Center(
                child: Container(
                  width: size * 0.14,
                  height: size * 0.14,
                  decoration: BoxDecoration(color: innerTan, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          // Right Ear
          Positioned(
            right: size * 0.16,
            top: size * 0.08,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: bearBrown,
                shape: BoxShape.circle,
                border: Border.all(color: lineBorder, width: 3),
              ),
              child: Center(
                child: Container(
                  width: size * 0.14,
                  height: size * 0.14,
                  decoration: BoxDecoration(color: innerTan, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          // Body Base
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.62,
              height: size * 0.45,
              decoration: BoxDecoration(
                color: bearBrown,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
                border: Border.all(color: lineBorder, width: 3),
              ),
              child: Center(
                child: Container(
                  width: size * 0.38,
                  height: size * 0.32,
                  margin: const EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                    color: innerTan,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          // Left Arm Resting
          Positioned(
            left: size * 0.08,
            bottom: size * 0.12,
            child: Container(
              width: size * 0.16,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: bearBrown,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: lineBorder, width: 3),
              ),
            ),
          ),
          // Right Arm Waving Up
          Positioned(
            right: size * 0.08,
            top: size * 0.42,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: size * 0.16,
                height: size * 0.24,
                decoration: BoxDecoration(
                  color: bearBrown,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lineBorder, width: 3),
                ),
              ),
            ),
          ),
          // Head Main Base
          Positioned(
            top: size * 0.18,
            child: Container(
              width: size * 0.72,
              height: size * 0.60,
              decoration: BoxDecoration(
                color: bearBrown,
                borderRadius: BorderRadius.circular(70),
                border: Border.all(color: lineBorder, width: 3),
              ),
              child: Stack(
                children: [
                  // Eyes
                  Positioned(left: size * 0.18, top: size * 0.16, child: _buildEye(size)),
                  Positioned(right: size * 0.18, top: size * 0.16, child: _buildEye(size)),
                  // Cheeks Spiral Swirls
                  Positioned(left: size * 0.08, top: size * 0.24, child: _buildCheek(size)),
                  Positioned(right: size * 0.08, top: size * 0.24, child: _buildCheek(size)),
                  // Snout Panel
                  Positioned(
                    bottom: size * 0.10,
                    left: size * 0.22,
                    right: size * 0.22,
                    child: Container(
                      height: size * 0.20,
                      decoration: BoxDecoration(color: innerTan, borderRadius: BorderRadius.circular(24)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Bear Nose
                          Positioned(
                            top: 4,
                            child: Container(
                              width: size * 0.08,
                              height: size * 0.05,
                              decoration: BoxDecoration(color: lineBorder, borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          // Round Pacifier
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: size * 0.11,
                              height: size * 0.11,
                              decoration: BoxDecoration(
                                color: pacifierBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: lineBorder, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: lineBorder.withOpacity(0.15),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: size * 0.04,
                                height: size * 0.04,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye(double size) {
    return Container(
      width: size * 0.06,
      height: size * 0.09,
      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(2),
      child: Container(width: size * 0.02, height: size * 0.02, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
    );
  }

  Widget _buildCheek(double size) {
    return Container(
      width: size * 0.12,
      height: size * 0.12,
      decoration: BoxDecoration(color: const Color(0xFFEF9A9A).withOpacity(0.6), shape: BoxShape.circle),
      child: Icon(Icons.gesture_rounded, size: size * 0.08, color: const Color(0xFFC62828).withOpacity(0.3)),
    );
  }
}

// ── Status Banner ──────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final SensorReading? reading;
  final Animation<double> pulse;
  final bool isAlert;
  final Color statusColor;
  final Color brightYellow;
  final Color panelBg;
  final Color textDark;
  final Color textMuted;

  const _StatusBanner({
    required this.reading,
    required this.pulse,
    required this.isAlert,
    required this.statusColor,
    required this.brightYellow,
    required this.panelBg,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: isAlert ? pulse : const AlwaysStoppedAnimation(1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brightYellow.withOpacity(0.5), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Center(
                child: Text(
                  reading == null ? '😴' : isAlert ? '🍼' : '👼',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reading == null ? 'Syncing...' : isAlert ? 'Attention Required!' : 'Sound Asleep',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  Text(
                    reading == null ? 'Connecting data stream' : reading!.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
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
  final Color    panelBg;

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
    required this.panelBg,
  });

  double get progress {
    final range = maxVal - minVal;
    return ((currentVal - (minVal - range * 0.25)) / (range * 1.5)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: textMuted)),
              const Spacer(),
              Text(sublabel, style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w700, color: textDark)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.15),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seamless Aesthetic Quote Carousel Container ──────────────────────────────
class _AestheticBeeQuoteView extends StatelessWidget {
  final List<String> quotes;
  final Color textDark;

  const _AestheticBeeQuoteView({
    required this.quotes,
    required this.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: PageView.builder(
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flying left bee with dynamic trailing dots and heart decoration path
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🐝', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 2),
                    Text(
                      '..·💛·....·💛·....·💛·....·💛·....·💛·..',
                      style: GoogleFonts.quicksand(
                        fontSize: 12, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.amber
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Aesthetic large floating quote body
                Expanded(
                  child: Text(
                    quotes[index],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comfortaa(
                      fontSize: 15, // Significantly larger, clean, round text
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Right watching bee decoration anchor
                const Text('..·💛·....·💛·....·💛·....·💛·....·💛·..🐝', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── History Chart ──────────────────────────────────────────────────────────────
class _HistoryChart extends StatelessWidget {
  final Color textMuted;
  final Color panelBg;
  final Color bgLight;
  final Color tempColor;
  final Color humColor;

  const _HistoryChart({
    required this.textMuted,
    required this.panelBg,
    required this.bgLight,
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
            decoration: BoxDecoration(color: panelBg, borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text('Aggregating statistics... 🧸', style: GoogleFonts.quicksand(color: textMuted, fontWeight: FontWeight.w600))),
          );
        }

        final tempSpots = readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList();
        final humSpots = readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.humidity)).toList();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: panelBg, borderRadius: BorderRadius.circular(20)),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: bgLight, strokeWidth: 1.5)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: GoogleFonts.quicksand(fontSize: 9, fontWeight: FontWeight.w700, color: textMuted)),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                _line(tempSpots, tempColor),
                _line(humSpots, humColor),
              ],
            ),
          ),
        );
      },
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: color.withOpacity(0.03)),
      );
}

