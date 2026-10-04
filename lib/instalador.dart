// Permite instalar la version web en el telefono o la computadora ("Agregar a inicio").
// En web usa el aviso de instalacion del navegador; en Android/Windows no hace nada.

import 'package:flutter/material.dart';

import 'instalador_stub.dart' if (dart.library.js_interop) 'instalador_web.dart'
    as plataforma;

class Instalador extends ChangeNotifier {
  Instalador() {
    plataforma.alCambiar(notifyListeners);
  }

  // Se muestra el boton solo en web y si la app todavia no esta instalada
  bool get mostrarBoton => plataforma.esWeb && !plataforma.yaInstalada();

  Future<void> instalar(BuildContext context) async {
    if (plataforma.puedeInstalar()) {
      await plataforma.pedirInstalacion();
      notifyListeners();
      return;
    }
    // Sin aviso automatico (iPhone, o navegadores que no lo tienen): se explica a mano
    if (!context.mounted) return;
    final ios = plataforma.esIOS();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.add_to_home_screen, size: 40),
        title: const Text('Agregar a inicio'),
        content: Text(
          ios
              ? '1. Toca el botón Compartir (cuadro con flecha hacia arriba) en Safari.\n'
                    '2. Elige "Agregar a pantalla de inicio".\n'
                    '3. Toca "Agregar".'
              : '1. Abre el menú del navegador (⋮).\n'
                    '2. Elige "Instalar app" o "Agregar a pantalla de inicio".\n'
                    '3. Confirma.',
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
}

final Instalador instalador = Instalador();

// Boton "Instalar app" que solo aparece cuando tiene sentido
class BotonInstalar extends StatelessWidget {
  const BotonInstalar({super.key, this.extendido = true});

  final bool extendido;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: instalador,
      builder: (context, _) {
        if (!instalador.mostrarBoton) return const SizedBox.shrink();
        if (!extendido) {
          return IconButton.filledTonal(
            tooltip: 'Instalar app',
            icon: const Icon(Icons.install_mobile),
            onPressed: () => instalador.instalar(context),
          );
        }
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.install_mobile),
          label: const Text('Instalar app'),
          onPressed: () => instalador.instalar(context),
        );
      },
    );
  }
}
