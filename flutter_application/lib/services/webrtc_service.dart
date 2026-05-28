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

  // Stream so the UI can react to connection state changes
  final _stateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get stateStream => _stateController.stream;

  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  final _offerRef  = FirebaseDatabase.instance.ref('baby_monitor/webrtc/offer');
  final _answerRef = FirebaseDatabase.instance.ref('baby_monitor/webrtc/answer');
  final _iceCandidatesRef =
      FirebaseDatabase.instance.ref('baby_monitor/webrtc/ice_candidates');

  // ── Init renderer ──────────────────────────────────────────────────────────
  Future<void> initRenderer() async {
    if (!_rendererInitialized) {
      await _remoteRenderer.initialize();
      _rendererInitialized = true;
    }
  }

  // ── Connect: read offer → create answer → exchange ICE ───────────────────
  Future<void> connect() async {
    await initRenderer();
    await _cleanup(); // close any previous connection

    // 1. Read offer from Firebase
    final snap = await _offerRef.get();
    final data = snap.value as Map?;
    if (data == null || data['sdp'] == null || data['active'] != true) {
      throw Exception('No active offer from Raspberry Pi. Is the camera running?');
    }

    // 2. Create peer connection
    _pc = await createPeerConnection({
      'iceServers': [
        // STUN for NAT traversal — works on the same LAN too
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

    // 5. Send our ICE candidates to Firebase so the Pi can reach us
    _pc!.onIceCandidate = (candidate) async {
      await _iceCandidatesRef.push().set({
        'candidate':     candidate.candidate,
        'sdpMid':        candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // 6. Set remote description (Pi's offer)
    final offer = RTCSessionDescription(data['sdp'], data['type']);
    await _pc!.setRemoteDescription(offer);

    // 7. Create & set local description (our answer)
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    // 8. Push answer to Firebase
    await _answerRef.set({
      'sdp':  answer.sdp,
      'type': answer.type,
    });
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    await _answerRef.remove();
    await _iceCandidatesRef.remove();
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