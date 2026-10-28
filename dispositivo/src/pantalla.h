// Pantallas de la OLED 0.96" (128 x 64).
#pragma once

#include <Adafruit_SSD1306.h>

#include "config.h"

struct DatosPantalla {
  const char *nombrePerfil;
  uint16_t fps;
  float uvi;           // lo que mide el sensor
  float restanteMin;   // minutos para reaplicar
  float avance;        // 0 a 1
  bool haySol;         // UV efectivo de 1 o más (si no, la cuenta está en pausa)
  bool conectado;      // celular conectado por Bluetooth
  bool haySensor;
};

class Pantalla {
 public:
  bool iniciar();
  bool hay() const { return hay_; }

  void bienvenida(const char *version);
  void normal(const DatosPantalla &d);
  // Alerta "Hora de reaplicar" (parpadea alternando colores).
  void alerta(bool invertida, bool silenciada);
  // Mensaje de dos renglones (por ejemplo "Listo" / "Cuenta desde cero").
  void mensaje(const char *titulo, const char *detalle);
  // Un cuadro de una animación corta (cuadro 0, 1, 2… cada 80 ms).
  // Tipos: 0 sol con rayos que giran, 1 sol con lentes, 2 bloqueador.
  static constexpr uint8_t kTiposAnimacion = 3;
  void animacion(uint8_t tipo, uint16_t cuadro);
  void apagar();
  // Pedazos de imagen que hubo que volver a mandar (para revisar los cables).
  uint32_t fallas() const { return fallas_; }
  // Franjas que no llegaron ni con 10 intentos (se ven mal hasta la siguiente imagen).
  uint32_t perdidas() const { return perdidas_; }

 private:
  // Manda la imagen a la pantalla revisando que llegue (ver pantalla.cpp).
  void mostrar();
  bool ordenes(const uint8_t *lista, uint8_t cantidad);
  uint8_t direccion_ = 0x3C;
  bool invertida_ = false;
  uint32_t fallas_ = 0;
  uint32_t perdidas_ = 0;

  // La librería sube el I2C a 400 kHz mientras dibuja; aquí se deja en VELOCIDAD_I2C.
  Adafruit_SSD1306 oled_{128, 64, &Wire, -1, VELOCIDAD_I2C, VELOCIDAD_I2C};
  bool hay_ = false;
};
