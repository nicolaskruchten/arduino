
#include <Wire.h>
#include "wiichuck.h"


boolean WiiChuck::readData()
{
	byte buffer[6];
	byte buffer_index = 0;
	
	Wire.beginTransmission(0x52);
	Wire.send(0x00);
	Wire.endTransmission();
	
	delay(1);	
	
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

void WiiChuck::init()
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
	}
	
	if(bytesReceived == 0)
	{
		return;
	}
	delay(30);
	
	if(allFF) 
	{ 
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