// App Sensor UV: avisa cuando toca reaplicar bloqueador solar.
// Esta primera version funciona sin Bluetooth: el indice UV se simula con un control deslizante.

import 'package:flutter/material.dart';

import 'aviso_medico.dart';
import 'instalador.dart';
import 'modelo.dart';
import 'pantalla_inicio.dart';
import 'pantalla_perfil.dart';
import 'tema.dart';

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
      theme: temaSensorUv(),
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
      final extendido = ancho >= anchoEscritorio;
      // Ancho del menu: angosto (solo iconos) o extendido (iconos y textos)
      final anchoMenu = extendido ? 256.0 : 80.0;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: extendido,
              minExtendedWidth: anchoMenu,
              selectedIndex: _pestana,
              onDestinationSelected: (indice) =>
                  setState(() => _pestana = indice),
              // Logo y boton de instalar alineados a la izquierda, con los iconos del menu
              leading: SizedBox(
                width: anchoMenu,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/logo.png',
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
              ),
              trailing: Expanded(
                child: SizedBox(
                  width: anchoMenu,
                  child: Align(
                    alignment: extendido
                        ? Alignment.bottomLeft
                        : Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: BotonInstalar(extendido: extendido),
                    ),
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
