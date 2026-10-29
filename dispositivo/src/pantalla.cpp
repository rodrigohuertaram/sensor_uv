#include "pantalla.h"

#include <CalculoUV.h>
#include <Avisos.h>

#include "pines.h"

// true si alguna pieza contesta en esa dirección del I2C
static bool responde(uint8_t direccion) {
  Wire.beginTransmission(direccion);
  return Wire.endTransmission() == 0;
}

// Manda órdenes a la pantalla y dice si llegaron (la pantalla contestó a cada byte).
bool Pantalla::ordenes(const uint8_t *lista, uint8_t cantidad) {
  Wire.beginTransmission(direccion_);
  Wire.write(0x00);  // lo que sigue son órdenes
  Wire.write(lista, cantidad);
  return Wire.endTransmission() == 0;
}

// Después de un error, el control del I2C de la ESP32 (Arduino 3.x) se queda trabado y rechaza
// los siguientes mensajes ("ESP_ERR_INVALID_STATE"). Se apaga y se vuelve a prender para reintentar.
static void reiniciarI2C() {
  Wire.end();
  Wire.begin(PIN_SDA, PIN_SCL);
  Wire.setClock(VELOCIDAD_I2C);
}

// Manda la imagen a la pantalla revisando que cada pedazo llegue; si uno falla, lo reintenta
// (hasta 10 veces).
// Antes también le repite los ajustes de posición (renglón 0, sin desplazamiento) y si va
// invertida. Así, aunque haya ruido en los cables (2026-10-28 se perdía ~10 % de los mensajes
// por la energía de la pantalla), la imagen sale completa y en su lugar. La librería de Adafruit
// manda todo de corrido sin revisar, por eso la imagen se veía partida o recorrida.
void Pantalla::mostrar() {
  // Cada lista empieza con dos órdenes "no hacer nada" (0xE3): si un mensaje anterior se cortó
  // y la pantalla quedó esperando un número, se los come a ellos y no a una orden de verdad.
  const uint8_t ajustes[] = {0xE3, 0xE3, SSD1306_DEACTIVATE_SCROLL,
                             SSD1306_SETSTARTLINE | 0,
                             SSD1306_SETDISPLAYOFFSET, 0,
                             SSD1306_SEGREMAP | 0x1,
                             SSD1306_COMSCANDEC,
                             SSD1306_MEMORYMODE, 0x00,  // horizontal
                             static_cast<uint8_t>(invertida_ ? SSD1306_INVERTDISPLAY : SSD1306_NORMALDISPLAY)};
  for (int intento = 0; intento < 5 && !ordenes(ajustes, sizeof(ajustes)); intento++) {
    reiniciarI2C();
  }

  // La imagen se manda en pedazos de 16 bytes, cada uno con su lugar exacto (franja y columnas),
  // y solo se reintenta el pedazo que falló. Con pedazos grandes casi nunca pasaba uno completo.
  const uint8_t *imagen = oled_.getBuffer();
  const uint8_t kPedazo = 16;
  for (uint8_t franja = 0; franja < 8; franja++) {
    for (uint8_t x = 0; x < 128; x += kPedazo) {
      bool llego = false;
      for (int intento = 0; intento < 10 && !llego; intento++) {
        const uint8_t lugar[] = {0xE3, 0xE3, SSD1306_COLUMNADDR, x, static_cast<uint8_t>(x + kPedazo - 1),
                                 SSD1306_PAGEADDR, franja, franja};
        if (ordenes(lugar, sizeof(lugar))) {
          Wire.beginTransmission(direccion_);
          Wire.write(0x40);  // lo que sigue es imagen
          Wire.write(imagen + franja * 128 + x, kPedazo);
          llego = Wire.endTransmission() == 0;
        }
        if (!llego) {
          fallas_++;
          reiniciarI2C();
        }
      }
      if (!llego) perdidas_++;
    }
  }
}

bool Pantalla::iniciar() {
  // begin() de Adafruit dice que sí aunque no haya pantalla; escribirle a una pantalla
  // que no contesta traba el I2C (y con él, el sensor). Por eso primero se pregunta.
  uint8_t direccion = responde(0x3C) ? 0x3C : (responde(0x3D) ? 0x3D : 0);
  hay_ = direccion != 0 && oled_.begin(SSD1306_SWITCHCAPVCC, direccion);
  direccion_ = direccion;
  if (hay_) {
    oled_.setTextColor(SSD1306_WHITE);
    oled_.cp437(true);
  }
  return hay_;
}

