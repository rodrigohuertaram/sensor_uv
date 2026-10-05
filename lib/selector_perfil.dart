// Tarjeta para elegir, crear, renombrar y borrar perfiles guardados con su propio nombre.

import 'package:flutter/material.dart';

import 'modelo.dart';

class SelectorPerfil extends StatelessWidget {
  const SelectorPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    // Se redibuja solo al cambiar de perfil (es un widget const dentro de "Mi perfil")
    return ListenableBuilder(
      listenable: modelo,
      builder: (context, _) => _tarjeta(context),
    );
  }

  Widget _tarjeta(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Icon(Icons.account_circle, color: tema.colorScheme.primary),
            DropdownButton<String>(
              value: modelo.idActivo,
              underline: const SizedBox.shrink(),
              style: tema.textTheme.titleMedium,
              items: [
                for (final perfil in modelo.perfiles)
                  DropdownMenuItem(
                    value: perfil.id,
                    child: Text(perfil.nombre),
                  ),
              ],
              onChanged: (id) {
                if (id != null) modelo.elegirPerfil(id);
              },
            ),
            IconButton(
              tooltip: 'Nuevo perfil',
              icon: const Icon(Icons.person_add_alt),
              onPressed: () => _crear(context),
            ),
            IconButton(
              tooltip: 'Cambiar nombre',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _renombrar(context),
            ),
            IconButton(
              tooltip: 'Borrar perfil',
              icon: const Icon(Icons.delete_outline),
              // Siempre debe quedar al menos un perfil
              onPressed: modelo.perfiles.length > 1
                  ? () => _borrar(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crear(BuildContext context) async {
    final nombre = await _pedirNombre(
      context,
      titulo: 'Nuevo perfil',
      textoBoton: 'Crear',
    );
    if (nombre != null) modelo.crearPerfil(nombre);
  }

  Future<void> _renombrar(BuildContext context) async {
    final nombre = await _pedirNombre(
      context,
      titulo: 'Cambiar nombre',
      textoBoton: 'Guardar',
      inicial: modelo.perfilActivo.nombre,
      idIgnorado: modelo.idActivo,
    );
    if (nombre != null) modelo.renombrarPerfil(nombre);
  }

  Future<void> _borrar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar perfil'),
        content: Text(
          '¿Borrar el perfil «${modelo.perfilActivo.nombre}»? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar == true) modelo.eliminarPerfilActivo();
  }
}

// Ventana para escribir el nombre de un perfil; devuelve el nombre o null si se cancela
Future<String?> _pedirNombre(
  BuildContext context, {
  required String titulo,
  required String textoBoton,
  String inicial = '',
  String? idIgnorado,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DialogoNombre(
      titulo: titulo,
      textoBoton: textoBoton,
      inicial: inicial,
      idIgnorado: idIgnorado,
    ),
  );
}

class _DialogoNombre extends StatefulWidget {
  const _DialogoNombre({
    required this.titulo,
    required this.textoBoton,
    required this.inicial,
    required this.idIgnorado,
  });

  final String titulo;
  final String textoBoton;
  final String inicial;
  final String? idIgnorado;

  @override
  State<_DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<_DialogoNombre> {
  late final TextEditingController _texto = TextEditingController(
    text: widget.inicial,
  );
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _aceptar() {
    final error = modelo.validarNombre(
      _texto.text,
      idIgnorado: widget.idIgnorado,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _texto.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _texto,
        autofocus: true,
        maxLength: ModeloUV.largoMaximoNombre,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Nombre del perfil',
          hintText: 'Por ejemplo: Rodrigo, Mamá, Playa',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _aceptar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _aceptar, child: Text(widget.textoBoton)),
      ],
    );
  }
}
