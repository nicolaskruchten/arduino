#include "Wire.h"
#include "Servo.h"
#include "wiichuck.h"
#include "pmc.h"

//constants
#define readDelay 50 
#define maxAngle 115
#define midAngle 90
#define minAngle 65
#define left 1
#define right 0
#define forward 255
#define backward 0
#define stopped 128

//pins
#define tuningPot 0
#define irSensor 2
#define underControlLED 10
#define autonomousLED 11
#define obstacleLED 13
#define servoPin 4
#define motorControlPin 7
#define motorResetPin 8

//controllers
Servo myservo;
MotorController mc;
WiiChuck chuck;

//globals
unsigned long previous_read_time = 0;
int sweepIncrement = 10;
boolean autonomous = false;

void setup()
{
  pinMode(tuningPot, INPUT);
  pinMode(irSensor, INPUT);
  pinMode(obstacleLED, OUTPUT);
  pinMode(autonomousLED, OUTPUT);
  pinMode(underControlLED, OUTPUT);
  
  myservo.attach(servoPin); 
  myservo.write(midAngle);
  
  mc.init(motorControlPin, motorResetPin);
  
  Wire.begin();
  Serial.begin(9600);
  previous_read_time = millis();
}

void loop()
{
  if(!chuck.inSync)
  {
    chuck.init();
  }

  if (chuck.inSync && (millis() - previous_read_time > readDelay))
  {
    previous_read_time = millis();
    if(chuck.readData())
    {      
      
      float angle = 45*PI/180;
      int x = chuck.joy_x -128;
      int y = chuck.joy_y -128;
      
      if(abs(x) > 50 || abs(y) > 50)
      {
        int leftSpeed  = 128 + 1.5*(x*cos(angle) + y*sin(angle));
        int rightSpeed = 128 + 1.5*(y*cos(angle) - x*sin(angle));
        mc.SetMotor(left, leftSpeed);
        mc.SetMotor(right, rightSpeed);
        autonomous = false;
      } 
      
      if(chuck.btn_c!= 0)
      {
        //stopped
        mc.SetMotor(left, stopped);
        mc.SetMotor(right, stopped);
        autonomous = false;
      }
      
      if(chuck.btn_z!= 0)
      {
        autonomous = true;
      }
    }
    
    if(autonomous)
    {
      sweep();
    } 
    else
    {
      myservo.write(midAngle);
    }
    
    digitalWrite(autonomousLED,  autonomous ? HIGH : LOW);
    digitalWrite(underControlLED,  autonomous ? LOW : HIGH);
  }
}

void sweep()
{
  int sensor = analogRead(irSensor);
  int thresh = analogRead(tuningPot);
  boolean obstacle = sensor > thresh;
  digitalWrite(obstacleLED,  obstacle ? HIGH : LOW);
  
  int pos = myservo.read();
  if(obstacle)
  {
    if(pos < midAngle)
    {
      mc.SetMotor(left, forward);
      mc.SetMotor(right, backward);
    }
    else
    {
      mc.SetMotor(left, backward);
      mc.SetMotor(right, forward);
    }
  }
  else
  {
    mc.SetMotor(left, forward);
    mc.SetMotor(right, forward);
    pos +=  sweepIncrement;
    if(pos >= maxAngle || pos <= minAngle) {sweepIncrement *= -1;}
    myservo.write(pos);
  }
}







