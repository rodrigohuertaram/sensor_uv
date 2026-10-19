// Sensor UV - prueba de cada pieza por separado (programa aparte, antes del programa completo).
// Se compila solo con los entornos prueba_componentes_* de platformio.ini (PRUEBA_COMPONENTES).
//
// Qué prueba:
//   1. I2C: busca qué hay conectado (el sensor debe aparecer en 0x53 y la pantalla en 0x3C o 0x3D).
//   2. Pantalla: muestra todo lo de abajo.
//   3. Sensor UV: lee el índice UV cada segundo.
//   4. Buzzer: toca una melodía al encender (y con las órdenes de abajo).
//   5. Botón: cada vez que se presiona suena "listo" y se suma a la cuenta de la pantalla.
//   6. Dormir: con la orden "d" la placa se duerme y debe despertar con el botón.
//
// Órdenes por el Monitor Serie (115200 baudios):
//   a   melodía "hora de reaplicar"     l   melodía "listo"
//   t   tonos de 500 a 4000 Hz (para escuchar cuál suena más fuerte)
//   h   señal del buzzer fija en alto 3 s y luego en bajo 3 s (por si el buzzer es activo)
//   d   dormir (despierta con el botón)  i   volver a buscar piezas I2C
//   v   ver si SDA y SCL están en alto (sin piezas pegadas a GND)
//
// Conexiones: ver DIAGRAMA_CONEXIONES.md (pines en pines.h).

#ifdef PRUEBA_COMPONENTES

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_LTR390.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <CalculoUV.h>  // nivelUV(): nivel de riesgo según la escala de la OMS

#include "boton.h"
#include "buzzer.h"
#include "dormir.h"
#include "pines.h"

// Hoja técnica del LTR390: con ganancia 18x y resolución de 20 bits,
// 2300 cuentas equivalen a 1 punto de índice UV (sin ventana delante del sensor).
// Se ajustará con la calibración (ventana de PTFE y comparación con Open-Meteo).
const float CUENTAS_POR_UVI = 2300.0f;

Adafruit_LTR390 sensor;
Adafruit_SSD1306 pantalla(128, 64, &Wire, -1);
Boton boton;
Buzzer buzzer;

bool haySensor = false;
bool hayPantalla = false;
bool desperto = false;      // true si encendió por el botón después de dormir
uint32_t vecesBoton = 0;
uint32_t cuentas = 0;
float uvi = 0;
uint32_t ultimaLecturaMs = 0;

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

// Lee SDA y SCL como entradas: en reposo las dos deben estar en alto (1) por las resistencias
// de los módulos. Un 0 quiere decir que algo jala esa línea a GND.
void revisarLineasI2C() {
  Wire.end();
  pinMode(PIN_SDA, INPUT);
  pinMode(PIN_SCL, INPUT);
  delay(5);
  Serial.printf("Sin resistencia interna:  SDA = %d   SCL = %d\n", digitalRead(PIN_SDA), digitalRead(PIN_SCL));
  pinMode(PIN_SDA, INPUT_PULLUP);
  pinMode(PIN_SCL, INPUT_PULLUP);
  delay(5);
  Serial.printf("Con resistencia interna:  SDA = %d   SCL = %d\n", digitalRead(PIN_SDA), digitalRead(PIN_SCL));
  Wire.begin(PIN_SDA, PIN_SCL);
}

void dibujar() {
  if (!hayPantalla) return;
  pantalla.clearDisplay();
  pantalla.setTextSize(1);
  pantalla.setCursor(0, 0);
  pantalla.print(haySensor ? "Indice UV" : "Sensor: NO responde");
  if (haySensor) {
    pantalla.setTextSize(3);
    pantalla.setCursor(0, 12);
    pantalla.printf("%.1f", uvi);
    pantalla.setTextSize(1);
    pantalla.setCursor(80, 12);
    pantalla.print(nivelUV(uvi));
    pantalla.setCursor(80, 24);
    pantalla.printf("%lu", (unsigned long)cuentas);
  }
  pantalla.setCursor(0, 44);
  pantalla.printf("Boton: %lu veces", (unsigned long)vecesBoton);
  pantalla.setCursor(0, 56);
  pantalla.print(desperto ? "Desperto: OK" : "d = dormir");
  pantalla.display();
}

// Un buzzer activo suena con la señal fija (en alto, o en bajo si se activa con 0) y no con tonos.
void probarSenalFija() {
  noTone(PIN_BUZZER);
  pinMode(PIN_BUZZER, OUTPUT);
  Serial.println("Senal del buzzer en ALTO (3 s)");
  digitalWrite(PIN_BUZZER, HIGH);
  delay(3000);
  Serial.println("Senal del buzzer en BAJO (3 s)");
  digitalWrite(PIN_BUZZER, LOW);
  delay(3000);
  Serial.println("Fin de la prueba");
}

