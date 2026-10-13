// Ajustes generales del programa del dispositivo.
#pragma once

#define VERSION_PROGRAMA "0.1"

// Velocidad del reloj de la dosis: 1 = tiempo real.
// 60 = cada segundo cuenta como 1 minuto (modo demostración, entornos demo_* de platformio.ini).
#ifndef ACELERACION
#define ACELERACION 1
#endif

// Cada cuánto se lee el sensor y se actualiza la pantalla.
#define CADA_LECTURA_MS 1000UL

// Cuánto dura un mensaje corto en la pantalla (por ejemplo "Listo, cuenta desde cero").
#define DURACION_MENSAJE_MS 2500UL
