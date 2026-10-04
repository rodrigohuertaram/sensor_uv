// Guarda datos pequenos en el dispositivo (por ejemplo, que ya se acepto el aviso medico).
// En web usa el almacenamiento del navegador; en las demas plataformas, por ahora,
// solo se recuerda mientras la app esta abierta.

export 'almacen_stub.dart' if (dart.library.js_interop) 'almacen_web.dart';
