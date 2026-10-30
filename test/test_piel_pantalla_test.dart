// Pruebas de la pantalla del test de tipo de piel: una pregunta por pantalla con barra de avance.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_uv/test_piel.dart';

void main() {
  testWidgets('Una pregunta a la vez, con avance y botón Anterior', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaTestPiel()));

    expect(find.text('Pregunta 1 de 6'), findsOneWidget);
    expect(find.text('¿Qué le pasa a tu piel?'), findsOneWidget);
    expect(find.text('¿Cómo cambia el color de tu piel?'), findsNothing);
    expect(find.text('Anterior'), findsNothing);

    // Al contestar pasa sola a la siguiente pregunta
    await tester.tap(
      find.text('Me quemo casi siempre: se pone roja y me arde'),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Pregunta 2 de 6'), findsOneWidget);
    expect(find.text('1 de 6 contestadas'), findsOneWidget);
    expect(find.text('¿Cómo cambia el color de tu piel?'), findsOneWidget);

    // Se puede regresar y la respuesta sigue elegida
    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Pregunta 1 de 6'), findsOneWidget);
    final siguiente = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Siguiente'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(siguiente.onPressed, isNotNull);
  });
}
