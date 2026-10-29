// Solaris Shield - prueba de cada pieza por separado (programa aparte, antes del programa completo).
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
//   x   buscar el sensor y la pantalla en todos los pines (por si un cable quedó en otro pin)
//   c   buscar pines unidos entre sí o pegados a GND
//   e   contar fallas del I2C con la pantalla y el sensor (para encontrar un cable flojo)
//   q   imagen fija en la pantalla y dejar de mandarle datos (para ver si la falla es de la pantalla)
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
#include "config.h"
#include "pines.h"

// Hoja técnica del LTR390: con ganancia 18x y resolución de 20 bits,
// 2300 cuentas equivalen a 1 punto de índice UV (sin ventana delante del sensor).
// Se ajustará con la calibración (ventana de PTFE y comparación con Open-Meteo).
const float CUENTAS_POR_UVI = 2300.0f;

Adafruit_LTR390 sensor;
Adafruit_SSD1306 pantalla(128, 64, &Wire, -1, VELOCIDAD_I2C, VELOCIDAD_I2C);
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

// Revisa SDA y SCL sin el I2C:
// - Con la resistencia interna hacia GND, una línea solo marca 1 si llega a un módulo con corriente
//   (sus resistencias a 3V3 ganan). Un 0 quiere decir cable suelto o módulo sin corriente.
// - Con la resistencia interna hacia 3V3, un 0 quiere decir que algo jala la línea a GND.
// - Al poner una línea en 0, la otra debe seguir en 1; si también baja, SDA y SCL están unidas.
void revisarLineasI2C() {
  Wire.end();
  pinMode(PIN_SDA, INPUT_PULLDOWN);
  pinMode(PIN_SCL, INPUT_PULLDOWN);
  delay(5);
  int sdaModulo = digitalRead(PIN_SDA), sclModulo = digitalRead(PIN_SCL);
  Serial.printf("Llega a un modulo con corriente (1 = si):  SDA = %d   SCL = %d\n", sdaModulo, sclModulo);
  pinMode(PIN_SDA, INPUT_PULLUP);
  pinMode(PIN_SCL, INPUT_PULLUP);
  delay(5);
  Serial.printf("En reposo (debe ser 1):                    SDA = %d   SCL = %d\n", digitalRead(PIN_SDA), digitalRead(PIN_SCL));
  pinMode(PIN_SCL, OUTPUT);
  digitalWrite(PIN_SCL, LOW);
  delay(5);
  int sdaConSclBajo = digitalRead(PIN_SDA);
  pinMode(PIN_SCL, INPUT_PULLUP);
  Serial.printf("SDA y SCL unidas: %s\n", sdaConSclBajo == 0 ? "SI (corto entre SDA y SCL)" : "no");
  if (sdaModulo == 0 || sclModulo == 0) {
    Serial.println("  -> Revisa el cable de la linea en 0 y que el modulo reciba 3V3 y GND.");
  }
  Wire.begin(PIN_SDA, PIN_SCL);
}

