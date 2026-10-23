#include "pantalla.h"

#include <CalculoUV.h>
#include <Avisos.h>

// true si alguna pieza contesta en esa dirección del I2C
static bool responde(uint8_t direccion) {
  Wire.beginTransmission(direccion);
  return Wire.endTransmission() == 0;
}

bool Pantalla::iniciar() {
  // begin() de Adafruit dice que sí aunque no haya pantalla; escribirle a una pantalla
  // que no contesta traba el I2C (y con él, el sensor). Por eso primero se pregunta.
  uint8_t direccion = responde(0x3C) ? 0x3C : (responde(0x3D) ? 0x3D : 0);
  hay_ = direccion != 0 && oled_.begin(SSD1306_SWITCHCAPVCC, direccion);
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
  oled_.invertDisplay(false);
  oled_.clearDisplay();
  centrado(oled_, "Sensor UV", 14, 2);
  char v[24];
  snprintf(v, sizeof(v), "version %s", version);
  centrado(oled_, v, 44, 1);
  oled_.display();
}

void Pantalla::normal(const DatosPantalla &d) {
  if (!hay_) return;
  oled_.invertDisplay(false);
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
    oled_.display();
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
  oled_.display();
}

void Pantalla::alerta(bool invertida, bool silenciada) {
  if (!hay_) return;
  oled_.clearDisplay();
  centrado(oled_, "HORA DE", 4, 2);
  centrado(oled_, "REAPLICAR", 22, 2);
  centrado(oled_, silenciada ? "(silenciado)" : "Presiona el boton", 46, 1);
  centrado(oled_, "al ponerte bloqueador", 56, 1);
  oled_.invertDisplay(invertida);
  oled_.display();
}

void Pantalla::mensaje(const char *titulo, const char *detalle) {
  if (!hay_) return;
  oled_.invertDisplay(false);
  oled_.clearDisplay();
  centrado(oled_, titulo, 14, 2);
  centrado(oled_, detalle, 42, 1);
  oled_.display();
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
  oled_.invertDisplay(false);
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
  oled_.display();
}

void Pantalla::apagar() {
  if (!hay_) return;
  oled_.clearDisplay();
  oled_.display();
  oled_.ssd1306_command(SSD1306_DISPLAYOFF);
}
