// Tarjeta "Dónde estás": lugar (ciudad, playa, nieve...), clima de tu zona con la
// ubicacion (siempre con permiso) y, si se usa el simulador, el cielo elegido a mano.

import 'package:flutter/material.dart';

import 'modelo.dart';

class TarjetaLugarClima extends StatelessWidget {
  const TarjetaLugarClima({super.key});

  @override
  Widget build(BuildContext context) {
    // Se redibuja por su cuenta porque se usa como widget const en la pantalla de inicio
    return ListenableBuilder(
      listenable: modelo,
      builder: (context, _) => _tarjeta(context),
    );
  }

  Widget _tarjeta(BuildContext context) {
    final tema = Theme.of(context);
    final nota = modelo.entorno.nota;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Dónde estás?', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final lugar in Entorno.values)
                  ChoiceChip(
                    avatar: Icon(lugar.icono, size: 18),
                    label: Text(lugar.nombre),
                    selected: modelo.entorno == lugar,
                    showCheckmark: false,
                    onSelected: (_) => modelo.cambiarEntorno(lugar),
                  ),
              ],
            ),
            if (nota != null) ...[
              const SizedBox(height: 8),
              _Nota(icono: Icons.info_outline, texto: nota),
            ],
            const Divider(height: 32),
            Text('Clima', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            _climaDeZona(context),
            const SizedBox(height: 12),
            if (modelo.fuente == FuenteUV.simulador)
              ..._cieloManual(context)
            else
              const _Nota(
                icono: Icons.check_circle_outline,
                texto: 'El índice UV de tu zona ya toma en cuenta las nubes.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _climaDeZona(BuildContext context) {
    final tema = Theme.of(context);
    final clima = modelo.clima;
    final privacidad = Text(
      'Tu ubicación aproximada solo se usa para consultar el clima en '
      'Open-Meteo (un servicio gratuito) y no se guarda.',
      style: tema.textTheme.bodySmall,
    );
    final error = modelo.errorClima;

    if (clima == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Con tu ubicación puedo mostrarte la temperatura y el índice UV '
            'real de tu zona.',
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            icon: modelo.consultandoClima
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Usar mi ubicación'),
            onPressed: modelo.consultandoClima ? null : modelo.actualizarClima,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: tema.colorScheme.error)),
          ],
          const SizedBox(height: 8),
          privacidad,
        ],
      );
    }

    final hora = TimeOfDay.fromDateTime(clima.consultado).format(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(clima.icono, size: 40, color: tema.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${clima.temperatura.round()} °C · ${clima.descripcion}',
                    style: tema.textTheme.titleLarge,
                  ),
                  Text(
                    'Sensación de ${clima.sensacion.round()} °C · '
                    'UV ahora ${clima.indiceUV.toStringAsFixed(1)} · '
                    'UV máximo hoy ${clima.uvMaximoHoy.round()}',
                  ),
                  Text(
                    'Actualizado a las $hora',
                    style: tema.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              icon: modelo.consultandoClima
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: modelo.consultandoClima
                  ? null
                  : modelo.actualizarClima,
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Usar el índice UV de tu zona'),
          subtitle: const Text(
            'En lugar del simulador. Se actualiza cada 15 minutos.',
          ),
          value: modelo.fuente == FuenteUV.zona,
          onChanged: modelo.usarUvDeZona,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, style: TextStyle(color: tema.colorScheme.error)),
          ),
        privacidad,
      ],
    );
  }

  List<Widget> _cieloManual(BuildContext context) {
    return [
      Text(
        modelo.clima == null
            ? '¿Cómo está el cielo?'
            : '¿Cómo está el cielo? (sugerido según el clima de tu zona)',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final opcion in Cielo.values)
            ChoiceChip(
              avatar: Icon(opcion.icono, size: 18),
              label: Text(opcion.nombre),
              selected: modelo.cielo == opcion,
              showCheckmark: false,
              onSelected: (_) => modelo.cambiarCielo(opcion),
            ),
        ],
      ),
      const SizedBox(height: 8),
      const _Nota(
        icono: Icons.warning_amber_rounded,
        texto:
            'Las nubes no bloquean tanto como parece: las delgadas dejan pasar '
            'hasta 80 % de los rayos UV. Aunque esté nublado, te puedes quemar.',
      ),
    ];
  }
}

class _Nota extends StatelessWidget {
  const _Nota({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: tema.colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: tema.textTheme.bodySmall)),
      ],
    );
  }
}
