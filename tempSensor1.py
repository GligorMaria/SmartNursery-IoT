import time
import board
import adafruit_dht
import pyrebase
import random

dhtDevice = adafruit_dht.DHT11(board.D23)

config={
    "apiKey": "AIzaSyDFzm096rCdu-7XNLLLMGRPAYnNkFiVf2M",
    "authDomain": "lab3-6a618.firebaseapp.com",
    "databaseURL": "https://lab3-6a618-default-rtdb.firebaseio.com",
    "storageBucket": "lab3-6a618.firebasestorage.app"
};

firebase=pyrebase.initialize_app(config)

db=firebase.database()

while True:
    try:
        # Print the values to the serial port
        temperature_c = dhtDevice.temperature
        temperature_f = temperature_c * (9 / 5) + 32
        humidity = dhtDevice.humidity
        print(f"Temp: {temperature_f} F / {temperature_c} C    Humidity: {humidity}% ")
        
        data={
            "Temperature": temperature_c,
            "Humidity": humidity
            }
        db.child("Status").push(data)
        
        db.update(data)
        print("Sent to FireBase")

    except RuntimeError as error:
        # Errors happen fairly often, DHT's are hard to read, just keep going
        print(error.args[0])
        time.sleep(5.0)
        continue
    except Exception as error:
        dhtDevice.exit()
        raise error

    time.sleep(5.0)
