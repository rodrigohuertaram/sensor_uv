// Aviso medico: se muestra al abrir la app hasta que la persona lo acepta,
// y se puede volver a leer desde la pantalla de inicio.

import 'package:flutter/material.dart';

import 'almacen.dart';

// Cambiar la version hace que el aviso se muestre otra vez a todos
const String _claveAceptado = 'avisoMedicoAceptado.v1';

const String textoEstadistico =
    'Sensor UV calcula cuándo reaplicar bloqueador con base en datos e '
    'investigación científica existente sobre la radiación UV y los tipos de '
    'piel. Los resultados son estimaciones estadísticas y pueden variar de '
    'una persona a otra.';

const String textoConsulta =
    'Esta app no sustituye una consulta médica. Te recomendamos acudir con un '
    'médico o dermatólogo para confirmar tu tipo de piel y la información que '
    'te damos, ya que no podemos garantizar que funcione al 100 % en tu caso.';

// Muestra el aviso solo si todavia no se ha aceptado
Future<void> mostrarAvisoSiHaceFalta(BuildContext context) async {
  if (leerDato(_claveAceptado) == 'si') return;
  await mostrarAvisoMedico(context, obligatorio: true);
}

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
            onPressed: () {
              guardarDato(_claveAceptado, 'si');
              Navigator.pop(context);
            },
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
