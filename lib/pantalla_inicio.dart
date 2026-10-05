// Pantalla principal: indice UV, minutos que faltan y boton "Ya me puse bloqueador".
// Cuando toca reaplicar, cambia a una pantalla de alerta completa.
// En pantallas anchas se acomoda en dos columnas.

import 'package:flutter/material.dart';

import 'aviso_medico.dart';
import 'instalador.dart';
import 'modelo.dart';
import 'tema.dart';

// Colores de la escala del indice UV
Color colorNivel(double uvi) {
  if (uvi < 3) return const Color(0xFF2E9E4F);
  if (uvi < 6) return const Color(0xFFE0B100);
  if (uvi < 8) return const Color(0xFFF7931E);
  if (uvi < 11) return const Color(0xFFD7322A);
  return const Color(0xFF7B2FBF);
}

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: modelo,
      builder: (context, _) {
        if (modelo.tocaReaplicar) {
          return AlertaReaplicar(onConfirmar: modelo.reiniciar);
        }
        return _vistaNormal(context);
      },
    );
  }

  Widget _vistaNormal(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, limites) {
          // Dos columnas cuando hay espacio (computadora o tablet horizontal)
          final dosColumnas = limites.maxWidth >= 820;
          return SingleChildScrollView(
            padding: EdgeInsets.all(dosColumnas ? 32 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: dosColumnas
                    ? _dosColumnas(context)
                    : _unaColumna(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _unaColumna(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezado(context),
        const SizedBox(height: 16),
        _tarjetaUV(),
        const SizedBox(height: 28),
        _anillo(context, 230),
        const SizedBox(height: 28),
        _botonReaplicar(),
        const SizedBox(height: 12),
        _resumen(context),
        const SizedBox(height: 24),
        _simulador(context),
      ],
    );
  }

  Widget _dosColumnas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezado(context),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tarjetaUV(),
                  const SizedBox(height: 24),
                  _simulador(context),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _anillo(context, 260),
                      const SizedBox(height: 28),
                      _botonReaplicar(),
                      const SizedBox(height: 12),
                      _resumen(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _encabezado(BuildContext context) {
    // En celular el boton de instalar va aqui; en pantallas anchas va en el menu lateral
    final esCelular = MediaQuery.sizeOf(context).width < 700;
    return Row(
      children: [
        // En pantallas anchas el logo ya aparece en el menu lateral
        if (esCelular) ...[
          Image.asset('assets/logo.png', width: 40, height: 40),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            'Sensor UV',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            // En celular el titulo comparte renglon con el logo y los botones
            style: esCelular
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(width: 8),
        Chip(
          avatar: esCelular
              ? null
              : const Icon(Icons.bluetooth_disabled, size: 18),
          label: const Text('Simulación'),
        ),
        if (esCelular) ...[
          const SizedBox(width: 8),
          const BotonInstalar(extendido: false),
        ],
      ],
    );
  }

  // Indice UV actual
  Widget _tarjetaUV() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorNivel(modelo.uvi),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Índice UV',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  modelo.nivel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            modelo.uvi.round().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Anillo con los minutos que faltan
  Widget _anillo(BuildContext context, double tamano) {
    final tema = Theme.of(context);
    return Center(
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: modelo.avance,
              strokeWidth: 16,
              color: tema.colorScheme.primary,
              backgroundColor: tema.colorScheme.surfaceContainerHighest,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    modelo.restanteMin.floor().toString(),
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const Text('min para reaplicar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonReaplicar() {
    return FilledButton.icon(
      onPressed: modelo.reiniciar,
      icon: const Icon(Icons.check_circle),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text('Ya me puse bloqueador', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  // Resumen de los datos del usuario y acceso al aviso medico
  Widget _resumen(BuildContext context) {
    return Column(
      children: [
        Text(
          'Piel tipo ${modelo.fototipo}  ·  FPS ${modelo.fps}  ·  '
          'Sudor o agua: ${modelo.sudorOAgua ? 'sí' : 'no'}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton.icon(
          onPressed: () => mostrarAvisoMedico(context),
          icon: const Icon(Icons.medical_information_outlined, size: 18),
          label: const Text('Aviso médico'),
        ),
      ],
    );
  }

  // Simulador: sustituye al sensor mientras no hay Bluetooth
  Widget _simulador(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulador de sol',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Mueve el control para simular el índice UV. '
              'Se reemplazará por el sensor real al conectar el Bluetooth.',
            ),
            Slider(
              value: modelo.uvi,
              min: 0,
              max: 13,
              divisions: 13,
              label: modelo.uvi.round().toString(),
              onChanged: modelo.cambiarUV,
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de alerta completa, con un sol que late para llamar la atencion
class AlertaReaplicar extends StatefulWidget {
  const AlertaReaplicar({super.key, required this.onConfirmar});

  final VoidCallback onConfirmar;

  @override
  State<AlertaReaplicar> createState() => _AlertaReaplicarState();
}

class _AlertaReaplicarState extends State<AlertaReaplicar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacion;

  @override
  void initState() {
    super.initState();
    _animacion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.8,
      upperBound: 1.15,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: azulMarino,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _animacion,
                    child: const Icon(Icons.wb_sunny, color: dorado, size: 140),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Hora de reaplicar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ponte bloqueador otra vez para proteger tu piel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 36),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: dorado,
                      foregroundColor: azulMarino,
                    ),
                    onPressed: widget.onConfirmar,
                    icon: const Icon(Icons.check_circle),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      child: Text(
                        'Ya me puse bloqueador',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
