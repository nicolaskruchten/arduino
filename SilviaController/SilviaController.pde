
#include <Wire.h>
#include <TypeK.h>
#include "TempSensor.h"

// ------------------------------------------------------------------------
// MAIN
//

TempSensor ts;

void setup()
{
  Serial.begin(BAUD);
  ts.init();
}

// -----------------------------------------------------------------  
void loop()
{
  ts.update();
  
  Serial.print(millis() / 1000.0, 2);
  Serial.print(",");
  Serial.print( 0.01 * ts.avgamb, 2 );
  Serial.print(",");
  Serial.print( 0.01 * ts.temp, 2 );
  Serial.println();
  
  delay(DELAY);
}



