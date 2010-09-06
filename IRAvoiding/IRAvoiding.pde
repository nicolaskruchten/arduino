#include <pmc.h>
#include <SoftwareServo.h>
#include <AikoEvents.h>

#define maxAngle 135
#define minAngle 45


#define left 0
#define right 1

#define forward 0
#define backward 255


using namespace Aiko;

SoftwareServo myservo; 

MotorController mc;

boolean obstacle = false;

int increment = 5;


void setup() 
{ 
  Serial.begin(9600);
  
  pinMode(0, INPUT);
  pinMode(1, INPUT);
  pinMode(12, OUTPUT);
  
  myservo.attach(4); 
  myservo.write(minAngle);
  
  mc.init(7, 8);
  
  Events.addHandler (readSensor, 50);
  Events.addHandler (sweep, 50);
} 

void goForward()
{
    mc.SetMotor(left, forward);
    mc.SetMotor(right, backward);
}

void goLeft()
{
    mc.SetMotor(left, forward);
    mc.SetMotor(right, backward);
}

void goRight()
{
    mc.SetMotor(left, forward);
    mc.SetMotor(right, backward);
}

void sweep()
{
  int pos = myservo.read();
  if(obstacle)
  {
    if(pos-90 < 0) {goRight();}
    else {goLeft();}
  }
  else
  {
    goForward();
    pos +=  increment;
    if(pos >= maxAngle || pos <= minAngle) {increment *= -1;}
    
    myservo.write(pos);
    myservo.refresh();
  }
}

void readSensor() 
{  
  int sensor = analogRead(0);
  int thresh = analogRead(1);
  obstacle = sensor > thresh;
  digitalWrite(12,  obstacle ? HIGH : LOW);
}


void loop() 
{
  Events.loop();
}


