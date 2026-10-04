// Prueba basica: la app abre y muestra la pantalla de inicio.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_uv/main.dart';

void main() {
  testWidgets('La app abre en la pantalla de inicio', (WidgetTester tester) async {
    await tester.pumpWidget(const SensorUvApp());

    expect(find.text('Sensor UV'), findsOneWidget);
    expect(find.text('Ya me puse bloqueador'), findsOneWidget);

    // Se desmonta la app para detener el reloj antes de terminar la prueba
    await tester.pumpWidget(const SizedBox());
  });
}
