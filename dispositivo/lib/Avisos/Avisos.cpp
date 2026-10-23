#include "Avisos.h"

void Alarma::activar(uint32_t ahoraMs) {
  activa_ = true;
  silenciada_ = false;
  inicioMs_ = ahoraMs;
}

void Alarma::silenciar() { silenciada_ = true; }

void Alarma::apagar() {
  activa_ = false;
  silenciada_ = false;
}

bool Alarma::debeSonar(uint32_t ahoraMs) const {
  if (!activa_ || silenciada_) return false;
  return (ahoraMs - inicioMs_) % (kSuenaMs + kPausaMs) < kSuenaMs;
}

void textoSinAcentos(const char *origen, char *destino, int tam) {
  // Pares UTF-8 de 2 bytes (0xC3 + segundo byte) -> letra sin acento
  struct Cambio {
    unsigned char segundo;
    char letra;
  };
  static const Cambio cambios[] = {
      {0xA1, 'a'}, {0xA9, 'e'}, {0xAD, 'i'}, {0xB3, 'o'}, {0xBA, 'u'}, {0xBC, 'u'}, {0xB1, 'n'},
      {0x81, 'A'}, {0x89, 'E'}, {0x8D, 'I'}, {0x93, 'O'}, {0x9A, 'U'}, {0x9C, 'U'}, {0x91, 'N'},
  };
  int j = 0;
  for (int i = 0; origen[i] != '\0' && j < tam - 1; i++) {
    unsigned char c = static_cast<unsigned char>(origen[i]);
    if (c < 0x80) {
      destino[j++] = static_cast<char>(c);
    } else if (c == 0xC3 && origen[i + 1] != '\0') {
      unsigned char s = static_cast<unsigned char>(origen[++i]);
      char letra = '?';
      for (const Cambio &k : cambios) {
        if (k.segundo == s) letra = k.letra;
      }
      destino[j++] = letra;
    } else {
      // Otro carácter de varios bytes: se salta completo y se pone '?'
      while ((static_cast<unsigned char>(origen[i + 1]) & 0xC0) == 0x80) i++;
      destino[j++] = '?';
    }
  }
  destino[j] = '\0';
}
