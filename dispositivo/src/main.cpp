// Sensor UV - programa del dispositivo ("la placa es el cerebro").
//
// Mide el UV, cuenta la dosis de sol con el perfil guardado, muestra todo en la pantalla
// y avisa con el buzzer cuando toca reaplicar bloqueador. Lo acordado está en
// PLAN_CODIGO_DISPOSITIVO.md; las conexiones, en DIAGRAMA_CONEXIONES.md.
//
// Con la app se comunica por Bluetooth (ver lib/Protocolo y bluetooth.h).
//
// Órdenes por el Monitor Serie (115200 baudios), para probar sin la app:
//   r          "Ya me reapliqué"
//   s          Silenciar la alarma
//   d          Dormir
//   uv 7.5     Fijar un índice UV a mano (sirve sin sensor)
//   p          Ver el perfil y la cuenta
//   a          Mostrar una animación ya

#ifndef PRUEBA_COMPONENTES

#include <Arduino.h>
#include <Wire.h>

#include <Avisos.h>
#include <CalculoUV.h>
#include <Protocolo.h>

#include "bluetooth.h"
#include "boton.h"
#include "buzzer.h"
#include "config.h"
#include "dormir.h"
#include "memoria.h"
#include "pantalla.h"
#include "pines.h"
#include "sensor_uv.h"

static CalculoUV calculo;
static Alarma alarma;
static MonitorSueno sueno;
static SensorUV sensor;
static Pantalla pantalla;
static Buzzer buzzer;
static Boton boton;

static float uvi = 0;               // último índice UV medido
static uint32_t ultimaLecturaMs = 0;
static uint32_t mensajeHastaMs = 0;  // mientras se muestra un mensaje corto
static bool parpadeo = false;

// Animación de vez en cuando (ver config.h)
static bool animando = false;
static uint8_t tipoAnimacion = 0;
static uint32_t inicioAnimacionMs = 0;
static uint32_t ultimoCuadroMs = 0;
static uint32_t proximaAnimacionMs = 0;

// ---------- Acciones (las mismas que llegarán desde la app) ----------

// `desdeLaApp`: si vino de la app no hace falta avisarle.
void reaplicado(bool desdeLaApp = false) {
  calculo.reiniciar();
  alarma.apagar();
  buzzer.tocar(kMelodiaListo, kLargoListo);
  pantalla.mensaje("Listo", "Cuenta desde cero");
  mensajeHastaMs = millis() + DURACION_MENSAJE_MS;
  Serial.println("Ya me reapliqué: la cuenta empieza desde cero.");
  if (!desdeLaApp) bluetooth::avisarOrden(protocolo::kOrdenReaplicado);
}

void publicarConfiguracion() {
  char texto[128];
  protocolo::escribirConfiguracion(calculo.perfil, texto, sizeof(texto));
  bluetooth::publicarConfiguracion(texto);
}

// Llega la configuración desde la app. Si es otra persona (otro perfil), la cuenta empieza de cero.
void recibirConfiguracion(const char *texto) {
  PerfilUV nuevo;
  if (!protocolo::leerConfiguracion(texto, calculo.perfil, nuevo)) {
    Serial.printf("Configuracion no valida: %s\n", texto);
    return;
  }
  bool otraPersona = strcmp(nuevo.id, calculo.perfil.id) != 0;
  calculo.perfil = nuevo;
  guardarPerfil(nuevo);
  publicarConfiguracion();
  if (otraPersona) {
    calculo.reiniciar();
    alarma.apagar();
    buzzer.detener();
    char nombre[22];
    textoSinAcentos(nuevo.nombre, nombre, 15);
    pantalla.mensaje("Perfil", nombre);
    mensajeHastaMs = millis() + DURACION_MENSAJE_MS;
  }
  Serial.printf("Configuracion recibida%s: %s\n", otraPersona ? " (otro perfil, cuenta desde cero)" : "", texto);
}

void publicarEstado(bool haySol) {
  protocolo::Estado e{uvi, calculo.avance(), calculo.restanteMin(uvi), calculo.tocaReaplicar,
                      alarma.silenciada(), haySol, -1};
  char texto[80];
  protocolo::escribirEstado(e, texto, sizeof(texto));
  bluetooth::publicarEstado(texto);
}

