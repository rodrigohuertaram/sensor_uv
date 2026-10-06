// Modelo de la app Sensor UV.
// Guarda los datos del usuario y hace el mismo calculo que el dispositivo:
// avisa cuando la dosis de sol llega al limite de la piel o cuando se acaba el tope de tiempo.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'almacen.dart';
import 'clima.dart';
import 'pantalla.dart';
import 'ubicacion.dart';

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

// Lugar donde esta la persona. El suelo refleja rayos UV y suma a lo que recibe la piel
// (Guia del Indice UV de la OMS: nieve fresca hasta 80 %, espuma de mar 25 %,
// arena seca 15 %; pasto, tierra y agua menos de 10 %).
enum Entorno {
  ciudad('Ciudad', Icons.location_city, 1.0, null),
  parque('Parque o bosque', Icons.park, 1.0, null),
  agua(
    'Alberca o lago',
    Icons.pool,
    1.1,
    'El agua refleja hasta 10 % más de rayos UV.',
  ),
  playa(
    'Playa',
    Icons.beach_access,
    1.25,
    'La arena y la espuma del mar reflejan hasta 25 % más de rayos UV.',
  ),
  nieve(
    'Nieve',
    Icons.ac_unit,
    1.8,
    'La nieve refleja hasta 80 % más de rayos UV: tu piel recibe casi el doble.',
  );

  const Entorno(this.nombre, this.icono, this.factor, this.nota);

  final String nombre;
  final IconData icono;
  final double factor; // cuanto aumenta la dosis por el reflejo del suelo
  final String? nota;
}

// Cielo elegido a mano (solo se usa con el simulador; el UV de tu zona ya incluye las nubes).
// Es conservador: las nubes delgadas dejan pasar hasta 80 % de los rayos UV (OMS).
enum Cielo {
  despejado('Despejado', Icons.wb_sunny, 1.0),
  algoNublado('Algo nublado', Icons.wb_cloudy_outlined, 1.0),
  nublado('Nublado', Icons.cloud, 0.8),
  lluvia('Lluvia o muy nublado', Icons.umbrella, 0.5);

  const Cielo(this.nombre, this.icono, this.factor);

  final String nombre;
  final IconData icono;
  final double factor;
}

