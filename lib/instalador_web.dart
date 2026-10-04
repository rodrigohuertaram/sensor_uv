// Version web: llama a las funciones de web/index.html que guardan el aviso de instalacion.

import 'dart:js_interop';

@JS('sensorUvPuedeInstalar')
external bool _puedeInstalar();

@JS('sensorUvInstalar')
external JSPromise<JSString> _instalar();

@JS('sensorUvEsIOS')
external bool _esIOS();

@JS('sensorUvInstalada')
external bool _instalada();

@JS('sensorUvAlCambiar')
external void _alCambiar(JSFunction callback);

const bool esWeb = true;

bool puedeInstalar() => _puedeInstalar();
bool esIOS() => _esIOS();
bool yaInstalada() => _instalada();
Future<void> pedirInstalacion() => _instalar().toDart;
void alCambiar(void Function() callback) => _alCambiar(callback.toJS);
