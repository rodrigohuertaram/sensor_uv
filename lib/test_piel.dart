// Test de tipo de piel (escala de Fitzpatrick) con 6 preguntas cerradas.
// Las preguntas 1 (quemadura) y 2 (bronceado) son las principales: hechas por separado
// son las que mejor predicen el tipo de piel. Las 3 a 6 (color de piel, pecas, cabello
// y ojos) solo ajustan el resultado si se contesta "No sé" o si 1 y 2 no coinciden.
// Si el resultado queda entre dos tipos, se elige el mas claro (el aviso llega antes).

import 'package:flutter/material.dart';

import 'modelo.dart';
import 'tipos_piel.dart';

void abrirTestPiel(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const PantallaTestPiel()));
}

// ---------- Calculo del resultado ----------

enum Precision { alta, media, baja }

class ResultadoTest {
  const ResultadoTest(this.fototipo, this.precision);

  final int fototipo;
  final Precision precision;
}

// quemadura y bronceado: 1 a 6, o null si se contesto "No sé".
// colorPiel: 1 a 6. pecas: 1 a 3, o null si no tiene (no da informacion).
// cabello y ojos: 1 a 5.
ResultadoTest calcularFototipo({
  required int? quemadura,
  required int? bronceado,
  required int colorPiel,
  required int? pecas,
  required int cabello,
  required int ojos,
}) {
  // Promedio de las preguntas de apoyo; el color de piel cuenta doble
  var suma = colorPiel * 2.0 + cabello + ojos;
  var pesos = 4.0;
  if (pecas != null) {
    suma += pecas;
    pesos += 1;
  }
  final apoyo = suma / pesos;

  int tipo;
  Precision precision;
  if (quemadura != null && bronceado != null) {
    if ((quemadura - bronceado).abs() <= 1) {
      // Coinciden: se elige el mas claro de los dos
      tipo = quemadura < bronceado ? quemadura : bronceado;
      precision = Precision.alta;
    } else {
      // No coinciden: las preguntas de apoyo desempatan
      tipo = ((quemadura + bronceado + apoyo) / 3).floor();
      precision = Precision.media;
    }
  } else if (quemadura != null || bronceado != null) {
    final conocida = quemadura ?? bronceado!;
    tipo = ((conocida * 2 + apoyo) / 3).floor();
    precision = Precision.media;
  } else {
    tipo = apoyo.floor();
    precision = Precision.baja;
  }
  return ResultadoTest(tipo.clamp(1, 6), precision);
}

// ---------- Preguntas ----------

class _Opcion {
  const _Opcion(this.texto, this.valor, {this.color});

  final String texto;
  final int? valor; // null = "No sé" o sin informacion
  final Color? color;
}

class _Pregunta {
  const _Pregunta(this.titulo, this.opciones, {this.detalle});

  final String titulo;
  final String? detalle;
  final List<_Opcion> opciones;
}

final List<_Pregunta> _preguntas = [
  const _Pregunta(
    '¿Qué le pasa a tu piel?',
    detalle:
        'Imagina que al inicio del verano estás al sol del mediodía unos '
        '30 a 60 minutos, sin protector.',
    [
      _Opcion(
        'Me quemo siempre: se pone muy roja, me duele y a veces se ampolla o se pela',
        1,
      ),
      _Opcion('Me quemo casi siempre: se pone roja y me arde', 2),
      _Opcion(
        'A veces me quemo un poco: se pone rosada pero no me duele mucho',
        3,
      ),
      _Opcion('Rara vez me quemo: apenas se enrojece', 4),
      _Opcion('Casi nunca me quemo', 5),
      _Opcion('Nunca me he quemado', 6),
      _Opcion('No sé (siempre uso protector o casi no me da el sol)', null),
    ],
  ),
  const _Pregunta(
    '¿Cómo cambia el color de tu piel?',
    detalle: 'Si estás al sol varios días seguidos.',
    [
      _Opcion('No me bronceo nada: me quedo blanco o solo me pongo rojo', 1),
      _Opcion('Me bronceo muy poco, apenas un tono más', 2),
      _Opcion('Me bronceo poco a poco y de forma pareja', 3),
      _Opcion('Me bronceo fácil y quedo moreno', 4),
      _Opcion('Me bronceo muy fácil y quedo moreno oscuro', 5),
      _Opcion('Mi piel ya es muy oscura y casi no cambia de color', 6),
      _Opcion('No sé', null),
    ],
  ),
  _Pregunta(
    '¿De qué color es tu piel donde casi no le da el sol?',
    detalle: 'Por ejemplo, la parte interna del brazo.',
    [
      for (final tipo in tiposPiel)
        _Opcion(tipo.nombre, tipo.numero, color: tipo.color),
    ],
  ),
  const _Pregunta('¿Tienes pecas en la cara, los hombros o los brazos?', [
    _Opcion('Muchas', 1),
    _Opcion('Varias', 2),
    _Opcion('Pocas', 3),
    _Opcion('Ninguna', null),
  ]),
  const _Pregunta('¿Cuál es tu color de cabello natural?', [
    _Opcion('Pelirrojo', 1),
    _Opcion('Rubio', 2),
    _Opcion('Castaño claro', 3),
    _Opcion('Castaño oscuro', 4),
    _Opcion('Negro', 5),
  ]),
  const _Pregunta('¿De qué color son tus ojos?', [
    _Opcion('Azul, gris o verde claro', 1),
    _Opcion('Azul, gris o verde', 2),
    _Opcion('Miel o café claro', 3),
    _Opcion('Café oscuro', 4),
    _Opcion('Negro o café muy oscuro', 5),
  ]),
];

