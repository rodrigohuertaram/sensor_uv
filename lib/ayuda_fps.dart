// Ayuda para encontrar el FPS y la resistencia al agua en el envase del bloqueador.
// Un boton redondo "?" abre una ilustracion de un bloqueador generico (sin marca).

import 'package:flutter/material.dart';

import 'tema.dart';

// Boton redondo con signo de interrogacion que abre la ayuda
class BotonAyudaFps extends StatelessWidget {
  const BotonAyudaFps({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: '¿Dónde veo el FPS?',
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.question_mark),
      onPressed: () => mostrarAyudaFps(context),
    );
  }
}

Future<void> mostrarAyudaFps(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Dónde veo el FPS?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: IlustracionBloqueador()),
              SizedBox(height: 16),
              Text(
                '• El FPS (en inglés SPF) está al frente del envase, en grande, '
                'por ejemplo «FPS 50» o «SPF 50+».',
              ),
              SizedBox(height: 6),
              Text(
                '• Si tu número no aparece en las opciones, elige el más '
                'cercano hacia abajo: así el aviso llega antes.',
              ),
              SizedBox(height: 6),
              Text(
                '• La resistencia al agua aparece como «resistente al agua '
                '40 min» u «80 min» (en inglés, water resistant). Si no lo '
                'dice, elige «No dice».',
              ),
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
  );
}

// Dibujo de un bloqueador generico con flechas que senalan el FPS y la resistencia al agua
class IlustracionBloqueador extends StatelessWidget {
  const IlustracionBloqueador({super.key});

  @override
  Widget build(BuildContext context) {
    const estiloNota = TextStyle(
      color: azulMarino,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return SizedBox(
      width: 300,
      height: 270,
      child: Stack(
        children: [
          // Tapa
          Positioned(
            left: 45,
            top: 0,
            child: Container(
              width: 70,
              height: 34,
              decoration: BoxDecoration(
                color: azulMarino,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Envase
          Positioned(
            left: 10,
            top: 28,
            child: Container(
              width: 140,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: azulMarino, width: 2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(36),
                  bottom: Radius.circular(18),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wb_sunny, color: dorado, size: 36),
                  const SizedBox(height: 4),
                  const Text(
                    'PROTECTOR\nSOLAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: azulMarino,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Recuadro resaltado con el FPS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: doradoClaro,
                      border: Border.all(color: dorado, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'FPS 50+',
                      style: TextStyle(
                        color: azulMarino,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Resistencia al agua
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: azulMarino.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Resistente al agua\n80 min',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: azulMarino, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Notas con flechas
          const Positioned(
            left: 152,
            top: 132,
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: dorado, size: 22),
                SizedBox(width: 2),
                Text('Aquí está\nel FPS', style: estiloNota),
              ],
            ),
          ),
          const Positioned(
            left: 152,
            top: 192,
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: dorado, size: 22),
                SizedBox(width: 2),
                Text('Resistencia\nal agua', style: estiloNota),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
