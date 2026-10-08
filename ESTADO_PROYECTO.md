# Estado del proyecto — Sensor UV

Última actualización: 2026-10-07

Documento para retomar el proyecto sin perder contexto. El registro detallado de cambios está en `HISTORIAL.md`; lo que necesita la futura app nativa de Android está en `PENDIENTES_ANDROID.md`.

---

## 1. Objetivo del proyecto

**Sensor UV** es un proyecto universitario (Ibero Puebla, equipo "DreamTeam") que avisa **cuándo volver a aplicar bloqueador solar**. Tiene dos partes:

1. **App** (Flutter, publicada como app web instalable): calcula la dosis de sol que recibe la piel según el índice UV, el tipo de piel (Fitzpatrick I–VI), el FPS del bloqueador, si hay sudor o agua, la resistencia al agua del envase y el lugar (reflejo del suelo). Avisa con una pantalla de alerta.
2. **Dispositivo físico** (por construir): una placa **Seeed Studio XIAO ESP32C3** con sensor **LTR390** que mide el UV real, pantalla **OLED 0.96"**, **buzzer** y **botón**. Se conectará a la app por **Bluetooth de bajo consumo (BLE)**.

**Diferenciadores:** funciona en Android **y** iPhone, **gratis** para el usuario, y el dispositivo avisa por su cuenta aunque el celular no esté.

- App publicada: https://rodrigohuertaram.github.io/sensor_uv/
- Repositorio: https://github.com/rodrigohuertaram/sensor_uv (público, rama `main`)
- Proyecto local: `C:\Innovacion_Frugal\App\sensor_uv`
- Flutter SDK: `C:\Innovacion_Frugal\dev\flutter` (Flutter 3.47.6, Dart 3.13.5)
- Jira: https://iberopuebla-dreamteam-01234.atlassian.net — proyecto **DreamTeam ÑAÑAÑA**, clave **DT**, tablero id `4` ("DreamTeam ÑAÑAÑA A"), filtro id `10003`, cloudId `509e6de4-132d-442f-97e4-c76397b932cb`.

---

## 2. Estado actual

### Funciona (publicado y probado en localhost)
- Cálculo de reaplicación con simulador de UV (control deslizante 0–13) y velocidad de prueba (Real / x60 / x600).
- Diseño adaptable: barra inferior en celular (< 700 px), menú lateral en tablet/computadora (≥ 700 px; extendido ≥ 1100 px), dos columnas cuando el contenido mide ≥ 820 px.
- App instalable (PWA): botón "Instalar app", manifiesto, service worker (funciona sin internet), pantalla de carga.
- Aviso médico obligatorio en **cada** apertura + botón "Aviso médico" en inicio + nota junto al tipo de piel.
- Logo (escudo blanco con sol dorado sobre azul marino) y paleta azul marino/dorado.
- Burbuja "?" con ilustración de bloqueador genérico (FPS y resistencia al agua).
- Perfiles con nombre guardados en `localStorage` (crear, renombrar, borrar, elegir).
- Test de tipo de piel de 6 preguntas con aviso de privacidad.
- Lugar (ciudad, parque, alberca/lago, playa, nieve) que ajusta el cálculo; cielo manual para el simulador.
- Clima y UV real de la zona con ubicación (Open-Meteo); opción "Usar el índice UV de tu zona" que se recuerda y se actualiza cada 15 min; opción "Mantener la pantalla encendida" (Wake Lock).
- Publicación automática en GitHub Pages con cada `git push`.
- 12 pruebas automáticas (`flutter test`), todas pasan.

### A medias
- **Dispositivo físico:** componentes de AliExpress pedidos el 2026-10-06 (llegan 10–25 oct); pedido de UNIT pendiente. **No hay programa (firmware) todavía.**
- **Conexión Bluetooth app ↔ dispositivo:** diseñada (ver sección 4) pero sin programar.
- **App nativa de Android:** no iniciada; lo que necesita está en `PENDIENTES_ANDROID.md`.
- **Jira:** epics DT-1 y DT-2 con cronograma; DT-3, DT-4 y DT-6 cerradas como "(no usar)"; faltan epics del dispositivo, armado, carcasa y pruebas.

