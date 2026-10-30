// Pruebas del formato de los mensajes por Bluetooth.
// Se corren con la placa conectada:   pio test -d dispositivo -e esp32c6 -f test_protocolo

#include <Arduino.h>
#include <unity.h>

#include "Protocolo.h"

using namespace protocolo;

void setUp() {}
void tearDown() {}

void test_lee_configuracion_completa() {
  PerfilUV actual, nuevo;
  TEST_ASSERT_TRUE(leerConfiguracion("i=123;n=Rodrigo;t=2;f=50;r=80;s=1;l=playa", actual, nuevo));
  TEST_ASSERT_EQUAL_STRING("123", nuevo.id);
  TEST_ASSERT_EQUAL_STRING("Rodrigo", nuevo.nombre);
  TEST_ASSERT_EQUAL(2, nuevo.fototipo);
  TEST_ASSERT_EQUAL(50, nuevo.fps);
  TEST_ASSERT_EQUAL(80, nuevo.resistenciaAguaMin);
  TEST_ASSERT_TRUE(nuevo.sudorOAgua);
  TEST_ASSERT_EQUAL(static_cast<int>(Lugar::playa), static_cast<int>(nuevo.lugar));
}

void test_configuracion_parcial_conserva_lo_demas() {
  PerfilUV actual, nuevo;
  actual.fps = 70;
  TEST_ASSERT_TRUE(leerConfiguracion("l=nieve", actual, nuevo));
  TEST_ASSERT_EQUAL(70, nuevo.fps);
  TEST_ASSERT_EQUAL(static_cast<int>(Lugar::nieve), static_cast<int>(nuevo.lugar));
}

void test_rechaza_valores_invalidos() {
  PerfilUV actual, nuevo;
  nuevo.fps = 15;
  TEST_ASSERT_FALSE(leerConfiguracion("t=9", actual, nuevo));
  TEST_ASSERT_FALSE(leerConfiguracion("f=abc", actual, nuevo));
  TEST_ASSERT_FALSE(leerConfiguracion("l=luna", actual, nuevo));
  TEST_ASSERT_FALSE(leerConfiguracion("sin-igual", actual, nuevo));
  TEST_ASSERT_EQUAL(15, nuevo.fps);  // no se tocó
}

void test_nombre_largo_se_recorta() {
  PerfilUV actual, nuevo;
  TEST_ASSERT_TRUE(leerConfiguracion("n=Un nombre muy muy largo de mas de treinta letras", actual, nuevo));
  TEST_ASSERT_EQUAL(30, strlen(nuevo.nombre));
}

void test_ida_y_vuelta() {
  PerfilUV p, leido;
  strcpy(p.id, "abc");
  strcpy(p.nombre, "Ana");
  p.fototipo = 5;
  p.fps = 100;
  p.lugar = Lugar::agua;
  char texto[120];
  escribirConfiguracion(p, texto, sizeof(texto));
  TEST_ASSERT_EQUAL_STRING("i=abc;n=Ana;t=5;f=100;r=0;s=0;l=agua", texto);
  TEST_ASSERT_TRUE(leerConfiguracion(texto, PerfilUV(), leido));
  TEST_ASSERT_EQUAL_STRING("Ana", leido.nombre);
  TEST_ASSERT_EQUAL(5, leido.fototipo);
}

void test_estado() {
  Estado e{5.24f, 0.426f, 36.6f, false, false, true, -1, 4.8f, 6.1f, 70, 30, false};
  char texto[120];
  escribirEstado(e, texto, sizeof(texto));
  TEST_ASSERT_EQUAL_STRING("uv=5.2;av=43;min=37;rea=0;sil=0;sol=1;bat=-1;uvs=4.8;uvc=6.1;ps=70;pc=30;som=0",
                           texto);
}

void test_uv_del_clima() {
  float uv = -1;
  int edad = -1;
  TEST_ASSERT_TRUE(leerUvClima("i=1;n=Ana;t=3;f=30;r=0;s=0;l=ciudad;z=8.5;za=12", uv, edad));
  TEST_ASSERT_FLOAT_WITHIN(0.01, 8.5, uv);
  TEST_ASSERT_EQUAL(12, edad);
  TEST_ASSERT_FALSE(leerUvClima("i=1;n=Ana;t=3", uv, edad));  // sin clima
  TEST_ASSERT_FALSE(leerUvClima("z=abc", uv, edad));
  // La configuración del perfil ignora z y za
  PerfilUV actual, nuevo;
  TEST_ASSERT_TRUE(leerConfiguracion("t=2;z=8.5;za=12", actual, nuevo));
  TEST_ASSERT_EQUAL(2, nuevo.fototipo);
}

void setup() {
  delay(2000);
  UNITY_BEGIN();
  RUN_TEST(test_lee_configuracion_completa);
  RUN_TEST(test_configuracion_parcial_conserva_lo_demas);
  RUN_TEST(test_rechaza_valores_invalidos);
  RUN_TEST(test_nombre_largo_se_recorta);
  RUN_TEST(test_ida_y_vuelta);
  RUN_TEST(test_estado);
  RUN_TEST(test_uv_del_clima);
  UNITY_END();
}

void loop() {}
