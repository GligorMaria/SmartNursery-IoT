# camerasensor.py
# Rulează pe Raspberry Pi
# pip install aiortc opencv-python firebase-admin av numpy

import asyncio
import cv2
import firebase_admin
from firebase_admin import credentials, db
from aiortc import RTCPeerConnection, RTCSessionDescription, VideoStreamTrack
from av import VideoFrame
import numpy as np

# ─── Firebase ─────────────────────────────────────────────────────────────────
cred = credentials.Certificate("a.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://smartnursery-iot-53f11-default-rtdb.firebaseio.com/'
    })

# ─── Camera Track ─────────────────────────────────────────────────────────────
class CameraTrack(VideoStreamTrack):
    """Captează frames de la camera conectată la Pi."""

    kind = "video"

    def __init__(self):
        super().__init__()
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH,  640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.cap.set(cv2.CAP_PROP_FPS, 15)

        if not self.cap.isOpened():
            print("⚠️  Camera not found on /dev/video0 — sending black frames")

    async def recv(self):
        pts, time_base = await self.next_timestamp()

        ret, frame = self.cap.read()
        if not ret:
            # ← fix: this line was wrongly dedented outside the if block
            frame = np.zeros((480, 640, 3), dtype=np.uint8)

        # BGR → RGB for aiortc
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        video_frame = VideoFrame.from_ndarray(frame_rgb, format="rgb24")
        video_frame.pts       = pts
        video_frame.time_base = time_base
        return video_frame

    def stop(self):
        self.cap.release()
        super().stop()

# ─── WebRTC Signaling ─────────────────────────────────────────────────────────
async def run():
    pc = RTCPeerConnection()
    camera = CameraTrack()
    pc.addTrack(camera)

    print("📷 Camera pornită. Se creează WebRTC offer...")

    # Create offer
    offer = await pc.createOffer()
    await pc.setLocalDescription(offer)

    # Wait for ICE gathering to complete
    await asyncio.sleep(2)

    # Push offer to Firebase
    offer_data = {
        'sdp':       pc.localDescription.sdp,
        'type':      pc.localDescription.type,
        'active':    True,
        'timestamp': {'.sv': 'timestamp'},
    }
    db.reference('baby_monitor/webrtc/offer').set(offer_data)
    print("✅ Offer trimis la Firebase. Aștept answer de la app...")

    # Poll for answer from Flutter app
    answer_ref = db.reference('baby_monitor/webrtc/answer')

    for _ in range(120):   # wait up to 2 minutes
        answer_data = answer_ref.get()
        if answer_data and answer_data.get('sdp'):
            print("📱 Answer primit de la app!")
            answer = RTCSessionDescription(
                sdp=answer_data['sdp'],
                type=answer_data['type'],
            )
            await pc.setRemoteDescription(answer)
            print("🎥 Stream video activ! Apasă Ctrl+C pentru a opri.")

            try:
                while True:
                    await asyncio.sleep(1)
            except KeyboardInterrupt:
                pass
            break
        await asyncio.sleep(1)
    else:
        print("⚠️  Timeout: niciun answer primit în 2 minute.")

    # Cleanup
    camera.stop()
    await pc.close()
    db.reference('baby_monitor/webrtc/offer').update({'active': False})
    print("🛑 Stream oprit.")

if __name__ == "__main__":
    asyncio.run(run())