### Falla / limitaciones conocidas
- **En segundo plano o con la pantalla apagada, Chrome congela la app web:** no se actualiza el clima ni corre el reloj. Solución parcial: al volver se cuenta el tiempo real transcurrido y se actualiza el clima. Solución real: app nativa.
- **Ubicación, guardado de perfiles y Wake Lock solo funcionan en web.** En Android nativo, los archivos `*_stub.dart` no guardan nada (`almacen_stub.dart` es memoria temporal; `ubicacion_stub.dart` lanza `ErrorUbicacion`).
- **El icono de la app ya instalada en Android tarda hasta ~1 día en actualizarse** (Chrome revisa el manifiesto una vez al día al abrir la app). En iPhone hay que reinstalar.
- **Perfiles por dispositivo:** no se sincronizan entre celular y computadora, ni entre navegadores.
- En el navegador de pruebas de Claude (panel), los toques en **modo celular** no llegan a Flutter; las interacciones se prueban en tamaño computadora.

---

## 3. Estructura

### `lib/` (código de la app)
| Archivo | Qué hace |
|---|---|
| `main.dart` | Arranque: `main()` llama `modelo.cargarPerfiles()` y `runApp(SensorUvApp)`. `Principal` (estado `_PrincipalState`): navegación (`NavigationBar` en celular / `NavigationRail` con logo y `BotonInstalar` en pantallas anchas), `modelo.iniciar()`, `AppLifecycleListener(onResume: modelo.alVolverALaApp)`, y tras el primer cuadro `mostrarAvisoMedico(context, obligatorio: true)` + `modelo.restaurarPreferencias()`. Constantes `anchoTablet = 700`, `anchoEscritorio = 1100`. |
| `modelo.dart` | Lógica central (`ModeloUV extends ChangeNotifier`, instancia global `modelo`). Clase `Perfil` (id, nombre, fototipo, fps, resistenciaAguaMin, `aJson`/`desdeJson`). Enums `Entorno`, `Cielo`, `FuenteUV`. Cálculo, reloj, perfiles, clima. Ver detalles abajo. |
| `pantalla_inicio.dart` | Pantalla de inicio (`PantallaInicio`): `_encabezado`, `_tarjetaUV`, `_anillo`, `_botonReaplicar`, `_resumen`, `_simulador`, layouts `_unaColumna`/`_dosColumnas`; `colorNivel(uvi)`; `AlertaReaplicar` (fondo azul marino, sol dorado que late). |
| `pantalla_perfil.dart` | "Mi perfil": `SelectorPerfil`, tipos de piel, botón "¿No sabes cuál es? Haz el test", FPS (15/30/50/70/100) con `BotonAyudaFps`, sudor o agua, resistencia (0/40/80), "Con estos datos, en: <lugar>", velocidad de prueba. |
| `selector_perfil.dart` | `SelectorPerfil` (desplegable + crear/renombrar/borrar) y `_DialogoNombre` con validación. |
| `test_piel.dart` | `abrirTestPiel(context)`, `PantallaTestPiel`, `calcularFototipo(...)` → `ResultadoTest(fototipo, Precision.alta/media/baja)`, preguntas `_preguntas`, aviso de privacidad. |
| `tipos_piel.dart` | `TipoPiel` y `tiposPiel` (6 tipos con colores), `tipoPiel(numero)`. |
| `ayuda_fps.dart` | `BotonAyudaFps`, `mostrarAyudaFps`, `IlustracionBloqueador` (bloqueador genérico "FPS 50+"). |
| `aviso_medico.dart` | `mostrarAvisoMedico(context, {obligatorio})`, textos `textoEstadistico` y `textoConsulta`, `NotaTipoPiel`. |
| `lugar_clima.dart` | `TarjetaLugarClima`: lugar, clima de tu zona, interruptores "Usar el índice UV de tu zona" y "Mantener la pantalla encendida", cielo manual, nota de privacidad. |
| `clima.dart` | `DatosClima` y `consultarClima(lat, lon)` → Open-Meteo (`api.open-meteo.com/v1/forecast`, `current=temperature_2m,apparent_temperature,uv_index,cloud_cover,weather_code`, `daily=uv_index_max`, coordenadas redondeadas a 2 decimales). Códigos OMM → descripción e icono. |
| `tema.dart` | `azulMarino = 0xFF122746`, `dorado = 0xFFC9A05A`, `doradoClaro = 0xFFF3E6CC`, `temaSensorUv()` (ColorScheme con primary azul marino; secondary y tertiary dorado). |
| `instalador.dart` (+ `_stub`, `_web`) | `Instalador`, `instalador`, `BotonInstalar`; en web usa `sensorUvPuedeInstalar`, `sensorUvInstalar`, `sensorUvEsIOS`, `sensorUvInstalada`, `sensorUvAlCambiar` de `index.html`. |
| `almacen.dart` (+ `_stub`, `_web`) | `leerDato(clave)` / `guardarDato(clave, valor)`; en web, `localStorage` con prefijo `sensorUv.` vía `sensorUvLeer`/`sensorUvGuardar`. |
| `ubicacion.dart` (+ `_stub`, `_web`) | `obtenerUbicacion()` → `(latitud, longitud)`; `ErrorUbicacion(mensaje)`. Web usa `sensorUvUbicacion` (rechaza con `sin-soporte`, `permiso`, `no-disponible`, `tiempo`). |
| `pantalla.dart` (+ `_stub`, `_web`) | `puedeMantenerPantalla()`, `mantenerPantallaEncendida(bool)` (Wake Lock vía `sensorUvPuedeMantenerPantalla` / `sensorUvPantallaEncendida`). |

