#include "memoria.h"

#include <Arduino.h>
#include <Preferences.h>

static const char *kEspacio = "sensoruv";

void cargarPerfil(PerfilUV &perfil) {
  Preferences p;
  if (!p.begin(kEspacio, true)) return;  // aún no hay nada guardado: perfil de fábrica
  PerfilUV leido;
  String nombre = p.getString("nombre", leido.nombre);
  strlcpy(leido.nombre, nombre.c_str(), sizeof(leido.nombre));
  leido.fototipo = p.getUChar("tipo", leido.fototipo);
  leido.fps = p.getUShort("fps", leido.fps);
  leido.resistenciaAguaMin = p.getUShort("resist", leido.resistenciaAguaMin);
  leido.sudorOAgua = p.getBool("sudor", leido.sudorOAgua);
  leido.lugar = static_cast<Lugar>(p.getUChar("lugar", static_cast<uint8_t>(leido.lugar)));
  p.end();
  if (leido.esValido()) perfil = leido;
}

void guardarPerfil(const PerfilUV &perfil) {
  Preferences p;
  if (!p.begin(kEspacio, false)) return;
  p.putString("nombre", perfil.nombre);
  p.putUChar("tipo", perfil.fototipo);
  p.putUShort("fps", perfil.fps);
  p.putUShort("resist", perfil.resistenciaAguaMin);
  p.putBool("sudor", perfil.sudorOAgua);
  p.putUChar("lugar", static_cast<uint8_t>(perfil.lugar));
  p.end();
}

// Memoria RTC: se conserva durante el sueño profundo, se borra al quitar la corriente.
struct CuentaGuardada {
  uint32_t marca;
  float dosis;
  float tiempoExpuestoS;
  bool tocaReaplicar;
};
static const uint32_t kMarca = 0x55564331;  // "UVC1"
RTC_DATA_ATTR static CuentaGuardada cuentaRtc;

void guardarCuentaAlDormir(const CalculoUV &calculo) {
  cuentaRtc.marca = kMarca;
  cuentaRtc.dosis = calculo.dosis;
  cuentaRtc.tiempoExpuestoS = calculo.tiempoExpuestoS;
  cuentaRtc.tocaReaplicar = calculo.tocaReaplicar;
}

bool recuperarCuentaAlDespertar(CalculoUV &calculo) {
  if (cuentaRtc.marca != kMarca) return false;
  calculo.dosis = cuentaRtc.dosis;
  calculo.tiempoExpuestoS = cuentaRtc.tiempoExpuestoS;
  calculo.tocaReaplicar = cuentaRtc.tocaReaplicar;
  cuentaRtc.marca = 0;
  return true;
}
