
int red = 3;
int green = 5;
int blue = 6;

float lastRed = 0;
float lastGreen = 0;
float lastBlue = 0;

float nextRed;
float nextGreen;
float nextBlue;

int STEPS = 50;

void setup()
{
  pinMode(red, OUTPUT);
  pinMode(green, OUTPUT);
  pinMode(blue, OUTPUT);
  analogWrite(red, 255);
  analogWrite(green, 255);
  analogWrite(blue, 255);
  Serial.begin(9600);
}

void loop()
{	
  if (Serial.available() > 0) 
  {
    nextRed = 255-Serial.read();
    delay(15);
    nextGreen = 255-Serial.read();
    delay(15);
    nextBlue = 255-Serial.read();
    delay(15);
    
    float incRed = (nextRed - lastRed) / STEPS;
    float incGreen = (nextGreen - lastGreen) / STEPS;
    float incBlue = (nextBlue - lastBlue) / STEPS;
    
    for(int i=0; i<STEPS; i++)
    {
      
      lastRed += incRed;
      lastGreen += incGreen;
      lastBlue += incBlue;
      
    
      analogWrite(red, lastRed);
      analogWrite(green, lastGreen);
      analogWrite(blue, lastBlue);
      delay(10);
    }
    
    analogWrite(red, nextRed);
    analogWrite(green, nextGreen);
    analogWrite(blue, nextBlue);
    
    lastRed = nextRed;
    lastGreen = nextGreen;
    lastBlue = nextBlue;
  }


}