### Detalles de `modelo.dart`
- Cálculo (igual al que tendrá el dispositivo): `dem = [0, 200, 250, 350, 450, 600, 1000]` J/m² por fototipo; `factorAplicacion = 0.3`; `margenSeguridad = 0.6`; `limiteDosis = dem[fototipo] * fps * 0.3 * 0.6`; `topeNormalMin = 120`; con sudor/agua el tope es 80 min si `resistenciaAguaMin >= 80`, si no 40 min. Dosis: `dosis += 0.025 * uvEfectivo * dt` (1 punto de índice UV = 0.025 W/m²); solo acumula si `uvEfectivo >= 1`.
- `uvEfectivo = uvi * (fuente == simulador ? cielo.factor : 1.0) * entorno.factor`.
- `Entorno`: ciudad 1.0, parque 1.0, agua 1.1, playa 1.25, nieve 1.8. `Cielo`: despejado 1.0, algoNublado 1.0, nublado 0.8, lluvia 0.5.
- Reloj: `iniciar()` usa `Timer.periodic(1 s)` midiendo el tiempo real con `_ultimaLectura`; `_lectura()` limita `dt` a `topeTiempoS`.
- Perfiles: `cargarPerfiles`, `_guardarPerfiles`, `elegirPerfil` (reinicia la cuenta), `crearPerfil` (copia datos del activo), `renombrarPerfil`, `eliminarPerfilActivo` (deja al menos uno), `validarNombre` (vacío, > 30, repetido). Claves: `perfiles`, `perfilActivo`.
- Clima: `actualizarClima()`, `usarUvDeZona(bool)` (clave `usarUvDeZona`, `cadaCuantoClima = 15 min`), `cambiarPantallaEncendida(bool)` (clave `pantallaEncendida`), `restaurarPreferencias()`, `alVolverALaApp()`, `_cieloSegun` (lluvia o nubosidad ≥ 90 → lluvia; ≥ 60 → nublado; ≥ 25 → algo nublado).

### `web/`
| Archivo | Qué hace |
|---|---|
| `index.html` | Metas (theme-color `#122746`), pantalla de carga `#carga` azul marino, funciones JS `sensorUv*` (instalación, `localStorage`, ubicación, Wake Lock) y registro de `sw.js`. Iconos con `?v=2`. |
| `manifest.json` | Nombre "Sensor UV", colores `#122746`, iconos `icons/Icon-*.png?v=2` (normales y maskable). Sin campo `id` (a propósito, por la subcarpeta de GitHub Pages). |
| `sw.js` | Service worker "primero la red"; caché `sensor-uv-v2` (cambiar el número borra la copia vieja). |
| `flutter_bootstrap.js` | Carga Flutter **sin** el service worker de Flutter (se usa el propio). |
| `icons/`, `favicon.png` | Generados desde `diseno/logo-1024.png`. |

