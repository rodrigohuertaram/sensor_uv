// Pruebas del ajuste por lugar (reflejo del suelo) y por nubes.

import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_uv/modelo.dart';

void main() {
  test('En la ciudad y despejado, el UV efectivo es el mismo índice', () {
    final m = ModeloUV()..cambiarUV(8);
    expect(m.uvEfectivo, 8);
  });

  test('La playa suma 25 % por el reflejo de la arena y el mar', () {
    final m = ModeloUV()
      ..cambiarUV(8)
      ..cambiarEntorno(Entorno.playa);
    expect(m.uvEfectivo, closeTo(10, 0.001));
  });

  test('Con el simulador, las nubes reducen el UV efectivo', () {
    final m = ModeloUV()
      ..cambiarUV(10)
      ..cambiarCielo(Cielo.nublado);
    expect(m.uvEfectivo, closeTo(8, 0.001));
  });

  test('Algo nublado no reduce nada (las nubes delgadas casi no filtran)', () {
    final m = ModeloUV()
      ..cambiarUV(10)
      ..cambiarCielo(Cielo.algoNublado);
    expect(m.uvEfectivo, 10);
  });

  test('En la nieve el aviso llega antes que en la ciudad', () {
    final m = ModeloUV();
    final enCiudad = m.minutosParaAvisar(9);
    m.cambiarEntorno(Entorno.nieve);
    expect(m.minutosParaAvisar(9), lessThan(enCiudad));
  });
}
