// Pruebas del calculo del test de tipo de piel.

import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_uv/test_piel.dart';

void main() {
  test('Si quemadura y bronceado coinciden, decide la respuesta principal', () {
    final r = calcularFototipo(
      quemadura: 3,
      bronceado: 3,
      colorPiel: 6, // las de apoyo no cambian el resultado
      pecas: null,
      cabello: 5,
      ojos: 5,
    );
    expect(r.fototipo, 3);
    expect(r.precision, Precision.alta);
  });

  test('Si quedan a un tipo de distancia, se elige el mas claro', () {
    final r = calcularFototipo(
      quemadura: 4,
      bronceado: 3,
      colorPiel: 4,
      pecas: null,
      cabello: 4,
      ojos: 4,
    );
    expect(r.fototipo, 3);
  });

  test('Si no coinciden, las preguntas de apoyo desempatan', () {
    // (1 + 5 + apoyo 2) / 3 = 2.67 -> tipo 2
    final r = calcularFototipo(
      quemadura: 1,
      bronceado: 5,
      colorPiel: 2,
      pecas: 2,
      cabello: 2,
      ojos: 2,
    );
    expect(r.fototipo, 2);
    expect(r.precision, Precision.media);
  });

  test('Con "No sé" en ambas principales se usan solo las de apoyo', () {
    // (3*2 + 4 + 4) / 4 = 3.5 -> tipo 3
    final r = calcularFototipo(
      quemadura: null,
      bronceado: null,
      colorPiel: 3,
      pecas: null,
      cabello: 4,
      ojos: 4,
    );
    expect(r.fototipo, 3);
    expect(r.precision, Precision.baja);
  });

  test('Con "No sé" en una principal, la otra pesa el doble', () {
    // (2*2 + apoyo 3) / 3 = 2.33 -> tipo 2
    final r = calcularFototipo(
      quemadura: 2,
      bronceado: null,
      colorPiel: 3,
      pecas: null,
      cabello: 3,
      ojos: 3,
    );
    expect(r.fototipo, 2);
  });

  test('El resultado siempre queda entre 1 y 6', () {
    final r = calcularFototipo(
      quemadura: 6,
      bronceado: 6,
      colorPiel: 6,
      pecas: null,
      cabello: 5,
      ojos: 5,
    );
    expect(r.fototipo, 6);
  });
}
