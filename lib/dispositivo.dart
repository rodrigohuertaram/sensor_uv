// Conexión por Bluetooth con el dispositivo Solaris Shield.
// En web usa Web Bluetooth (Chrome en Android y computadora; Bluefy en iPhone).
// En la app nativa de Android se hará con un paquete nativo (ver PENDIENTES_ANDROID.md).

export 'dispositivo_stub.dart'
    if (dart.library.js_interop) 'dispositivo_web.dart';

class ErrorBluetooth implements Exception {
  const ErrorBluetooth(this.mensaje, {this.cancelado = false});

  final String mensaje;
  final bool cancelado; // la persona cerró la lista sin elegir un dispositivo
}
