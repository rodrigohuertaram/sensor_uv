// Modelo de la app Sensor UV.
// Guarda los datos del usuario y hace el mismo calculo que el dispositivo:
// avisa cuando la dosis de sol llega al limite de la piel o cuando se acaba el tope de tiempo.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'almacen.dart';

// Un perfil guardado con su propio nombre (por ejemplo, uno por cada persona de la familia)
class Perfil {
  Perfil({
    required this.id,
    required this.nombre,
    this.fototipo = 3,
    this.fps = 30,
    this.resistenciaAguaMin = 0,
  });

  final String id;
  String nombre;
  int fototipo; // tipo de piel, 1 (muy clara) a 6 (muy oscura)
  int fps; // FPS del envase
  int resistenciaAguaMin; // lo que dice el envase: 0, 40 u 80 minutos

  Map<String, Object> aJson() => {
    'id': id,
    'nombre': nombre,
    'fototipo': fototipo,
    'fps': fps,
    'resistenciaAguaMin': resistenciaAguaMin,
  };

  factory Perfil.desdeJson(Map<String, dynamic> json) => Perfil(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    fototipo: json['fototipo'] as int,
    fps: json['fps'] as int,
    resistenciaAguaMin: json['resistenciaAguaMin'] as int,
  );
}

class ModeloUV extends ChangeNotifier {
  // ---------- Perfiles guardados ----------
  static const String _clavePerfiles = 'perfiles';
  static const String _claveActivo = 'perfilActivo';
  static const int largoMaximoNombre = 30;

  List<Perfil> perfiles = [Perfil(id: 'inicial', nombre: 'Mi perfil')];
  String idActivo = 'inicial';

  Perfil get perfilActivo => perfiles.firstWhere(
    (p) => p.id == idActivo,
    orElse: () => perfiles.first,
  );

  // ---------- Datos del perfil activo ----------
  int get fototipo => perfilActivo.fototipo;
  int get fps => perfilActivo.fps;
  int get resistenciaAguaMin => perfilActivo.resistenciaAguaMin;

  bool sudorOAgua = false; // true si la persona esta sudando o nadando

  // ---------- Parametros del calculo (iguales a los del dispositivo) ----------
  // Dosis minima que enrojece la piel (J/m2) para cada fototipo, posiciones 1 a 6
  static const List<double> dem = [0, 200, 250, 350, 450, 600, 1000];
  static const double factorAplicacion = 0.3;
  static const double margenSeguridad = 0.6;
  static const double topeNormalMin = 120;

  // ---------- Simulacion (mientras no hay sensor conectado) ----------
  double uvi = 0; // indice UV actual; por ahora lo da el control deslizante
  double aceleracion = 60; // 60 = cada segundo real cuenta como 1 minuto

  // ---------- Estado ----------
  double dosis = 0; // J/m2 acumulados desde la ultima aplicacion
  double tiempoExpuestoS = 0; // segundos al sol desde la ultima aplicacion
  bool tocaReaplicar = false;
  Timer? _reloj;

  // Limite de dosis segun tipo de piel y FPS
  double get limiteDosis =>
      dem[fototipo] * fps * factorAplicacion * margenSeguridad;

  // Tope de tiempo segun sudor o agua
  double get topeTiempoMin {
    if (!sudorOAgua) return topeNormalMin;
    return resistenciaAguaMin >= 80 ? 80 : 40;
  }

  double get topeTiempoS => topeTiempoMin * 60;

  // Minutos que faltan para reaplicar con el sol de este momento
  double get restanteMin {
    double restanteS = topeTiempoS - tiempoExpuestoS;
    if (uvi >= 1) {
      final porDosis = (limiteDosis - dosis) / (0.025 * uvi);
      if (porDosis < restanteS) restanteS = porDosis;
    }
    if (restanteS < 0) restanteS = 0;
    return restanteS / 60;
  }

  // Avance de 0 a 1 hacia el limite mas cercano (dosis o tiempo)
  double get avance {
    final a = math.max(dosis / limiteDosis, tiempoExpuestoS / topeTiempoS);
    return a.clamp(0.0, 1.0).toDouble();
  }

  String get nivel {
    if (uvi < 3) return 'Bajo';
    if (uvi < 6) return 'Moderado';
    if (uvi < 8) return 'Alto';
    if (uvi < 11) return 'Muy alto';
    return 'Extremo';
  }

  // Minutos en los que avisaria con un indice UV fijo (para mostrar ejemplos)
  double minutosParaAvisar(double indiceUV) {
    final porTope = topeTiempoMin;
    if (indiceUV < 1) return porTope;
    final porDosis = limiteDosis / (0.025 * indiceUV) / 60;
    return math.min(porTope, porDosis);
  }

