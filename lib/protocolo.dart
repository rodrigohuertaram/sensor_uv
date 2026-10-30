// Formato de los mensajes por Bluetooth entre la app y el dispositivo.
// Es el MISMO que usa la placa (dispositivo/lib/Protocolo): si se cambia uno, cambiar el otro.
//
//   Configuración (app -> placa):
//     i=<id del perfil>;n=<nombre>;t=<tipo 1-6>;f=<FPS>;r=<resistencia>;s=<sudor 0/1>;l=<lugar>
//     y, si hay clima de tu zona: ;z=<UV del clima>;za=<minutos que tiene el dato>
//   Estado (placa -> app, cada segundo):
//     uv=5.2;av=43;min=37;rea=0;sil=0;sol=1;bat=-1;uvs=4.8;uvc=6.1;ps=70;pc=30;som=0
//     (uv = combinado del sensor y el clima; uvs = sensor; uvc = clima, -1 si no hay;
//      ps/pc = % de credibilidad de cada uno; som = se usó el mínimo en sombra)
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
  double? uvClima, // UV del clima de tu zona (si hay)
  int edadClimaMin = 0, // minutos que tiene ese dato
}) {
  final idCorto = id.length > 24 ? id.substring(id.length - 24) : id;
  final clima = uvClima == null
      ? ''
      : ';z=${uvClima.toStringAsFixed(1)};za=$edadClimaMin';
  return 'i=$idCorto;n=${limpiarNombre(nombre)};t=$fototipo;f=$fps;'
      'r=$resistenciaAguaMin;s=${sudorOAgua ? 1 : 0};l=$lugar$clima';
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
    required this.uvSensor,
    required this.uvClima,
    required this.pesoSensor,
    required this.pesoClima,
    required this.sombra,
  });

  final double
  uvi; // índice UV que usa la placa (sensor combinado con el clima)
  final double avance; // 0 a 1
  final double restanteMin;
  final bool tocaReaplicar;
  final bool silenciada; // la alarma del dispositivo se silenció
  final bool haySol;
  final int? bateria; // % (null si el dispositivo no la mide)
  final double uvSensor; // lo que mide el sensor
  final double? uvClima; // UV del clima de tu zona (null si no hay o es viejo)
  final int pesoSensor; // % de credibilidad del sensor
  final int pesoClima; // % de credibilidad del clima
  final bool sombra; // se usó el mínimo en sombra (50 % del clima)
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
  final uvc = double.tryParse(datos['uvc'] ?? '');
  final ps = int.tryParse(datos['ps'] ?? '') ?? 100;
  return EstadoDispositivo(
    uvi: uvi,
    avance: (av / 100).clamp(0.0, 1.0).toDouble(),
    restanteMin: min.toDouble(),
    tocaReaplicar: datos['rea'] == '1',
    silenciada: datos['sil'] == '1',
    haySol: datos['sol'] != '0',
    bateria: (bat == null || bat < 0) ? null : bat,
    // Placas con el programa anterior no mandan estos datos: solo sensor
    uvSensor: double.tryParse(datos['uvs'] ?? '') ?? uvi,
    uvClima: (uvc == null || uvc < 0) ? null : uvc,
    pesoSensor: ps,
    pesoClima: int.tryParse(datos['pc'] ?? '') ?? (100 - ps),
    sombra: datos['som'] == '1',
  );
}