// Prueba todas las parejas de pines como SDA y SCL y dice dónde contestan el sensor y la pantalla.
// Sirve para encontrar cables que quedaron en otro pin. Al final regresa a los pines de pines.h.
void buscarEnTodosLosPines() {
#if defined(ARDUINO_XIAO_ESP32C3)
  // GPIO de D0 a D10 (sin 18 y 19, que son el USB)
  const uint8_t pines[] = {2, 3, 4, 5, 6, 7, 21, 20, 8, 9, 10};
  const char *nombres[] = {"D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10"};
#else
  const uint8_t pines[] = {0, 1, 2, 3, 6, 7, 10, 11, 18, 19, 20, 21, 22, 23};
  const char *nombres[] = {"0", "1", "2", "3", "6", "7", "10", "11", "18", "19", "20", "21", "22", "23"};
#endif
  const uint8_t direcciones[] = {0x53, 0x3C, 0x3D};
  const int cantidad = sizeof(pines) / sizeof(pines[0]);
  Serial.println("Probando todas las parejas de pines (tarda unos segundos)...");
  int encontradas = 0;
  for (int a = 0; a < cantidad; a++) {
    for (int b = 0; b < cantidad; b++) {
      if (a == b) continue;
      Wire.end();
      Wire.begin(pines[a], pines[b]);
      Wire.setTimeOut(20);
      for (uint8_t d : direcciones) {
        Wire.beginTransmission(d);
        if (Wire.endTransmission() == 0) {
          Serial.printf("  %s en 0x%02X con SDA = %s y SCL = %s\n",
                        d == 0x53 ? "Sensor UV" : "Pantalla", d, nombres[a], nombres[b]);
          encontradas++;
        }
      }
    }
  }
  if (encontradas == 0) Serial.println("  Nada en ningun pin: revisa 3V3 y GND de las piezas.");
  Wire.end();
  Wire.begin(PIN_SDA, PIN_SCL);
  Serial.printf("Listo. Lo correcto es SDA = GPIO%d y SCL = GPIO%d.\n", PIN_SDA, PIN_SCL);
}

// Busca pines unidos entre sí (por ejemplo SDA y SCL en la misma fila del protoboard):
// pone un pin en 0 y revisa si otro, con su resistencia interna, también baja a 0.
void buscarCortos() {
#if defined(ARDUINO_XIAO_ESP32C3)
  const uint8_t pines[] = {2, 3, 4, 5, 6, 7, 21, 20, 8, 9, 10};
  const char *nombres[] = {"D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10"};
#else
  const uint8_t pines[] = {0, 1, 2, 3, 6, 7, 10, 11, 18, 19, 20, 21, 22, 23};
  const char *nombres[] = {"0", "1", "2", "3", "6", "7", "10", "11", "18", "19", "20", "21", "22", "23"};
#endif
  const int cantidad = sizeof(pines) / sizeof(pines[0]);
  Wire.end();
  noTone(PIN_BUZZER);
  Serial.println("Buscando pines unidos entre si o a GND...");
  for (int i = 0; i < cantidad; i++) pinMode(pines[i], INPUT_PULLUP);
  delay(5);
  for (int i = 0; i < cantidad; i++) {
    if (digitalRead(pines[i]) == LOW) Serial.printf("  %s esta en 0 sin tocarlo (pegado a GND o al boton presionado)\n", nombres[i]);
  }
  int unidos = 0;
  for (int a = 0; a < cantidad; a++) {
    pinMode(pines[a], OUTPUT);
    digitalWrite(pines[a], LOW);
    delay(2);
    for (int b = a + 1; b < cantidad; b++) {
      if (digitalRead(pines[b]) == LOW) {
        Serial.printf("  %s y %s estan unidos\n", nombres[a], nombres[b]);
        unidos++;
      }
    }
    pinMode(pines[a], INPUT_PULLUP);
    delay(2);
  }
  if (unidos == 0) Serial.println("  Ningun pin unido con otro.");
  pinMode(PIN_BOTON, INPUT_PULLUP);
  Wire.begin(PIN_SDA, PIN_SCL);
}

// Cuenta cuántos mensajes cortos fallan con la pantalla y el sensor, a varias velocidades del I2C.
// Con buenos cables debe dar 0 fallas. Sirve para encontrar un cable flojo: mover los cables
// uno por uno mientras se repite la prueba y ver con cuál suben las fallas.
void contarErrores() {
  const uint32_t velocidades[] = {400000, 100000, 50000};
  const int intentos = 300;
  Serial.println("Contando fallas del I2C (300 mensajes por pieza y velocidad)...");
  for (uint32_t v : velocidades) {
    Wire.setClock(v);
    int fallasPantalla = 0, fallasSensor = 0;
    for (int i = 0; i < intentos; i++) {
      Wire.beginTransmission(0x3C);
      Wire.write(0x00);  // lo que sigue es una orden
      Wire.write(0xE3);  // orden "no hacer nada" de la SSD1306
      if (Wire.endTransmission() != 0) fallasPantalla++;
      Wire.beginTransmission(0x53);
      if (Wire.endTransmission() != 0) fallasSensor++;
    }
    Serial.printf("  %3lu kHz: pantalla %d fallas, sensor %d fallas (de %d)\n", (unsigned long)(v / 1000),
                  fallasPantalla, fallasSensor, intentos);
  }
  Wire.setClock(VELOCIDAD_I2C);
}

