// Sensor UV - primera prueba de la placa.
// Escribe un mensaje cada segundo en el Monitor Serie (115200 baudios).
// Sirve para comprobar que PlatformIO compila para la placa y que se puede cargar el programa.

#include <Arduino.h>

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Hola, soy la placa del Sensor UV");
}

void loop() {
  Serial.print("Funcionando. Segundos desde que encendi: ");
  Serial.println(millis() / 1000);
  delay(1000);
}
