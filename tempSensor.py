import Adafruit_DHT
import time
import firebase_admin
from firebase_admin import credentials, db

# ─── Firebase Initialization ───────────────────────────────────────────────────
# Download your serviceAccountKey.json from Firebase Console:
# Project Settings → Service Accounts → Generate New Private Key
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://smartnursery-iot-53f11-default-rtdb.firebaseio.com/'
})

# ─── DHT11 Configuration ───────────────────────────────────────────────────────
DHT_SENSOR = Adafruit_DHT.DHT11
DHT_PIN    = 4          # GPIO 4 (Pin 7 on the board)

# ─── Safe ranges for a baby's environment ─────────────────────────────────────
TEMP_MIN =  18.0        # °C  — below this is too cold
TEMP_MAX =  22.0        # °C  — above this is too warm
HUM_MIN  =  40.0        # %   — below this is too dry
HUM_MAX  =  60.0        # %   — above this is too humid

POLL_INTERVAL = 10      # seconds between readings

def classify(temperature, humidity):
    """Return a status string and human-readable alert message."""
    issues = []
    if temperature is not None:
        if temperature < TEMP_MIN:
            issues.append(f"Temperature too LOW ({temperature:.1f}°C < {TEMP_MIN}°C)")
        elif temperature > TEMP_MAX:
            issues.append(f"Temperature too HIGH ({temperature:.1f}°C > {TEMP_MAX}°C)")

    if humidity is not None:
        if humidity < HUM_MIN:
            issues.append(f"Humidity too LOW ({humidity:.1f}% < {HUM_MIN}%)")
        elif humidity > HUM_MAX:
            issues.append(f"Humidity too HIGH ({humidity:.1f}% > {HUM_MAX}%)")

    if issues:
        return "ALERT", " | ".join(issues)
    return "OK", "Environment is safe for baby"

def push_to_firebase(temperature, humidity, status, message):
    """Write a timestamped reading to Firebase Realtime Database."""
    ref = db.reference('baby_monitor/readings')
    ref.push({
        'temperature': temperature,
        'humidity':    humidity,
        'status':      status,
        'message':     message,
        'timestamp':   {'.sv': 'timestamp'}   # server-side Unix ms
    })

    # Also keep a 'latest' node so the app can query a single location
    db.reference('baby_monitor/latest').set({
        'temperature': temperature,
        'humidity':    humidity,
        'status':      status,
        'message':     message,
        'timestamp':   {'.sv': 'timestamp'}
    })

def main():
    print("Baby Monitor – DHT11 sensor started")
    print(f"Safe range → Temp: {TEMP_MIN}–{TEMP_MAX} °C | Humidity: {HUM_MIN}–{HUM_MAX} %")
    print("-" * 60)

    while True:
        humidity, temperature = Adafruit_DHT.read_retry(DHT_SENSOR, DHT_PIN)

        if humidity is not None and temperature is not None:
            status, message = classify(temperature, humidity)
            push_to_firebase(temperature, humidity, status, message)

            icon = "✅" if status == "OK" else "⚠️ "
            print(f"{icon}  Temp: {temperature:.1f} °C  |  Humidity: {humidity:.1f}%  |  {message}")
        else:
            print("⚠️  Failed to read from DHT11 sensor – retrying …")

        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()