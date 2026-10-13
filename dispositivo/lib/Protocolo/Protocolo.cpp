#include "Protocolo.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

namespace protocolo {

namespace {
// Copia `valor` (de largo `n`) a `destino` terminado en '\0', recortando si no cabe.
void copiar(char *destino, size_t tam, const char *valor, size_t n) {
  if (n >= tam) n = tam - 1;
  memcpy(destino, valor, n);
  destino[n] = '\0';
}

bool numeroEntero(const char *texto, long &numero) {
  char *fin = nullptr;
  numero = strtol(texto, &fin, 10);
  return fin != texto && *fin == '\0';
}
}  // namespace

bool leerConfiguracion(const char *texto, const PerfilUV &actual, PerfilUV &resultado) {
  PerfilUV p = actual;
  const char *pos = texto;
  while (*pos != '\0') {
    const char *finPar = strchr(pos, ';');
    size_t largoPar = finPar ? static_cast<size_t>(finPar - pos) : strlen(pos);
    const char *igual = static_cast<const char *>(memchr(pos, '=', largoPar));
    if (igual == nullptr || igual == pos) return false;

    char clave[4];
    copiar(clave, sizeof(clave), pos, igual - pos);
    char valor[40];
    copiar(valor, sizeof(valor), igual + 1, largoPar - (igual - pos) - 1);

    long n = 0;
    if (strcmp(clave, "i") == 0) {
      copiar(p.id, sizeof(p.id), valor, strlen(valor));
    } else if (strcmp(clave, "n") == 0) {
      if (valor[0] == '\0') return false;
      copiar(p.nombre, sizeof(p.nombre), valor, strlen(valor));
    } else if (strcmp(clave, "t") == 0) {
      if (!numeroEntero(valor, n) || n < 1 || n > 6) return false;
      p.fototipo = static_cast<uint8_t>(n);
    } else if (strcmp(clave, "f") == 0) {
      if (!numeroEntero(valor, n) || n < 1 || n > 100) return false;
      p.fps = static_cast<uint16_t>(n);
    } else if (strcmp(clave, "r") == 0) {
      if (!numeroEntero(valor, n) || n < 0 || n > 240) return false;
      p.resistenciaAguaMin = static_cast<uint16_t>(n);
    } else if (strcmp(clave, "s") == 0) {
      if (!numeroEntero(valor, n) || (n != 0 && n != 1)) return false;
      p.sudorOAgua = n == 1;
    } else if (strcmp(clave, "l") == 0) {
      if (!lugarDesdeNombre(valor, p.lugar)) return false;
    }
    // Claves desconocidas se ignoran (para versiones futuras de la app)

    if (finPar == nullptr) break;
    pos = finPar + 1;
  }
  if (!p.esValido()) return false;
  resultado = p;
  return true;
}

void escribirConfiguracion(const PerfilUV &perfil, char *destino, size_t tam) {
  snprintf(destino, tam, "i=%s;n=%s;t=%u;f=%u;r=%u;s=%u;l=%s", perfil.id, perfil.nombre,
           perfil.fototipo, perfil.fps, perfil.resistenciaAguaMin, perfil.sudorOAgua ? 1 : 0,
           nombreLugar(perfil.lugar));
}

void escribirEstado(const Estado &e, char *destino, size_t tam) {
  int av = static_cast<int>(e.avance * 100 + 0.5f);
  int min = static_cast<int>(e.restanteMin + 0.5f);
  snprintf(destino, tam, "uv=%.1f;av=%d;min=%d;rea=%d;sil=%d;sol=%d;bat=%d", e.uvi, av, min,
           e.tocaReaplicar ? 1 : 0, e.silenciada ? 1 : 0, e.haySol ? 1 : 0, e.bateria);
}

}  // namespace protocolo
