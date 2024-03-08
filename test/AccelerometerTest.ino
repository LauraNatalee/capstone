//  File:  demoAccellFeathernRF52.ino
//
//  Demonstrate use of accelerometer data on an Adafruit Feather nRF52840 Sense
//  Read the accelerometer, gyro and internal temperature data.  Print the
//  accelerometer data to the Serial object so that it can be displayed as
//  text in the Serial Monitor or as a continuous plot in the Serial Plotter
//
//  Adapted from feather_sense_sensor_demo.ino from Adafruit

#include <Adafruit_LSM6DS33.h>    // Library for support of LSM6DS33 chip
#include <Adafruit_LSM6DS3TRC.h>
//Adafruit_LSM6DS33 accelerometer;  // Create an accelerometer object
Adafruit_LSM6DS3TRC accelerometer;

// --------------------------------------------------------------------------------
void setup() 
{
  Serial.begin(115200);
  accelerometer.begin_I2C();        //  Start the I2C interface to the sensors
}

// --------------------------------------------------------------------------------
void loop() 
{
  float ax, ay, az, gx, gy, gz;
  sensors_event_t accel, gyro, temp;

  accelerometer.getEvent(&accel, &gyro, &temp);  //  get the data

  Serial.print("ax: ");     Serial.print(accel.acceleration.x);    //  Print plain data so that
  Serial.print("  ay: ");   Serial.print(accel.acceleration.y);    //  Serial Plotter can be used
  Serial.print("  az: ");   Serial.println(accel.acceleration.z);

  Serial.print("gx: ");     Serial.print(gyro.gyro.x);
  Serial.print("  gy: ");   Serial.print(gyro.gyro.y);  
  Serial.print("  gz: ");   Serial.println(gyro.gyro.z);
  Serial.print("t:  ");     Serial.println(temp.temperature);  Serial.println(" ");

  delay(50);                   //  Arbitrary delay to slow down display

  /*// serial plotter friendly format

  Serial.print(temp.temperature);
  Serial.print(",");

  Serial.print(accel.acceleration.x);
  Serial.print(","); Serial.print(accel.acceleration.y);
  Serial.print(","); Serial.print(accel.acceleration.z);
  Serial.print(",");

  Serial.print(gyro.gyro.x);
  Serial.print(","); Serial.print(gyro.gyro.y);
  Serial.print(","); Serial.print(gyro.gyro.z);
  Serial.println();
  delayMicroseconds(10000);*/
}