void silenciar() {
  alarma.silenciar();
  buzzer.detener();
  Serial.println("Alarma silenciada (la alerta sigue en la pantalla).");
}

[[noreturn]] void dormir() {
  buzzer.detener();
  buzzer.tocar(kMelodiaDormir, kLargoDormir);
  pantalla.mensaje("Durmiendo", "Presiona el boton");
  uint32_t fin = millis() + 2000;
  while (millis() < fin) {
    buzzer.actualizar(millis());
    delay(5);
  }
  buzzer.detener();
  pantalla.apagar();
  guardarCuentaAlDormir(calculo);
  dormirHastaElBoton(PIN_BOTON);
}

// ---------- Monitor Serie ----------

void mostrarEstado() {
  Serial.printf("Perfil: %s | tipo %u | FPS %u | resistencia %u min | sudor/agua %s | lugar %s\n",
                calculo.perfil.nombre, calculo.perfil.fototipo, calculo.perfil.fps,
                calculo.perfil.resistenciaAguaMin, calculo.perfil.sudorOAgua ? "si" : "no",
                nombreLugar(calculo.perfil.lugar));
  Serial.printf("Limite %.0f J/m2 | tope %.0f min | dosis %.1f | expuesto %.1f min | toca reaplicar: %s\n",
                calculo.limiteDosis(), calculo.topeTiempoMin(), calculo.dosis,
                calculo.tiempoExpuestoS / 60.0f, calculo.tocaReaplicar ? "si" : "no");
}

void leerOrdenSerie() {
  if (!Serial.available()) return;
  String linea = Serial.readStringUntil('\n');
  linea.trim();
  if (linea == "r") {
    reaplicado();
  } else if (linea == "s") {
    silenciar();
  } else if (linea == "d") {
    dormir();
  } else if (linea == "p") {
    mostrarEstado();
  } else if (linea == "a") {
    proximaAnimacionMs = millis();  // la siguiente animación sale ya
    Serial.println("Animacion");
  } else if (linea.startsWith("uv ")) {
    sensor.fijarSimulado(linea.substring(3).toFloat());
    Serial.printf("UV fijado a mano: %.1f\n", linea.substring(3).toFloat());
  } else if (linea.length() > 0) {
    Serial.println("Ordenes: r (reaplique), s (silenciar), d (dormir), p (perfil), a (animacion), uv 7.5");
  }
}

// ---------- Animaciones ----------

void programarAnimacion(uint32_t ahora) {
  proximaAnimacionMs = ahora + random(ANIMACION_CADA_MIN_MS, ANIMACION_CADA_MAX_MS + 1);
}

// Empieza una animación al azar cuando toca y dibuja sus cuadros. No tapa la alerta ni los mensajes:
// si aparece uno, la animación se corta y se programa otra.
void actualizarAnimacion(uint32_t ahora) {
  if (!pantalla.hay()) return;
  bool ocupada = alarma.alertaVisible() || ahora < mensajeHastaMs;
  if (!animando) {
    if (ocupada || static_cast<int32_t>(ahora - proximaAnimacionMs) < 0) return;
    animando = true;
    tipoAnimacion = random(Pantalla::kTiposAnimacion);
    inicioAnimacionMs = ahora;
    ultimoCuadroMs = ahora - 80;
  }
  uint32_t pasado = ahora - inicioAnimacionMs;
  if (ocupada || pasado >= DURACION_ANIMACION_MS) {
    animando = false;
    programarAnimacion(ahora);
    return;
  }
  if (ahora - ultimoCuadroMs >= 80) {
    ultimoCuadroMs = ahora;
    pantalla.animacion(tipoAnimacion, pasado / 80);
  }
}

// ---------- Programa ----------

