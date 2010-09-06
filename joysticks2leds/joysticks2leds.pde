int red = 3;
int green = 5;
int blue = 6;

int lx = 1;
int ly = 2;
int ry = 3;
int rx = 4;

void setup()
{
  pinMode(red, OUTPUT);
  pinMode(green, OUTPUT);
  pinMode(blue, OUTPUT);
  analogWrite(red, 255);
  analogWrite(green, 255);
  analogWrite(blue, 255);
}

void loop()
{
  analogWrite(red, analogRead(lx)/4);
  analogWrite(green, analogRead(ly)/4);
  analogWrite(blue, analogRead(rx)/4);
}
