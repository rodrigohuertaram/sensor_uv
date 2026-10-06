// Version web: usa las funciones de web/index.html que piden el Wake Lock del navegador.

import 'dart:js_interop';

@JS('sensorUvPuedeMantenerPantalla')
external bool _puede();

@JS('sensorUvPantallaEncendida')
external void _mantener(bool activar);

bool puedeMantenerPantalla() => _puede();

void mantenerPantallaEncendida(bool activar) => _mantener(activar);
