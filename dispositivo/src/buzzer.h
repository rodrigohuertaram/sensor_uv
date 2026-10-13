// Buzzer pasivo: toca melodías cortas sin detener el resto del programa.
#pragma once

#include <stdint.h>

struct Nota {
  uint16_t frecuencia;  // Hz; 0 = silencio
  uint16_t duracionMs;
};

class Buzzer {
 public:
  void iniciar(uint8_t pin) { pin_ = pin; }
  // Empieza una melodía. Con `repetir`, vuelve a empezar al terminar hasta llamar a detener().
  void tocar(const Nota *melodia, uint8_t cantidad, bool repetir = false);
  void detener();
  // Llamar seguido (en cada vuelta del loop).
  void actualizar(uint32_t ahoraMs);
  bool sonando() const { return melodia_ != nullptr; }
  bool repitiendo() const { return sonando() && repetir_; }

 private:
  void empezarNota(uint32_t ahoraMs);

  uint8_t pin_ = 0;
  const Nota *melodia_ = nullptr;
  uint8_t cantidad_ = 0;
  uint8_t indice_ = 0;
  bool repetir_ = false;
  bool notaEmpezada_ = false;
  uint32_t finNotaMs_ = 0;
};

// Melodías del dispositivo
extern const Nota kMelodiaReaplicar[];
extern const uint8_t kLargoReaplicar;
extern const Nota kMelodiaListo[];
extern const uint8_t kLargoListo;
extern const Nota kMelodiaInicio[];
extern const uint8_t kLargoInicio;
extern const Nota kMelodiaDormir[];
extern const uint8_t kLargoDormir;
