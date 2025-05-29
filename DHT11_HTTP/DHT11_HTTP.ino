#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "DHT.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ArduinoJson.h>  // Make sure to install this library

// Pin Configuration 
#define DHTPIN 4
#define DHTTYPE DHT11
#define RELAY_PIN 25

// OLED Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// WiFi Configuration 
const char* ssid = "";
const char* pass = "";

// Server Configuration
const char* serverName = "https://humancc.site/ndhos/DHT11/dht11_backend.php";
const char* thresholdEndpoint = "https://humancc.site/ndhos/DHT11/fetch_threshold.php";

// Threshold Variables
float tempThreshold = 0.0;  // Default values
float humThreshold = 0.0;

// Global Variables
float temp = 0.0, hum = 0.0;
unsigned long lastSendTime = 0;
unsigned long lastThresholdUpdate = 0;                           
const long interval = 10000;  // 10 seconds for sensor readings
const long thresholdInterval = 10000;  // 10 seconds for threshold updates
String relayStatus = "Off";

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Start with relay OFF (active LOW)

  // Initialize OLED
  Wire.begin(21, 22); // SDA = GPIO 21, SCL = GPIO 22
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println(F("OLED init failed"));
    while (true);
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Initializing...");
  display.display();

  // Connect to WiFi
  WiFi.begin(ssid, pass);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("WiFi Connected");
  display.print("IP: ");
  display.println(WiFi.localIP());
  display.display();
  delay(2000);

  // Initial threshold fetch
  fetchThresholds();
}

void loop() {
  unsigned long currentMillis = millis();

  // Update thresholds every 10 seconds
  if (currentMillis - lastThresholdUpdate > thresholdInterval || lastThresholdUpdate == 0) {
    lastThresholdUpdate = currentMillis;
    fetchThresholds();
  }

  // Main sensor reading cycle
  if (currentMillis - lastSendTime > interval || lastSendTime == 0) {
    lastSendTime = currentMillis;
    readSensor();
    controlRelay();
    sendData();
    updateOLED();
  }
}

void readSensor() {
  temp = dht.readTemperature();
  hum = dht.readHumidity();

  if (isnan(temp) || isnan(hum)) {
    Serial.println("Failed to read from DHT sensor!");
    temp = 0;
    hum = 0;
  } else {
    Serial.printf("Temp: %.2f °C, Humidity: %.2f %%\n", temp, hum);
  }
}

void fetchThresholds() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Can't fetch thresholds - WiFi disconnected");
    return;
  }

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient https;

  Serial.println("Fetching thresholds...");
  https.begin(client, thresholdEndpoint);
  int httpCode = https.GET();

  if (httpCode == HTTP_CODE_OK) {
    String payload = https.getString();
    Serial.println("Response: " + payload);

    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, payload);

    if (!error) {
      // Check server response status
      if (strcmp(doc["status"], "success") == 0) {
        float newTempThreshold = doc["data"]["temp_treshold"];
        float newHumThreshold = doc["data"]["hum_treshold"];
        
        if (newTempThreshold != tempThreshold || newHumThreshold != humThreshold) {
          tempThreshold = newTempThreshold;
          humThreshold = newHumThreshold;
          Serial.printf("New thresholds set - Temp: %.1f°C, Hum: %.1f%%\n", 
                       tempThreshold, humThreshold);
          controlRelay();
        }
      } else {
        Serial.print("Server error: ");
        Serial.println(doc["message"].as<String>());
      }
    } else {
      Serial.print("JSON parse error: ");
      Serial.println(error.c_str());
    }
  } else {
    Serial.print("HTTP error: ");
    Serial.println(https.errorToString(httpCode));
  }

  https.end();
}

void controlRelay() {
  bool shouldRelayBeOn = (temp > tempThreshold) || (hum > humThreshold);
  
  digitalWrite(RELAY_PIN, shouldRelayBeOn ? LOW : HIGH);
  relayStatus = shouldRelayBeOn ? "On" : "Off";
  
  Serial.printf("Relay %s (Temp: %.1f/%1.f°C, Hum: %.1f/%.1f%%)\n",
               relayStatus.c_str(), temp, tempThreshold, hum, humThreshold);
}

void sendData() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected - can't send data");
    return;
  }

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient https;

  String url = String(serverName) +
               "?device_id=103" +
               "&temperature=" + String(temp, 2) +
               "&humidity=" + String(hum, 2) +
               "&relay_status=" + relayStatus;

  Serial.println("Sending data: " + url);
  https.begin(client, url);
  int httpCode = https.GET();

  if (httpCode > 0) {
    Serial.print("HTTP Response Code: ");
    Serial.println(httpCode);
    String payload = https.getString();
    Serial.println("Server Reply: " + payload);
  } else {
    Serial.print("HTTP Error: ");
    Serial.println(https.errorToString(httpCode));
  }

  https.end();
}

void updateOLED() {
  display.clearDisplay();
  
  // Line 1: Show thresholds (top of display)
  display.setCursor(0, 0);
  display.print("THolds: ");
  display.print(tempThreshold, 1);
  display.print("C ");
  display.print(humThreshold, 1);
  display.println("%");

  // Line 2: Current temperature
  display.setCursor(0, 10);
  display.print("Temp: ");
  display.print(temp, 1);
  display.print("C");

  // Line 3: Current humidity
  display.setCursor(0, 20);
  display.print("Hum:  ");
  display.print(hum, 1);
  display.print("%");

  // Line 4: Relay status (bottom)
  display.setCursor(70, 10);  // Right side of Temp line
  display.print("Relay: ");
  display.print(relayStatus);

  display.display();
}