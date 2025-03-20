/*
  ESP-NOW Demo - Receive
  esp-now-demo-rcv.ino
  Reads data from Initiator

  DroneBot Workshop 2022
  https://dronebotworkshop.com
*/

// Include Libraries
#include <esp_now.h>
#include <WiFi.h>


#define relais_all 23
#define relais_walker 19



int led =2;
char msg;

// Define a data structure
typedef struct struct_message {
  char m;
} struct_message;

// Create a structured object
struct_message myData;

//voids declaration
void action();
void open_all_action();
void open_walker_action();
void clear();


// Callback function executed when data is received
void OnDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
  memcpy(&myData, incomingData, sizeof(myData));
  Serial.print("char Value: ");
  Serial.println(myData.m);
  Serial.println();

  

  if(myData.m){
   
   
    msg = myData.m;
    action();

  }
}

void setup() {
  // Set up Serial Monitor
  Serial.begin(115200);

  // Set ESP32 as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Initilize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  pinMode(led,OUTPUT);

  pinMode(relais_all,OUTPUT);
  pinMode(relais_walker,OUTPUT);

  clear();

  // Register callback function
  esp_now_register_recv_cb(OnDataRecv);
}

void loop() {

}

void action(){
  if(msg == 'a'){
    open_all_action();
  }
  else if(msg == 'w'){
    open_walker_action();
  }
  clear();
}

void open_all_action(){
  digitalWrite(relais_all,HIGH);
  digitalWrite(led,HIGH);
  delay(1000);
  digitalWrite(relais_all,LOW);
  digitalWrite(led,LOW);
}

void open_walker_action(){
   digitalWrite(relais_walker,LOW);
  digitalWrite(led,HIGH);
  delay(1000);
  digitalWrite(relais_walker,HIGH);
  digitalWrite(led,LOW);
}

void clear(){
  digitalWrite(relais_all,LOW);
  digitalWrite(relais_walker,LOW);

}

