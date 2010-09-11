#include <Wire.h>
#include <Servo.h>
#include <wiichuck.h>
#include <pmc.h>


#define READ_DELAY 50 


#define maxAngle 115
#define minAngle 65


#define left 1
#define right 0

#define forward 255
#define backward 0
#define stopped 128

unsigned long previous_read_time = 0;

Servo myservo;
MotorController mc;
WiiChuck chuck;

boolean obstacle = false;
int increment = 10;
int motorState = 2;
boolean autonomous = false;


void setup()
{
  pinMode(0, INPUT);
  pinMode(2, INPUT);
  pinMode(13, OUTPUT);
  pinMode(11, OUTPUT);
  pinMode(10, OUTPUT);
  myservo.attach(4); 
  myservo.write(90);
  mc.init(7, 8);
  Wire.begin();
  previous_read_time = millis();
  Serial.begin(9600);
}

void loop()
{
  if(!chuck.inSync)
  {
    chuck.init();
  }

  if (chuck.inSync && (millis() - previous_read_time > READ_DELAY))
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
      
      if(chuck.btn_z!= 0)
      {
        autonomous = true;
      }
      
      if(chuck.btn_c!= 0)
      {
        //stopped
        mc.SetMotor(left, stopped);
        mc.SetMotor(right, stopped);
        autonomous = false;
      }
    }
    
    if(autonomous)
    {
      motorState = 2;
      sweep();
    } 
    readSensor();
    digitalWrite(11,  autonomous ? HIGH : LOW);
    digitalWrite(10,  autonomous ? LOW : HIGH);
  }
}



void go()
{
  if(motorState == 0) return;
  motorState = 0;
  mc.SetMotor(left, forward);
  mc.SetMotor(right, forward);
}

void goLeft()
{
  if(motorState == -1) return;
  motorState = -1;
  mc.SetMotor(left, backward);
  mc.SetMotor(right, forward);
}

void goRight()
{
  if(motorState == 1) return;
  motorState = 1;
  mc.SetMotor(left, forward);
  mc.SetMotor(right, backward);
}

void sweep()
{
  int pos = myservo.read();
  if(obstacle)
  {
    if(pos-90 < 0)
    {
      goRight();
    }
    else
    {
      goLeft();
    }
  }
  else
  {
    go();
    pos +=  increment;
    if(pos >= maxAngle || pos <= minAngle) {increment *= -1;}
    
    myservo.write(pos);
  }
}

void readSensor() 
{  
  int sensor = analogRead(2);
  int thresh = analogRead(0);
  obstacle = sensor > thresh;
  digitalWrite(13,  obstacle ? HIGH : LOW);
}







