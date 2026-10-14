// Version para Android, iOS y escritorio: todavia no disponible (app nativa pendiente).

import 'dispositivo.dart';

bool puedeUsarBluetooth() => false;

Future<String> conectarDispositivo({
  required void Function(String texto) alEstado,
  required void Function(String orden) alOrden,
  required void Function(String conexion) alCambioConexion,
}) async {
  throw const ErrorBluetooth(
    'Esta versión de la app aún no puede usar Bluetooth.',
  );
}

Future<void> enviarConfiguracion(String texto) async {}

Future<void> enviarOrden(String orden) async {}

void desconectarDispositivo() {}
