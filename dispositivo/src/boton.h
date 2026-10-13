// Botón "Ya me reapliqué" (entre el pin y GND, con la resistencia interna).
#pragma once

#include <Arduino.h>

class Boton {
 public:
  void iniciar(uint8_t pin) {
    pin_ = pin;
    pinMode(pin_, INPUT_PULLUP);
  }
  // Devuelve true una sola vez por cada vez que se presiona (con antirrebote).
  bool presionado(uint32_t ahoraMs) {
    bool abajo = digitalRead(pin_) == LOW;
    if (abajo != ultimoLeido_) {
      ultimoLeido_ = abajo;
      cambioMs_ = ahoraMs;
    }
    if (ahoraMs - cambioMs_ >= kAntirreboteMs && abajo != estable_) {
      estable_ = abajo;
      return estable_;  // true solo al bajar
    }
    return false;
  }

 private:
  static constexpr uint32_t kAntirreboteMs = 30;
  uint8_t pin_ = 0;
  bool ultimoLeido_ = false;
  bool estable_ = false;
  uint32_t cambioMs_ = 0;
};
