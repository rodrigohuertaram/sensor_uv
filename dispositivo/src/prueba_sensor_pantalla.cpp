// Sensor UV - prueba del sensor LTR390 y de la pantalla OLED (programa aparte para probar las piezas).
// Se compila solo con los entornos prueba_sensor_* de platformio.ini (PRUEBA_SENSOR_PANTALLA).
//
// Qué hace:
//   1. Busca qué hay conectado en el I2C (el sensor debe aparecer en 0x53 y la pantalla en 0x3C o 0x3D).
//   2. Cada segundo lee el índice UV y lo muestra en la pantalla y en el Monitor Serie (115200 baudios).
//
// Conexiones (las dos piezas comparten los mismos 4 cables):
//   3V3 -> VIN/VCC   GND -> GND   PIN_SDA -> SDA   PIN_SCL -> SCL   (pines en pines.h)

#ifdef PRUEBA_SENSOR_PANTALLA

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_LTR390.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <CalculoUV.h>  // nivelUV(): nivel de riesgo según la escala de la OMS

#include "pines.h"

// Hoja técnica del LTR390: con ganancia 18x y resolución de 20 bits,
// 2300 cuentas equivalen a 1 punto de índice UV (sin ventana delante del sensor).
// Se ajustará con la calibración (ventana de PTFE y comparación con Open-Meteo).
const float CUENTAS_POR_UVI = 2300.0f;

Adafruit_LTR390 sensor;
Adafruit_SSD1306 pantalla(128, 64, &Wire, -1);

bool haySensor = false;
bool hayPantalla = false;

// Muestra en el Monitor Serie las direcciones I2C que responden.
void buscarI2C() {
  Serial.println("Buscando piezas conectadas por I2C...");
  int encontradas = 0;
  for (uint8_t direccion = 1; direccion < 127; direccion++) {
    Wire.beginTransmission(direccion);
    if (Wire.endTransmission() == 0) {
      Serial.printf("  Encontrada en 0x%02X", direccion);
      if (direccion == 0x53) Serial.print("  <- sensor UV LTR390");
      if (direccion == 0x3C || direccion == 0x3D) Serial.print("  <- pantalla OLED");
      Serial.println();
      encontradas++;
    }
  }
  if (encontradas == 0) {
    Serial.println("  Nada. Revisa 3V3, GND, SDA y SCL (y que SDA y SCL no esten al reves).");
  }
}

void setup() {
  Serial.begin(115200);
  delay(2000);  // tiempo para abrir el Monitor Serie
  Serial.printf("\nSensor UV - prueba del sensor y la pantalla (%s)\n", NOMBRE_PLACA);
  Serial.printf("SDA = GPIO%d, SCL = GPIO%d\n", PIN_SDA, PIN_SCL);

  Wire.begin(PIN_SDA, PIN_SCL);
  buscarI2C();

  hayPantalla = pantalla.begin(SSD1306_SWITCHCAPVCC, 0x3C) || pantalla.begin(SSD1306_SWITCHCAPVCC, 0x3D);
  Serial.println(hayPantalla ? "Pantalla OLED: OK" : "Pantalla OLED: NO responde");

  haySensor = sensor.begin(&Wire);
  if (haySensor) {
    sensor.setMode(LTR390_MODE_UVS);
    sensor.setGain(LTR390_GAIN_18);
    sensor.setResolution(LTR390_RESOLUTION_20BIT);
  }
  Serial.println(haySensor ? "Sensor LTR390: OK" : "Sensor LTR390: NO responde");

  if (hayPantalla) {
    pantalla.clearDisplay();
    pantalla.setTextColor(SSD1306_WHITE);
    pantalla.setTextSize(1);
    pantalla.setCursor(0, 0);
    pantalla.println("Sensor UV");
    pantalla.println("Prueba de pantalla");
    pantalla.println();
    pantalla.println(haySensor ? "Sensor: OK" : "Sensor: NO responde");
    pantalla.display();
  }
  delay(2000);
}

void loop() {
  if (!haySensor) {
    Serial.println("Sin sensor: revisa los cables y presiona RESET.");
    delay(3000);
    return;
  }

  if (sensor.newDataAvailable()) {
    uint32_t cuentas = sensor.readUVS();
    float uvi = cuentas / CUENTAS_POR_UVI;

    Serial.printf("Cuentas: %lu   Indice UV: %.1f   (%s)\n", (unsigned long)cuentas, uvi, nivelUV(uvi));

    if (hayPantalla) {
      pantalla.clearDisplay();
      pantalla.setTextSize(1);
      pantalla.setCursor(0, 0);
      pantalla.println("Indice UV");
      pantalla.setTextSize(3);
      pantalla.setCursor(0, 14);
      pantalla.printf("%.1f", uvi);
      pantalla.setTextSize(1);
      pantalla.setCursor(0, 42);
      pantalla.println(nivelUV(uvi));
      pantalla.setCursor(0, 54);
      pantalla.printf("Cuentas: %lu", (unsigned long)cuentas);
      pantalla.display();
    }
  }
  delay(1000);
}

#endif  // PRUEBA_SENSOR_PANTALLA
