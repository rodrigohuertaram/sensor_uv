// App Sensor UV: avisa cuando toca reaplicar bloqueador solar.
// Esta primera version funciona sin Bluetooth: el indice UV se simula con un control deslizante.

import 'package:flutter/material.dart';

import 'aviso_medico.dart';
import 'instalador.dart';
import 'modelo.dart';
import 'pantalla_inicio.dart';
import 'pantalla_perfil.dart';

// Anchos a partir de los cuales cambia el diseño
const double anchoTablet = 700;
const double anchoEscritorio = 1100;

void main() {
  runApp(const SensorUvApp());
}

class SensorUvApp extends StatelessWidget {
  const SensorUvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor UV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF7931E)),
        useMaterial3: true,
      ),
      home: const Principal(),
    );
  }
}

// Contenedor con la barra de navegacion inferior
class Principal extends StatefulWidget {
  const Principal({super.key});

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  int _pestana = 0;

  @override
  void initState() {
    super.initState();
    modelo.iniciar(); // empieza el reloj: una lectura por segundo
    // El aviso medico se muestra cada vez que se abre la app
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mostrarAvisoMedico(context, obligatorio: true),
    );
  }

  @override
  void dispose() {
    modelo.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenido = IndexedStack(
      index: _pestana,
      children: const [PantallaInicio(), PantallaPerfil()],
    );

    // Pantallas anchas (tablet o computadora): menu lateral en lugar de barra inferior
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho >= anchoTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: ancho >= anchoEscritorio,
              selectedIndex: _pestana,
              onDestinationSelected: (indice) =>
                  setState(() => _pestana = indice),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.wb_sunny,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: BotonInstalar(extendido: ancho >= anchoEscritorio),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.wb_sunny),
                  label: Text('Inicio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Mi perfil'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: contenido),
          ],
        ),
      );
    }

    return Scaffold(
      body: contenido,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (indice) => setState(() => _pestana = indice),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Mi perfil'),
        ],
      ),
    );
  }
}
