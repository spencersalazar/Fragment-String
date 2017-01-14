
int SW1 = 11;
int AN1 = A1;
int AN2 = A3;

int clamp(int v)
{
  if(v >= 255)
    return 254;
  else
    return v;
}

void sendit(int an1, int an2, int sw1)
{
  Serial.print(an1); Serial.print(",");
  Serial.print(an2); Serial.print(",");
  Serial.print(sw1); Serial.println();
}

void setup() {
  Serial.begin(9600);

  
  pinMode(SW1, INPUT_PULLUP);
}

void loop() {
  int an1 = analogRead(AN1);
  int an2 = analogRead(AN2);
  int sw1 = digitalRead(SW1);

  sendit(an1, an2, sw1);
  
  delay(2);
}

