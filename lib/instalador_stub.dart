// Version para Android, iOS y escritorio: no hay nada que instalar.

const bool esWeb = false;

bool puedeInstalar() => false;
bool esIOS() => false;
bool yaInstalada() => true;
Future<void> pedirInstalacion() async {}
void alCambiar(void Function() callback) {}
