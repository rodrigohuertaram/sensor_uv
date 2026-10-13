// Sensor UV LTR390: entrega el índice UV.
#pragma once

#include <Adafruit_LTR390.h>

class SensorUV {
 public:
  bool iniciar();
  bool hay() const { return hay_; }
  // Devuelve el índice UV más reciente (si el sensor aún no tiene lectura nueva, la anterior).
  float leer();
  uint32_t ultimasCuentas() const { return cuentas_; }

  // Sin sensor conectado se puede fijar un UV a mano desde el Monitor Serie (para pruebas).
  void fijarSimulado(float uvi) {
    simulado_ = true;
    uvi_ = uvi;
  }
  bool simulado() const { return simulado_; }

 private:
  Adafruit_LTR390 ltr_;
  bool hay_ = false;
  bool simulado_ = false;
  float uvi_ = 0;
  uint32_t cuentas_ = 0;
};
