// lib/widgets/pose_status_card.dart
// Add this widget to your HomeScreen's SliverList, below the metric cards.
//
// Usage in home_screen.dart:
//   import '../widgets/pose_status_card.dart';
//   ...
//   const SizedBox(height: 20),
//   const PoseStatusCard(),

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pose_status.dart';
import '../services/database_service.dart';

class PoseStatusCard extends StatelessWidget {
  const PoseStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PoseStatus?>(
      stream: DatabaseService.instance.poseStream,
      builder: (context, snap) {
        final pose = snap.data;

        // ── Loading / ML not running ───────────────────────────────────────
        if (pose == null) {
          return _card(
            color: const Color(0xFFB0BEC5),
            icon: Icons.model_training_rounded,
            title: 'Movement detection offline',
            subtitle: 'Start baby_monitor_ml.py on the Pi',
            onClear: null,
          );
        }

        final color = _colorFor(pose.position);

        return _card(
          color: color,
          icon: _iconFor(pose.position),
          title: _titleFor(pose.position),
          subtitle: pose.message,
          isCritical: pose.isCritical,
          onClear: pose.danger
              ? () => DatabaseService.instance.clearMlAlert()
              : null,
          extra: pose.secondsStill > 5
              ? 'Still for ${pose.secondsStill}s'
              : null,
        );
      },
    );
  }

  Widget _card({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isCritical = false,
    String? extra,
    VoidCallback? onClear,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(isCritical ? 0.9 : 0.4),
          width: isCritical ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🍼 Movement',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFF8FA3B1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (extra != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          extra,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF5A7188),
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.check_circle_outline_rounded),
              color: color,
              tooltip: 'Mark as checked',
            ),
          ],
        ],
      ),
    );
  }

  Color _colorFor(String position) {
    switch (position) {
      case 'PRONE':     return const Color(0xFFE53935); // red
      case 'SIDE':      return const Color(0xFFFF8F00); // amber
      case 'NO_MOTION': return const Color(0xFF5C6BC0); // indigo
      case 'SAFE':      return const Color(0xFF4CAF7D); // green
      default:          return const Color(0xFFB0BEC5); // grey
    }
  }

  IconData _iconFor(String position) {
    switch (position) {
      case 'PRONE':     return Icons.warning_rounded;
      case 'SIDE':      return Icons.rotate_90_degrees_ccw_rounded;
      case 'NO_MOTION': return Icons.pause_circle_outline_rounded;
      case 'SAFE':      return Icons.child_care_rounded;
      default:          return Icons.help_outline_rounded;
    }
  }

  String _titleFor(String position) {
    switch (position) {
      case 'PRONE':     return 'Face-down detected!';
      case 'SIDE':      return 'Rolled to side';
      case 'NO_MOTION': return 'No movement';
      case 'SAFE':      return 'Position safe';
      default:          return 'Detecting...';
    }
  }
}