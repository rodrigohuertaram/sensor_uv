// Version web: usa las funciones de web/index.html que leen y escriben en el navegador.

import 'dart:js_interop';

@JS('sensorUvLeer')
external JSString? _leer(JSString clave);

@JS('sensorUvGuardar')
external void _guardar(JSString clave, JSString valor);

String? leerDato(String clave) => _leer(clave.toJS)?.toDart;

void guardarDato(String clave, String valor) =>
    _guardar(clave.toJS, valor.toJS);