static void centrado(Adafruit_SSD1306 &o, const char *texto, int y, int tam) {
  o.setTextSize(tam);
  int ancho = strlen(texto) * 6 * tam;
  o.setCursor(ancho < 128 ? (128 - ancho) / 2 : 0, y);
  o.print(texto);
}

void Pantalla::bienvenida(const char *version) {
  if (!hay_) return;
  invertida_ = false;
  oled_.clearDisplay();
  // "Solaris Shield" no cabe en un renglón con letra grande: va en dos
  centrado(oled_, "Solaris", 6, 2);
  centrado(oled_, "Shield", 26, 2);
  char v[24];
  snprintf(v, sizeof(v), "version %s", version);
  centrado(oled_, v, 52, 1);
  mostrar();
}

void Pantalla::normal(const DatosPantalla &d) {
  if (!hay_) return;
  invertida_ = false;
  oled_.clearDisplay();
  oled_.setTextSize(1);

  // Renglón de arriba: perfil y FPS; "BT" si el celular está conectado
  char nombre[22];
  textoSinAcentos(d.nombrePerfil, nombre, 15);
  oled_.setCursor(0, 0);
  oled_.printf("%s FPS%u", nombre, d.fps);
  if (d.conectado) {
    oled_.setCursor(116, 0);
    oled_.print("BT");
  }

  if (!d.haySensor) {
    centrado(oled_, "Sin sensor UV", 24, 1);
    centrado(oled_, "Revisa los cables", 38, 1);
    mostrar();
    return;
  }

  // Índice UV grande y su nivel
  oled_.setTextSize(3);
  oled_.setCursor(0, 12);
  oled_.printf("%.1f", d.uvi);
  oled_.setTextSize(1);
  oled_.setCursor(80, 14);
  oled_.print("UV");
  oled_.setCursor(80, 26);
  oled_.print(nivelUV(d.uvi));

  // Barra de avance hacia reaplicar
  oled_.drawRect(0, 40, 128, 8, SSD1306_WHITE);
  int lleno = static_cast<int>(d.avance * 124);
  if (lleno > 0) oled_.fillRect(2, 42, lleno, 4, SSD1306_WHITE);

  oled_.setCursor(0, 54);
  if (!d.haySol) {
    oled_.print("Sin sol: en pausa");
  } else {
    int min = static_cast<int>(d.restanteMin + 0.5f);
    if (min >= 60) {
      oled_.printf("Faltan %d h %02d min", min / 60, min % 60);
    } else {
      oled_.printf("Faltan %d min", min);
    }
  }
  mostrar();
}

void Pantalla::alerta(bool invertida, bool silenciada) {
  if (!hay_) return;
  oled_.clearDisplay();
  centrado(oled_, "HORA DE", 4, 2);
  centrado(oled_, "REAPLICAR", 22, 2);
  centrado(oled_, silenciada ? "(silenciado)" : "Presiona el boton", 46, 1);
  centrado(oled_, "al ponerte bloqueador", 56, 1);
  invertida_ = invertida;
  mostrar();
}

void Pantalla::mensaje(const char *titulo, const char *detalle) {
  if (!hay_) return;
  invertida_ = false;
  oled_.clearDisplay();
  centrado(oled_, titulo, 14, 2);
  centrado(oled_, detalle, 42, 1);
  mostrar();
}

// ---------- Animaciones ----------

// Sol: círculo con 8 rayos. `giro` en radianes, `largo` de los rayos en pixeles.
static void dibujarSol(Adafruit_SSD1306 &o, int cx, int cy, int r, float giro, int largo) {
  o.drawCircle(cx, cy, r, SSD1306_WHITE);
  o.drawCircle(cx, cy, r - 1, SSD1306_WHITE);
  for (int i = 0; i < 8; i++) {
    float a = giro + i * PI / 4;
    o.drawLine(cx + cosf(a) * (r + 3), cy + sinf(a) * (r + 3), cx + cosf(a) * (r + 3 + largo),
               cy + sinf(a) * (r + 3 + largo), SSD1306_WHITE);
  }
}

