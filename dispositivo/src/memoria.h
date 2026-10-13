// Memoria de la placa:
//  - el perfil (lo manda la app) se guarda en la memoria flash y sobrevive a apagarla;
//  - la cuenta de sol se guarda en la memoria RTC al dormir, para seguir al despertar.
//    Con el interruptor (apagado total) la cuenta empieza de cero.
#pragma once

#include <CalculoUV.h>

void cargarPerfil(PerfilUV &perfil);
void guardarPerfil(const PerfilUV &perfil);

void guardarCuentaAlDormir(const CalculoUV &calculo);
// Devuelve true si había una cuenta guardada (la placa venía de dormir).
bool recuperarCuentaAlDespertar(CalculoUV &calculo);
