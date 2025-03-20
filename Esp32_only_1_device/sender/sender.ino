/*
  ESP-NOW Demo - Transmit
  esp-now-demo-xmit.ino
  Sends data to Responder

  DroneBot Workshop 2022
  https://dronebotworkshop.com
*/

// Include Libraries
#include <esp_now.h>
#include <WiFi.h>
#include <FirebaseESP32.h>

// Wi-Fi credentials
#define WIFI_SSID "Ayman"
#define WIFI_PASSWORD ""

// // Wi-Fi credentials
// #define WIFI_SSID "Ayman"
// #define WIFI_PASSWORD "siayman123"


// Firebase project URL (without the API key)
#define FIREBASE_HOST "https://portail-coulissant-default-rtdb.firebaseio.com/" // Replace with your Firebase Database URL
#define FIREBASE_KEY "VRN03NPfLBkOHU5nhCMCiToF2H9QDHAgrtOxprje" // Replace with your Firebase Database URL
#define relais_all 23
#define relais_walker 19



#define TIMEOUT_CONNECTION    5000



// Variables for test data

FirebaseData firebaseData;

int led = 2;
String stateValue;

// REPLACE WITH YOUR RECEIVER MAC Address
uint8_t broadcastAddress[] = {0xd0, 0xef, 0x76, 0x33, 0x1c, 0x90};
 
// Define a data structure
typedef struct struct_message {
  char m;
} struct_message;

// Create a structured object
struct_message myData;

// Peer info
esp_now_peer_info_t peerInfo;

// Callback function called when data is sent
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}

void connect_wifi();
void RESET();
bool button_pressed();

void setup() {

  // Set up Serial Monitor
  Serial.begin(115200);


  pinMode(led,OUTPUT);
 
  digitalWrite(led,HIGH);




  // Connect to Wi-Fi
  connect_wifi();
  

  // Initialize Firebase without API key
  Firebase.begin(FIREBASE_HOST,FIREBASE_KEY);
  Firebase.reconnectWiFi(true);
  //clear();
 //initialize_espnow();
}


void loop() {



  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    digitalWrite(2,HIGH);
    connect_wifi();
  }

  readState_Action();

}






void open_all(){
    pinMode(relais_all,OUTPUT);
    digitalWrite(relais_all,LOW);
    delay(1000);
    pinMode(relais_all,INPUT);
}
void open_walker(){
  pinMode(relais_walker,OUTPUT);
    digitalWrite(relais_walker,LOW);
    delay(1000);
    pinMode(relais_walker,INPUT);
}



void initialize_espnow(){
   // Set ESP32 as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Initilize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Register the send callback
  esp_now_register_send_cb(OnDataSent);

  // Register peer
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;

  // Add peer
  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add peer");
    return;
  }
}


void connect_wifi(){
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("\nConnecting to Wi-Fi");

  double last_time = millis();
  
  while (WiFi.status() != WL_CONNECTED ) {
    delay(50);
    Serial.print(".");

    if(millis() - last_time > 5000){
      Serial.println("time out ***************");
      esp_restart();
    }
  }
  Serial.println();
  Serial.println("Connected to Wi-Fi");
  digitalWrite(2,LOW);
}

void disconnect_wifi(){
  WiFi.disconnect(true);
  Serial.println("wifi desiconnected");
  digitalWrite(2,HIGH);
}


void readState_Action(){
// Read the 'state' value from Firebase
  if (Firebase.getString(firebaseData, "/state/state")) {
    if (firebaseData.dataType() == "string") {
      stateValue = firebaseData.stringData();

      stateValue = stateValue.substring(1, stateValue.length() - 1);

      Serial.print("current state is :");
      Serial.println(stateValue);

      // If the state is not "null", make it "null"
      if (stateValue != "null") {
       
        if(stateValue == "open all"){
          open_all();
        }

        if(stateValue == "open walker"){
          open_walker();

        }


        if (Firebase.setString(firebaseData, "/state/state", "null")) {
         
        } else {
          Serial.println("Failed to update state.");
        
      }
    }
  } else {
    Serial.println("Failed to read from Firebase.");
    Serial.println("REASON: " + firebaseData.errorReason());
  }
}
}


void send(char msg) {
  // Invert the boolean value

  // Format structured data
  myData.m = msg;
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(broadcastAddress, (uint8_t *)&myData, sizeof(myData));

  if (result == ESP_OK) {
    Serial.println("Sending confirmed");
  } else {
    Serial.println("Sending error");
  }
}



