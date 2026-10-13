#include "buzzer.h"

#include <Arduino.h>

// Notas (Hz)
enum : uint16_t { DO5 = 523, MI5 = 659, SOL5 = 784, DO6 = 1047, MI6 = 1319, SOL6 = 1568, DO7 = 2093 };

// "Hora de reaplicar": arpegio que sube y una pausa; se repite mientras suena la alarma.
const Nota kMelodiaReaplicar[] = {{DO6, 150}, {MI6, 150}, {SOL6, 150}, {DO7, 300}, {0, 450}};
const uint8_t kLargoReaplicar = sizeof(kMelodiaReaplicar) / sizeof(Nota);

// "Listo": se presionó "Ya me reapliqué".
const Nota kMelodiaListo[] = {{SOL5, 100}, {0, 30}, {DO6, 200}};
const uint8_t kLargoListo = sizeof(kMelodiaListo) / sizeof(Nota);

// Al encender.
const Nota kMelodiaInicio[] = {{DO6, 80}, {0, 60}, {DO6, 80}};
const uint8_t kLargoInicio = sizeof(kMelodiaInicio) / sizeof(Nota);

// Antes de dormir: baja.
const Nota kMelodiaDormir[] = {{SOL5, 120}, {MI5, 120}, {DO5, 220}};
const uint8_t kLargoDormir = sizeof(kMelodiaDormir) / sizeof(Nota);

void Buzzer::tocar(const Nota *melodia, uint8_t cantidad, bool repetir) {
  melodia_ = melodia;
  cantidad_ = cantidad;
  repetir_ = repetir;
  indice_ = 0;
  notaEmpezada_ = false;
}

void Buzzer::detener() {
  melodia_ = nullptr;
  noTone(pin_);
}

void Buzzer::empezarNota(uint32_t ahoraMs) {
  const Nota &n = melodia_[indice_];
  if (n.frecuencia > 0) {
    tone(pin_, n.frecuencia);
  } else {
    noTone(pin_);
  }
  finNotaMs_ = ahoraMs + n.duracionMs;
  notaEmpezada_ = true;
}

void Buzzer::actualizar(uint32_t ahoraMs) {
  if (melodia_ == nullptr) return;
  if (!notaEmpezada_) {
    empezarNota(ahoraMs);
    return;
  }
  if (static_cast<int32_t>(ahoraMs - finNotaMs_) < 0) return;
  indice_++;
  if (indice_ >= cantidad_) {
    if (!repetir_) {
      detener();
      return;
    }
    indice_ = 0;
  }
  empezarNota(ahoraMs);
}
