// Version para Android, iOS y escritorio: por ahora no hay ubicacion.

import 'ubicacion.dart';

Future<({double latitud, double longitud})> obtenerUbicacion() async {
  throw const ErrorUbicacion(
    'La ubicación todavía no está disponible en esta versión de la app.',
  );
}
