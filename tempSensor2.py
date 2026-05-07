import time
import board
import adafruit_dht
import boto3
import random

db= boto3.resource()
table=db.Table()




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
        print("Sent to AWS")

    except RuntimeError as error:
        # Errors happen fairly often, DHT's are hard to read, just keep going
        print(error.args[0])
        time.sleep(5.0)
        continue
    except Exception as error:
        dhtDevice.exit()
        raise error