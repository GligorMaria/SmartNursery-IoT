// lib/screens/camera_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'camera_screen.dart';
import '../services/webrtc_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _svc = WebRTCService.instance;
  _ConnState _connState = _ConnState.idle;
  String? _error;

  @override
  void initState() {
    super.initState();
    _svc.initRenderer().then((_) => _connect());

    _svc.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _connState = _ConnState.connected;
            _error = null;
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _connState = _ConnState.error;
            _error = 'Connection lost. Tap retry.';
            break;
          default:
            break;
        }
      });
    });
  }

  Future<void> _connect() async {
    setState(() { _connState = _ConnState.connecting; _error = null; });
    try {
      await _svc.connect();
      // connected state set via stateStream listener above
    } catch (e) {
      if (mounted) setState(() {
        _connState = _ConnState.error;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _svc.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('📷 Live Camera',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        actions: [
          if (_connState != _ConnState.connecting)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reconnect',
              onPressed: _connect,
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Video ──────────────────────────────────────────────────────────
          if (_connState == _ConnState.connected)
            RTCVideoView(
              _svc.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),

          // ── Overlay states ────────────────────────────────────────────────
          if (_connState != _ConnState.connected)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_connState == _ConnState.connecting) ...[
                      const CircularProgressIndicator(color: Color(0xFF7EC8C8)),
                      const SizedBox(height: 20),
                      Text('Connecting to camera…',
                          style: GoogleFonts.nunito(
                              color: Colors.white70, fontSize: 16)),
                    ] else ...[
                      const Icon(Icons.videocam_off_rounded,
                          color: Color(0xFFE57373), size: 56),
                      const SizedBox(height: 16),
                      Text(_error ?? 'Camera unavailable',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                              color: Colors.white70, fontSize: 15)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _connect,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7EC8C8),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // ── "LIVE" badge ───────────────────────────────────────────────────
          if (_connState == _ConnState.connected)
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 8),
                    const SizedBox(width: 4),
                    Text('LIVE',
                        style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _ConnState { idle, connecting, connected, error }