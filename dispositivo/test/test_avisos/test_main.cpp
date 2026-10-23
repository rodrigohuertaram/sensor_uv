// Pruebas de la alarma, el modo dormir y los textos sin acentos.
// Se corren con la placa conectada:   pio test -d dispositivo -e esp32c6 -f test_avisos

#include <Arduino.h>
#include <unity.h>

#include "Avisos.h"

void setUp() {}
void tearDown() {}

const uint32_t SEG = 1000;
const uint32_t MIN = 60 * SEG;

void test_suena_5_segundos_y_calla_3() {
  Alarma a;
  a.activar(0);
  TEST_ASSERT_TRUE(a.debeSonar(0));
  TEST_ASSERT_TRUE(a.debeSonar(4 * SEG));
  TEST_ASSERT_FALSE(a.debeSonar(6 * SEG));
  TEST_ASSERT_TRUE(a.debeSonar(9 * SEG));  // vuelve a sonar a los 8 s
  TEST_ASSERT_TRUE(a.alertaVisible());
}

void test_sigue_sonando_hasta_el_boton() {
  Alarma a;
  a.activar(0);
  int vecesQueEmpezo = 0;
  bool antes = false;
  for (uint32_t t = 0; t < 60 * MIN; t += SEG) {
    bool ahora = a.debeSonar(t);
    if (ahora && !antes) vecesQueEmpezo++;
    antes = ahora;
  }
  TEST_ASSERT_EQUAL(450, vecesQueEmpezo);  // cada 8 s durante una hora
  a.apagar();
  TEST_ASSERT_FALSE(a.debeSonar(60 * MIN));
}

void test_silenciar_no_quita_la_alerta() {
  Alarma a;
  a.activar(0);
  a.silenciar();
  TEST_ASSERT_FALSE(a.debeSonar(1 * SEG));
  TEST_ASSERT_FALSE(a.debeSonar(20 * MIN));
  TEST_ASSERT_TRUE(a.alertaVisible());
}

void test_reaplicar_quita_todo() {
  Alarma a;
  a.activar(0);
  a.apagar();
  TEST_ASSERT_FALSE(a.debeSonar(1 * SEG));
  TEST_ASSERT_FALSE(a.alertaVisible());
}

void test_duerme_tras_30_min_sin_sol() {
  MonitorSueno m;
  m.reiniciar(0);
  m.actualizar(true, 5 * MIN);
  TEST_ASSERT_FALSE(m.debeDormir(30 * MIN));
  TEST_ASSERT_FALSE(m.debeDormir(34 * MIN));
  TEST_ASSERT_TRUE(m.debeDormir(35 * MIN));
  TEST_ASSERT_EQUAL(30, m.minutosSinSol(35 * MIN));
}

void test_texto_sin_acentos() {
  char t[32];
  textoSinAcentos("Peña Ramírez", t, sizeof(t));
  TEST_ASSERT_EQUAL_STRING("Pena Ramirez", t);
  textoSinAcentos("ÁÉÍÓÚ ü", t, sizeof(t));
  TEST_ASSERT_EQUAL_STRING("AEIOU u", t);
  textoSinAcentos("abcdefghij", t, 5);  // se corta sin pasarse del tamaño
  TEST_ASSERT_EQUAL_STRING("abcd", t);
}

void setup() {
  delay(2000);
  UNITY_BEGIN();
  RUN_TEST(test_suena_5_segundos_y_calla_3);
  RUN_TEST(test_sigue_sonando_hasta_el_boton);
  RUN_TEST(test_silenciar_no_quita_la_alerta);
  RUN_TEST(test_reaplicar_quita_todo);
  RUN_TEST(test_duerme_tras_30_min_sin_sol);
  RUN_TEST(test_texto_sin_acentos);
  UNITY_END();
}

void loop() {}