// De donde sale el indice UV
enum FuenteUV { simulador, zona }

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

  // ---------- Indice UV (mientras no hay sensor conectado) ----------
  double uvi = 0; // indice UV actual: del simulador o de tu zona
  FuenteUV fuente = FuenteUV.simulador;
  double aceleracion = 60; // 60 = cada segundo real cuenta como 1 minuto

  // ---------- Lugar y clima ----------
  Entorno entorno = Entorno.ciudad;
  Cielo cielo = Cielo.despejado;
  DatosClima? clima; // ultimo clima consultado en tu zona
  bool consultandoClima = false;
  String? errorClima;
  Timer? _relojClima;

  // UV que de verdad recibe la piel: el indice mas el reflejo del suelo y, con el
  // simulador, menos lo que filtran las nubes
  double get uvEfectivo {
    final filtroNubes = fuente == FuenteUV.simulador ? cielo.factor : 1.0;
    return uvi * filtroNubes * entorno.factor;
  }

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
    if (uvEfectivo >= 1) {
      final porDosis = (limiteDosis - dosis) / (0.025 * uvEfectivo);
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

  // Minutos en los que avisaria con un indice UV fijo, en el lugar elegido (para ejemplos)
  double minutosParaAvisar(double indiceUV) {
    final porTope = topeTiempoMin;
    final efectivo = indiceUV * entorno.factor;
    if (efectivo < 1) return porTope;
    final porDosis = limiteDosis / (0.025 * efectivo) / 60;
    return math.min(porTope, porDosis);
  }

  // ---------- Reloj: una lectura por segundo ----------
  // Se mide el tiempo real entre lecturas: si el telefono congelo la app (segundo plano
  // o pantalla apagada), al volver se cuenta todo el tiempo que paso.
  DateTime? _ultimaLectura;

  void iniciar() {
    _ultimaLectura = DateTime.now();
    _reloj ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final ahora = DateTime.now();
      final anterior = _ultimaLectura ?? ahora;
      _ultimaLectura = ahora;
      _lectura(ahora.difference(anterior).inMilliseconds / 1000);
    });
  }

  void detener() {
    _reloj?.cancel();
    _reloj = null;
    _relojClima?.cancel();
    _relojClima = null;
  }

  void _lectura(double segundosReales) {
    // Despues de una pausa larga no hace falta contar mas alla del tope de tiempo
    final dt = math.min(segundosReales * aceleracion, topeTiempoS);
    // Solo se acumula cuando hay sol (indice UV de 1 o mas)
    if (!tocaReaplicar && uvEfectivo >= 1) {
      dosis += 0.025 * uvEfectivo * dt; // 1 punto de indice UV = 0.025 W/m2
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

  void cambiarEntorno(Entorno valor) {
    entorno = valor;
    notifyListeners();
  }

  void cambiarCielo(Cielo valor) {
    cielo = valor;
    notifyListeners();
  }

  // ---------- Clima de tu zona ----------
  // Pide la ubicacion (con permiso), consulta el clima y sugiere el cielo
  Future<void> actualizarClima() async {
    if (consultandoClima) return;
    consultandoClima = true;
    errorClima = null;
    notifyListeners();
    try {
      final posicion = await obtenerUbicacion();
      final datos = await consultarClima(posicion.latitud, posicion.longitud);
      clima = datos;
      cielo = _cieloSegun(datos);
      if (fuente == FuenteUV.zona) uvi = datos.indiceUV;
    } on ErrorUbicacion catch (e) {
      errorClima = e.mensaje;
    } catch (_) {
      errorClima =
          'No se pudo consultar el clima. Revisa tu conexión a internet e '
          'inténtalo de nuevo.';
    } finally {
      consultandoClima = false;
      notifyListeners();
    }
  }

  // Usar el indice UV de tu zona en lugar del simulador; se actualiza cada 15 minutos.
  // La eleccion se recuerda para la proxima vez que se abra la app.
  static const String _claveUsarZona = 'usarUvDeZona';
  static const Duration cadaCuantoClima = Duration(minutes: 15);

  void usarUvDeZona(bool usar) {
    final datos = clima;
    if (usar && datos == null) return;
    guardarDato(_claveUsarZona, usar ? 'si' : 'no');
    fuente = usar ? FuenteUV.zona : FuenteUV.simulador;
    _relojClima?.cancel();
    _relojClima = null;
    if (usar) {
      uvi = datos!.indiceUV;
      _relojClima = Timer.periodic(cadaCuantoClima, (_) => actualizarClima());
    }
    notifyListeners();
  }

  // Mantener la pantalla encendida mientras la app esta abierta (gasta mas bateria).
  // Asi la app no se congela y sigue actualizando el clima cada 15 minutos.
  static const String _clavePantalla = 'pantallaEncendida';
  bool pantallaEncendida = false;

  void cambiarPantallaEncendida(bool valor) {
    pantallaEncendida = valor;
    mantenerPantallaEncendida(valor);
    guardarDato(_clavePantalla, valor ? 'si' : 'no');
    notifyListeners();
  }

  // Al abrir la app se recupera lo que se eligio la vez pasada
  Future<void> restaurarPreferencias() async {
    if (leerDato(_clavePantalla) == 'si') cambiarPantallaEncendida(true);
    if (leerDato(_claveUsarZona) == 'si') {
      await actualizarClima();
      if (clima != null) usarUvDeZona(true);
    }
  }

  // Al volver a la app (estaba en segundo plano o con la pantalla apagada):
  // si el clima tiene mas de 15 minutos, se actualiza de inmediato
  void alVolverALaApp() {
    final datos = clima;
    if (fuente != FuenteUV.zona || datos == null) return;
    if (DateTime.now().difference(datos.consultado) >= cadaCuantoClima) {
      actualizarClima();
    }
  }

  Cielo _cieloSegun(DatosClima datos) {
    if (datos.llueve || datos.nubosidad >= 90) return Cielo.lluvia;
    if (datos.nubosidad >= 60) return Cielo.nublado;
    if (datos.nubosidad >= 25) return Cielo.algoNublado;
    return Cielo.despejado;
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
