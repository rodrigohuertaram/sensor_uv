// Consulta el clima actual (temperatura, nubes e indice UV) en Open-Meteo, un servicio
// gratuito que no pide cuenta. Para cuidar la privacidad, la ubicacion se redondea
// a 2 decimales (alrededor de 1 km) antes de enviarla, y no se guarda.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DatosClima {
  const DatosClima({
    required this.temperatura,
    required this.sensacion,
    required this.indiceUV,
    required this.uvMaximoHoy,
    required this.nubosidad,
    required this.codigo,
    required this.consultado,
  });

  final double temperatura; // grados C
  final double sensacion; // sensacion termica, grados C
  final double indiceUV; // indice UV en este momento (ya incluye las nubes)
  final double uvMaximoHoy;
  final int nubosidad; // porcentaje del cielo cubierto
  final int codigo; // codigo del clima de la OMM
  final DateTime consultado;

  String get descripcion => _descripcion(codigo);
  IconData get icono => _icono(codigo);
  bool get llueve => codigo >= 51;
}

Future<DatosClima> consultarClima(double latitud, double longitud) async {
  final url = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': latitud.toStringAsFixed(2),
    'longitude': longitud.toStringAsFixed(2),
    'current':
        'temperature_2m,apparent_temperature,uv_index,cloud_cover,weather_code',
    'daily': 'uv_index_max',
    'forecast_days': '1',
    'timezone': 'auto',
  });
  final respuesta = await http.get(url).timeout(const Duration(seconds: 15));
  if (respuesta.statusCode != 200) {
    throw Exception('Open-Meteo respondió ${respuesta.statusCode}');
  }
  final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
  final actual = json['current'] as Map<String, dynamic>;
  final diario = json['daily'] as Map<String, dynamic>;
  return DatosClima(
    temperatura: (actual['temperature_2m'] as num).toDouble(),
    sensacion: (actual['apparent_temperature'] as num).toDouble(),
    indiceUV: (actual['uv_index'] as num).toDouble(),
    uvMaximoHoy: ((diario['uv_index_max'] as List).first as num).toDouble(),
    nubosidad: (actual['cloud_cover'] as num).round(),
    codigo: (actual['weather_code'] as num).round(),
    consultado: DateTime.now(),
  );
}

// Codigos de clima de la Organizacion Meteorologica Mundial (los que usa Open-Meteo)
String _descripcion(int codigo) {
  if (codigo == 0) return 'Despejado';
  if (codigo <= 2) return 'Parcialmente nublado';
  if (codigo == 3) return 'Nublado';
  if (codigo <= 48) return 'Niebla';
  if (codigo <= 57) return 'Llovizna';
  if (codigo <= 67) return 'Lluvia';
  if (codigo <= 77) return 'Nieve';
  if (codigo <= 82) return 'Chubascos';
  if (codigo <= 86) return 'Nevadas';
  return 'Tormenta';
}

IconData _icono(int codigo) {
  if (codigo == 0) return Icons.wb_sunny;
  if (codigo <= 2) return Icons.wb_cloudy_outlined;
  if (codigo <= 48) return Icons.cloud;
  if (codigo <= 67) return Icons.umbrella;
  if (codigo <= 77) return Icons.ac_unit;
  if (codigo <= 82) return Icons.umbrella;
  if (codigo <= 86) return Icons.ac_unit;
  return Icons.thunderstorm;
}
