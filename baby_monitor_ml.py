# baby_monitor_ml.py
# Runs on Raspberry Pi alongside camerasensor.py
# pip install mediapipe opencv-python firebase-admin numpy
 
import cv2
import numpy as np
import mediapipe as mp
import firebase_admin
from firebase_admin import credentials, db
import time
import math
 
# ─── Firebase ──────────────────────────────────────────────────────────────────
if not firebase_admin._apps:
    cred = credentials.Certificate("a.json")
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://smartnursery-iot-default-rtdb.firebaseio.com/'
    })
 
alert_ref  = db.reference('baby_monitor/ml_alert')
pose_ref   = db.reference('baby_monitor/pose_status')
 
# ─── MediaPipe Setup ───────────────────────────────────────────────────────────
mp_pose    = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils
 
# ─── Landmark indices we care about ───────────────────────────────────────────
# Full list: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker
NOSE          = 0
LEFT_EYE      = 2
RIGHT_EYE     = 5
LEFT_EAR      = 7
RIGHT_EAR     = 8
LEFT_SHOULDER = 11
RIGHT_SHOULDER= 12
LEFT_HIP      = 23
RIGHT_HIP     = 24
LEFT_KNEE     = 25
RIGHT_KNEE    = 26
LEFT_ANKLE    = 27
RIGHT_ANKLE   = 28
 
# ─── Danger thresholds ────────────────────────────────────────────────────────
# These were tuned by observing MediaPipe output on baby-in-crib footage.
# Adjust if your camera angle is very different.
PRONE_VISIBILITY_THRESHOLD  = 0.35   # face landmarks below this = face down
ROLL_ANGLE_THRESHOLD        = 40     # degrees from vertical = rolled to side
MOTIONLESS_SECONDS          = 20     # seconds without movement = no motion alert
MOTION_PIXEL_THRESHOLD      = 800    # pixel diff to count as movement
 
# ─── Pose Classifier ──────────────────────────────────────────────────────────
class BabyPoseClassifier:
    """
    Classifies baby position into:
      SAFE      – on back, face visible
      PRONE     – face down (highest danger, SIDS risk)
      SIDE      – rolled to side (medium danger)
      NO_MOTION – no movement detected for N seconds
      UNKNOWN   – landmarks not visible enough
    """
 
    def __init__(self):
        self._last_motion_time  = time.time()
        self._prev_gray         = None
        self._alert_cooldown    = 0   # seconds before re-alerting
        self._last_alert_time   = 0
 
    # ── Motion detection via frame differencing ────────────────────────────
    def _detect_motion(self, frame_gray: np.ndarray) -> bool:
        if self._prev_gray is None:
            self._prev_gray = frame_gray
            return True
        diff  = cv2.absdiff(self._prev_gray, frame_gray)
        moved = int(np.sum(diff > 25)) > MOTION_PIXEL_THRESHOLD
        self._prev_gray = frame_gray
        if moved:
            self._last_motion_time = time.time()
        return moved
 
    # ── Angle between three landmarks (degrees) ────────────────────────────
    @staticmethod
    def _angle(a, b, c) -> float:
        """Angle at point b formed by a-b-c."""
        ba = np.array([a.x - b.x, a.y - b.y])
        bc = np.array([c.x - b.x, c.y - b.y])
        cos = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
        return math.degrees(math.acos(np.clip(cos, -1, 1)))
 
    # ── Main classify ──────────────────────────────────────────────────────
    def classify(self, landmarks, frame_gray: np.ndarray) -> dict:
        motion = self._detect_motion(frame_gray)
        seconds_still = time.time() - self._last_motion_time
 
        if landmarks is None:
            return {
                'position': 'UNKNOWN',
                'danger':   False,
                'message':  'Baby not detected in frame',
                'seconds_still': int(seconds_still),
            }
 
        lm = landmarks.landmark
 
        # ── 1. PRONE detection ─────────────────────────────────────────────
        # When baby is face-down, nose / eyes / ears all have very low
        # visibility scores because they're hidden from the camera.
        face_visibility = (
            lm[NOSE].visibility +
            lm[LEFT_EYE].visibility +
            lm[RIGHT_EYE].visibility +
            lm[LEFT_EAR].visibility +
            lm[RIGHT_EAR].visibility
        ) / 5.0
 
        if face_visibility < PRONE_VISIBILITY_THRESHOLD:
            return {
                'position': 'PRONE',
                'danger':   True,
                'message':  '🚨 Baby face-down! Turn baby immediately.',
                'seconds_still': int(seconds_still),
            }
 
        # ── 2. SIDE ROLL detection ─────────────────────────────────────────
        # Compare shoulder midpoint y vs hip midpoint y.
        # When lying on back both are roughly same y.
        # When rolled, one shoulder is much higher than the other.
        ls, rs = lm[LEFT_SHOULDER], lm[RIGHT_SHOULDER]
        lh, rh = lm[LEFT_HIP],      lm[RIGHT_HIP]
 
        shoulder_diff = abs(ls.y - rs.y)   # normalised coords [0,1]
        hip_diff      = abs(lh.y - rh.y)
 
        # shoulder_diff > 0.15 in normalised coords ≈ strongly rolled
        if shoulder_diff > 0.15 or hip_diff > 0.15:
            return {
                'position': 'SIDE',
                'danger':   True,
                'message':  '⚠️ Baby rolled to side — check position.',
                'seconds_still': int(seconds_still),
            }
 
        # ── 3. NO MOTION detection ─────────────────────────────────────────
        if seconds_still >= MOTIONLESS_SECONDS:
            return {
                'position': 'NO_MOTION',
                'danger':   True,
                'message':  f'⚠️ No movement for {int(seconds_still)}s — check baby.',
                'seconds_still': int(seconds_still),
            }
 
        # ── 4. SAFE ────────────────────────────────────────────────────────
        return {
            'position': 'SAFE',
            'danger':   False,
            'message':  '✅ Baby position safe.',
            'seconds_still': int(seconds_still),
        }
 
    # ── Should we push a Firebase alert? ──────────────────────────────────
    def should_alert(self, result: dict) -> bool:
        if not result['danger']:
            return False
        now = time.time()
        # Re-alert every 30 seconds max to avoid spam
        if now - self._last_alert_time > 30:
            self._last_alert_time = now
            return True
        return False
 
 
