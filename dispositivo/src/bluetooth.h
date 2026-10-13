// Bluetooth de bajo consumo (BLE): la placa anuncia "Sensor UV" y la app se conecta.
// Tres canales (ver lib/Protocolo): Configuración, Estado y Órdenes.
#pragma once

#include <stddef.h>

namespace bluetooth {

void iniciar();
bool conectado();

// Lo que llegó desde la app (se recoge en el loop, fuera de las funciones del Bluetooth).
struct Recibido {
  bool hayConfiguracion = false;
  char configuracion[128] = "";
  bool reaplicado = false;
  bool silenciar = false;
  bool dormir = false;
};
// Devuelve true si llegó algo nuevo y lo copia en `r`.
bool tomarRecibido(Recibido &r);

void publicarEstado(const char *texto);         // notifica a la app (cada segundo)
void publicarConfiguracion(const char *texto);  // la deja para que la app la lea
void avisarOrden(const char *orden);            // por ejemplo "reaplicado" (botón de la placa)

}  // namespace bluetooth
