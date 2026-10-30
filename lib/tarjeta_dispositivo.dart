// Tarjeta "Tu dispositivo": conectar por Bluetooth el dispositivo Solaris Shield.
// Con el dispositivo conectado, el indice UV y la cuenta los lleva la placa
// ("la placa es el cerebro") y la app muestra lo que ella manda.

import 'package:flutter/material.dart';

import 'dispositivo.dart';
import 'modelo.dart';
import 'protocolo.dart';

class TarjetaDispositivo extends StatelessWidget {
  const TarjetaDispositivo({super.key});

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu dispositivo', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._contenido(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _contenido(BuildContext context) {
    final tema = Theme.of(context);
    if (!puedeUsarBluetooth()) {
      return const [
        _Renglon(
          icono: Icons.bluetooth_disabled,
          texto:
              'Este navegador no permite Bluetooth. Para conectar tu dispositivo '
              'usa Chrome en Android o en la computadora, o Bluefy en iPhone.',
        ),
      ];
    }

    switch (modelo.conexion) {
      case EstadoConexion.desconectado:
        final error = modelo.errorDispositivo;
        return [
          const Text(
            'Conecta tu dispositivo Solaris Shield para usar el índice UV que mide '
            'su sensor. Tu perfil y el lugar se le envían solos.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: modelo.conectarDispositivo,
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Conectar dispositivo'),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: tema.colorScheme.error)),
          ],
        ];
      case EstadoConexion.conectando:
        return const [
          Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Conectando… elige "Solaris Shield" en la lista.'),
              ),
            ],
          ),
        ];
      case EstadoConexion.reconectando:
        return const [
          _Renglon(
            icono: Icons.bluetooth_searching,
            texto:
                'Se perdió la conexión. Reconectando… Mientras tanto, tu '
                'dispositivo sigue contando y te avisa por su cuenta.',
          ),
        ];
      case EstadoConexion.conectado:
        final silenciable =
            modelo.tocaReaplicar && !modelo.alarmaDispositivoSilenciada;
        return [
          const _Renglon(
            icono: Icons.bluetooth_connected,
            texto:
                'Conectado. Tu dispositivo calcula el índice UV con su sensor y '
                'el clima de tu zona; tu perfil, el lugar y si sudas o estás en '
                'el agua se le envían solos.',
          ),
          const SizedBox(height: 12),
          const _CombinacionUV(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: silenciable ? modelo.silenciarDispositivo : null,
                icon: const Icon(Icons.volume_off),
                label: const Text('Silenciar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmarDormir(context),
                icon: const Icon(Icons.bedtime_outlined),
                label: const Text('Dormir dispositivo'),
              ),
              TextButton(
                onPressed: modelo.desconectarDispositivo,
                child: const Text('Desconectar'),
              ),
            ],
          ),
        ];
    }
  }

  Future<void> _confirmarDormir(BuildContext context) async {
    final dormir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Dormir el dispositivo?'),
        content: const Text(
          'Se apagan su pantalla, su sonido y su Bluetooth para ahorrar batería. '
          'Para despertarlo hay que presionar el botón del dispositivo '
          '(desde la app no se puede).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Dormir'),
          ),
        ],
      ),
    );
    if (dormir == true) modelo.dormirDispositivo();
  }
}

// Cómo se calculó el índice UV: sensor del dispositivo + clima de tu zona, con el porcentaje
// de credibilidad de cada uno (2026-10-29). La cuenta la hace la placa; aquí solo se muestra.
class _CombinacionUV extends StatelessWidget {
  const _CombinacionUV();

  @override
  Widget build(BuildContext context) {
    // Se redibuja por su cuenta: es un widget const dentro de la tarjeta
    return ListenableBuilder(
      listenable: modelo,
      builder: (context, _) => _contenido(context),
    );
  }

  Widget _contenido(BuildContext context) {
    final tema = Theme.of(context);
    final datos = modelo.datosDispositivo;
    final uvClima = datos?.uvClima;

    final List<Widget> renglones;
    if (datos == null) {
      renglones = [const Text('Esperando datos del dispositivo…')];
    } else {
      renglones = [
        Text(
          'Índice UV que se usa: ${datos.uvi.toStringAsFixed(1)}',
          style: tema.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        _Fuente(
          icono: Icons.sensors,
          nombre: 'Sensor',
          valor: datos.uvSensor,
          porcentaje: datos.pesoSensor,
        ),
        _Fuente(
          icono: Icons.cloud_outlined,
          nombre: 'Clima de tu zona',
          valor: uvClima,
          porcentaje: datos.pesoClima,
        ),
        const SizedBox(height: 6),
        Text(_explicacion(datos), style: tema.textTheme.bodySmall),
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...renglones,
          if (modelo.clima == null) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: modelo.consultandoClima
                  ? null
                  : modelo.usarClimaConDispositivo,
              icon: const Icon(Icons.my_location),
              label: const Text('Usar también el clima de tu zona'),
            ),
          ],
        ],
      ),
    );
  }

  String _explicacion(EstadoDispositivo d) {
    if (d.sombra) {
      return 'Posible sombra: el sensor marca poco, pero en sombra sigue llegando UV. '
          'Se usa el mínimo: la mitad del UV del clima de tu zona.';
    }
    if (d.uvClima == null) {
      return modelo.clima == null
          ? 'Solo el sensor. Con tu ubicación se combina también con el clima de '
                'tu zona (nubes, ozono y altura).'
          : 'Solo el sensor: el dato del clima tiene más de 1 hora. Se actualiza '
                'cada 15 minutos mientras la app está abierta.';
    }
    if (d.pesoClima == 0) {
      return d.uvSensor >= d.uvClima!
          ? 'El sensor marca más que el clima (reflejo del agua o la arena, o '
                'altura): se usa el sensor.'
          : 'El sensor casi no detecta UV (adentro o tapado): no se cuenta sol.';
    }
    return 'Se combinan: el sensor mide justo donde estás y el clima toma en '
        'cuenta la atmósfera (nubes, ozono y altura).';
  }
}

class _Fuente extends StatelessWidget {
  const _Fuente({
    required this.icono,
    required this.nombre,
    required this.valor,
    required this.porcentaje,
  });

  final IconData icono;
  final String nombre;
  final double? valor;
  final int porcentaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icono, size: 18, color: tema.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valor == null
                  ? '$nombre: sin dato'
                  : '$nombre: UV ${valor!.toStringAsFixed(1)}',
            ),
          ),
          Text(
            '$porcentaje %',
            style: tema.textTheme.titleSmall?.copyWith(
              color: porcentaje > 0
                  ? tema.colorScheme.primary
                  : tema.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(texto)),
      ],
    );
  }
}
