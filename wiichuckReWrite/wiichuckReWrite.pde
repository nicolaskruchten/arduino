

#include <Wire.h>

/* Debug definitions */
#define PRINT_NUNCHUK_DATA

#define READ_DELAY        100      /* (milliseconds) - Increase this number to not read the nunchuk data so fast */
#define SERIAL_BAUD_RATE  19200

unsigned int joy_x = 0;
unsigned int joy_y = 0;
unsigned int acc_x = 0;
unsigned int acc_y = 0;
unsigned int acc_z = 0;
unsigned int btn_c = 0;
unsigned int btn_z = 0;

unsigned long previous_read_time = 0;

boolean inSync = false;

void setup()
{
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
          //forward
      }
      else if(joy_y < 40)
      {
          //backward
      }
      else if(joy_x >255)
      {
          //right
      }
      else if(joy_x < 40)
      {
          //left
      }
    }
  }
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





