#include <Servo.h>
#include <SoftwareSerial.h>
#include "math.h"

#define maxAngle 135
#define minAngle 45


#define rxPin 9    // Defines the "recieve" pin for software serial to motor controller
#define txPin 7    // Defines the "transmit" pin for software serial to motor controller
#define resetPin 8 // Defines the reset pin for the motor controller

#define left 0
#define right 1

#define forward 0
#define backward 255


Servo myservo;  // create servo object to control a servo 

// Create a special SoftwareSerial for direction communications with the motor controller
SoftwareSerial motorSerial = SoftwareSerial(rxPin, txPin);

boolean obstacle = false;

int increment = 10;

int motorState = 2;

void setup() 
{ 
  pinMode(0, INPUT);
  pinMode(2, INPUT);
  pinMode(13, OUTPUT);
  myservo.attach(4); 
  myservo.write(minAngle);
  Serial.begin(9600);
  
  InitMotor();
  
} 

void go()
{
  if(motorState == 0) return;
  motorState = 0;
  SetMotor(left, forward);
  SetMotor(right, forward);
}

void goLeft()
{
  if(motorState == -1) return;
  motorState = -1;
  SetMotor(left, backward);
  SetMotor(right, forward);
}

void goRight()
{
  if(motorState == 1) return;
  motorState = 1;
  SetMotor(left, forward);
  SetMotor(right, backward);
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
  Serial.print("s: ");
  Serial.print(sensor);
  int thresh = analogRead(0);
  Serial.print(", t: ");
  Serial.print(thresh);
  Serial.println(" ");
  obstacle = sensor > thresh;
  digitalWrite(13,  obstacle ? HIGH : LOW);
}


void loop() 
{
  readSensor();
  sweep();
  delay(50);
}




// Public: Initialize the motor controller and unique serial communications
void InitMotor()
{
	// Setup Pins for I/O
	pinMode(rxPin, INPUT);		// Serial Recieve Pin
	pinMode(txPin, OUTPUT);		// Serial Transmit Pin
	pinMode(resetPin, OUTPUT);	// Motor Reset Pin
 
	// Set the baud rate of software serial
	motorSerial.begin(9600);
	delay(100);
 
    // Reset the motor controller (By setting low then high signals to the resetPin)
	digitalWrite(resetPin, LOW);
	delay(10);
	digitalWrite(resetPin, HIGH);
 
	// Pause of the reset
	delay(100);
}
 
// Public: Set a speed (0 to 127 for backwards, 128 to 255 for forward) based on a motor index
void SetMotor(int motorIndex, int speed)
{
	// Cap the given speed
	if(speed < 0)
		speed = 0;
	else if(speed > 255)
		speed = 255;
 
	// Convert the given speed to directional speeds
	bool Forward;
	if(speed >= 128)
	{
		Forward = true;
		speed -= 128;
	}
	else
	{
		Forward = false;
		speed = 127 - speed;
	}
 
	// Pass our conversion to the base SetMotor function
	SetMotor(motorIndex, speed, Forward);
}
 
// Public: Set a speed (0 to 127) and direction (boolean) to a motor
void SetMotor(int motorIndex, int speed, boolean GoForward)
{
	// Create the packet buffer
	unsigned char buffer[4];
 
	// Start byte and device ID byte
	buffer[0] = 0x80;
	buffer[1] = 0x00;
 
	// Set motor index
	unsigned char index = 0;
	if(motorIndex > 0 || motorIndex < 0)
		index = 2;
 
	// Motor number and direction
	if(GoForward)
		buffer[2] = 0x00 | index;
	else
		buffer[2] = 0x01 | index;
 
	// Motor speed
	unsigned char targetSpeed = 0;
	if(speed >= 128)
		targetSpeed = 127;
	else if(speed < 0)
		targetSpeed = 0;
	else
		targetSpeed = (unsigned char)speed;
	buffer[3] = targetSpeed;
 
	// Send the packet
	SendPacket(buffer, 4);
}
 
// Private: Send a packet through the custom serial motorSerial
void SendPacket(unsigned char *buffer, int bufferCount)
{
	for(int i = 0; i < bufferCount; i++)
		motorSerial.print(buffer[i], BYTE);
}

