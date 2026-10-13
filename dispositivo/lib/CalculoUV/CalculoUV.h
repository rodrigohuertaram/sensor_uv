// Cálculo de cuándo reaplicar bloqueador: IGUAL al de la app (lib/modelo.dart).
// Si se cambia una constante aquí, cambiarla también en la app (y al revés).
//
// No usa nada de Arduino para poder probarlo aparte (dispositivo/test/test_calculo).
#pragma once

#include <stdint.h>

// Lugar: cuánto aumenta la dosis por el reflejo del suelo (Guía del Índice UV de la OMS).
// Con el sensor real NO se usan las nubes: el sensor ya mide el UV que pasa entre ellas.
enum class Lugar : uint8_t { ciudad = 0, parque, agua, playa, nieve };

float factorLugar(Lugar lugar);
const char *nombreLugar(Lugar lugar);           // "ciudad", "parque"... (para Bluetooth)
bool lugarDesdeNombre(const char *nombre, Lugar &lugar);

// Nivel de riesgo según el índice UV (escala de la OMS), sin acentos para la pantalla.
const char *nivelUV(float uvi);

// Datos del perfil activo (los manda la app; la placa los guarda en su memoria).
struct PerfilUV {
  char id[25] = "";               // id del perfil en la app (si cambia, es otra persona)
  char nombre[31] = "Mi perfil";  // máximo 30 caracteres, como en la app
  uint8_t fototipo = 3;           // tipo de piel 1 a 6
  uint16_t fps = 30;              // 15, 30, 50, 70 o 100
  uint16_t resistenciaAguaMin = 0;  // 0, 40 u 80
  bool sudorOAgua = false;
  Lugar lugar = Lugar::ciudad;

  bool esValido() const;
};

class CalculoUV {
 public:
  // Constantes (iguales a las de la app)
  static constexpr float kDem[7] = {0, 200, 250, 350, 450, 600, 1000};  // J/m2 por fototipo
  static constexpr float kFactorAplicacion = 0.3f;
  static constexpr float kMargenSeguridad = 0.6f;
  static constexpr float kTopeNormalMin = 120.0f;
  static constexpr float kWm2PorUvi = 0.025f;  // 1 punto de índice UV = 0.025 W/m2
  static constexpr float kUvMinimo = 1.0f;     // por debajo no se cuenta la dosis

  PerfilUV perfil;

  // Estado desde la última aplicación de bloqueador
  float dosis = 0;            // J/m2 acumulados
  float tiempoExpuestoS = 0;  // segundos al sol
  bool tocaReaplicar = false;

  // UV que de verdad recibe la piel: lo que mide el sensor más el reflejo del suelo.
  float uvEfectivo(float uviSensor) const;

  float limiteDosis() const;
  float topeTiempoMin() const;
  float topeTiempoS() const { return topeTiempoMin() * 60.0f; }

  // Suma la dosis de `segundos` con el UV medido. Devuelve true si en esta lectura
  // empezó a tocar reaplicar.
  bool actualizar(float uviSensor, float segundos);

  // Minutos que faltan para reaplicar con el sol de este momento.
  float restanteMin(float uviSensor) const;

  // Avance de 0 a 1 hacia el límite más cercano (dosis o tiempo).
  float avance() const;

  // Minutos en los que avisaría con un índice UV fijo (para comparar con la app).
  float minutosParaAvisar(float uviSensor) const;

  // "Ya me reapliqué" o cambio de perfil: la cuenta empieza desde cero.
  void reiniciar();
};
