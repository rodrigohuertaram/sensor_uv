// Modelo de la app Sensor UV.
// Guarda los datos del usuario y hace el mismo calculo que el dispositivo:
// avisa cuando la dosis de sol llega al limite de la piel o cuando se acaba el tope de tiempo.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class ModeloUV extends ChangeNotifier {
  // ---------- Datos del usuario ----------
  int fototipo = 3; // tipo de piel, 1 (muy clara) a 6 (muy oscura)
  int fps = 30; // FPS del envase
  bool sudorOAgua = false; // true si la persona esta sudando o nadando
  int resistenciaAguaMin = 0; // lo que dice el envase: 0, 40 u 80 minutos

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
    dosis = 0;
    tiempoExpuestoS = 0;
    tocaReaplicar = false;
    notifyListeners();
  }

  // ---------- Cambios desde las pantallas ----------
  void cambiarUV(double valor) {
    uvi = valor;
    notifyListeners();
  }

  void cambiarFototipo(int valor) {
    fototipo = valor;
    notifyListeners();
  }

  void cambiarFps(int valor) {
    fps = valor;
    notifyListeners();
  }

  void cambiarSudor(bool valor) {
    sudorOAgua = valor;
    notifyListeners();
  }

  void cambiarResistencia(int valor) {
    resistenciaAguaMin = valor;
    notifyListeners();
  }

  void cambiarAceleracion(double valor) {
    aceleracion = valor;
    notifyListeners();
  }
}

// Un solo modelo compartido por todas las pantallas
final ModeloUV modelo = ModeloUV();
