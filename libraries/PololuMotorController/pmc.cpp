
#include "pmc.h"

#define BITDELAY 84

// Public: Initialize the motor controller and unique serial communications
void MotorController::init(int txPin, int resetPin)
{
	tx = txPin;
	pinMode(txPin, OUTPUT); 
	digitalWrite(txPin, HIGH);
	delay(100);

	
	pinMode(resetPin, OUTPUT);
	digitalWrite(resetPin, LOW);
	delay(10);
	digitalWrite(resetPin, HIGH);
	delay(100);
}
 
// Public: Set a speed (0 to 127 for backwards, 128 to 255 for forward) based on a motor index
void MotorController::SetMotor(int motorIndex, int speed)
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
void MotorController::SetMotor(int motorIndex, int speed, boolean GoForward)
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
	for(int i = 0; i < 4; i++)
	{
	  digitalWrite(tx,LOW);
      delayMicroseconds(BITDELAY);
      for (byte mask = 0x01; mask>0; mask <<= 1) 
      { 
        digitalWrite(tx, buffer[i] & mask ? HIGH : LOW);
        delayMicroseconds(BITDELAY);
      }
      digitalWrite(tx, HIGH);
      delayMicroseconds(BITDELAY);
	}
	delay(10);
}

