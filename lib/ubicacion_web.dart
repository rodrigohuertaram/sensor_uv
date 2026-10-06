// Version web: usa la funcion de web/index.html que llama a navigator.geolocation.

import 'dart:js_interop';

import 'ubicacion.dart';

// Devuelve "latitud,longitud" o falla con: sin-soporte, permiso, no-disponible o tiempo
@JS('sensorUvUbicacion')
external JSPromise<JSString> _ubicacion();

Future<({double latitud, double longitud})> obtenerUbicacion() async {
  try {
    final texto = (await _ubicacion().toDart).toDart;
    final partes = texto.split(',');
    return (
      latitud: double.parse(partes[0]),
      longitud: double.parse(partes[1]),
    );
  } catch (e) {
    final motivo = e.toString();
    if (motivo.contains('permiso')) {
      throw const ErrorUbicacion(
        'No diste permiso para usar tu ubicación. Puedes activarlo en la '
        'configuración del navegador.',
      );
    }
    if (motivo.contains('sin-soporte')) {
      throw const ErrorUbicacion(
        'Este navegador no permite usar la ubicación.',
      );
    }
    throw const ErrorUbicacion(
      'No se pudo obtener tu ubicación. Revisa que esté activada e '
      'inténtalo de nuevo.',
    );
  }
}
