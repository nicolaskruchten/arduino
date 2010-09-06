#include <Servo.h> 

Servo myservo;  // create servo object to control a servo 

int pos = 90;    // variable to store the servo position 

void setup() 
{ 
  myservo.attach(9);  // attaches the servo on pin 9 to the servo object 
  pinMode(0, INPUT);
  Serial.begin(9600);
} 

void loop() 
{ 
  int val = analogRead(0);
  Serial.println(val);
    if(val > 650) { pos = pos + 3; }
    if(val > 630) { pos = pos + 2; }
    if(val > 610) { pos = pos + 1; }
    if(val < 590) { pos = pos - 1; }
    if(val < 570) { pos = pos - 2; }
    if(val < 550) { pos = pos - 3; }
    
    if(pos > 180) { pos = 180; }
    if(pos < 0  ) { pos = 0; }
    
    myservo.write(pos);
    delay(50);

} 

