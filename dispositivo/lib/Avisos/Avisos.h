// Lógica de la alarma y del modo dormir (sin nada de Arduino, para poder probarla aparte).
// Lo acordado está en PLAN_CODIGO_DISPOSITIVO.md, sección 4.
#pragma once

#include <stdint.h>

// Alarma corta: al tocar reaplicar suena ~10 s y se calla. Si no se presiona el botón,
// lo recuerda cada 10 min, máximo 3 veces; después solo queda la alerta en la pantalla.
class Alarma {
 public:
  static constexpr uint32_t kDuracionMs = 10UL * 1000;        // cuánto suena cada vez
  static constexpr uint32_t kIntervaloMs = 10UL * 60 * 1000;  // cada cuánto lo recuerda
  static constexpr uint8_t kRecordatorios = 3;                // cuántas veces lo recuerda

  // Empieza a tocar reaplicar: suena ya.
  void activar(uint32_t ahoraMs);
  // "Silenciar" desde la app: deja de sonar y no lo recuerda más (la alerta sigue en pantalla).
  void silenciar();
  // "Ya me reapliqué": se quita todo.
  void apagar();

  // ¿Debe estar sonando en este momento? (también avanza los recordatorios)
  bool debeSonar(uint32_t ahoraMs);

  bool alertaVisible() const { return activa_; }
  bool silenciada() const { return silenciada_; }
  uint8_t recordatoriosHechos() const { return recordatorios_; }

 private:
  bool activa_ = false;
  bool silenciada_ = false;
  uint32_t inicioMs_ = 0;  // cuándo empezó a sonar la última vez
  uint8_t recordatorios_ = 0;
};

// Modo dormir: si el sensor no detecta sol durante 30 min, la placa se duerme
// (pantalla, buzzer y Bluetooth apagados) y despierta con el botón.
class MonitorSueno {
 public:
  static constexpr uint32_t kSinSolMs = 30UL * 60 * 1000;

  void reiniciar(uint32_t ahoraMs) { ultimoSolMs_ = ahoraMs; }
  // Se llama en cada lectura del sensor.
  void actualizar(bool haySol, uint32_t ahoraMs) {
    if (haySol) ultimoSolMs_ = ahoraMs;
  }
  bool debeDormir(uint32_t ahoraMs) const { return ahoraMs - ultimoSolMs_ >= kSinSolMs; }
  uint32_t minutosSinSol(uint32_t ahoraMs) const { return (ahoraMs - ultimoSolMs_) / 60000UL; }

 private:
  uint32_t ultimoSolMs_ = 0;
};

// Quita acentos y la ñ de un texto UTF-8 (la letra de la pantalla no los tiene).
// Escribe en `destino` (máximo `tam` bytes, siempre termina en '\0').
void textoSinAcentos(const char *origen, char *destino, int tam);