  // ---------- Reloj: una lectura por segundo ----------
  void iniciar() {
    _reloj ??= Timer.periodic(const Duration(seconds: 1), (_) => _lectura(1));
  }

  void detener() {
    _reloj?.cancel();
    _reloj = null;
  }

  void _lectura(double segundosReales) {
    final dt = segundosReales * aceleracion;
    // Solo se acumula cuando hay sol (indice UV de 1 o mas)
    if (!tocaReaplicar && uvi >= 1) {
      dosis += 0.025 * uvi * dt; // 1 punto de indice UV = 0.025 W/m2
      tiempoExpuestoS += dt;
    }
    if (dosis >= limiteDosis || tiempoExpuestoS >= topeTiempoS) {
      tocaReaplicar = true;
    }
    notifyListeners();
  }

  // Boton "Ya me puse bloqueador"
  void reiniciar() {
    _reiniciarCuenta();
    notifyListeners();
  }

  // ---------- Cambios desde las pantallas ----------
  void cambiarUV(double valor) {
    uvi = valor;
    notifyListeners();
  }

  void cambiarFototipo(int valor) {
    perfilActivo.fototipo = valor;
    _guardarPerfiles();
  }

  void cambiarFps(int valor) {
    perfilActivo.fps = valor;
    _guardarPerfiles();
  }

  void cambiarSudor(bool valor) {
    sudorOAgua = valor;
    notifyListeners();
  }

  void cambiarResistencia(int valor) {
    perfilActivo.resistenciaAguaMin = valor;
    _guardarPerfiles();
  }

  // ---------- Perfiles ----------
  // Lee los perfiles guardados en el dispositivo (se llama una vez al abrir la app)
  void cargarPerfiles() {
    try {
      final texto = leerDato(_clavePerfiles);
      if (texto == null) return;
      final lista = (jsonDecode(texto) as List)
          .map((p) => Perfil.desdeJson(p as Map<String, dynamic>))
          .toList();
      if (lista.isEmpty) return;
      perfiles = lista;
      idActivo = leerDato(_claveActivo) ?? lista.first.id;
    } catch (_) {
      // Datos danados o de una version anterior: se empieza con el perfil inicial
    }
  }

  void _guardarPerfiles() {
    guardarDato(
      _clavePerfiles,
      jsonEncode(perfiles.map((p) => p.aJson()).toList()),
    );
    guardarDato(_claveActivo, idActivo);
    notifyListeners();
  }

  // Al cambiar de persona se reinicia la cuenta de sol, porque es otra piel
  void elegirPerfil(String id) {
    if (id == idActivo) return;
    idActivo = id;
    _reiniciarCuenta();
    _guardarPerfiles();
  }

  // El perfil nuevo empieza con los mismos datos del activo, para editar solo lo que cambia
  void crearPerfil(String nombre) {
    final actual = perfilActivo;
    final nuevo = Perfil(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nombre: nombre.trim(),
      fototipo: actual.fototipo,
      fps: actual.fps,
      resistenciaAguaMin: actual.resistenciaAguaMin,
    );
    perfiles.add(nuevo);
    idActivo = nuevo.id;
    _reiniciarCuenta();
    _guardarPerfiles();
  }

  void renombrarPerfil(String nombre) {
    perfilActivo.nombre = nombre.trim();
    _guardarPerfiles();
  }

  // Siempre queda al menos un perfil
  void eliminarPerfilActivo() {
    if (perfiles.length <= 1) return;
    perfiles.removeWhere((p) => p.id == idActivo);
    idActivo = perfiles.first.id;
    _reiniciarCuenta();
    _guardarPerfiles();
  }

  // Revisa un nombre antes de guardarlo; devuelve el error o null si esta bien
  String? validarNombre(String nombre, {String? idIgnorado}) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe un nombre';
    if (limpio.length > largoMaximoNombre) {
      return 'Máximo $largoMaximoNombre caracteres';
    }
    final repetido = perfiles.any(
      (p) =>
          p.id != idIgnorado && p.nombre.toLowerCase() == limpio.toLowerCase(),
    );
    if (repetido) return 'Ya hay un perfil con ese nombre';
    return null;
  }

  void _reiniciarCuenta() {
    dosis = 0;
    tiempoExpuestoS = 0;
    tocaReaplicar = false;
  }

  void cambiarAceleracion(double valor) {
    aceleracion = valor;
    notifyListeners();
  }
}

// Un solo modelo compartido por todas las pantallas
final ModeloUV modelo = ModeloUV();
