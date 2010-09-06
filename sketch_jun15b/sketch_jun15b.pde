#include <pmc.h>

MotorController mc = MotorController(7, 8);

void setup()
{
}
 
void loop()
{
    for(int i = 0; i < 100; i += 1)
    {
        // Set the motors (index 0 and 1) forward
        SetMotor(0, 128+i);
        SetMotor(1, 128+i);
        delay(1000); // Wait 1 second
 
        // Set the motors (index 0 and 1) backwards
        SetMotor(0, 128-i);
        SetMotor(1, 128-i);
        delay(1000); // Wait 1 second
    }
}
 


// Public: Initialize the motor controller and unique serial communications
void InitMotor(int txPin, int resetPin)
{
	// Setup Pins for I/O
	pinMode(txPin, OUTPUT);		// Serial Transmit Pin
	pinMode(resetPin, OUTPUT);	// Motor Reset Pin
   digitalWrite(txPin, HIGH);

 
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
		SWprint(buffer[i]);
}

void SWprint(int data)
{
  byte mask;
  //startbit
  digitalWrite(7,LOW);
  delayMicroseconds(84);
  for (mask = 0x01; mask>0; mask <<= 1) {
    if (data & mask){ // choose bit
     digitalWrite(7,HIGH); // send 1
    }
    else{
     digitalWrite(7,LOW); // send 0
    }
    delayMicroseconds(84);
  }
  //stop bit
  digitalWrite(7, HIGH);
  delayMicroseconds(84);
}