// Sonrisa: más abajo en el centro que en las orillas.
static void dibujarSonrisa(Adafruit_SSD1306 &o, int cx, int cy, int ancho) {
  for (int dx = -ancho; dx <= ancho; dx++) {
    o.drawPixel(cx + dx, cy + (ancho * ancho - dx * dx) / (2 * ancho), SSD1306_WHITE);
  }
}

// Gota de bloqueador: círculo con punta hacia arriba.
static void dibujarGota(Adafruit_SSD1306 &o, int x, int y) {
  o.fillCircle(x, y, 3, SSD1306_WHITE);
  o.fillTriangle(x - 3, y, x + 3, y, x, y - 7, SSD1306_WHITE);
}

void Pantalla::animacion(uint8_t tipo, uint16_t cuadro) {
  if (!hay_) return;
  invertida_ = false;
  oled_.clearDisplay();
  oled_.setTextColor(SSD1306_WHITE);

  if (tipo == 0) {
    // Sol sonriente con rayos que giran
    dibujarSol(oled_, 64, 26, 12, cuadro * 0.12f, 6);
    oled_.fillCircle(60, 23, 1, SSD1306_WHITE);
    oled_.fillCircle(68, 23, 1, SSD1306_WHITE);
    dibujarSonrisa(oled_, 64, 29, 5);
    centrado(oled_, "Protegete del sol", 56, 1);

  } else if (tipo == 1) {
    // Sol con lentes de sol que entra desde la izquierda; los rayos laten y los lentes brillan
    int cx = -20 + cuadro * 6;
    if (cx > 64) cx = 64;
    int largo = 4 + static_cast<int>(3 * sinf(cuadro * 0.5f));
    dibujarSol(oled_, cx, 26, 13, 0, largo);
    oled_.fillRoundRect(cx - 10, 20, 9, 6, 2, SSD1306_WHITE);
    oled_.fillRoundRect(cx + 1, 20, 9, 6, 2, SSD1306_WHITE);
    oled_.drawLine(cx - 1, 22, cx + 1, 22, SSD1306_WHITE);
    if (cx == 64 && cuadro % 12 < 3) {  // brillo en un lente
      oled_.drawPixel(cx - 7, 22, SSD1306_BLACK);
      oled_.drawPixel(cx - 6, 21, SSD1306_BLACK);
      oled_.drawPixel(cx - 5, 22, SSD1306_BLACK);
      oled_.drawPixel(cx - 6, 23, SSD1306_BLACK);
    }
    dibujarSonrisa(oled_, cx, 31, 6);
    centrado(oled_, "Disfruta con cuidado", 56, 1);

  } else {
    // Bote de bloqueador que suelta gotas
    oled_.fillRect(16, 4, 6, 4, SSD1306_WHITE);           // boquilla
    oled_.fillRect(12, 8, 14, 8, SSD1306_WHITE);          // tapa
    oled_.fillRoundRect(6, 17, 26, 42, 4, SSD1306_WHITE);  // bote
    oled_.setTextColor(SSD1306_BLACK);
    oled_.setTextSize(1);
    oled_.setCursor(11, 28);
    oled_.print("FPS");
    oled_.setCursor(13, 40);
    oled_.print("50");
    oled_.setTextColor(SSD1306_WHITE);

    int y = 10 + (cuadro * 4) % 40;
    if (y < 46) {
      dibujarGota(oled_, 44, y);
    } else {  // la gota cae y salpica
      oled_.drawLine(38, 52, 41, 49, SSD1306_WHITE);
      oled_.drawLine(50, 52, 47, 49, SSD1306_WHITE);
      oled_.drawPixel(44, 47, SSD1306_WHITE);
    }
    oled_.drawLine(36, 55, 52, 55, SSD1306_WHITE);

    oled_.setCursor(62, 18);
    oled_.print("No olvides");
    oled_.setCursor(62, 30);
    oled_.print("tu");
    oled_.setCursor(62, 42);
    oled_.print("bloqueador");
  }
  mostrar();
}

void Pantalla::apagar() {
  if (!hay_) return;
  oled_.clearDisplay();
  mostrar();
  oled_.ssd1306_command(SSD1306_DISPLAYOFF);
}
