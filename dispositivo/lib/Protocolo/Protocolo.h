// Formato de los mensajes por Bluetooth entre la app y la placa.
// Son textos cortos "clave=valor;clave=valor" para poder leerlos también con nRF Connect.
// La app (lib/dispositivo.dart) usa exactamente el mismo formato.
//
//   Configuración (app -> placa; la placa también la deja para leer):
//     i=<id del perfil>;n=<nombre>;t=<tipo 1-6>;f=<FPS>;r=<resistencia 0/40/80>;s=<sudor 0/1>;l=<lugar>
//     lugar: ciudad, parque, agua, playa o nieve
//   Estado (placa -> app, cada segundo):
//     uv=5.2;av=43;min=37;rea=0;sil=0;sol=1;bat=-1
//     uv = índice UV medido, av = avance en %, min = minutos para reaplicar,
//     rea = toca reaplicar, sil = alarma silenciada, sol = hay sol, bat = batería en % (-1 = no se mide)
//   Órdenes (los dos sentidos):  reaplicado | silenciar | dormir
#pragma once

#include <stddef.h>

#include <CalculoUV.h>

namespace protocolo {

// UUID del servicio y de sus tres canales (características)
constexpr const char *kServicio = "5e6c0001-7a3b-4c2d-9f10-53e05a7b1c01";
constexpr const char *kConfiguracion = "5e6c0002-7a3b-4c2d-9f10-53e05a7b1c01";
constexpr const char *kEstado = "5e6c0003-7a3b-4c2d-9f10-53e05a7b1c01";
constexpr const char *kOrdenes = "5e6c0004-7a3b-4c2d-9f10-53e05a7b1c01";
constexpr const char *kNombreDispositivo = "Sensor UV";

constexpr const char *kOrdenReaplicado = "reaplicado";
constexpr const char *kOrdenSilenciar = "silenciar";
constexpr const char *kOrdenDormir = "dormir";

// Lee una configuración. Parte de `actual` (lo que falte se queda igual).
// Devuelve false si el texto no es válido (y no cambia `resultado`).
bool leerConfiguracion(const char *texto, const PerfilUV &actual, PerfilUV &resultado);

void escribirConfiguracion(const PerfilUV &perfil, char *destino, size_t tam);

struct Estado {
  float uvi;
  float avance;  // 0 a 1
  float restanteMin;
  bool tocaReaplicar;
  bool silenciada;
  bool haySol;
  int bateria;  // % o -1
};

void escribirEstado(const Estado &estado, char *destino, size_t tam);

}  // namespace protocolo
