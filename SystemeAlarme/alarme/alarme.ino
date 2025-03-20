#include <WiFi.h>
#include <FirebaseESP32.h>
#include <HTTPClient.h>

// Replace with your network credentials
const char* WIFI_SSID = "Ayman";          // Your Wi-Fi SSID
const char* WIFI_PASSWORD = "";

// Structure to hold user credentials
typedef struct {
  const char* phoneNumber;
  const char* apiKey;
} Credentials_t;

// Users with their respective API keys
Credentials_t Ayman = {.phoneNumber = "21654393769", .apiKey = "5563167"};
Credentials_t Slim = {.phoneNumber = "21629214151", .apiKey = "5331012"};
Credentials_t Wael = {.phoneNumber = "21656903985", .apiKey = "4355216"};

Credentials_t Users[] = {Slim, Ayman, Wael};
#define USERS_LENGTH 3

#define FIREBASE_HOST "https://portail-coulissant-default-rtdb.firebaseio.com/" // Replace with your Firebase Database URL
#define FIREBASE_KEY "VRN03NPfLBkOHU5nhCMCiToF2H9QDHAgrtOxprje" // Replace with your Firebase Key

int rssiThreshold = 2;   // Define the threshold for detecting motion
int numSamples = 10;     // Number of samples for calculating the moving average
float rssiReadings[10];  // Array to store RSSI readings
int sampleIndex = 0;
bool motionDetected = false;
String stateValue;

bool isOpened = false;
String message = "ATTENTION !! Mouvement capté dans le garage.";

float last_time_init = 0;
int ledState = 1;

FirebaseData firebaseData;

// Function prototypes
void check_motion();
void AlarmIsOpened();
void sendAlert();
void sendMessage(Credentials_t user);
void connect_wifi();

void setup() {
  pinMode(2, OUTPUT);
  Serial.begin(115200);
  
  connect_wifi();

  // Initialize Firebase
  Firebase.begin(FIREBASE_HOST, FIREBASE_KEY);
  Firebase.reconnectWiFi(true);
}

void loop() {
  AlarmIsOpened();
  if (isOpened) {
    check_motion();
  } else {
    motionDetected = false;
    ledState = 0;
    digitalWrite(2, ledState);
    last_time_init = 0;
    
  }

  delay(50);
}

void check_motion() {
  if (WiFi.status() == WL_CONNECTED) {
    float currentRSSI = WiFi.RSSI();
    Serial.print("Current RSSI: ");
    Serial.println(currentRSSI);

    // Store the current reading in the array
    rssiReadings[sampleIndex] = currentRSSI;

    // Calculate the average RSSI
    float averageRSSI = calculateAverage(rssiReadings, sampleIndex + 1);
    sampleIndex = (sampleIndex + 1) % numSamples;

    if(!last_time_init){
      last_time_init = millis();
    }

    Serial.print("Average RSSI: ");
    Serial.println(averageRSSI);

    if(millis() - last_time_init > 5000){
      // Check for motion
      if (abs(currentRSSI - averageRSSI) > rssiThreshold) {
        
        if (!motionDetected) {
          motionDetected = true;
          // digitalWrite(2, 1);
          sendAlert();
          Serial.println("Motion Detected!");
        }
      }else{
        if(motionDetected)
          digitalWrite(2, 1);
        else
          digitalWrite(2, 0);
        
      }
    }else{
      Serial.println("starting ...");
      digitalWrite(2,ledState);
      ledState = !ledState;
    }

    
  }else{
    connect_wifi();
  }
}




void connect_wifi(){
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("\nConnecting to Wi-Fi");

  double last_time = millis();
  ledState = 1;
  
  while (WiFi.status() != WL_CONNECTED ) {
    digitalWrite(2,ledState);
    ledState = !ledState;

    delay(100);
    Serial.print(".");

    if(millis() - last_time > 5000){
      Serial.println("time out ***************");
      esp_restart();
    }
  }
  Serial.println();
  Serial.println("Connected to Wi-Fi");
  digitalWrite(2,0);
  
}



float calculateAverage(float readings[], int size) {
  float sum = 0;
  for (int i = 0; i < size; i++) {
    sum += readings[i];

  }
  return sum / size;
}

void AlarmIsOpened() {
  //check internet connection
  if(WiFi.status() == WL_CONNECTED){
    
    // Read the 'state' value from Firebase
    if (Firebase.getString(firebaseData, "/alarm/alarm")) {
      if (firebaseData.dataType() == "string") {
        stateValue = firebaseData.stringData();
        stateValue = stateValue.substring(1, stateValue.length() - 1);

        Serial.print("Current state is: ");
        Serial.println(stateValue);

        // If the state is not "null", update accordingly
        if (stateValue != "null") {
          if (stateValue == "OpnReq") {
            Firebase.setString(firebaseData, "/alarm/alarm", "opened");
            isOpened = true;
          }

          if(stateValue == "opened" && !isOpened){
            isOpened = true;
          }

          if (stateValue == "ClsReq") {
            Firebase.setString(firebaseData, "/alarm/alarm", "closed");
            isOpened = false;
          }

          if(stateValue == "closed"  && isOpened){
            isOpened = false;
          }
        }
      }
    } else {
      Serial.println("Failed to read from Firebase.");
      Serial.println("REASON: " + firebaseData.errorReason());
    }

  }else{
    connect_wifi();
  }

}

// Function to send messages to all users simultaneously using FreeRTOS tasks
void sendAlert() {
  for (int i = 0; i < USERS_LENGTH; i++) {
    sendMessage(Users[i]);
    delay(10);
  }
}

// Task function to send a message
void sendMessage(Credentials_t  user) {


  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String url = "https://api.callmebot.com/whatsapp.php?phone=" + String(user.phoneNumber) + "&text=" + message + "&apikey=" + String(user.apiKey);
    url.replace(" ", "%20");

    http.begin(url);
    int httpCode = http.GET();
    if (httpCode > 0) {
      Serial.println("Message Sent Successfully to: " + String(user.phoneNumber));
    } else {
      Serial.println("Error Sending Message to: " + String(user.phoneNumber));
    }

    http.end();
  }
}
