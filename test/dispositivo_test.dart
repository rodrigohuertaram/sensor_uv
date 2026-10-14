// Pruebas de la app con el dispositivo conectado: la app muestra lo que manda la placa.

import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_uv/modelo.dart';

void main() {
  test('Con el dispositivo, el UV y los minutos vienen de la placa', () {
    final m = ModeloUV()..simularDispositivoConectado();
    m.recibirEstado('uv=7.3;av=40;min=25;rea=0;sil=0;sol=1;bat=-1');
    expect(m.uvi, 7.3);
    expect(m.restanteMin, 25);
    expect(m.avance, closeTo(0.40, 0.001));
    expect(m.tocaReaplicar, isFalse);
  });

  test('Cuando la placa dice que toca reaplicar, la app muestra la alerta', () {
    final m = ModeloUV()..simularDispositivoConectado();
    m.recibirEstado('uv=9.0;av=100;min=0;rea=1;sil=0;sol=1;bat=-1');
    expect(m.tocaReaplicar, isTrue);
    expect(m.alarmaDispositivoSilenciada, isFalse);
  });

  test('Al presionar "Ya me puse bloqueador" la alerta no regresa por un estado viejo', () {
    final m = ModeloUV()..simularDispositivoConectado();
    m.recibirEstado('uv=9.0;av=100;min=0;rea=1;sil=0;sol=1;bat=-1');
    m.reiniciar();
    // La placa todavia no se entera y manda el estado anterior
    m.recibirEstado('uv=9.0;av=100;min=0;rea=1;sil=0;sol=1;bat=-1');
    expect(m.tocaReaplicar, isFalse);
  });

  test('El botón de la placa también quita la alerta de la app', () {
    final m = ModeloUV()..simularDispositivoConectado();
    m.recibirEstado('uv=9.0;av=100;min=0;rea=1;sil=0;sol=1;bat=-1');
    m.recibirOrden('reaplicado');
    expect(m.tocaReaplicar, isFalse);
  });

  test('Sin dispositivo conectado se ignora lo que llegue', () {
    final m = ModeloUV();
    m.recibirEstado('uv=9.0;av=100;min=0;rea=1;sil=0;sol=1;bat=-1');
    expect(m.uvi, 0);
    expect(m.tocaReaplicar, isFalse);
  });
}
