// Obtiene la ubicacion aproximada del dispositivo (siempre pidiendo permiso).
// En web usa el navegador; en Android/iOS todavia no esta disponible.

export 'ubicacion_stub.dart' if (dart.library.js_interop) 'ubicacion_web.dart';

// Errores posibles al pedir la ubicacion
class ErrorUbicacion implements Exception {
  const ErrorUbicacion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
