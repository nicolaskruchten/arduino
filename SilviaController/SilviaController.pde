#include <Wire.h>
#include <TypeK.h>
#include <WiShield.h>
#include "TempSensor.h"
#include "WifiConfig.h"


// This is the webpage that is served up by the webserver
const prog_char webpage[] PROGMEM = {"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"};


TempSensor ts;
unsigned long int nextUpdate = 0;

float temp = 0; //last recorded temperature value
float ambient = 0; //last recorded ambient value
float setpoint = 0; //target temperature
unsigned long int lastStart = 0; //last time controller was activated

void setup()
{
  Serial.begin(9600);
  ts.init();
  WiFi.init();
  Serial.println("Wifi active");
  nextUpdate = millis();
  lastStart = millis();
}

 
void loop()
{
  if(millis() > nextUpdate)
  {
    //check the temperature
    ts.update();
    temp = ts.temp*0.01;
    ambient = ts.avgamb*0.01;
    Serial.print(millis() / 1000.0, 2);
    Serial.print(",");
    Serial.print( ambient, 2 );
    Serial.print(",");
    Serial.print( temp, 2 );
    Serial.println();
    
    nextUpdate += 300;
    
    //control the temperature
  }
  
  //turn things off after an hour
  if(millis() > lastStart+1000*60*60)
  {
      setpoint = 0;
  }
  
  //let the web server do its thing
  WiFi.run();
}