// ---------- Pantalla ----------

class PantallaTestPiel extends StatefulWidget {
  const PantallaTestPiel({super.key});

  @override
  State<PantallaTestPiel> createState() => _PantallaTestPielState();
}

class _PantallaTestPielState extends State<PantallaTestPiel> {
  // Indice de la opcion elegida en cada pregunta (null = sin contestar)
  final List<int?> _respuestas = List.filled(_preguntas.length, null);
  String? _error;

  int? _valor(int pregunta) =>
      _preguntas[pregunta].opciones[_respuestas[pregunta]!].valor;

  void _verResultado() {
    final faltante = _respuestas.indexWhere((r) => r == null);
    if (faltante != -1) {
      setState(() => _error = 'Te falta contestar la pregunta ${faltante + 1}');
      return;
    }
    final resultado = calcularFototipo(
      quemadura: _valor(0),
      bronceado: _valor(1),
      colorPiel: _valor(2)!,
      pecas: _valor(3),
      cabello: _valor(4)!,
      ojos: _valor(5)!,
    );
    _mostrarResultado(resultado);
  }

  Future<void> _mostrarResultado(ResultadoTest resultado) async {
    final tipo = tipoPiel(resultado.fototipo);
    final nota = switch (resultado.precision) {
      Precision.alta => 'Tus respuestas sobre quemadura y bronceado coinciden.',
      Precision.media =>
        'Algunas respuestas no coinciden o contestaste «No sé», '
            'así que el resultado es menos exacto.',
      Precision.baja =>
        'Contestaste «No sé» en las preguntas principales, así que el '
            'resultado es solo una aproximación.',
    };
    final usar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu tipo de piel'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 32, backgroundColor: tipo.color),
              const SizedBox(height: 12),
              Text(
                'Tipo ${tipo.numero} — ${tipo.nombre}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(tipo.descripcion, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(nota, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                'Es una estimación. Un dermatólogo puede confirmarte '
                'cuál es tu tipo de piel.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Revisar respuestas'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usar este tipo'),
          ),
        ],
      ),
    );
    if (usar != true || !mounted) return;
    modelo.cambiarFototipo(resultado.fototipo);
    final mensajero = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          'Se guardó el tipo ${tipo.numero} en el perfil '
          '«${modelo.perfilActivo.nombre}»',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Test de tipo de piel')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Contesta pensando en tu piel sin protector. Las dos primeras '
                  'preguntas son las más importantes; si no sabes la respuesta, '
                  'elige «No sé» y las demás preguntas ayudarán.',
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _preguntas.length; i++) _tarjeta(i, tema),
                const SizedBox(height: 8),
                // Aviso de privacidad: las respuestas no se guardan ni se envian
                Card(
                  color: tema.colorScheme.tertiaryContainer,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tus respuestas son privadas y no se comparten con '
                            'nadie. Se usan única y exclusivamente para calcular '
                            'tu tipo de piel, en este dispositivo. Si eliges '
                            '«Usar este tipo», solo se guarda el resultado en tu '
                            'perfil, también en este dispositivo.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: tema.colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Ver mi resultado'),
                  ),
                  onPressed: _verResultado,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(int i, ThemeData tema) {
    final pregunta = _preguntas[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${i + 1}. ${pregunta.titulo}',
                style: tema.textTheme.titleMedium,
              ),
            ),
            if (pregunta.detalle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(pregunta.detalle!, style: tema.textTheme.bodySmall),
              ),
            const SizedBox(height: 4),
            for (var j = 0; j < pregunta.opciones.length; j++)
              _opcion(i, j, tema),
          ],
        ),
      ),
    );
  }

  Widget _opcion(int i, int j, ThemeData tema) {
    final opcion = _preguntas[i].opciones[j];
    final elegida = _respuestas[i] == j;
    return ListTile(
      dense: true,
      selected: elegida,
      leading: Icon(
        elegida ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: elegida ? tema.colorScheme.primary : null,
      ),
      title: Text(opcion.texto),
      trailing: opcion.color == null
          ? null
          : CircleAvatar(radius: 14, backgroundColor: opcion.color),
      onTap: () => setState(() {
        _respuestas[i] = j;
        _error = null;
      }),
    );
  }
}