### Otros
| Ruta | Qué es |
|---|---|
| `assets/logo.png` | Logo dentro de la app (declarado en `pubspec.yaml`). |
| `diseno/logo-original.png`, `diseno/logo-1024.png` | Logo original de Nano Banana y versión sin marca de agua. |
| `test/test_piel_test.dart` (6), `test/modelo_test.dart` (5), `test/widget_test.dart` (1) | Pruebas automáticas. |
| `.github/workflows/publicar-web.yml` | GitHub Actions "Publicar app web": Flutter 3.47.6 → `flutter analyze` → `flutter build web --release --base-href "/sensor_uv/"` → GitHub Pages. |
| `HISTORIAL.md` | Historial por secciones (1 Investigación, 2 Entorno, 3 App, 4 Publicación y documentación, 5 Dispositivo físico, 6 Mejoras a futuro, 7 Jira). |
| `PENDIENTES_ANDROID.md` | Lo que la app nativa de Android debe hacer distinto a la web. |
| `pubspec.yaml` | Dependencias: `cupertino_icons`, `http: ^1.6.0`. **Ningún plugin nativo** (ver decisión sobre Modo de programador). |
| `.claude/launch.json` | Servidor de prueba "sensor-uv-web" (ignorado en git). |

---

## 4. Decisiones clave (y lo descartado)

### App
- **App web instalable (PWA) primero**, publicada gratis en GitHub Pages: se instala en Android desde Chrome sin tienda de apps. La app instalada desde Chrome **es** la página web y se actualiza sola.
- **Sin plugins nativos por ahora:** `flutter pub add shared_preferences` falló porque los plugins en Windows requieren "Modo de programador" (symlinks), que es una configuración del sistema que el usuario debe activar. Se usa `localStorage` con `dart:js_interop` y funciones en `index.html`. Para Android nativo se compilará en GitHub Actions.
- **Service worker propio** (`sw.js`, primero la red) en lugar del de Flutter.
- **Aviso médico en cada apertura** (al principio era solo la primera vez; el usuario lo pidió así).
- **Test de piel:** prioriza precisión sobre brevedad. Preguntas 1 (quemadura) y 2 (bronceado) son principales y deciden; 3–6 (color de piel, pecas, cabello, ojos) solo ajustan si hay «No sé» o si 1 y 2 difieren por 2 o más. Entre dos tipos se elige el más claro. Respuestas cerradas y descriptivas (no "mucho/poco"). Base: PubMed 29882998.
- **Ilustración propia del bloqueador** en lugar de una foto de un producto real (derechos de autor y marcas).
- **Factores de lugar y nubes de la Guía del Índice UV de la OMS**, con criterio conservador ("Algo nublado" no reduce nada).
- **Ubicación redondeada a ~1 km**, no se guarda; solo se consulta Open-Meteo. Se descartó mostrar el nombre de la ciudad porque requeriría enviar la ubicación a un segundo servicio.
- **"Mantener la pantalla encendida" opcional** (gasta batería); actualizar en segundo plano es imposible en web.
- **Logo en `?v=2`** para forzar a Chrome a actualizar el icono instalado.
- **Paleta azul marino/dorado** tomada del logo; la escala de colores del índice UV (verde → morado) no se cambia por ser estándar.

