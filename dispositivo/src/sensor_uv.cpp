#include "sensor_uv.h"

#include <Wire.h>

// Hoja técnica del LTR390: con ganancia 18x y resolución de 20 bits,
// 2300 cuentas = 1 punto de índice UV (sin ventana). Se ajustará con la calibración.
static const float kCuentasPorUvi = 2300.0f;

bool SensorUV::iniciar() {
  hay_ = ltr_.begin(&Wire);
  if (hay_) {
    ltr_.setMode(LTR390_MODE_UVS);
    ltr_.setGain(LTR390_GAIN_18);
    ltr_.setResolution(LTR390_RESOLUTION_20BIT);
  }
  return hay_;
}

float SensorUV::leer() {
  if (simulado_ || !hay_) return uvi_;
  if (ltr_.newDataAvailable()) {
    cuentas_ = ltr_.readUVS();
    uvi_ = cuentas_ / kCuentasPorUvi;
  }
  return uvi_;
}
