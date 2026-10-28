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

// Velocidad del I2C (sensor y pantalla). Se probó 100 kHz (2026-10-28), pero la pantalla
// rechazaba más mensajes: el ruido llega cada cierto tiempo y los mensajes lentos lo atrapan más.
// A 400 kHz falla menos; además pantalla.cpp reintenta lo que no llega.
#define VELOCIDAD_I2C 400000UL

// Cuánto dura un mensaje corto en la pantalla (por ejemplo "Listo, cuenta desde cero").
#define DURACION_MENSAJE_MS 2500UL

// Animaciones de la pantalla: salen de vez en cuando, a una hora al azar, mientras corre la cuenta
// (nunca encima de la alerta de reaplicar ni de un mensaje).
#define DURACION_ANIMACION_MS 3000UL
#if ACELERACION > 1
// Modo demostración: más seguido, para poder verlas al presentar
#define ANIMACION_CADA_MIN_MS (20UL * 1000)
#define ANIMACION_CADA_MAX_MS (40UL * 1000)
#else
#define ANIMACION_CADA_MIN_MS (2UL * 60 * 1000)
#define ANIMACION_CADA_MAX_MS (6UL * 60 * 1000)
#endif
