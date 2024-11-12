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
}

void open_all_action(){
  digitalWrite(led, 1);
  delay(100);
  digitalWrite(led, 0);
}

void open_walker_action(){
  digitalWrite(led, 1);
  delay(100);
  digitalWrite(led, 0);
  delay(100);
  digitalWrite(led, 1);
  delay(100);
  digitalWrite(led, 0);
}

