#include "CalculoUV.h"

#include <string.h>

constexpr float CalculoUV::kDem[7];

namespace {
struct DatosLugar {
  const char *nombre;
  float factor;
};

// Mismo orden que el enum Lugar
const DatosLugar kLugares[] = {
    {"ciudad", 1.0f},
    {"parque", 1.0f},
    {"agua", 1.1f},
    {"playa", 1.25f},
    {"nieve", 1.8f},
};
const int kNumLugares = sizeof(kLugares) / sizeof(kLugares[0]);

float minimo(float a, float b) { return a < b ? a : b; }
float maximo(float a, float b) { return a > b ? a : b; }
}  // namespace

float factorLugar(Lugar lugar) {
  int i = static_cast<int>(lugar);
  return (i >= 0 && i < kNumLugares) ? kLugares[i].factor : 1.0f;
}

const char *nombreLugar(Lugar lugar) {
  int i = static_cast<int>(lugar);
  return (i >= 0 && i < kNumLugares) ? kLugares[i].nombre : "ciudad";
}

bool lugarDesdeNombre(const char *nombre, Lugar &lugar) {
  for (int i = 0; i < kNumLugares; i++) {
    if (strcmp(nombre, kLugares[i].nombre) == 0) {
      lugar = static_cast<Lugar>(i);
      return true;
    }
  }
  return false;
}

const char *nivelUV(float uvi) {
  if (uvi < 3) return "Bajo";
  if (uvi < 6) return "Moderado";
  if (uvi < 8) return "Alto";
  if (uvi < 11) return "Muy alto";
  return "Extremo";
}

bool PerfilUV::esValido() const {
  return fototipo >= 1 && fototipo <= 6 && fps >= 1 && fps <= 100 &&
         static_cast<int>(lugar) < kNumLugares;
}

float CalculoUV::uvEfectivo(float uviSensor) const {
  return uviSensor * factorLugar(perfil.lugar);
}

float CalculoUV::limiteDosis() const {
  return kDem[perfil.fototipo] * perfil.fps * kFactorAplicacion * kMargenSeguridad;
}

float CalculoUV::topeTiempoMin() const {
  if (!perfil.sudorOAgua) return kTopeNormalMin;
  return perfil.resistenciaAguaMin >= 80 ? 80.0f : 40.0f;
}

bool CalculoUV::actualizar(float uviSensor, float segundos) {
  // Después de una pausa larga no hace falta contar más allá del tope de tiempo
  float dt = minimo(segundos, topeTiempoS());
  float efectivo = uvEfectivo(uviSensor);
  if (!tocaReaplicar && efectivo >= kUvMinimo) {
    dosis += kWm2PorUvi * efectivo * dt;
    tiempoExpuestoS += dt;
  }
  bool antes = tocaReaplicar;
  if (dosis >= limiteDosis() || tiempoExpuestoS >= topeTiempoS()) {
    tocaReaplicar = true;
  }
  return tocaReaplicar && !antes;
}

float CalculoUV::restanteMin(float uviSensor) const {
  float restanteS = topeTiempoS() - tiempoExpuestoS;
  float efectivo = uvEfectivo(uviSensor);
  if (efectivo >= kUvMinimo) {
    float porDosis = (limiteDosis() - dosis) / (kWm2PorUvi * efectivo);
    if (porDosis < restanteS) restanteS = porDosis;
  }
  if (restanteS < 0) restanteS = 0;
  return restanteS / 60.0f;
}

float CalculoUV::avance() const {
  float a = maximo(dosis / limiteDosis(), tiempoExpuestoS / topeTiempoS());
  if (a < 0) a = 0;
  if (a > 1) a = 1;
  return a;
}

float CalculoUV::minutosParaAvisar(float uviSensor) const {
  float porTope = topeTiempoMin();
  float efectivo = uvEfectivo(uviSensor);
  if (efectivo < kUvMinimo) return porTope;
  float porDosis = limiteDosis() / (kWm2PorUvi * efectivo) / 60.0f;
  return minimo(porTope, porDosis);
}

void CalculoUV::reiniciar() {
  dosis = 0;
  tiempoExpuestoS = 0;
  tocaReaplicar = false;
}

UvCombinado combinarUV(float uvSensor, bool haySensor, float uvClima, bool climaVigente) {
  bool hayClima = climaVigente && uvClima >= 0;
  if (!hayClima) return {uvSensor, 100, 0, false};
  if (!haySensor) return {uvClima, 0, 100, false};
  // El sensor marca más (reflejos, altura): se usa el valor más alto
  if (uvSensor >= uvClima) return {uvSensor, 100, 0, false};
  // Casi nada de UV en el sensor: adentro, de noche o tapado; no se cuenta sol
  if (uvSensor < kSensorMinimoSombra) return {uvSensor, 100, 0, false};
  float mezcla = kPesoSensor * uvSensor + (1.0f - kPesoSensor) * uvClima;
  float piso = kPisoSombra * uvClima;
  uint8_t ps = static_cast<uint8_t>(kPesoSensor * 100 + 0.5f);
  if (mezcla < piso) return {piso, ps, static_cast<uint8_t>(100 - ps), true};
  return {mezcla, ps, static_cast<uint8_t>(100 - ps), false};
}
