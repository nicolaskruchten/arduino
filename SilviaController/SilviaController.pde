#include <WiServer.h>
#include <Wire.h>
#include <TypeK.h>
#include "TempSensor.h"
#include "WifiConfig.h"


class Controller {
  private:
    float p,i,d, temp, setpoint, lastError, integral;
    unsigned long int lastStart; //last time controller was activated
  public:
    Controller(float p_, float i_ = 0, float d_ = 0):
      p(p_), i(i_), d(d_),
      temp(0.0), setpoint(0.0), lastStart(0), 
      lastError(0), integral(0) {}
    
    float getTemp() { return temp; }
    
    void incSetpoint() {
      setSetpoint(setpoint+1);
    };
    
    void decSetpoint() {
      setSetpoint(setpoint-1);
    }
    
    void setSetpoint(float s) {
      if(s-setpoint > 10) { lastStart = millis(); }
      setpoint = s;
    }
    
    float getSetpoint() { 
      if(getOnTime() > 60.0) { setSetpoint(0.0); }
      return setpoint; 
    }
    
    float getOnTime() { 
      return (millis() - lastStart) / (1000.0 * 60.0); 
    }
    
    void setTemp(float temp_) { 
      temp = temp_;
      float error = setpoint - temp;   
      if(abs(error) < 4) { integral += error; } //windup protection
      float derivative = error - lastError;
      lastError = error;
      
      int val = (error * p) + (integral * i) + (derivative * d) ;
      
      if(val <= 0) { 
        analogWrite(9, 0);
        pinMode(9, INPUT);
      }
      else {
        if(val > 255) { val = 255; }
        
        pinMode(9, OUTPUT);
        analogWrite(9, val);
      }
      
      Serial.print( getOnTime());
      Serial.print(",");
    
    
      Serial.print(millis() / 1000.0, 2);
      Serial.print(",");
      Serial.print( temp, 2 );
      Serial.print(",");
      Serial.print(setpoint);
      Serial.print(",");
      Serial.print(val);
      Serial.println();
    }
};

Controller controller(4.0, 0.001, 0.0);
TempSensor ts;
unsigned long int nextUpdate = 0;

boolean handler(char* URL)
{
    // Check if the requested URL matches "/"
    if (URL[0] == '/') {
      
      WiServer.print("{\"url\":\"");
      WiServer.print(URL);
      if (strcmp(URL, "/start") == 0) {
        controller.setSetpoint(99.0);
      }
      else if(strcmp(URL, "/stop") == 0) {
        controller.setSetpoint(0.0);
      }
      else if(strcmp(URL, "/up") == 0) {
        controller.incSetpoint();
      }
      else if(strcmp(URL, "/down") == 0) {
        controller.decSetpoint();
      }
        WiServer.print("\"");
        WiServer.print(",\"temp\":");
        WiServer.print(controller.getTemp());
        WiServer.print(",\"target\":");
        WiServer.print(controller.getSetpoint());
        WiServer.print(",\"ontime\":");
        WiServer.print( controller.getOnTime() );
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
  controller.setSetpoint(99.0);
}
 
void loop()
{
  if(millis() > nextUpdate)
  {
    nextUpdate += 300;
    //check the temperature
    ts.update();
    
    //control the temperature
    controller.setTemp(ts.temp*0.01);
  }
  
  //let the web server do its thing  
  WiServer.server_task();
}