# ─── Main loop ────────────────────────────────────────────────────────────────
def main():
    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH,  640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    cap.set(cv2.CAP_PROP_FPS, 15)
 
    if not cap.isOpened():
        print("❌ Camera not found. Check connection.")
        return
 
    classifier = BabyPoseClassifier()
 
    # MediaPipe Pose — use lite model for Pi performance
    with mp_pose.Pose(
        model_complexity=0,          # 0=Lite, 1=Full, 2=Heavy — use 0 on Pi
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
        static_image_mode=False,
    ) as pose:
 
        print("🍼 Baby monitor ML started. Press Ctrl+C to stop.")
        last_firebase_push = 0
 
        while True:
            ret, frame = cap.read()
            if not ret:
                print("⚠️  Frame read failed, retrying...")
                time.sleep(0.1)
                continue
 
            frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
 
            # MediaPipe needs RGB
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frame_rgb.flags.writeable = False
            results = pose.process(frame_rgb)
            frame_rgb.flags.writeable = True
 
            # Classify
            result = classifier.classify(results.pose_landmarks, frame_gray)
 
            # Print to console
            print(
                f"[{result['position']}] {result['message']} "
                f"| still: {result['seconds_still']}s"
            )
 
            # Push to Firebase every 3 seconds (avoid hammering)
            now = time.time()
            if now - last_firebase_push > 3:
                last_firebase_push = now
                pose_ref.set({
                    'position':      result['position'],
                    'danger':        result['danger'],
                    'message':       result['message'],
                    'seconds_still': result['seconds_still'],
                    'timestamp':     {'.sv': 'timestamp'},
                })
 
            # Push alert if dangerous
            if classifier.should_alert(result):
                alert_ref.set({
                    'active':    True,
                    'position':  result['position'],
                    'message':   result['message'],
                    'timestamp': {'.sv': 'timestamp'},
                })
                print(f"🚨 ALERT pushed to Firebase: {result['message']}")
 
            # Optional: draw landmarks on frame for local debug
            # Uncomment if you have a monitor connected to the Pi
            # if results.pose_landmarks:
            #     mp_drawing.draw_landmarks(
            #         frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
            # cv2.imshow('Baby Monitor ML', frame)
            # if cv2.waitKey(1) & 0xFF == ord('q'):
            #     break
 
    cap.release()
    print("🛑 ML monitor stopped.")
 
 
if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n🛑 Stopped by user.")