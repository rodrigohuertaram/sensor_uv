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

void Pantalla::apagar() {
  if (!hay_) return;
  oled_.clearDisplay();
  oled_.display();
  oled_.ssd1306_command(SSD1306_DISPLAYOFF);
}
