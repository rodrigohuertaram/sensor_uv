// Version web: usa las funciones de web/index.html (Web Bluetooth).

import 'dart:js_interop';

import 'dispositivo.dart';

@JS('sensorUvBlePuede')
external bool _puede();

@JS('sensorUvBleConectar')
external JSPromise<JSString> _conectar(
  JSFunction alEstado,
  JSFunction alOrden,
  JSFunction alCambioConexion,
);

@JS('sensorUvBleEnviarConfig')
external JSPromise<JSAny?> _enviarConfig(JSString texto);

@JS('sensorUvBleEnviarOrden')
external JSPromise<JSAny?> _enviarOrden(JSString orden);

@JS('sensorUvBleDesconectar')
external void _desconectar();

bool puedeUsarBluetooth() => _puede();

// Abre la lista del navegador para elegir el dispositivo y se conecta.
// Devuelve el nombre del dispositivo. `alCambioConexion` recibe "reconectando",
// "conectado" o "desconectado".
Future<String> conectarDispositivo({
  required void Function(String texto) alEstado,
  required void Function(String orden) alOrden,
  required void Function(String conexion) alCambioConexion,
}) async {
  try {
    final nombre = await _conectar(
      ((JSString t) => alEstado(t.toDart)).toJS,
      ((JSString t) => alOrden(t.toDart)).toJS,
      ((JSString t) => alCambioConexion(t.toDart)).toJS,
    ).toDart;
    return nombre.toDart;
  } catch (e) {
    final motivo = e.toString();
    if (motivo.contains('cancelado')) {
      throw const ErrorBluetooth(
        'No se eligió ningún dispositivo.',
        cancelado: true,
      );
    }
    if (motivo.contains('sin-soporte')) {
      throw const ErrorBluetooth(
        'Este navegador no permite Bluetooth. Usa Chrome en Android o en la '
        'computadora, o Bluefy en iPhone.',
      );
    }
    throw const ErrorBluetooth(
      'No se pudo conectar. Revisa que el dispositivo esté encendido y cerca, '
      'y que el Bluetooth del teléfono esté activado.',
    );
  }
}

Future<void> enviarConfiguracion(String texto) async {
  try {
    await _enviarConfig(texto.toJS).toDart;
  } catch (_) {
    // Si se perdió la conexión, se vuelve a enviar al reconectar
  }
}

Future<void> enviarOrden(String orden) async {
  try {
    await _enviarOrden(orden.toJS).toDart;
  } catch (_) {}
}

void desconectarDispositivo() => _desconectar();