### Dispositivo
- **Placa: Seeed Studio XIAO ESP32C3** (AliExpress, producto 1005006979844970, con antena). Razones: pequeña, BLE, carga batería LiPo a 380 mA, barata. La antena externa debe estar siempre conectada.
- **Descartadas:** ESP32-C3 SuperMini (no carga batería, antena débil), XIAO ESP32S3 (carga a 50 mA, gasta más), FireBeetle 2 ESP32-C6 (61.2 × 25.4 mm, demasiado grande, aunque tiene entrada solar), ESP32 DevKit (WROOM-32) y ESP32-C6 DevKit (sin cargador, grandes; sirven solo para pruebas en mesa). La XIAO ESP32C6 sería alternativa válida.
- **Sensor: LTR390** (digital, I2C) en lugar de **GUVA-S12SD** (analógico, ruidoso con el ADC de la ESP32-C3).
- **Pantalla: OLED 0.96" 128×64 I2C SSD1306, 4 pines, blanca** (Estardyn, AliExpress). Se lee mal al sol; se compensa con sonido.
- **Buzzer: Módulo Zumbador Pasivo 80 dB – UNIT DevLab** (trae transistor; VCC/Signal/GND; 3.3–5.5 V). Descartados: KY-006 (sin transistor, suena bajo) y buzzer activo (un solo tono).
- **Batería: LiPo 3.7 V 1500 mAh 103050** (UNIT, con protección, conector JST PH 2 mm). Se descartó 400 mAh como final (dura ~8 h; la carga de 380 mA queda justa). Baterías < 400 mAh no se deben usar con la XIAO C3.
- **Interruptor:** Interruptor Deslizable SPDT ON/OFF de UNIT (19.6 × 5.8 mm, agujeros de 2.5 mm). **Botón:** el usuario tiene pulsadores de 2 patas (sirven).
- **Sin PCB para el prototipo:** módulos y cables; carcasa impresa en **PLA** con el sensor arriba y ventana abierta o de **PTFE** (el PLA bloquea el UV).
- **Arquitectura propuesta "placa = cerebro" (opción A, pendiente de confirmar):** la placa mide, calcula (mismas constantes que `modelo.dart`), guarda el perfil y avisa con buzzer y OLED aunque el celular no esté; la app envía tipo de piel, FPS, resistencia, sudor/agua y lugar, muestra el estado y tiene el botón "Ya me reapliqué" sincronizado. Se descartó "app = cerebro" porque si la app está congelada o el celular lejos no habría aviso, y no funcionaría gratis en iPhone. Canales BLE previstos: **Configuración** (app → placa), **Estado** (placa → app, cada segundo: UV, avance, minutos restantes, toca reaplicar, batería) y **Órdenes** (ambos sentidos: "ya me reapliqué", "silenciar"). Con el sensor real, la placa aplica el factor de lugar (el sensor no mide el reflejo del suelo) pero no el de nubes.
- **iPhone gratis:** app web dentro del navegador Bluefy (Web Bluetooth). App nativa de iPhone requiere 99 USD/año; queda como mejora a futuro.

### Jira
- No se borran tareas (borrado permanente y sin permiso "Eliminar actividades"); se cierran con "(no usar)". Mi conexión no permite archivar.
- Fechas: `duedate` = vencimiento; `customfield_10015` = "Fecha de inicio" (en JQL: `cf[10015]`).

---

## 5. Reglas e instrucciones de trabajo del usuario

1. **Contestar siempre en español.**
2. **Mostrar siempre los avances corriendo en localhost** (servidor "sensor-uv-web") y probar en tamaño computadora y celular.
3. **Anotar cada cambio en `HISTORIAL.md` solo con la fecha (nunca la hora)**, por sección (orden: Investigación, Entorno, App, Publicación y documentación, Dispositivo físico, Mejoras a futuro, **Jira al final**); dentro de cada sección, de lo más antiguo a lo más nuevo; títulos "### Título — AAAA-MM-DD". Incluir también lo que no es código (Jira, compras, decisiones).
4. **Subir cada cambio a GitHub** (`git push`), lo que publica la app solo. El usuario aceptó que esto haga más lentas las respuestas.
5. **Mantener actualizado `PENDIENTES_ANDROID.md`** con todo lo que funciona gracias al navegador y la app nativa deberá hacer distinto.
6. **No agregar al historial la lista de compras** (el usuario lo pidió explícitamente).
7. **No agregar tareas a Jira sin que lo pida** (en la epic "App" dijo "NO LE VAYAS A AGREGAR ALGUNA TAREA AÚN" antes de pedir el cronograma). Mostrar el plan antes de cambios grandes.
8. **Ir paso a paso** y explicar en lenguaje sencillo; el usuario no quiere complicarse con la electrónica.
9. **Priorizar soluciones gratuitas** (diferenciador del proyecto) y que funcione en Android e iPhone.
10. En el test de piel, **la precisión importa más que la brevedad**.
11. Los mensajes de privacidad deben decir **exactamente** lo que hace la app.
12. Autor de los commits en este repo: `Rodrigo Huerta <337875389+RodrigoHuertaram@users.noreply.github.com>` (configurado solo en este repo; el global es `199722@iberopuebla.mx`). Commits terminan con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

