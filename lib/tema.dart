// Colores y tema de la app, tomados del logo (escudo blanco con sol dorado sobre azul marino).
// La escala de colores del indice UV (verde a morado) no cambia: es el estandar internacional.

import 'package:flutter/material.dart';

const Color azulMarino = Color(0xFF122746);
const Color dorado = Color(0xFFC9A05A);
const Color doradoClaro = Color(0xFFF3E6CC);

ThemeData temaSensorUv() {
  final esquema = ColorScheme.fromSeed(
    seedColor: azulMarino,
    primary: azulMarino,
    onPrimary: Colors.white,
    secondary: dorado,
    onSecondary: azulMarino,
    secondaryContainer: doradoClaro,
    onSecondaryContainer: azulMarino,
    tertiary: dorado,
    onTertiary: azulMarino,
    tertiaryContainer: doradoClaro,
    onTertiaryContainer: azulMarino,
  );
  return ThemeData(colorScheme: esquema, useMaterial3: true);
}
