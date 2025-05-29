#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "DHT.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// === Pin Configuration ===
#define DHTPIN 4
#define DHTTYPE DHT11
#define RELAY_PIN 25

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C  // Common I2C address
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// === WiFi Configuration ===
const char* ssid = "";
const char* pass = "";

// === Server Configuration ===
const char* serverName = "https://humancc.site/ndhos/DHT11/dht11_backend.php";

// === Thresholds ===
const float TEMP_THRESHOLD = 26.0;
const float HUM_THRESHOLD = 70.0;

// === Global Variables ===
float temp = 0.0, hum = 0.0;
unsigned long lastSendTime = 0;
const long interval = 10000;
String relayStatus = "Off";

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Start with relay OFF (active LOW)

  // OLED Init
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
}

void loop() {
  if (millis() - lastSendTime > interval || lastSendTime == 0) {
    lastSendTime = millis();

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
  } else {
    Serial.printf("Temp: %.2f °C, Humidity: %.2f %%\n", temp, hum);
  }
}

void controlRelay() {
  if (temp > TEMP_THRESHOLD || hum > HUM_THRESHOLD) {
    digitalWrite(RELAY_PIN, LOW); // Relay ON
    relayStatus = "On";
    Serial.println("Relay ON (Threshold exceeded)");
  } else {
    digitalWrite(RELAY_PIN, HIGH); // Relay OFF
    relayStatus = "Off";
    Serial.println("Relay OFF (Within range)");
  }
}

void sendData() {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure();

    HTTPClient https;

    String url = String(serverName) +
                 "?device_id=103" +
                 "&temperature=" + String(temp, 2) +
                 "&humidity=" + String(hum, 2) +
                 "&relay_status=" + relayStatus;

    Serial.println("Sending GET: " + url);
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
  } else {
    Serial.println("WiFi not connected!");
  }
}

void updateOLED() {
  display.clearDisplay();
  display.setCursor(0, 0);
  display.printf("Temp: %.1f C\n", temp);
  display.printf("Humidity: %.1f %%\n", hum);
  display.print("Relay: ");
  display.println(relayStatus);
  display.display();
}
