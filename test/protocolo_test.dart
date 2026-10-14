// Pruebas del formato de los mensajes por Bluetooth (los mismos casos que
// dispositivo/test/test_protocolo en la placa).

import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_uv/protocolo.dart';

void main() {
  test('La configuración tiene el formato que espera la placa', () {
    final texto = textoConfiguracion(
      id: 'abc',
      nombre: 'Ana',
      fototipo: 5,
      fps: 100,
      resistenciaAguaMin: 0,
      sudorOAgua: false,
      lugar: 'agua',
    );
    expect(texto, 'i=abc;n=Ana;t=5;f=100;r=0;s=0;l=agua');
  });

  test('El nombre no lleva ";" ni "=" y se corta a 30 letras', () {
    expect(limpiarNombre('Ana;María=Luz'), 'Ana María Luz');
    expect(limpiarNombre('x' * 40).length, 30);
  });

  test('Se lee el estado que manda la placa', () {
    final e = leerEstado('uv=5.2;av=43;min=37;rea=0;sil=0;sol=1;bat=-1')!;
    expect(e.uvi, 5.2);
    expect(e.avance, closeTo(0.43, 0.001));
    expect(e.restanteMin, 37);
    expect(e.tocaReaplicar, isFalse);
    expect(e.silenciada, isFalse);
    expect(e.haySol, isTrue);
    expect(e.bateria, isNull);
  });

  test('Toca reaplicar y alarma silenciada', () {
    final e = leerEstado('uv=9.0;av=100;min=0;rea=1;sil=1;sol=1;bat=80')!;
    expect(e.tocaReaplicar, isTrue);
    expect(e.silenciada, isTrue);
    expect(e.bateria, 80);
  });

  test('Un estado dañado se ignora', () {
    expect(leerEstado('hola'), isNull);
    expect(leerEstado('uv=abc;av=1;min=2'), isNull);
  });
}
