# camera_stream.py
# Rulează pe Raspberry Pi
# pip install aiortc opencv-python firebase-admin
 
import asyncio
import json
import cv2
import firebase_admin
from firebase_admin import credentials, db
from aiortc import RTCPeerConnection, RTCSessionDescription, VideoStreamTrack
from aiortc.contrib.media import MediaPlayer
from av import VideoFrame
import fractions
import time
 
# ─── Firebase ─────────────────────────────────────────────────────────────────
cred = credentials.Certificate("serviceAccountKey.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://smartnursery-iot-default-rtdb.firebaseio.com/'
    })
 
# ─── Camera Track ─────────────────────────────────────────────────────────────
class CameraTrack(VideoStreamTrack):
    """Captează frames de la camera conectată la Pi."""
 
    kind = "video"
 
    def __init__(self):
        super().__init__()
        # 0 = prima cameră USB / Camera Module
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH,  640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.cap.set(cv2.CAP_PROP_FPS, 15)
        self._timestamp = 0
 
    async def recv(self):
        pts, time_base = await self.next_timestamp()
        ret, frame = self.cap.read()
        if not ret:
            # Dacă camera nu răspunde, trimite frame negru
            frame = cv2.imencode('.jpg',
                __import__('numpy').zeros((480, 640, 3), dtype='uint8'))[1]
 
        # BGR → RGB pentru aiortc
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        video_frame = VideoFrame.from_ndarray(frame_rgb, format="rgb24")
        video_frame.pts      = pts
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
 
    # Creează offer
    offer = await pc.createOffer()
    await pc.setLocalDescription(offer)
 
    # Așteaptă ICE gathering
    await asyncio.sleep(2)
 
    # Trimite offer la Firebase
    offer_data = {
        'sdp':  pc.localDescription.sdp,
        'type': pc.localDescription.type,
        'active': True,
        'timestamp': {'.sv': 'timestamp'}
    }
    db.reference('baby_monitor/webrtc/offer').set(offer_data)
    print("✅ Offer trimis la Firebase. Aștept answer de la app...")
 
    # Ascultă answer de la Flutter app
    answer_ref = db.reference('baby_monitor/webrtc/answer')
 
    for _ in range(120):   # Așteaptă max 2 minute
        answer_data = answer_ref.get()
        if answer_data and answer_data.get('sdp'):
            print("📱 Answer primit de la app!")
            answer = RTCSessionDescription(
                sdp=answer_data['sdp'],
                type=answer_data['type']
            )
            await pc.setRemoteDescription(answer)
            print("🎥 Stream video activ! Apasă Ctrl+C pentru a opri.")
 
            # Ține conexiunea vie
            try:
                while True:
                    await asyncio.sleep(1)
            except KeyboardInterrupt:
                pass
            break
        await asyncio.sleep(1)
    else:
        print("⚠️  Timeout: niciun answer primit în 2 minute.")
 
    # Curăță
    camera.stop()
    await pc.close()
    db.reference('baby_monitor/webrtc/offer').update({'active': False})
    print("🛑 Stream oprit.")
 
if __name__ == "__main__":
    asyncio.run(run())