// Formato de los mensajes por Bluetooth entre la app y el dispositivo.
// Es el MISMO que usa la placa (dispositivo/lib/Protocolo): si se cambia uno, cambiar el otro.
//
//   Configuración (app -> placa):
//     i=<id del perfil>;n=<nombre>;t=<tipo 1-6>;f=<FPS>;r=<resistencia>;s=<sudor 0/1>;l=<lugar>
//   Estado (placa -> app, cada segundo):
//     uv=5.2;av=43;min=37;rea=0;sil=0;sol=1;bat=-1
//   Órdenes (los dos sentidos): reaplicado | silenciar | dormir

const String ordenReaplicado = 'reaplicado';
const String ordenSilenciar = 'silenciar';
const String ordenDormir = 'dormir';

// El nombre no puede llevar ";" ni "=" (separan los datos) y se corta a 30 letras como en la app.
String limpiarNombre(String nombre) {
  final limpio = nombre.replaceAll(RegExp('[;=]'), ' ').trim();
  return limpio.length > 30 ? limpio.substring(0, 30) : limpio;
}

String textoConfiguracion({
  required String id,
  required String nombre,
  required int fototipo,
  required int fps,
  required int resistenciaAguaMin,
  required bool sudorOAgua,
  required String lugar, // ciudad, parque, agua, playa o nieve
}) {
  final idCorto = id.length > 24 ? id.substring(id.length - 24) : id;
  return 'i=$idCorto;n=${limpiarNombre(nombre)};t=$fototipo;f=$fps;'
      'r=$resistenciaAguaMin;s=${sudorOAgua ? 1 : 0};l=$lugar';
}

// Lo que manda el dispositivo cada segundo
class EstadoDispositivo {
  const EstadoDispositivo({
    required this.uvi,
    required this.avance,
    required this.restanteMin,
    required this.tocaReaplicar,
    required this.silenciada,
    required this.haySol,
    required this.bateria,
  });

  final double uvi; // índice UV medido por el sensor
  final double avance; // 0 a 1
  final double restanteMin;
  final bool tocaReaplicar;
  final bool silenciada; // la alarma del dispositivo se silenció
  final bool haySol;
  final int? bateria; // % (null si el dispositivo no la mide)
}

// Devuelve null si el texto no tiene el formato esperado
EstadoDispositivo? leerEstado(String texto) {
  final datos = <String, String>{};
  for (final par in texto.trim().split(';')) {
    final igual = par.indexOf('=');
    if (igual <= 0) return null;
    datos[par.substring(0, igual)] = par.substring(igual + 1);
  }
  final uvi = double.tryParse(datos['uv'] ?? '');
  final av = int.tryParse(datos['av'] ?? '');
  final min = int.tryParse(datos['min'] ?? '');
  if (uvi == null || av == null || min == null) return null;
  final bat = int.tryParse(datos['bat'] ?? '');
  return EstadoDispositivo(
    uvi: uvi,
    avance: (av / 100).clamp(0.0, 1.0).toDouble(),
    restanteMin: min.toDouble(),
    tocaReaplicar: datos['rea'] == '1',
    silenciada: datos['sil'] == '1',
    haySol: datos['sol'] != '0',
    bateria: (bat == null || bat < 0) ? null : bat,
  );
}
