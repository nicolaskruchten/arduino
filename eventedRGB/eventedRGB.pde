
#include <AikoEvents.h>
using namespace Aiko;



int red = 3;
int green = 5;
int blue = 6;

boolean redON = false;
boolean greenON = false;
boolean blueON = false;

void setup()
{
  pinMode(red, OUTPUT);
  pinMode(green, OUTPUT);
  pinMode(blue, OUTPUT);
  
  Events.addHandler (switchRed, 1000);
  Events.addHandler (switchGreen, 2000);
  Events.addHandler (switchBlue, 3000);

}

void switchRed()
{
  redON = !redON;
  digitalWrite(red, redON ? HIGH : LOW);
}

void switchGreen()
{
  greenON = !greenON;
  digitalWrite(green, greenON ? HIGH : LOW);
}

void switchBlue()
{
  blueON = !blueON;
  digitalWrite(blue, blueON ? HIGH : LOW);
}

void loop() {
  Events.loop();
}

