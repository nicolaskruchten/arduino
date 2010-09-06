
int red = 3;
int green = 5;
int blue = 6;

int lastRed = 0;
int lastGreen = 0;
int lastBlue = 0;

int nextRed;
int nextGreen;
int nextBlue;

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
    
    int incRed = lastRed < nextRed ? 1 : -1;
    int incGreen = lastGreen < nextGreen ? 1 : -1;
    int incBlue = lastBlue < nextBlue ? 1 : -1;
    
    for(int i=0; i<255; i++)
    {
      
      lastRed += lastRed != nextRed ? incRed : 0;
      lastGreen += lastGreen != nextGreen ? incGreen : 0;
      lastBlue += lastBlue != nextBlue ? incBlue : 0;
      
    
      analogWrite(red, lastRed);
      analogWrite(green, lastGreen);
      analogWrite(blue, lastBlue);
      delay(5);
    }
    
    lastRed = nextRed;
    lastGreen = nextGreen;
    lastBlue = nextBlue;
  }


}


