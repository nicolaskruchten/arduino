

#include <Wire.h>
#include <Servo.h>
#include <SoftwareSerial.h>
#include "math.h"

/* Debug definitions */
#define PRINT_NUNCHUK_DATA

#define READ_DELAY        50      /* (milliseconds) - Increase this number to not read the nunchuk data so fast */
#define SERIAL_BAUD_RATE  9600


#define maxAngle 115
#define minAngle 65


#define rxPin 9    // Defines the "recieve" pin for software serial to motor controller
#define txPin 7    // Defines the "transmit" pin for software serial to motor controller
#define resetPin 8 // Defines the reset pin for the motor controller

#define left 1
#define right 0

#define forward 255
#define backward 0
#define stopped 128


unsigned int joy_x = 0;
unsigned int joy_y = 0;
unsigned int acc_x = 0;
unsigned int acc_y = 0;
unsigned int acc_z = 0;
unsigned int btn_c = 0;
unsigned int btn_z = 0;

unsigned long previous_read_time = 0;

boolean inSync = false;


Servo myservo;  // create servo object to control a servo 

// Create a special SoftwareSerial for direction communications with the motor controller
SoftwareSerial motorSerial = SoftwareSerial(rxPin, txPin);

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
  InitMotor();
  Serial.begin(SERIAL_BAUD_RATE);
  Wire.begin();
  previous_read_time = millis();
}

void loop()
{
  if(!inSync)
  {
    initialize_nunchuk();
  }

  if (inSync && (millis() - previous_read_time > READ_DELAY))
  {
    previous_read_time = millis();
    if(read_nunchuk_data())
    {
      #ifdef PRINT_NUNCHUK_DATA
        Serial.print("    "); 
        Serial.print(joy_x);
        Serial.print("      "); 
        Serial.print(joy_y);
        Serial.print("      "); 
        Serial.print(acc_x);
        Serial.print("       "); 
        Serial.print(acc_y);
        Serial.print("       "); 
        Serial.print(acc_z);
        Serial.print("        "); 
        Serial.print(btn_c);
        Serial.print("          "); 
        Serial.print(btn_z);
        Serial.println("");
      #endif
      
      if(joy_y > 240)
      {
        SetMotor(left, forward);
        SetMotor(right, forward);
        autonomous = false;
      }
      else if(joy_y < 40)
      {
          //backward
        SetMotor(left, backward);
        SetMotor(right, backward);
        autonomous = false;
      }
      else if(joy_x >240)
      {
          //right
        SetMotor(left, forward);
        SetMotor(right, backward);
        autonomous = false;
      }
      else if(joy_x < 40)
      {
          //left
        SetMotor(left, backward);
        SetMotor(right, forward);
        autonomous = false;
      }
      
      if(btn_z!= 0)
      {
        autonomous = true;
      }
      
      if(btn_c!= 0)
      {
        //stopped
        SetMotor(left, stopped);
        SetMotor(right, stopped);
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
  int thresh = analogRead(0);
  obstacle = sensor > thresh;
  digitalWrite(13,  obstacle ? HIGH : LOW);
}



boolean read_nunchuk_data()
{
  byte buffer[6];
  byte buffer_index = 0;

  Wire.beginTransmission(0x52);
  Wire.send(0x00);
  Wire.endTransmission();

  delay(1); /* This delay is required for a wired nunchuk otherwise the data will appear maxed out */


  Wire.requestFrom(0x52, 6);
  boolean allFF = true;
  while(Wire.available())    
  {
    buffer[buffer_index] = Wire.receive();
    if(buffer[buffer_index] != 0xFF) { 
      allFF = false; 
    }
    buffer[buffer_index] = (buffer[buffer_index] ^ 0x17) + 0x17;
    buffer_index++;
  }
  if(allFF) { 
    inSync = false;
#ifdef PRINT_NUNCHUK_DATA
    Serial.println("Saw all-FF, trying to resync");
#endif
    return false; 
  }

  joy_x = buffer[0];
  joy_y = buffer[1];
  acc_x = ((buffer[2] << 2) | ((buffer[5] & 0x0C) >> 2) & 0x03FF);
  acc_y = ((buffer[3] << 2) | ((buffer[5] & 0x30) >> 4) & 0x03FF);
  acc_z = ((buffer[4] << 2) | ((buffer[5] & 0xC0) >> 6) & 0x03FF);
  btn_c = !((buffer[5] & 0x02) >> 1);
  btn_z = !(buffer[5] & 0x01);

  return true;
}

void initialize_nunchuk()
{
  Wire.beginTransmission(0x52);
  Wire.send (0xF0);
  Wire.send (0x55);
  Wire.endTransmission();
  delay(30);

  Wire.beginTransmission (0x52);
  Wire.send (0xFB);
  Wire.send (0x00);
  Wire.endTransmission();
  delay(30);

  Wire.beginTransmission(0x52);
  Wire.send (0xFA);
  Wire.endTransmission();
  delay(30);

  Wire.requestFrom(0x52, 6);
  boolean allFF = true;
  int bytesReceived = 0;
  while(Wire.available())  
  {
    byte c = Wire.receive();
    bytesReceived++;
    if(c != 0xFF) { 
      allFF = false; 
    }
#ifdef PRINT_NUNCHUK_DATA
    Serial.print(c, HEX);
    Serial.print(" ");
#endif
  }
  
  if(bytesReceived == 0)
  {
#ifdef PRINT_NUNCHUK_DATA
    Serial.println("Not sync'ed");  
#endif
    return;
  }
#ifdef PRINT_NUNCHUK_DATA
  Serial.println("");  
#endif
  delay(30);
  
  if(allFF) 
  { 
#ifdef PRINT_NUNCHUK_DATA
    Serial.println("Saw all-FF, will try again...");  
#endif
    delay(1000);
  }
  else
  {
  
    
  Wire.beginTransmission(0x52);
  Wire.send (0xF0);
  Wire.send (0xAA);
  Wire.endTransmission();
  delay(30);
    
  Wire.beginTransmission(0x52);
  Wire.send (0x40);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.endTransmission();
  delay(30);
    
  Wire.beginTransmission(0x52);
  Wire.send (0x46);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.endTransmission();
  delay(30);
    
  Wire.beginTransmission(0x52);
  Wire.send (0x4C);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.send (0x00);
  Wire.endTransmission();
  delay(30);
    
    inSync = true;
  }

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





