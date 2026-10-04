// Aviso medico: se muestra cada vez que se abre la app,
// y se puede volver a leer desde la pantalla de inicio.

import 'package:flutter/material.dart';

const String textoEstadistico =
    'Sensor UV calcula cuándo reaplicar bloqueador con base en datos e '
    'investigación científica existente sobre la radiación UV y los tipos de '
    'piel. Los resultados son estimaciones estadísticas y pueden variar de '
    'una persona a otra.';

const String textoConsulta =
    'Esta app no sustituye una consulta médica. Te recomendamos acudir con un '
    'médico o dermatólogo para confirmar tu tipo de piel y la información que '
    'te damos, ya que no podemos garantizar que funcione al 100 % en tu caso.';

Future<void> mostrarAvisoMedico(
  BuildContext context, {
  bool obligatorio = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !obligatorio,
    builder: (context) => PopScope(
      canPop: !obligatorio,
      child: AlertDialog(
        icon: const Icon(Icons.medical_information, size: 40),
        title: const Text('Antes de empezar'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(textoEstadistico),
                SizedBox(height: 12),
                Text(textoConsulta),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    ),
  );
}

// Recordatorio corto que se queda visible en "Mi perfil", junto al tipo de piel
class NotaTipoPiel extends StatelessWidget {
  const NotaTipoPiel({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      color: tema.colorScheme.tertiaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Elegir tu tipo de piel aquí es una estimación. '
                'Un dermatólogo puede confirmarte cuál es el tuyo.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
