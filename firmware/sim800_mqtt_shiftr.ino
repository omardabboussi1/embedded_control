#include <SoftwareSerial.h>
SoftwareSerial sim800(8, 9);

const char* APN        = "ooredoo.tn";
const char* MQTT_HOST  = "mountainroarer689.cloud.shiftr.io";
const int   MQTT_PORT  = 1883;
const char* CLIENT_ID  = "arduino_sim800_001";
const char* MQTT_USER  = "mountainroarer689";
const char* MQTT_PASS  = "Lu0mBA93WrwJwQzS";
const char* TOPIC_CMD  = "relay/cmd";
const char* TOPIC_STAT = "relay/status";

#define LED_PIN 2

bool ledState = false;
bool mqttConnected = false;
String dataBuffer = "";  // Buffer persistant qui accumule les données

// Prototypes
bool connectGPRS();
bool connectMQTT();
void subscribeMQTT(const char* topic);
void publishMQTT(const char* topic, const char* message);
void sendPingMQTT();
String sendAT(const char* cmd, const char* expected, int timeout);
void sendRaw(byte* data, int length);
void processCommand(String cmd);

// ─────────────────────────────────────────
void setup() {
    Serial.begin(9600);
    sim800.begin(9600);
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);
    Serial.println("=== SIM800L MQTT ===");
    delay(5000);

    while (!connectGPRS()) {
        Serial.println(">>> GPRS échoué, retry...");
        delay(5000);
    }
    while (!connectMQTT()) {
        Serial.println(">>> MQTT échoué, retry...");
        delay(5000);
    }
    subscribeMQTT(TOPIC_CMD);
    publishMQTT(TOPIC_STAT, "OFF1");
}

// ─────────────────────────────────────────
//  CHERCHER UNE COMMANDE DANS LES DONNÉES
// ─────────────────────────────────────────
String findCommand(String raw) {
    if (raw.indexOf("OFF1") != -1)   return "OFF1";
    if (raw.indexOf("ON1") != -1)    return "ON1";
    if (raw.indexOf("OFF2") != -1)   return "OFF2";
    if (raw.indexOf("ON2") != -1)    return "ON2";
    if (raw.indexOf("STATUS") != -1) return "STATUS";
    return "";
}

void loop() {
    if (!mqttConnected) {
        Serial.println(">>> Reconnexion...");
        delay(3000);
        connectGPRS();
        connectMQTT();
        subscribeMQTT(TOPIC_CMD);
        return;
    }

    // ─── Lire TOUT ce qui est disponible dans le buffer ─────
    if (sim800.available()) {
        delay(500);  // Attendre que le paquet complet arrive
        while (sim800.available()) {
            dataBuffer += (char)sim800.read();
        }
    }

    // ─── Vérifier déconnexion ───────────────────────────────
    if (dataBuffer.indexOf("CLOSED") != -1 ||
        dataBuffer.indexOf("PDP: DEACT") != -1) {
        mqttConnected = false;
        dataBuffer = "";
        return;
    }

    // ─── Chercher une commande dans le buffer accumulé ──────
    if (dataBuffer.length() > 0) {
        String cmd = findCommand(dataBuffer);
        if (cmd.length() > 0) {
            Serial.print(">>> COMMANDE TROUVEE: ");
            Serial.println(cmd);
            processCommand(cmd);
            dataBuffer = "";  // Vider après traitement
        }

        // Empêcher le buffer de grossir trop (garder les 50 derniers chars)
        if (dataBuffer.length() > 200) {
            dataBuffer = dataBuffer.substring(dataBuffer.length() - 50);
        }
    }

    static unsigned long lastPing = 0;
    if (millis() - lastPing > 50000) {
        lastPing = millis();
        sendPingMQTT();
    }
}

// ─────────────────────────────────────────
//  TRAITER LA COMMANDE REÇUE
// ─────────────────────────────────────────
void processCommand(String cmd) {
    cmd.trim();
    cmd.toUpperCase();

    Serial.print(">>> Commande: ");
    Serial.println(cmd);

    if (cmd == "ON1") {
        ledState = true;
        digitalWrite(LED_PIN, HIGH);
        publishMQTT(TOPIC_STAT, "ON1");
        Serial.println(">>> LED → ON");

    } else if (cmd == "OFF1") {
        ledState = false;
        digitalWrite(LED_PIN, LOW);
        publishMQTT(TOPIC_STAT, "OFF1");
        Serial.println(">>> LED → OFF");

    } else if (cmd == "STATUS") {
        publishMQTT(TOPIC_STAT, ledState ? "ON1" : "OFF1");
        Serial.println(">>> STATUS envoyé");

    } else {
        Serial.print(">>> Commande inconnue: ");
        Serial.println(cmd);
    }
}

// ─────────────────────────────────────────
bool connectGPRS() {
    sendAT("AT",         "OK",      3000);
    sendAT("AT+CPIN?",   "READY",   3000);
    sendAT("AT+CIPSHUT", "SHUT OK", 5000);
    sendAT("AT+CGATT=0", "OK",      5000);
    sendAT("AT+CGATT=1", "OK",      5000);
    String cstt = "AT+CSTT=\"";
    cstt += APN;
    cstt += "\",\"\",\"\"";
    sendAT(cstt.c_str(), "OK",  5000);
    sendAT("AT+CIICR",   "OK", 15000);

    String ip = sendAT("AT+CIFSR", ".", 5000);
    if (ip.indexOf(".") == -1) {
        Serial.println(">>> GPRS échoué : pas d'IP");
        return false;
    }
    Serial.println(">>> GPRS OK");
    return true;
}

