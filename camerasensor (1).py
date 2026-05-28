# camerasensor.py
import asyncio
import cv2
import firebase_admin
from firebase_admin import credentials, db
from aiortc import RTCPeerConnection, RTCSessionDescription, RTCIceCandidate, VideoStreamTrack
from av import VideoFrame
import numpy as np

cred = credentials.Certificate("a.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://smartnursery-iot-53f11-default-rtdb.firebaseio.com/'
    })

class CameraTrack(VideoStreamTrack):
    kind = "video"

    def __init__(self):
        super().__init__()
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH,  640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.cap.set(cv2.CAP_PROP_FPS, 15)
        if not self.cap.isOpened():
            print("⚠️  Camera not found — sending black frames")

    async def recv(self):
        pts, time_base = await self.next_timestamp()
        ret, frame = self.cap.read()
        if not ret:
            frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        video_frame = VideoFrame.from_ndarray(frame_rgb, format="rgb24")
        video_frame.pts       = pts
        video_frame.time_base = time_base
        return video_frame

    def stop(self):
        self.cap.release()
        super().stop()

async def run():
    pc = RTCPeerConnection()
    camera = CameraTrack()
    pc.addTrack(camera)

    ice_ref = db.reference('baby_monitor/webrtc/pi_ice_candidates')
    flutter_ice_ref = db.reference('baby_monitor/webrtc/ice_candidates')

    # Send our ICE candidates to Firebase so Flutter can receive them
    @pc.on("icecandidate")
    async def on_ice_candidate(candidate):
        if candidate:
            ice_ref.push({
                'candidate':     candidate.candidate,
                'sdpMid':        candidate.sdpMid,
                'sdpMLineIndex': candidate.sdpMLineIndex,
            })
            print(f"📡 ICE candidate sent: {candidate.candidate[:40]}...")

    print("📷 Camera pornită. Se creează WebRTC offer...")
    offer = await pc.createOffer()
    await pc.setLocalDescription(offer)

    # Wait for ICE gathering
    await asyncio.sleep(3)

    db.reference('baby_monitor/webrtc/offer').set({
        'sdp':       pc.localDescription.sdp,
        'type':      pc.localDescription.type,
        'active':    True,
        'timestamp': {'.sv': 'timestamp'},
    })
    print("✅ Offer trimis. Aștept answer...")

    answer_ref = db.reference('baby_monitor/webrtc/answer')

    # Wait for answer
    for _ in range(120):
        answer_data = answer_ref.get()
        if answer_data and answer_data.get('sdp'):
            print("📱 Answer primit!")
            await pc.setRemoteDescription(RTCSessionDescription(
                sdp=answer_data['sdp'],
                type=answer_data['type'],
            ))
            break
        await asyncio.sleep(1)
    else:
        print("⚠️  Timeout: niciun answer.")
        camera.stop()
        await pc.close()
        return

    # Read Flutter's ICE candidates and add them to our PC
    print("🔄 Citesc ICE candidates de la Flutter...")
    await asyncio.sleep(2)  # give Flutter time to push candidates

    flutter_candidates = flutter_ice_ref.get()
    if flutter_candidates:
        for key, c in flutter_candidates.items():
            try:
                candidate = RTCIceCandidate(
                    candidate=c['candidate'],
                    sdpMid=c.get('sdpMid'),
                    sdpMLineIndex=c.get('sdpMLineIndex'),
                )
                await pc.addIceCandidate(candidate)
                print(f"✅ ICE candidate adăugat de la Flutter")
            except Exception as e:
                print(f"⚠️  ICE candidate invalid: {e}")

    print("🎥 Stream activ! Ctrl+C pentru oprire.")
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        pass

    camera.stop()
    await pc.close()
    db.reference('baby_monitor/webrtc/offer').update({'active': False})
    print("🛑 Stream oprit.")

if __name__ == "__main__":
    asyncio.run(run())
