// lib/services/webrtc_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  WebRTCService._();
  static final WebRTCService instance = WebRTCService._();

  RTCPeerConnection? _pc;
  final _remoteRenderer = RTCVideoRenderer();
  bool _rendererInitialized = false;

  final _stateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get stateStream => _stateController.stream;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  final _offerRef = FirebaseDatabase.instance.ref('baby_monitor/webrtc/offer');
  final _answerRef =
      FirebaseDatabase.instance.ref('baby_monitor/webrtc/answer');
  // Flutter → Pi
  final _flutterIceRef =
      FirebaseDatabase.instance.ref('baby_monitor/webrtc/ice_candidates');
  // Pi → Flutter
  final _piIceRef =
      FirebaseDatabase.instance.ref('baby_monitor/webrtc/pi_ice_candidates');

  Future<void> initRenderer() async {
    if (!_rendererInitialized) {
      await _remoteRenderer.initialize();
      _rendererInitialized = true;
    }
  }

  Future<void> connect() async {
    await initRenderer();
    await _cleanup();

    // 1. Read offer from Firebase
    final snap = await _offerRef.get();
    final data = snap.value as Map?;
    if (data == null || data['sdp'] == null || data['active'] != true) {
      throw Exception(
          'No active offer from Raspberry Pi. Is the camera running?');
    }

    // 2. Create peer connection
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    // 3. Attach remote track → renderer
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    // 4. Track connection state
    _pc!.onConnectionState = (state) {
      _stateController.add(state);
    };

    // 5. Send our ICE candidates to Firebase (Flutter → Pi)
    _pc!.onIceCandidate = (candidate) async {
      await _flutterIceRef.push().set({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // 6. Set remote description (Pi's offer)
    await _pc!.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type']));

    // 7. Create & set local answer
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    // 8. Push answer to Firebase
    await _answerRef.set({
      'sdp': answer.sdp,
      'type': answer.type,
    });

    // 9. Read Pi's ICE candidates and add them (Pi → Flutter)
    await Future.delayed(const Duration(seconds: 3));
    final piCandidatesSnap = await _piIceRef.get();
    final piCandidates = piCandidatesSnap.value as Map?;
    if (piCandidates != null) {
      for (final entry in piCandidates.values) {
        final c = entry as Map;
        try {
          await _pc!.addCandidate(RTCIceCandidate(
            c['candidate'],
            c['sdpMid'],
            c['sdpMLineIndex'],
          ));
        } catch (e) {
          // ignore invalid candidates
        }
      }
    }

    // 10. Also listen for new Pi ICE candidates in real-time
    _piIceRef.onChildAdded.listen((event) async {
      final c = event.snapshot.value as Map?;
      if (c == null) return;
      try {
        await _pc!.addCandidate(RTCIceCandidate(
          c['candidate'],
          c['sdpMid'],
          c['sdpMLineIndex'],
        ));
      } catch (_) {}
    });
  }

  Future<void> disconnect() async {
    await _answerRef.remove();
    await _flutterIceRef.remove();
    await _piIceRef.remove();
    await _cleanup();
  }

  Future<void> _cleanup() async {
    await _pc?.close();
    _pc = null;
    _remoteRenderer.srcObject = null;
  }

  void dispose() {
    _cleanup();
    _remoteRenderer.dispose();
    _stateController.close();
  }
}
