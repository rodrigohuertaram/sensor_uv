// Sueño profundo: se apagan pantalla, buzzer y Bluetooth; despierta al presionar el botón.
#pragma once

#include <stdint.h>

// Prepara el botón para despertar a la placa y la duerme (no regresa: al despertar,
// el programa empieza otra vez desde setup()).
[[noreturn]] void dormirHastaElBoton(uint8_t pinBoton);

// true si la placa acaba de despertar por el botón.
bool despertoPorBoton();

// Al empezar el programa: suelta el pin del botón (en la XIAO queda "congelado" para dormir).
void liberarBotonAlDespertar(uint8_t pinBoton);
