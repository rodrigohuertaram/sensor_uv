// Tarjeta "Tu dispositivo": conectar por Bluetooth el dispositivo Solaris Shield.
// Con el dispositivo conectado, el indice UV y la cuenta los lleva la placa
// ("la placa es el cerebro") y la app muestra lo que ella manda.

import 'package:flutter/material.dart';

import 'dispositivo.dart';
import 'modelo.dart';

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
                'Conectado. El índice UV lo mide tu dispositivo; tu perfil, el '
                'lugar y si sudas o estás en el agua se le envían solos.',
          ),
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
