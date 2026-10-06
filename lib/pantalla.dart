// Mantener la pantalla encendida mientras la app esta abierta, para que siga
// actualizando el clima. En web usa el "Wake Lock" del navegador.

export 'pantalla_stub.dart' if (dart.library.js_interop) 'pantalla_web.dart';
