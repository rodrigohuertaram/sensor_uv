// Pantallas de la OLED 0.96" (128 x 64).
#pragma once

#include <Adafruit_SSD1306.h>

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
  void apagar();

 private:
  Adafruit_SSD1306 oled_{128, 64, &Wire, -1};
  bool hay_ = false;
};