---

## 6. Cómo correr y probar

Desde `C:\Innovacion_Frugal\App\sensor_uv` (Flutter ya está en el PATH del usuario; si no: `$env:Path="C:\Innovacion_Frugal\dev\flutter\bin;$env:Path"`):

```
flutter analyze                 # debe decir "No issues found!"
flutter test                    # 12 pruebas, "All tests passed!"
flutter build web --release     # genera build/web
python -m http.server 8080 --bind 127.0.0.1 --directory build/web   # http://localhost:8080
```

- En Claude, el servidor se inicia con la configuración **"sensor-uv-web"** de `.claude/launch.json` (puerto 8080).
- Al abrir aparece el aviso médico: hay que tocar "Entendido".
- **Probar la ubicación sin compartir la real:** en la consola del navegador, después de cargar: `window.sensorUvUbicacion = () => Promise.resolve('19.04,-98.21')` (centro de Puebla).
- **Forzar la alerta:** "Mi perfil" → velocidad **x600** → simulador UV en 13 → esperar ~10–15 s.
- **Limpiar datos de prueba:** `localStorage.clear()`.
- **Publicar:** `git add -A`, `git commit`, `git push` → GitHub Actions "Publicar app web" (3–5 min). Comprobar en https://rodrigohuertaram.github.io/sensor_uv/.
- **Mensajes de commit largos en PowerShell:** escribir el mensaje en un archivo y usar `git commit -F .git\MSG_TMP` (ver bugs).

---

## 7. Bugs difíciles ya resueltos

| Problema | Causa | Solución |
|---|---|---|
| El selector de perfiles no se actualizaba al crear un perfil | `const SelectorPerfil()` dentro de un `ListenableBuilder`: Flutter no reconstruye un widget `const` idéntico | El propio widget envuelve su contenido en `ListenableBuilder(listenable: modelo)`. Mismo arreglo en `TarjetaLugarClima`. |
| `flutter pub add shared_preferences` → "Building with plugins requires symlink support" | Los plugins en Windows requieren Modo de programador | Se quitó el paquete; almacenamiento con `localStorage` (`almacen_web.dart` + `sensorUvLeer/Guardar`). |
| La nota del tipo de piel salía rosa | `tertiaryContainer` generado por la semilla azul marino | En `temaSensorUv()` se fijaron `tertiary`/`tertiaryContainer` en dorado. |
| Título "Sensor UV" partido en dos renglones en celular | Logo + chip + botón de instalar en el mismo renglón | `titleLarge`, `maxLines: 1`, `softWrap: false`, y el chip sin icono en celular. |
| Logo centrado en el menú lateral extendido | `NavigationRail` centra `leading` | `SizedBox(width: anchoMenu)` + `Align(centerLeft)` + padding 16; `minExtendedWidth = 256`. |
| El icono de la app instalada en Android seguía siendo el viejo | Chrome actualiza el icono de PWAs instaladas como máximo una vez al día | Iconos con `?v=2` en `manifest.json`/`index.html` y caché `sensor-uv-v2` en `sw.js`; o reinstalar. |
| `Slider` podía fallar con UV real > 13 | El valor debe estar entre `min` y `max` | `value: modelo.uvi.clamp(0, 13)`. |
| La cuenta de sol se detenía con la app en segundo plano | Chrome congela los temporizadores | `iniciar()` mide el tiempo real con `_ultimaLectura`; `_lectura` limita `dt` a `topeTiempoS`. |
| Marca de agua de Gemini en el logo | Imagen generada por IA | Se tapó copiando un parche del fondo (script en el scratchpad); el original queda en `diseno/`. |
| `git push` desde la terminal de Claude: "Invalid username or token" | Git Credential Manager necesita una ventana para iniciar sesión | El usuario hizo el primer `git push` en su terminal; desde entonces queda la sesión guardada. |
| Repositorio creado como `sensor_uv.` (con punto) | Error al crearlo | Se renombró a `sensor_uv`; el remoto es `https://github.com/rodrigohuertaram/sensor_uv.git`. |
| `git commit -m @'...'@` partía el mensaje en argumentos | Comillas dentro del here-string en PowerShell | Escribir el mensaje en archivo y `git commit -F .git\MSG_TMP` (rutas del scratchpad son demasiado largas para Git). |
| Un script de PowerShell con código Dart fue bloqueado ("Remove-Item on system path '//'") | El texto `//` de los comentarios Dart se interpretó como ruta | Escribir archivos con la herramienta Write, no con PowerShell. |
| En el panel de pruebas, los toques en modo celular no llegaban | Emulación táctil del panel con Flutter | Probar interacciones en tamaño computadora; en modo celular solo revisar el diseño. |
| Capturas del panel "con zoom" y clics fuera de lugar | Escala 1.25 del panel | Dividir las coordenadas de la imagen entre 1.25, o usar 1200 × 700 justo después de navegar. |
| Jira: "No podemos eliminar estas actividades" | El esquema de permisos no concede "Eliminar actividades" | Se cerraron como "(no usar)"; el usuario recibió el rol "Administrador de aplicaciones" en Jira Administration, pero decidió no seguir. |

