// Pantalla "Mi perfil": tipo de piel, FPS del bloqueador, sudor o agua y resistencia al agua.
// En pantallas anchas se acomoda en dos columnas.

import 'package:flutter/material.dart';

import 'aviso_medico.dart';
import 'ayuda_fps.dart';
import 'modelo.dart';
import 'selector_perfil.dart';
import 'test_piel.dart';
import 'tipos_piel.dart';

const List<int> _opcionesFps = [15, 30, 50, 70, 100];

class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: modelo,
      builder: (context, _) => _contenido(context),
    );
  }

  Widget _contenido(BuildContext context) {
    final tema = Theme.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, limites) {
          final dosColumnas = limites.maxWidth >= 820;
          final titulo = [
            Text('Mi perfil', style: tema.textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('Con estos datos se calcula cuándo te toca reaplicar.'),
            const SizedBox(height: 16),
            const SelectorPerfil(),
            const SizedBox(height: 20),
          ];

          return SingleChildScrollView(
            padding: EdgeInsets.all(dosColumnas ? 32 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: dosColumnas
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...titulo,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _seccionPiel(context),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _seccionAjustes(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...titulo,
                          ..._seccionPiel(context),
                          const SizedBox(height: 20),
                          ..._seccionAjustes(context),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Tipo de piel ----------
  List<Widget> _seccionPiel(BuildContext context) {
    final tema = Theme.of(context);
    return [
      Text('Tipo de piel', style: tema.textTheme.titleLarge),
      const SizedBox(height: 8),
      const NotaTipoPiel(),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.quiz_outlined),
        label: const Text('¿No sabes cuál es? Haz el test'),
        onPressed: () => abrirTestPiel(context),
      ),
      const SizedBox(height: 8),
      for (final tipo in tiposPiel)
        Card(
          color: modelo.fototipo == tipo.numero
              ? tema.colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: tipo.color),
            title: Text('${tipo.numero}. ${tipo.nombre}'),
            subtitle: Text(tipo.descripcion),
            trailing: modelo.fototipo == tipo.numero
                ? Icon(Icons.check_circle, color: tema.colorScheme.primary)
                : null,
            onTap: () => modelo.cambiarFototipo(tipo.numero),
          ),
        ),
    ];
  }

  List<Widget> _seccionAjustes(BuildContext context) {
    final tema = Theme.of(context);
    return [
      // ---------- FPS ----------
      Row(
        children: [
          Text('FPS de tu bloqueador', style: tema.textTheme.titleLarge),
          const SizedBox(width: 8),
          const BotonAyudaFps(),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final valor in _opcionesFps)
            ChoiceChip(
              label: Text('FPS $valor'),
              selected: modelo.fps == valor,
              onSelected: (_) => modelo.cambiarFps(valor),
            ),
        ],
      ),
      const SizedBox(height: 20),

      // ---------- Sudor o agua ----------
      Text('Actividad', style: tema.textTheme.titleLarge),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Estoy sudando o en el agua'),
        subtitle: const Text('El bloqueador dura menos con sudor o agua'),
        value: modelo.sudorOAgua,
        onChanged: modelo.cambiarSudor,
      ),
      const SizedBox(height: 8),
      const Row(
        children: [
          Flexible(child: Text('Resistencia al agua que dice el envase')),
          SizedBox(width: 8),
          BotonAyudaFps(),
        ],
      ),
      const SizedBox(height: 8),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('No dice')),
          ButtonSegment(value: 40, label: Text('40 min')),
          ButtonSegment(value: 80, label: Text('80 min')),
        ],
        selected: {modelo.resistenciaAguaMin},
        onSelectionChanged: (seleccion) =>
            modelo.cambiarResistencia(seleccion.first),
      ),
      const SizedBox(height: 24),

      // ---------- Resultado con estos datos ----------
      SizedBox(
        width: double.infinity,
        child: Card(
          color: tema.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Con estos datos', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Sol moderado (UV 5): aviso a los '
                  '${modelo.minutosParaAvisar(5).round()} min',
                ),
                Text(
                  'Sol muy alto (UV 9): aviso a los '
                  '${modelo.minutosParaAvisar(9).round()} min',
                ),
                Text(
                  'Sol extremo (UV 12): aviso a los '
                  '${modelo.minutosParaAvisar(12).round()} min',
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),

      // ---------- Velocidad de la simulacion ----------
      Text('Velocidad de prueba', style: tema.textTheme.titleLarge),
      const SizedBox(height: 4),
      const Text('Acelera el tiempo para probar la app sin esperar horas.'),
      const SizedBox(height: 8),
      SegmentedButton<double>(
        segments: const [
          ButtonSegment(value: 1.0, label: Text('Real')),
          ButtonSegment(value: 60.0, label: Text('x60')),
          ButtonSegment(value: 600.0, label: Text('x600')),
        ],
        selected: {modelo.aceleracion},
        onSelectionChanged: (seleccion) =>
            modelo.cambiarAceleracion(seleccion.first),
      ),
      const SizedBox(height: 24),
    ];
  }
}
