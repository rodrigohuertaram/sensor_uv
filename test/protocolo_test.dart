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

  test('La configuración lleva el UV del clima cuando lo hay', () {
    final texto = textoConfiguracion(
      id: 'abc',
      nombre: 'Ana',
      fototipo: 3,
      fps: 30,
      resistenciaAguaMin: 0,
      sudorOAgua: false,
      lugar: 'ciudad',
      uvClima: 8.46,
      edadClimaMin: 12,
    );
    expect(texto, 'i=abc;n=Ana;t=3;f=30;r=0;s=0;l=ciudad;z=8.5;za=12');
  });

  test('Se leen el sensor, el clima y sus porcentajes', () {
    final e = leerEstado(
      'uv=6.6;av=10;min=80;rea=0;sil=0;sol=1;bat=-1;'
      'uvs=6.0;uvc=8.0;ps=70;pc=30;som=0',
    )!;
    expect(e.uvi, 6.6);
    expect(e.uvSensor, 6.0);
    expect(e.uvClima, 8.0);
    expect(e.pesoSensor, 70);
    expect(e.pesoClima, 30);
    expect(e.sombra, isFalse);
  });

  test('Sombra y clima viejo', () {
    final sombra = leerEstado(
      'uv=5.0;av=1;min=90;rea=0;sil=0;sol=1;bat=-1;uvs=2.0;uvc=10.0;ps=70;pc=30;som=1',
    )!;
    expect(sombra.sombra, isTrue);
    final sinClima = leerEstado(
      'uv=4.0;av=1;min=90;rea=0;sil=0;sol=1;bat=-1;uvs=4.0;uvc=-1.0;ps=100;pc=0;som=0',
    )!;
    expect(sinClima.uvClima, isNull);
    expect(sinClima.pesoSensor, 100);
  });

  test('Una placa con el programa anterior se entiende como solo sensor', () {
    final e = leerEstado('uv=5.2;av=43;min=37;rea=0;sil=0;sol=1;bat=-1')!;
    expect(e.uvSensor, 5.2);
    expect(e.uvClima, isNull);
    expect(e.pesoSensor, 100);
    expect(e.pesoClima, 0);
  });
}
