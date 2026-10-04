// Version para Android, iOS y escritorio: memoria temporal mientras la app esta abierta.

final Map<String, String> _datos = {};

String? leerDato(String clave) => _datos[clave];

void guardarDato(String clave, String valor) => _datos[clave] = valor;
