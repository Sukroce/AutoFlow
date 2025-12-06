#include <SoftwareSerial.h>

#define BT_RX 5   // HC-05 TX
#define BT_TX 6   // HC-05 RX
SoftwareSerial BT(BT_RX, BT_TX);

#define IR1 2
#define IR2 3
#define IR3 4

int countA = 0;
int countB = 0;
int countC = 0;

int prevA = 0;
int prevB = 0;
int prevC = 0;

unsigned long lastPrint = 0;
const unsigned long printInterval = 300;  

unsigned long lastReset = 0;
const unsigned long resetInterval = 300000; 

void setup() {
  Serial.begin(9600);
  BT.begin(9600);

  pinMode(IR1, INPUT);
  pinMode(IR2, INPUT);
  pinMode(IR3, INPUT);

  Serial.println("3 IR Sensors + Bluetooth Ready");
  BT.println("3 IR Sensors + Bluetooth Ready");

  lastReset = millis();  
}

void loop() {

  int A = !digitalRead(IR1);  
  int B = !digitalRead(IR2);
  int C = !digitalRead(IR3);

  if (A == 1 && prevA == 0) countA++;
  if (B == 1 && prevB == 0) countB++;
  if (C == 1 && prevC == 0) countC++;

  prevA = A;
  prevB = B;
  prevC = C;

  unsigned long now = millis();
  if (now - lastReset >= resetInterval) {
    countA = 0;
    countB = 0;
    countC = 0;

    lastReset = now; 

    Serial.println("----- 5 MIN RESET -----");
    BT.println("----- 5 MIN RESET -----");
  }

  if (now - lastPrint >= printInterval) {
    lastPrint = now;

    Serial.print("A:");
    Serial.print(A);
    Serial.print(" CountA:");
    Serial.println(countA);

    Serial.print("B:");
    Serial.print(B);
    Serial.print(" CountB:");
    Serial.println(countB);

    Serial.print("C:");
    Serial.print(C);
    Serial.print(" CountC:");
    Serial.println(countC);

    Serial.println();

    BT.print("A;");
    BT.println(countA);

    BT.print("B;");
    BT.println(countB);

    BT.print("C;");
    BT.println(countC);

    BT.println();
  }

  delay(250);  
}
