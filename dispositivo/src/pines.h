// Pines del dispositivo para cada placa.
// Para pasar de la ESP32-C6 (prestada) a la XIAO ESP32C3 solo se cambia la placa en PlatformIO;
// el programa toma los pines de aquí.
#pragma once

#if defined(ARDUINO_XIAO_ESP32C3)
// Seeed Studio XIAO ESP32C3 (placa final). Ver PLAN_CODIGO_DISPOSITIVO.md:
// no se usan los pines de las esquinas (D0, 5V, D6, D7) porque ahí van las patas de la base.
#define NOMBRE_PLACA "XIAO ESP32C3"
#define PIN_SDA     6  // D4
#define PIN_SCL     7  // D5
#define PIN_BOTON   3  // D1 (puede despertar a la placa del sueño profundo)
#define PIN_BUZZER  5  // D3
#define PIN_BATERIA 4  // D2 (medir batería, mejora a futuro)

#elif defined(CONFIG_IDF_TARGET_ESP32C6)
// ESP32-C6 DevKit (prestada para pruebas). Pines marcados en la placa con su número de GPIO.
// Se evitan los pines de arranque de la C6 (4, 5, 8, 9 y 15).
#define NOMBRE_PLACA "ESP32-C6 DevKit"
#define PIN_SDA     23
#define PIN_SCL     22
#define PIN_BOTON   2
#define PIN_BUZZER  19
#define PIN_BATERIA 3

#else
#error "Placa no reconocida: agregar sus pines en pines.h"
#endif