---

## 8. Pendientes (en orden) y dónde estábamos

### Dónde estábamos (2026-10-07)
Se agregó la sección **"6. Mejoras a futuro"** al `HISTORIAL.md` (iPhone, carga solar, ahorro de batería, nivel de batería, calibración, vibración, carcasa PETG/ASA, actualización sin cable, historial de exposición, consejos según UV, mejoras de la app, PCB). Antes se armó en Jira el cronograma de la epic **DT-2 "App"** (DT-9 a DT-19 con subtareas DT-20 a DT-52, del 2 oct al 1 nov) y se ajustó la epic **DT-1** (2–24 oct) con DT-7, DT-8 y DT-5 "Probar componentes" (21–24 oct). Luego se pidió este documento.

### Pendientes
1. **Usuario: confirmar la arquitectura "placa = cerebro" (opción A).** Bloquea el programa de la placa.
2. **Usuario: pedir en UNIT Electronics** (Jira DT-8, vence 2026-10-20): 2 × Módulo Zumbador Pasivo 80 dB – UNIT DevLab, 2 × Interruptor Deslizable SPDT ON/OFF, 1 × Batería LiPo 3.7V 1500mAh 103050.
3. **Programa de la placa (firmware, Arduino IDE 2):** LTR390 + cálculo (mismas constantes que `modelo.dart` + factor de lugar) + OLED + buzzer (melodías cortas) + botón + BLE con canales Configuración/Estado/Órdenes + perfil guardado en memoria. Debe funcionar en **XIAO ESP32C3** (objetivo) y **ESP32-C6 DevKit** (pruebas en mesa; el usuario la tiene). Incluir de inicio: ahorro de batería y nivel de batería si se aprueban.
4. **Diagrama de conexiones** (XIAO ESP32C3 y ESP32-C6 DevKit; I2C para LTR390 y OLED; batería a BAT+/BAT− bajo la XIAO; interruptor en la línea de la batería).
5. **Guía de Arduino IDE 2:** soporte de placas ESP32 de Espressif y librerías (sensor LTR390, pantalla SSD1306, BLE).
6. **App: botón "Conectar dispositivo"** con Web Bluetooth (Chrome en Android y computadora; iPhone vía Bluefy). Con el dispositivo conectado, la app muestra lo que manda la placa en lugar de calcular por su cuenta.
7. **Probar componentes** cuando lleguen (Jira DT-5, 21–24 oct).
8. **Jira:** proponer y crear (con aprobación) las epics restantes reutilizando DT-3, DT-4 y DT-6 (Programa del dispositivo, Armado y conexiones, Carcasa) y una nueva "Pruebas y presentación". Confirmar si DT-7 ya está finalizada y si la petición "ordenar el Jira" se refería a Jira o al historial.
9. **Diseño de la carcasa** (PLA; sensor arriba con ventana abierta o PTFE 0.5 mm; botón; interruptor de 19.6 × 5.8 mm; espacio para batería 10 × 30 × 50 mm; pantalla hundida para dar sombra).
10. **App nativa de Android** (ver `PENDIENTES_ANDROID.md`), compilada en GitHub Actions.
11. Comprar lámina PTFE 0.5 mm y, si hace falta, cable 26–28 AWG y termofit.
12. **Mejoras a futuro** (sección 6 del historial), cuando el usuario decida.