// Imagen fija para revisar la pantalla: un marco en la orilla, una cuadrícula y texto.
// Después de dibujarla ya no se le manda nada; si aun así la imagen se mueve o se parte,
// la falla está en la pantalla (vidrio o cinta flexible) y no en el programa ni en los cables.
bool pantallaCongelada = false;

void imagenFija() {
  if (!hayPantalla) return;
  pantalla.clearDisplay();
  pantalla.drawRect(0, 0, 128, 64, SSD1306_WHITE);
  for (int x = 16; x < 128; x += 16) pantalla.drawFastVLine(x, 0, 64, SSD1306_WHITE);
  for (int y = 16; y < 64; y += 16) pantalla.drawFastHLine(0, y, 128, SSD1306_WHITE);
  pantalla.fillRect(34, 22, 60, 20, SSD1306_BLACK);
  pantalla.setTextSize(1);
  pantalla.setCursor(40, 24);
  pantalla.print("IMAGEN");
  pantalla.setCursor(46, 33);
  pantalla.print("FIJA");
  pantalla.display();
  pantallaCongelada = true;
  Serial.println("Imagen fija: ya no se le manda nada a la pantalla. 'q' otra vez para volver.");
}

void dibujar() {
  if (!hayPantalla || pantallaCongelada) return;
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
    case 'x': buscarEnTodosLosPines(); break;
    case 'c': buscarCortos(); break;
    case 'e': contarErrores(); break;
    case 'q':
      if (pantallaCongelada) {
        pantallaCongelada = false;
        Serial.println("Pantalla normal otra vez");
      } else {
        imagenFija();
      }
      break;
    default: break;  // saltos de línea y otras teclas
  }
}

void setup() {
  desperto = despertoPorBoton();
  if (desperto) liberarBotonAlDespertar(PIN_BOTON);

  Serial.begin(115200);
  delay(2000);  // tiempo para abrir el Monitor Serie
  Serial.printf("\nSolaris Shield - prueba de componentes (%s)\n", NOMBRE_PLACA);
  Serial.printf("SDA = GPIO%d, SCL = GPIO%d, boton = GPIO%d, buzzer = GPIO%d\n",
                PIN_SDA, PIN_SCL, PIN_BOTON, PIN_BUZZER);
  if (desperto) Serial.println("Desperte con el boton: dormir funciona.");

  Wire.begin(PIN_SDA, PIN_SCL);
  Wire.setClock(VELOCIDAD_I2C);
  buscarI2C();

  // begin() de Adafruit dice que sí aunque no haya pantalla; escribirle a una pantalla
  // que no contesta traba el I2C (y con él, el sensor). Por eso primero se pregunta.
  uint8_t dirPantalla = 0;
  for (uint8_t d : {0x3C, 0x3D}) {
    Wire.beginTransmission(d);
    if (Wire.endTransmission() == 0) dirPantalla = d;
  }
  hayPantalla = dirPantalla != 0 && pantalla.begin(SSD1306_SWITCHCAPVCC, dirPantalla);
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
  Serial.println("Ordenes: a = reaplicar, l = listo, t = tonos, h = senal fija, d = dormir, i = buscar I2C, v = ver SDA y SCL, x = buscar en todos los pines, c = buscar cortos, q = imagen fija, e = contar fallas");
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