void setup() {
  Serial.begin(115200);
  liberarBotonAlDespertar(PIN_BOTON);
  boton.iniciar(PIN_BOTON);
  buzzer.iniciar(PIN_BUZZER);
  Wire.begin(PIN_SDA, PIN_SCL);

  cargarPerfil(calculo.perfil);
  bool veniaDeDormir = despertoPorBoton() && recuperarCuentaAlDespertar(calculo);

  pantalla.iniciar();
  sensor.iniciar();
  bluetooth::iniciar();
  publicarConfiguracion();

  if (veniaDeDormir) {
    pantalla.mensaje("Hola", "Sigo con tu cuenta");
  } else {
    pantalla.bienvenida(VERSION_PROGRAMA);
  }
  buzzer.tocar(kMelodiaInicio, kLargoInicio);
  mensajeHastaMs = millis() + DURACION_MENSAJE_MS;

  delay(500);
  Serial.printf("\nSensor UV %s en %s%s\n", VERSION_PROGRAMA, NOMBRE_PLACA,
                veniaDeDormir ? " (desperto, sigue la cuenta)" : "");
  Serial.printf("Pantalla: %s | Sensor UV: %s | aceleracion x%d\n", pantalla.hay() ? "OK" : "NO",
                sensor.hay() ? "OK" : "NO (usa 'uv 7' para probar)", ACELERACION);
  mostrarEstado();

  ultimaLecturaMs = millis();
  sueno.reiniciar(ultimaLecturaMs);
  programarAnimacion(ultimaLecturaMs);
}

void loop() {
  uint32_t ahora = millis();
  buzzer.actualizar(ahora);
  leerOrdenSerie();

  if (boton.presionado(ahora)) reaplicado();

  // Lo que llegó desde la app por Bluetooth
  bluetooth::Recibido r;
  if (bluetooth::tomarRecibido(r)) {
    if (r.hayConfiguracion) recibirConfiguracion(r.configuracion);
    if (r.reaplicado) reaplicado(true);
    if (r.silenciar) silenciar();
    if (r.dormir) dormir();
  }

  actualizarAnimacion(ahora);

  if (ahora - ultimaLecturaMs < CADA_LECTURA_MS) return;
  float segundos = (ahora - ultimaLecturaMs) / 1000.0f;
  ultimaLecturaMs = ahora;

  // Medir y contar
  uvi = sensor.leer();
  bool haySol = calculo.uvEfectivo(uvi) >= CalculoUV::kUvMinimo;
  if (calculo.actualizar(uvi, segundos * ACELERACION)) {
    alarma.activar(ahora);
    Serial.println("¡Hora de reaplicar bloqueador!");
  }
  sueno.actualizar(haySol, ahora);

  // Buzzer: 5 s sí y 3 s no, hasta "Ya me reapliqué"
  bool debeSonar = alarma.debeSonar(ahora);
  if (debeSonar && !buzzer.repitiendo()) buzzer.tocar(kMelodiaReaplicar, kLargoReaplicar, true);
  if (!debeSonar && buzzer.repitiendo()) buzzer.detener();

  // Pantalla (mientras hay una animación, ella dibuja)
  if (ahora >= mensajeHastaMs && !animando) {
    if (alarma.alertaVisible()) {
      parpadeo = !parpadeo;
      pantalla.alerta(parpadeo, alarma.silenciada());
    } else {
      DatosPantalla d{calculo.perfil.nombre, calculo.perfil.fps, uvi,
                      calculo.restanteMin(uvi), calculo.avance(), haySol, bluetooth::conectado(),
                      sensor.hay() || sensor.simulado()};
      pantalla.normal(d);
    }
  }

  publicarEstado(haySol);

  Serial.printf("UV %.1f (%s) | efectivo %.1f | avance %3.0f%% | faltan %.0f min%s\n", uvi,
                nivelUV(uvi), calculo.uvEfectivo(uvi), calculo.avance() * 100,
                calculo.restanteMin(uvi), alarma.alertaVisible() ? " | HORA DE REAPLICAR" : "");

  // Dormir tras 30 min sin sol (sin interrumpir la alarma)
  if (sueno.debeDormir(ahora) && !buzzer.sonando()) {
    Serial.printf("%u min sin sol: a dormir.\n", sueno.minutosSinSol(ahora));
    dormir();
  }
}

#endif  // !PRUEBA_COMPONENTES
