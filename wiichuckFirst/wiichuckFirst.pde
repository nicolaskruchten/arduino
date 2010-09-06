// read out a Wii Nunchuck controller
// adapted to work with wireless Nunchuck controllers of third party vendors by Michael Dreher

// adapt to your hardware config
//#define DEBUG_RCV_TEL 1

#define USE_NEW_WAY_INIT 1 // use "The New Way" of initialization <http://wiibrew.org/wiki/Wiimote#The_New_Way>
#undef USE_NEW_WAY_INIT
#define WII_IDENT_LEN ((byte)6)
#define WII_TELEGRAM_LEN ((byte)6)
#define WII_NUNCHUCK_TWI_ADR ((byte)0x52)

#include <Wire.h>
#include <string.h>
#include <utility/twi.h>
#undef int
#include <stdio.h>

uint8_t outbuf[WII_TELEGRAM_LEN]; // array to store arduino output
int cnt = 0;
int ledPin = 13;

void setup ()
{
  delay(1000);
Serial.begin (19200);

Serial.print(TWI_FREQ);


Wire.begin(); // initialize i2c

nunchuck_init(0); // send the initialization handshake

// display the identification bytes, must be "00 00 A4 20 00 00" for the Nunchuck
byte i;
if(readControllerIdent(outbuf) == 0)
{
Serial.print("Ident=");
for (i = 0; i < WII_TELEGRAM_LEN; i++)
{
Serial.print(outbuf[i], HEX);
Serial.print(' ');
}
Serial.println();
}

Serial.println("Finished setup");
}

// params:
// timeout: abort when timeout (in ms) expires, 0 for unlimited timeout
// return: 0 == ok, 1 == timeout
byte nunchuck_init (unsigned short timeout)
{
byte rc = 1;

#ifndef USE_NEW_WAY_INIT
// look at <http://wiibrew.org/wiki/Wiimote#The_Old_Way> at "The Old Way"
Wire.beginTransmission (WII_NUNCHUCK_TWI_ADR); // transmit to device 0x52
Wire.send (0x40); // sends memory address
Wire.send (0x00); // sends sent a zero.
Wire.endTransmission (); // stop transmitting
#else
// disable encryption
// look at <http://wiibrew.org/wiki/Wiimote#The_New_Way> at "The New Way"

unsigned long time = millis();
do
{
Wire.beginTransmission (WII_NUNCHUCK_TWI_ADR); // transmit to device 0x52
Wire.send (0xF0); // sends memory address
Wire.send (0x55); // sends data.
if(Wire.endTransmission() == 0) // stop transmitting
{
Wire.beginTransmission (WII_NUNCHUCK_TWI_ADR); // transmit to device 0x52
Wire.send (0xFB); // sends memory address
Wire.send (0x00); // sends sent a zero.
if(Wire.endTransmission () == 0) // stop transmitting
{  
rc = 0;
}
}
}
while (rc != 0 && (!timeout || ((millis() - time) < timeout)));
#endif

return rc;
}


// params:
// ident [out]: pointer to buffer where 6 bytes of identification is stored. Buffer must be at least 6 bytes long.
// A list of possible identifications can be found here: <http://wiibrew.org/wiki/Wiimote#The_New_Way>
// return: 0 == ok, 1 == error
byte readControllerIdent(byte* pIdent)
{
byte rc = 1;

// read identification
Wire.beginTransmission (WII_NUNCHUCK_TWI_ADR); // transmit to device 0x52
Wire.send (0xFA); // sends memory address of ident in controller
if(Wire.endTransmission () == 0) // stop transmitting
{
byte i;
Wire.requestFrom (WII_NUNCHUCK_TWI_ADR, WII_TELEGRAM_LEN); // request data from nunchuck
for (i = 0; (i < WII_TELEGRAM_LEN) && Wire.available (); i++)
{
pIdent[i] = Wire.receive(); // receive byte as an integer
}
if(i == WII_TELEGRAM_LEN)
{
rc = 0;
}
}
return rc;
}

void clearTwiInputBuffer(void)
{
// clear the receive buffer from any partial data
while( Wire.available ())
Wire.receive ();
}


void send_zero ()
{
// I don't know why, but it only works correct when doing this exactly 3 times
// otherwise only each 3rd call reads data from the controller (cnt will be 0 the other times)
for(byte i = 0; i < 2; i++)
{
Wire.beginTransmission (WII_NUNCHUCK_TWI_ADR); // transmit to device 0x52
Wire.send (0x00); // sends one byte
Wire.endTransmission (); // stop transmitting
}
}

void loop ()
{
Wire.requestFrom (WII_NUNCHUCK_TWI_ADR, WII_TELEGRAM_LEN); // request data from nunchuck

for (cnt = 0; (cnt < WII_TELEGRAM_LEN) && Wire.available (); cnt++)
{
outbuf[cnt] = nunchuk_decode_byte (Wire.receive ()); // receive byte as an integer
digitalWrite (ledPin, HIGH); // sets the LED on
}

// debugging
#ifdef DEBUG_RCV_TEL
Serial.print("avail=");
Serial.print(Wire.available());
Serial.print(" cnt=");
Serial.println(cnt);
#endif

clearTwiInputBuffer();

// If we recieved the 6 bytes, then go print them
if (cnt >= WII_TELEGRAM_LEN)
{
print ();
}

delay (500);
send_zero (); // send the request for next bytes
}

// Print the input data we have recieved
// accel data is 10 bits long
// so we read 8 bits, then we have to add
// on the last 2 bits. That is why I
// multiply them by 2 * 2
void print ()
{
int joy_x_axis = outbuf[0];
int joy_y_axis = outbuf[1];
int accel_x_axis = outbuf[2] * 2 * 2;
int accel_y_axis = outbuf[3] * 2 * 2;
int accel_z_axis = outbuf[4] * 2 * 2;

int z_button = 0;
int c_button = 0;

// byte outbuf[5] contains bits for z and c buttons
// it also contains the least significant bits for the accelerometer data
// so we have to check each bit of byte outbuf[5]
if ((outbuf[5] >> 0) & 1)
{
z_button = 1;
}
if ((outbuf[5] >> 1) & 1)
{
c_button = 1;
}

if ((outbuf[5] >> 2) & 1)
{
accel_x_axis += 2;
}
if ((outbuf[5] >> 3) & 1)
{
accel_x_axis += 1;
}

if ((outbuf[5] >> 4) & 1)
{
accel_y_axis += 2;
}
if ((outbuf[5] >> 5) & 1)
{
accel_y_axis += 1;
}

if ((outbuf[5] >> 6) & 1)
{
accel_z_axis += 2;
}
if ((outbuf[5] >> 7) & 1)
{
accel_z_axis += 1;
}

Serial.print (joy_x_axis, DEC);
Serial.print ("\t");

Serial.print (joy_y_axis, DEC);
Serial.print ("\t");

Serial.print (accel_x_axis, DEC);
Serial.print ("\t");

Serial.print (accel_y_axis, DEC);
Serial.print ("\t");

Serial.print (accel_z_axis, DEC);
Serial.print ("\t");

Serial.print (z_button, DEC);
Serial.print ("\t");

Serial.print (c_button, DEC);
Serial.print ("\t");

Serial.print ("\r\n");
}

// Decode data format that original Nunchuck uses with old init sequence. This never worked with
// other controllers (e.g. wireless Nunchuck from other vendors)
char nunchuk_decode_byte (char x)
{
#ifndef USE_NEW_WAY_INIT
x = (x ^ 0x17) + 0x17;
#endif
return x;
}
