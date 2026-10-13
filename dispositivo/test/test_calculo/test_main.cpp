// Pruebas del cálculo de la placa. Los resultados esperados salen de las mismas fórmulas
// de la app (lib/modelo.dart y test/modelo_test.dart), para comprobar que dan lo mismo.
//
// Se corren con la placa conectada:   pio test -d dispositivo -e esp32c6   (o -e xiao_esp32c3)

#include <Arduino.h>
#include <unity.h>

#include "CalculoUV.h"

void setUp() {}
void tearDown() {}

// Perfil de fábrica (igual al de la app): tipo 3, FPS 30 -> límite 350*30*0.3*0.6 = 1890 J/m2
void test_limite_perfil_de_fabrica() {
  CalculoUV c;
  TEST_ASSERT_FLOAT_WITHIN(0.01, 1890.0, c.limiteDosis());
  TEST_ASSERT_FLOAT_WITHIN(0.01, 120.0, c.topeTiempoMin());
}

// Igual que la prueba de la app: en la ciudad el UV efectivo es el mismo índice
void test_ciudad_sin_cambio() {
  CalculoUV c;
  TEST_ASSERT_FLOAT_WITHIN(0.001, 8.0, c.uvEfectivo(8));
}

// Igual que la app: la playa suma 25 %
void test_playa_25_por_ciento() {
  CalculoUV c;
  c.perfil.lugar = Lugar::playa;
  TEST_ASSERT_FLOAT_WITHIN(0.001, 10.0, c.uvEfectivo(8));
}

// Igual que la app: en la nieve el aviso llega antes que en la ciudad (UV 9)
void test_nieve_avisa_antes() {
  CalculoUV c;
  float enCiudad = c.minutosParaAvisar(9);  // 1890 / (0.025*9) = 8400 s = 140 min -> tope 120
  TEST_ASSERT_FLOAT_WITHIN(0.01, 120.0, enCiudad);
  c.perfil.lugar = Lugar::nieve;            // 9*1.8 = 16.2 -> 1890/0.405 = 4666.7 s = 77.78 min
  TEST_ASSERT_FLOAT_WITHIN(0.01, 77.78, c.minutosParaAvisar(9));
}

// Tipo 2, FPS 15: límite 250*15*0.18 = 675; con UV 10 -> 675/0.25 = 2700 s = 45 min
void test_minutos_tipo2_fps15() {
  CalculoUV c;
  c.perfil.fototipo = 2;
  c.perfil.fps = 15;
  TEST_ASSERT_FLOAT_WITHIN(0.01, 675.0, c.limiteDosis());
  TEST_ASSERT_FLOAT_WITHIN(0.01, 45.0, c.restanteMin(10));
}

// Sudor o agua: tope de 80 min con resistencia 80, si no 40 min
void test_tope_sudor_o_agua() {
  CalculoUV c;
  c.perfil.sudorOAgua = true;
  c.perfil.resistenciaAguaMin = 80;
  TEST_ASSERT_FLOAT_WITHIN(0.01, 80.0, c.topeTiempoMin());
  c.perfil.resistenciaAguaMin = 40;
  TEST_ASSERT_FLOAT_WITHIN(0.01, 40.0, c.topeTiempoMin());
  c.perfil.resistenciaAguaMin = 0;
  TEST_ASSERT_FLOAT_WITHIN(0.01, 40.0, c.topeTiempoMin());
}

// Con UV menor a 1 no se acumula nada
void test_sin_sol_no_cuenta() {
  CalculoUV c;
  c.actualizar(0.5, 600);
  TEST_ASSERT_FLOAT_WITHIN(0.001, 0.0, c.dosis);
  TEST_ASSERT_FLOAT_WITHIN(0.001, 0.0, c.tiempoExpuestoS);
}

// 10 minutos con UV 10 (tipo 2, FPS 15): dosis 150, faltan 35 min, avance 150/675
void test_acumula_dosis() {
  CalculoUV c;
  c.perfil.fototipo = 2;
  c.perfil.fps = 15;
  for (int i = 0; i < 600; i++) c.actualizar(10, 1);
  TEST_ASSERT_FLOAT_WITHIN(0.05, 150.0, c.dosis);
  TEST_ASSERT_FLOAT_WITHIN(0.01, 35.0, c.restanteMin(10));
  TEST_ASSERT_FLOAT_WITHIN(0.001, 150.0 / 675.0, c.avance());
  TEST_ASSERT_FALSE(c.tocaReaplicar);
}

// A los 45 min con UV 10 (tipo 2, FPS 15) toca reaplicar, y reiniciar empieza de cero
void test_toca_reaplicar_y_reiniciar() {
  CalculoUV c;
  c.perfil.fototipo = 2;
  c.perfil.fps = 15;
  bool aviso = false;
  int segundos = 0;
  while (!aviso && segundos < 2800) {
    aviso = c.actualizar(10, 1);
    segundos++;
  }
  TEST_ASSERT_TRUE(aviso);
  TEST_ASSERT_INT_WITHIN(2, 2700, segundos);
  TEST_ASSERT_TRUE(c.tocaReaplicar);
  TEST_ASSERT_FLOAT_WITHIN(0.001, 1.0, c.avance());
  c.reiniciar();
  TEST_ASSERT_FALSE(c.tocaReaplicar);
  TEST_ASSERT_FLOAT_WITHIN(0.001, 0.0, c.dosis);
}

// Una pausa larga no cuenta más allá del tope de tiempo
void test_pausa_larga_limitada() {
  CalculoUV c;
  c.actualizar(1, 99999);  // UV bajo: llega primero el tope de 120 min
  TEST_ASSERT_FLOAT_WITHIN(0.01, 7200.0, c.tiempoExpuestoS);
  TEST_ASSERT_TRUE(c.tocaReaplicar);
}

// Nombres de los lugares que se usan por Bluetooth
void test_nombres_de_lugar() {
  Lugar l = Lugar::ciudad;
  TEST_ASSERT_TRUE(lugarDesdeNombre("playa", l));
  TEST_ASSERT_EQUAL(static_cast<int>(Lugar::playa), static_cast<int>(l));
  TEST_ASSERT_FALSE(lugarDesdeNombre("luna", l));
  TEST_ASSERT_EQUAL_STRING("nieve", nombreLugar(Lugar::nieve));
}

void test_niveles() {
  TEST_ASSERT_EQUAL_STRING("Bajo", nivelUV(2.9));
  TEST_ASSERT_EQUAL_STRING("Moderado", nivelUV(3));
  TEST_ASSERT_EQUAL_STRING("Alto", nivelUV(6));
  TEST_ASSERT_EQUAL_STRING("Muy alto", nivelUV(8));
  TEST_ASSERT_EQUAL_STRING("Extremo", nivelUV(11));
}

void setup() {
  delay(2000);
  UNITY_BEGIN();
  RUN_TEST(test_limite_perfil_de_fabrica);
  RUN_TEST(test_ciudad_sin_cambio);
  RUN_TEST(test_playa_25_por_ciento);
  RUN_TEST(test_nieve_avisa_antes);
  RUN_TEST(test_minutos_tipo2_fps15);
  RUN_TEST(test_tope_sudor_o_agua);
  RUN_TEST(test_sin_sol_no_cuenta);
  RUN_TEST(test_acumula_dosis);
  RUN_TEST(test_toca_reaplicar_y_reiniciar);
  RUN_TEST(test_pausa_larga_limitada);
  RUN_TEST(test_nombres_de_lugar);
  RUN_TEST(test_niveles);
  UNITY_END();
}

void loop() {}
