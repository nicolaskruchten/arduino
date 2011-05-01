#include <WiServer.h>
#include <Wire.h>
#include <TypeK.h>
#include "TempSensor.h"
#include "WifiConfig.h"



TempSensor ts;
unsigned long int nextUpdate = 0;

float temp = 0; //last recorded temperature value
float ambient = 0; //last recorded ambient value
int val = 0;

class Setpoint {
  private:
    float setpoint;
    unsigned long int lastStart; //last time controller was activated
  public:
    Setpoint():setpoint(0.0), lastStart(0) {}
    
    void inc() {
      set(setpoint+1);
    };
    
    void dec() {
      set(setpoint-1);
    }
    
    void set(float s) {
      if(s-setpoint > 10) { lastStart = millis(); }
      setpoint = s;
      pinMode(9, s==0.0 ? INPUT : OUTPUT);
    }
    
    float value() { 
      if(getOnTime() > 60.0) { set(0.0); }
      return setpoint; 
    }
    float getOnTime() { return (millis() - lastStart) / (1000.0 * 60.0); }
};

Setpoint setpoint;

boolean handler(char* URL)
{
    // Check if the requested URL matches "/"
    if (URL[0] == '/') {
      
      WiServer.print("{\"url\":\"");
      WiServer.print(URL);
      if (strcmp(URL, "/start") == 0) {
        setpoint.set(99.0);
      }
      else if(strcmp(URL, "/stop") == 0) {
        setpoint.set(0.0);
      }
      else if(strcmp(URL, "/up") == 0) {
        setpoint.inc();
      }
      else if(strcmp(URL, "/down") == 0) {
        setpoint.dec();
      }
        WiServer.print("\"");
        WiServer.print(",\"temp\":");
        WiServer.print(temp);
        WiServer.print(",\"target\":");
        WiServer.print(setpoint.value());
        WiServer.print(",\"ontime\":");
        WiServer.print( setpoint.getOnTime() );
        WiServer.print("}");
        return true;
    }
    // URL not found
    return false;
}

void setup()
{
  Serial.begin(9600);
  ts.init();
  WiServer.init(handler);
  WiServer.enableVerboseMode(true);
  Serial.println("Wifi active");
  nextUpdate = millis();
  setpoint.set(99.0);
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
    float error = setpoint.value() - temp;
    val = error * 10; // val = 255 when temp is 25.5 degC below setpoint or less...
    if(val < 0) { val = 0; }
    if(val > 255) { val = 255; }
    analogWrite(9, val);
    
    serialDump();
  }
  
  //let the web server do its thing  
  WiServer.server_task();
}

void serialDump()
{
    Serial.print( setpoint.getOnTime());
    Serial.print(",");
  
  
    Serial.print(millis() / 1000.0, 2);
    Serial.print(",");
    Serial.print( ambient, 2 );
    Serial.print(",");
    Serial.print( temp, 2 );
    Serial.print(",");
    Serial.print(val);
    Serial.print(",");
    Serial.print(setpoint.value());
    Serial.println();
}

