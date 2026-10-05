// Los 6 tipos de piel de la escala de Fitzpatrick, con un color de referencia para cada uno.
// Se usan en "Mi perfil" y en el test de tipo de piel.

import 'package:flutter/material.dart';

class TipoPiel {
  const TipoPiel(this.numero, this.nombre, this.descripcion, this.color);

  final int numero;
  final String nombre;
  final String descripcion;
  final Color color;
}

const List<TipoPiel> tiposPiel = [
  TipoPiel(
    1,
    'Muy clara',
    'Siempre se quema, nunca se broncea',
    Color(0xFFF6DCC0),
  ),
  TipoPiel(2, 'Clara', 'Se quema fácil, se broncea poco', Color(0xFFE8BD92)),
  TipoPiel(
    3,
    'Media',
    'A veces se quema, se broncea poco a poco',
    Color(0xFFCF9A6B),
  ),
  TipoPiel(
    4,
    'Morena clara',
    'Rara vez se quema, se broncea fácil',
    Color(0xFFA86F43),
  ),
  TipoPiel(5, 'Morena', 'Muy rara vez se quema', Color(0xFF7A4A27)),
  TipoPiel(6, 'Muy oscura', 'Casi nunca se quema', Color(0xFF4A2A14)),
];

TipoPiel tipoPiel(int numero) => tiposPiel[numero - 1];