// ─────────────────────────────────────────
bool connectMQTT() {
    String cmd = "AT+CIPSTART=\"TCP\",\"";
    cmd += MQTT_HOST;
    cmd += "\",";
    cmd += MQTT_PORT;
    String r = sendAT(cmd.c_str(), "CONNECT OK", 10000);
    if (r.indexOf("CONNECT OK") == -1) {
        Serial.println(">>> TCP échoué");
        return false;
    }
    delay(500);

    String clientId = CLIENT_ID;
    String user     = MQTT_USER;
    String pass     = MQTT_PASS;

    int len = 2 + clientId.length()
            + 2 + user.length()
            + 2 + pass.length()
            + 10;

    byte packet[100];
    int i = 0;
    packet[i++] = 0x10;
    packet[i++] = len;
    packet[i++] = 0x00;
    packet[i++] = 0x04;
    packet[i++] = 'M';
    packet[i++] = 'Q';
    packet[i++] = 'T';
    packet[i++] = 'T';
    packet[i++] = 0x04;
    packet[i++] = 0xC2;
    packet[i++] = 0x00;
    packet[i++] = 0x3C;
    packet[i++] = 0x00;
    packet[i++] = (byte)clientId.length();
    for (int j = 0; j < (int)clientId.length(); j++)
        packet[i++] = clientId[j];
    packet[i++] = 0x00;
    packet[i++] = (byte)user.length();
    for (int j = 0; j < (int)user.length(); j++)
        packet[i++] = user[j];
    packet[i++] = 0x00;
    packet[i++] = (byte)pass.length();
    for (int j = 0; j < (int)pass.length(); j++)
        packet[i++] = pass[j];

    sendRaw(packet, i);
    delay(2000);

    String response = "";
    long deadline = millis() + 5000;
    while (millis() < deadline) {
        while (sim800.available()) {
            char c = sim800.read();
            response += c;
            Serial.write(c);
        }
    }

    if (response.indexOf("CLOSED") != -1) {
        Serial.println(">>> MQTT refusé");
        return false;
    }

    Serial.println(">>> MQTT connecté OK");
    mqttConnected = true;
    return true;
}

// ─────────────────────────────────────────
void subscribeMQTT(const char* topic) {
    String t = topic;
    int topicLen  = t.length();
    int remaining = 2 + 2 + topicLen + 1;

    byte packet[30];
    int i = 0;
    packet[i++] = 0x82;
    packet[i++] = remaining;
    packet[i++] = 0x00;
    packet[i++] = 0x01;
    packet[i++] = 0x00;
    packet[i++] = topicLen;
    for (int j = 0; j < topicLen; j++)
        packet[i++] = t[j];
    packet[i++] = 0x00;

    sendRaw(packet, i);
    Serial.print(">>> Souscrit à : ");
    Serial.println(topic);
}

// ─────────────────────────────────────────
void publishMQTT(const char* topic, const char* message) {
    String t = topic;
    String m = message;
    int topicLen   = t.length();
    int messageLen = m.length();
    int remaining  = 2 + topicLen + messageLen;

    byte packet[128];
    int i = 0;
    packet[i++] = 0x30;
    packet[i++] = remaining;
    packet[i++] = (topicLen >> 8) & 0xFF;
    packet[i++] = topicLen & 0xFF;
    for (int j = 0; j < topicLen; j++)
        packet[i++] = t[j];
    for (int j = 0; j < messageLen; j++)
        packet[i++] = m[j];

    sendRaw(packet, i);
    Serial.print(">>> Publié sur ");
    Serial.print(topic);
    Serial.print(" : ");
    Serial.println(message);
}

// ─────────────────────────────────────────
void sendPingMQTT() {
    byte packet[2] = {0xC0, 0x00};
    sendRaw(packet, 2);
    Serial.println(">>> PING envoyé");
}

// ─────────────────────────────────────────
String sendAT(const char* cmd, const char* expected, int timeout) {
    Serial.print(">>> ");
    Serial.println(cmd);
    sim800.println(cmd);
    String response = "";
    long deadline = millis() + timeout;
    while (millis() < deadline) {
        while (sim800.available()) {
            char c = sim800.read();
            response += c;
            Serial.write(c);
        }
        if (response.indexOf(expected) != -1) break;
        if (response.indexOf("ERROR")   != -1) break;
    }
    Serial.println("\n---");
    return response;
}

// ─────────────────────────────────────────
void sendRaw(byte* data, int length) {
    String cmd = "AT+CIPSEND=";
    cmd += length;
    sim800.println(cmd);
    Serial.println(cmd);

    long deadline = millis() + 5000;
    bool prompted = false;
    while (millis() < deadline) {
        if (sim800.available()) {
            char c = sim800.read();
            Serial.write(c);
            if (c == '>') {
                prompted = true;
                break;
            }
        }
    }

    if (!prompted) {
        Serial.println(">>> ERREUR : pas de prompt >");
        mqttConnected = false;
        return;
    }

    delay(100);
    sim800.write(data, length);
    sim800.write(0x1A);
    Serial.println(">>> Donnees envoyees");

    String response = "";
    deadline = millis() + 8000;
    while (millis() < deadline) {
        while (sim800.available()) {
            char c = sim800.read();
            response += c;
            Serial.write(c);
        }
        if (response.indexOf("SEND OK") != -1) {
            Serial.println("\n>>> SEND OK");
            break;
        }
        if (response.indexOf("ERROR") != -1) {
            Serial.println("\n>>> ERREUR SEND");
            mqttConnected = false;
            break;
        }
    }
    // Sauvegarder toute la réponse dans le buffer global
    if (response.length() > 0) {
        dataBuffer += response;
    }
    // Lire aussi les données qui arrivent juste après
    delay(100);
    while (sim800.available()) {
        dataBuffer += (char)sim800.read();
    }
    Serial.println("\n---");
}
