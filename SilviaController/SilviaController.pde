#include <Wire.h>
#include <TypeK.h>
#include <WiShield.h>
#include "TempSensor.h"
#include "WifiConfig.h"



TempSensor ts;
unsigned long int nextUpdate = 0;

float temp = 0; //last recorded temperature value
float ambient = 0; //last recorded ambient value
float setpoint = 100.0; //target temperature
int val = 0;
unsigned long int lastStart = 0; //last time controller was activated

void setup()
{
  pinMode(9, OUTPUT);
  analogWrite(9, 255);
  lastStart = millis();
  Serial.begin(9600);
  ts.init();
  WiFi.init();
  Serial.println("Wifi active");
  nextUpdate = millis();
}

 
void loop()
{
  if(millis() > nextUpdate)
  {
    nextUpdate += 300;
    //check the temperature
    ts.update();
    temp = ts.temp*0.01;
    ambient = ts.avgamb*0.01;
    
    //control the temperature
    float error = setpoint - temp;
    val = error * 10; // val = 255 when temp is 25.5 degC below setpoint or less...
    if(val < 0) { val = 0; }
    if(val > 255) { val = 255; }
    analogWrite(9, val);
    
    serialDump();
  }
  
  //turn things off after an hour
  if(millis() > lastStart+1000*60*60)
  {
      setpoint = 0;
  }
  
  //let the web server do its thing
  WiFi.run();
}

void serialDump()
{
    Serial.print(millis() / 1000.0, 2);
    Serial.print(",");
    Serial.print( ambient, 2 );
    Serial.print(",");
    Serial.print( temp, 2 );
    Serial.print(",");
    Serial.print(val);
    Serial.print(",");
    Serial.print(setpoint);
    Serial.println();
}