void tocarTonos() {
  Serial.println("Tonos de 500 a 4000 Hz (cada uno 0.4 s):");
  for (uint16_t f = 500; f <= 4000; f += 500) {
    Serial.printf("  %u Hz\n", f);
    tone(PIN_BUZZER, f);
    delay(400);
  }
  noTone(PIN_BUZZER);
}

void dormir() {
  Serial.println("Me duermo. Presiona el boton para despertarme.");
  if (hayPantalla) {
    pantalla.clearDisplay();
    pantalla.setTextSize(1);
    pantalla.setCursor(0, 24);
    pantalla.println("Durmiendo...");
    pantalla.println("Presiona el boton");
    pantalla.display();
    delay(1500);
    pantalla.ssd1306_command(SSD1306_DISPLAYOFF);
  }
  dormirHastaElBoton(PIN_BOTON);
}

void leerOrdenes() {
  if (!Serial.available()) return;
  char orden = Serial.read();
  switch (orden) {
    case 'a': Serial.println("Melodia: hora de reaplicar"); buzzer.tocar(kMelodiaReaplicar, kLargoReaplicar); break;
    case 'l': Serial.println("Melodia: listo"); buzzer.tocar(kMelodiaListo, kLargoListo); break;
    case 't': tocarTonos(); break;
    case 'h': probarSenalFija(); break;
    case 'd': dormir(); break;
    case 'i': buscarI2C(); break;
    case 'v': revisarLineasI2C(); break;
    default: break;  // saltos de línea y otras teclas
  }
}

void setup() {
  desperto = despertoPorBoton();
  if (desperto) liberarBotonAlDespertar(PIN_BOTON);

  Serial.begin(115200);
  delay(2000);  // tiempo para abrir el Monitor Serie
  Serial.printf("\nSensor UV - prueba de componentes (%s)\n", NOMBRE_PLACA);
  Serial.printf("SDA = GPIO%d, SCL = GPIO%d, boton = GPIO%d, buzzer = GPIO%d\n",
                PIN_SDA, PIN_SCL, PIN_BOTON, PIN_BUZZER);
  if (desperto) Serial.println("Desperte con el boton: dormir funciona.");

  Wire.begin(PIN_SDA, PIN_SCL);
  buscarI2C();

  hayPantalla = pantalla.begin(SSD1306_SWITCHCAPVCC, 0x3C) || pantalla.begin(SSD1306_SWITCHCAPVCC, 0x3D);
  Serial.println(hayPantalla ? "Pantalla OLED: OK" : "Pantalla OLED: NO responde");
  if (hayPantalla) pantalla.setTextColor(SSD1306_WHITE);

  haySensor = sensor.begin(&Wire);
  if (haySensor) {
    sensor.setMode(LTR390_MODE_UVS);
    sensor.setGain(LTR390_GAIN_18);
    sensor.setResolution(LTR390_RESOLUTION_20BIT);
  }
  Serial.println(haySensor ? "Sensor LTR390: OK" : "Sensor LTR390: NO responde");

  boton.iniciar(PIN_BOTON);
  buzzer.iniciar(PIN_BUZZER);
  buzzer.tocar(kMelodiaInicio, kLargoInicio);
  Serial.println("Buzzer: debiste oir dos pitidos cortos.");
  Serial.println("Ordenes: a = reaplicar, l = listo, t = tonos, h = senal fija, d = dormir, i = buscar I2C, v = ver SDA y SCL");
  dibujar();
}

void loop() {
  uint32_t ahora = millis();
  buzzer.actualizar(ahora);
  leerOrdenes();

  if (boton.presionado(ahora)) {
    vecesBoton++;
    Serial.printf("Boton presionado (%lu veces)\n", (unsigned long)vecesBoton);
    buzzer.tocar(kMelodiaListo, kLargoListo);
    dibujar();
  }

  if (ahora - ultimaLecturaMs >= 1000) {
    ultimaLecturaMs = ahora;
    if (haySensor && sensor.newDataAvailable()) {
      cuentas = sensor.readUVS();
      uvi = cuentas / CUENTAS_POR_UVI;
      Serial.printf("Cuentas: %lu   Indice UV: %.1f   (%s)\n", (unsigned long)cuentas, uvi, nivelUV(uvi));
    }
    dibujar();
  }
  delay(5);
}

#endif  // PRUEBA_COMPONENTES
