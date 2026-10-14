# Historial de cambios — Sensor UV

Registro de todo lo que se ha hecho en el proyecto: investigación, aplicación, dispositivo físico y organización.
Está ordenado **por secciones**; dentro de cada sección, los cambios van **del más antiguo al más nuevo**, y cada uno indica su **fecha**.

## Contenido
1. [Investigación](#1-investigación)
2. [Entorno de desarrollo](#2-entorno-de-desarrollo)
3. [App](#3-app)
4. [Publicación y documentación](#4-publicación-y-documentación)
5. [Dispositivo físico](#5-dispositivo-físico)
6. [Mejoras a futuro](#6-mejoras-a-futuro)
7. [Jira (cronograma)](#7-jira-cronograma)

---

## 1. Investigación

### Comparación de componentes del dispositivo — 2026-10-04
- Se compararon placas, sensores UV, pantallas, buzzers y baterías (tablas completas en la sección [5. Dispositivo físico](#5-dispositivo-físico)).
- Sensor UV: el LTR390 (digital, I2C) es más estable y preciso que el GUVA-S12SD (analógico), que se descartó.
- Buzzer: un módulo pasivo con transistor suena fuerte; los módulos KY-006 (sin transistor) suenan bajo.
- Carcasa: el PLA bloquea los rayos UV, así que el sensor necesita una ventana abierta o de teflón (PTFE); el PLA se deforma con calor (55–60 °C).

### Tipo de piel (escala de Fitzpatrick) — 2026-10-05
- La escala de Fitzpatrick (tipos I a VI) es la forma estándar de clasificar el tipo de piel.
- Un estudio encontró que lo que mejor predice el tipo de piel son dos preguntas hechas por separado: qué tan fácil te quemas y qué tan fácil te bronceas. El color de ojos, cabello y pecas sirven como apoyo.
- Limitaciones: la gente puede no recordar bien cómo reacciona su piel, y la escala es menos precisa en pieles oscuras. Por eso el resultado es una estimación.

### Reflejo del suelo y efecto de las nubes — 2026-10-05
- Según la Guía del Índice UV de la OMS: la nieve fresca refleja hasta 80 % de los rayos UV, la espuma del mar 25 %, la arena seca 15 %, y el pasto, la tierra y el agua menos de 10 %.
- Hasta 80 % de los rayos UV atraviesa las nubes delgadas: uno se puede quemar aunque esté nublado.

### Servicio de clima — 2026-10-05
- Open-Meteo da gratis y sin cuenta la temperatura, la sensación térmica, la nubosidad, el índice UV actual y el UV máximo del día.

### Límites de la app web en segundo plano — 2026-10-05
- Android y Chrome congelan las apps web cuando están en segundo plano o con la pantalla apagada: no pueden usar la ubicación ni actualizarse. Solo la app nativa de Android puede hacerlo.

### Carga de batería de cada placa — 2026-10-05
- XIAO ESP32C3: carga a 380 mA (batería mínima recomendada: 400 mAh).
- XIAO ESP32C6: oficialmente 100 mA, pero usuarios midieron 330–380 mA; su placa no protege la batería contra descarga excesiva, así que la batería debe traer protección.
- XIAO ESP32S3: carga a 50 mA (muy lento) y gasta más; se descartó.
- Todas las baterías LiPo de UNIT Electronics traen circuito de protección y conector JST PH de 2 mm.

---

## 2. Entorno de desarrollo

### Configuración inicial — 2026-10-04
- Se verificó la licencia y los paquetes del SDK de Android.
- Se configuraron `ANDROID_HOME`, `ANDROID_SDK_ROOT` y `JAVA_HOME`, y se agregaron al PATH las herramientas de Android, Java y Flutter.

### Guía de Arduino IDE 2 — 2026-10-11
- Nuevo documento `GUIA_ARDUINO_IDE.md`: instalar Arduino IDE 2, agregar las placas ESP32 de Espressif, elegir **XIAO_ESP32C3** (con "USB CDC On Boot" activado), instalar las librerías **Adafruit LTR390** y **Adafruit SSD1306** (con sus dependencias) y comprobar que compila sin la placa. Incluye cómo cargar el programa cuando llegue la XIAO y qué hacer si no aparece el puerto (modo BOOT).
- Primer programa de prueba: `dispositivo/prueba_xiao/prueba_xiao.ino` (escribe un mensaje cada segundo en el Monitor Serie).

### Cambio a VS Code con PlatformIO — 2026-10-13
- Se decidió programar la placa en **VS Code con la extensión PlatformIO** en lugar de Arduino IDE 2: el usuario ya usa VS Code, las librerías se instalan solas y Claude puede compilar y cargar el programa desde la terminal.
- El programa de la placa queda en el **mismo repositorio que la app**, en su propia carpeta `dispositivo/` (no puede ir en los mismos archivos: la app es Dart y la placa es C++):
  - `dispositivo/platformio.ini`: dos placas, **XIAO ESP32C3** (`xiao_esp32c3`) y **ESP32-C6 DevKit** prestada (`esp32c6`), con la plataforma comunitaria **pioarduino** (Arduino 3.x, necesaria para la C6) y las librerías Adafruit LTR390, SSD1306 y GFX.
  - `dispositivo/src/main.cpp`: el programa de prueba (antes `dispositivo/prueba_xiao/prueba_xiao.ino`).
- Nueva guía `GUIA_VSCODE_PLATFORMIO.md`; `GUIA_ARDUINO_IDE.md` queda como alternativa.

### PlatformIO instalado y primera compilación — 2026-10-13
- El usuario instaló la extensión **PlatformIO IDE** en VS Code.
- Claude compiló el programa de prueba desde la terminal: **compila sin errores para la XIAO ESP32C3 y para la ESP32-C6** (en la XIAO usa 4.3 % de la RAM y 23.6 % de la memoria del programa).
- Problema resuelto: la primera instalación de las herramientas de Espressif falló porque se ejecutó desde Git Bash ("MSys/Mingw is not supported") y el compilador quedó vacío; se borró y se reinstaló desde PowerShell.

---

## 3. App

### Versión inicial — 2026-10-04
- App Flutter con el cálculo de cuándo reaplicar bloqueador según índice UV, tipo de piel, FPS, sudor o agua y resistencia al agua.
- Pantalla de inicio con índice UV, minutos restantes, botón "Ya me puse bloqueador" y alerta de reaplicar.
- Pantalla "Mi perfil" con los datos del usuario.
- El índice UV se simula con un control deslizante mientras no está conectado el sensor por Bluetooth.

### Versión web responsiva e instalable — 2026-10-04
- Diseño adaptable:
  - Celular: barra de navegación inferior.
  - Tablet y computadora: menú lateral, y las pantallas de Inicio y Mi perfil en dos columnas.
- Instalación en celular y computadora ("Agregar a inicio"):
  - Botón "Instalar app" que abre el aviso de instalación del navegador (Android, Chrome y Edge).
  - En iPhone, o navegadores sin ese aviso, el botón muestra los pasos para agregarla a inicio.
- Funciona sin internet una vez abierta (service worker).
- Icono nuevo (sol blanco sobre fondo naranja), nombre "Sensor UV" y colores de la app.
- Pantalla de carga naranja mientras la app arranca.

### Aviso médico — 2026-10-04
- Al abrir la app aparece un aviso que se debe aceptar:
  - Los resultados son estimaciones estadísticas basadas en datos e investigación existente y pueden variar entre personas.
  - La app no sustituye una consulta médica; se recomienda acudir con un médico o dermatólogo para confirmar el tipo de piel y la información.
- Al principio solo aparecía la primera vez; el mismo día se cambió para que aparezca **cada vez que se abre la app**.
- Botón "Aviso médico" en la pantalla de inicio para volver a leerlo.
- Nota fija en "Mi perfil", junto al tipo de piel: elegirlo es una estimación y un dermatólogo puede confirmarlo.

### Nuevo logo e identidad de colores — 2026-10-05
- Nuevo logo: escudo blanco con un sol dorado sobre fondo azul marino (diseñado por Rodrigo en Nano Banana).
  - Original guardado en `diseno/logo-original.png`; versión limpia (sin marca de agua) en `diseno/logo-1024.png`.
- Iconos actualizados con el nuevo logo: icono de la app, icono para Android (adaptable), icono para iPhone, ícono de la pestaña del navegador y pantalla de carga.
- El logo aparece dentro de la app: en el menú lateral (computadora) y junto al título (celular).
- Nueva paleta de colores tomada del logo, aplicada en toda la app:
  - Azul marino `#122746`: botones principales, barra del celular y pantalla de carga.
  - Dorado `#C9A05A` y dorado claro `#F3E6CC`: menú, botón de instalar y cuadros informativos.
  - La escala de colores del índice UV (verde, amarillo, naranja, rojo y morado) se mantiene, porque es el estándar internacional.
- Pantalla de alerta "Hora de reaplicar" rediseñada: fondo azul marino con el sol y el botón en dorado.
- En celular, el título "Sensor UV" se ajustó para que quepa en una línea junto al logo.

### Ajuste del menú lateral — 2026-10-05
- En computadora, el logo y el botón "Instalar app" quedan alineados a la izquierda con los íconos del menú (antes el logo quedaba centrado).

### Ayuda para encontrar el FPS — 2026-10-05
- Primero se agregó un cuadro fijo "¿Dónde veo el FPS?" y un texto de ayuda en "Resistencia al agua".
- El mismo día se reemplazó por una **burbuja "?"** junto a "FPS de tu bloqueador" y junto a "Resistencia al agua que dice el envase".
- Al tocarla se abre una ilustración de un bloqueador genérico (sin marca) con flechas que señalan dónde está el FPS («FPS 50+») y la resistencia al agua, más una explicación corta: si el número no está entre las opciones, conviene elegir el más cercano hacia abajo.

### Perfiles personalizables — 2026-10-05
- En "Mi perfil" hay un selector de perfiles: cada perfil tiene su propio nombre y guarda su tipo de piel, FPS y resistencia al agua.
- Botones para crear un perfil nuevo, cambiarle el nombre y borrarlo (con confirmación). Siempre queda al menos uno.
- El nombre no puede estar vacío, tiene máximo 30 caracteres y no se puede repetir.
- Los perfiles se guardan en el dispositivo y se recuerdan al volver a abrir la app.
- Al cambiar de perfil se reinicia la cuenta de sol, porque es otra persona.
- La pantalla de inicio muestra el nombre del perfil activo junto a sus datos.

### Test de tipo de piel — 2026-10-05
- Nuevo botón "¿No sabes cuál es? Haz el test" en "Mi perfil", debajo de la nota del tipo de piel.
- Test de 6 preguntas de opción múltiple basado en la escala de Fitzpatrick:
  1. ¿Qué le pasa a tu piel al sol? (quemadura) — principal, con opción «No sé».
  2. ¿Cómo cambia el color de tu piel? (bronceado) — principal, con opción «No sé».
  3. Color de la piel donde casi no da el sol (con círculos de color) — apoyo.
  4. Pecas — apoyo.
  5. Color de cabello natural — apoyo.
  6. Color de ojos — apoyo.
- Cálculo: las preguntas 1 y 2 deciden el tipo; las preguntas 3 a 6 solo ajustan el resultado si se contesta «No sé» o si 1 y 2 no coinciden. Si queda entre dos tipos, se elige el más claro para que el aviso llegue antes.
- El resultado muestra el tipo, qué tan exacto es según las respuestas, y el recordatorio de confirmarlo con un dermatólogo; el botón "Usar este tipo" lo guarda en el perfil activo.
- No deja ver el resultado si falta contestar alguna pregunta.
- Aviso de privacidad al final de la encuesta: las respuestas son privadas, no se comparten con nadie y se usan solo para calcular el tipo de piel en el dispositivo; si se elige «Usar este tipo», solo se guarda el resultado en el perfil, también en el dispositivo.
- Se agregaron pruebas automáticas del cálculo (6 casos).

### Lugar, clima y ubicación — 2026-10-05
- Nueva tarjeta "¿Dónde estás?" en la pantalla de inicio.
- **Lugar:** Ciudad, Parque o bosque, Alberca o lago, Playa o Nieve. El cálculo se ajusta por el reflejo del suelo:
  - Ciudad y parque: sin cambio · Alberca o lago: +10 % · Playa (arena y espuma del mar): +25 % · Nieve: +80 %.
- **Clima de tu zona (con permiso de ubicación):** temperatura, sensación térmica, estado del cielo, índice UV actual y UV máximo del día, consultados en Open-Meteo.
  - La ubicación se redondea a ~1 km antes de enviarla y no se guarda; la app lo explica en la misma tarjeta.
  - Opción "Usar el índice UV de tu zona" en lugar del simulador; se actualiza cada 15 minutos.
- **Cielo manual (cuando se usa el simulador):** Despejado, Algo nublado, Nublado o Lluvia; se sugiere solo según el clima de tu zona. Es conservador y la app advierte que las nubes no bloquean tanto. Con el UV de tu zona no hace falta, porque ya incluye las nubes.
- El resumen de inicio muestra el lugar, la etiqueta de arriba indica si el UV viene del simulador o de tu zona, y en "Mi perfil" los ejemplos de aviso se calculan para el lugar elegido.
- Se agregaron 5 pruebas automáticas del ajuste por lugar y nubes.

### "UV de tu zona" más constante — 2026-10-05
- La opción "Usar el índice UV de tu zona" se recuerda: al volver a abrir la app se reactiva sola y consulta el clima.
- Al regresar a la app (después de estar en segundo plano o con la pantalla apagada), si el clima tiene más de 15 minutos se actualiza de inmediato.
- La cuenta de sol ya no se pierde cuando el teléfono congela la app: al volver se cuenta el tiempo real que pasó.
- Nueva opción "Mantener la pantalla encendida" (aparece al usar el UV de tu zona): mientras la app está abierta la pantalla no se apaga y sigue actualizando cada 15 minutos. Gasta más batería, por eso es opcional y también se recuerda.
- Nota en la app: con la app en segundo plano o la pantalla apagada, el teléfono la pausa.

### Icono de la app en celulares que ya la tenían instalada — 2026-10-06
- En un Android con la app ya instalada seguía apareciendo el icono anterior (sol naranja), aunque los iconos publicados ya eran los nuevos: Chrome tarda en actualizar el icono de las apps instaladas.
- Las direcciones de los iconos ahora llevan un número de versión (`?v=2`) para que Chrome los reconozca como nuevos, y se renovó la copia guardada sin internet (`sensor-uv-v2`) para borrar los iconos viejos.
- Si el icono no cambia en uno o dos días, la forma inmediata es quitar la app de inicio y volver a instalarla desde Chrome.

### Conectar el dispositivo por Bluetooth — 2026-10-13
- Nueva tarjeta **"Tu dispositivo"** en la pantalla de inicio con el botón **"Conectar dispositivo"** (Web Bluetooth: Chrome en Android y computadora, Bluefy en iPhone; en otros navegadores explica cuál usar).
- Con el dispositivo conectado ("la placa es el cerebro"):
  - El índice UV, los minutos que faltan y el avance **vienen de la placa**; la app ya no cuenta por su cuenta.
  - La etiqueta de arriba dice **"Dispositivo"**; el simulador y el cielo manual se desactivan (el sensor mide el UV real con todo y nubes) y se oculta "Usar el índice UV de tu zona" (el clima se sigue mostrando).
  - El **perfil, el lugar y si hay sudor o agua se envían solos** a la placa en cuanto cambian; al cambiar de perfil, la placa empieza la cuenta de cero.
  - **"Ya me puse bloqueador"** en la app reinicia también la placa; el **botón de la placa** quita la alerta de la app.
  - Botones **"Silenciar"** (también en la pantalla de alerta: "Silenciar el dispositivo") y **"Dormir dispositivo"** (con aviso de que se despierta solo con su botón), y **"Desconectar"**.
  - Si se pierde la conexión, la app intenta **reconectar** cada 5 segundos durante 1 minuto y vuelve a enviar el perfil.
- Nuevos archivos: `lib/protocolo.dart` (mismo formato que la placa), `lib/dispositivo.dart` (+ `_stub`, `_web`), `lib/tarjeta_dispositivo.dart`; funciones `sensorUvBle*` en `web/index.html`.
- 10 pruebas nuevas (`test/protocolo_test.dart` y `test/dispositivo_test.dart`): **22 pruebas en total, todas pasan**. Se probó en el navegador con un dispositivo simulado: conectar, enviar perfil y lugar, alerta, silenciar, reaplicar, reconectar y desconectar.

---

## 4. Publicación y documentación

### Publicación en GitHub — 2026-10-04
- App publicada en https://rodrigohuertaram.github.io/sensor_uv/ (repositorio: https://github.com/rodrigohuertaram/sensor_uv).
- Publicación automática: cada vez que se suben cambios a GitHub, la app se compila y se publica sola.
- Ajuste del manifiesto para que la app instalada funcione bien desde la dirección de GitHub.

### Lista de pendientes para la app nativa de Android — 2026-10-05
- Nuevo documento `PENDIENTES_ANDROID.md` con todo lo que habrá que adaptar o agregar en la app nativa de Android (segundo plano, ubicación, guardado de perfiles, avisos, Bluetooth, icono y nombre). Se actualiza con cada cambio.

### Decisión: app nativa de Android como APK gratis — 2026-10-07
- La app nativa de Android se instalará con un archivo **APK gratis**, sin pasar por la Play Store (que cuesta 25 USD y requiere revisión de Google).
- Ventajas sobre la app web: funciona en segundo plano, mantiene la conexión con el dispositivo y manda notificaciones con el celular bloqueado.
- Se hará **cuando se programe el dispositivo**. La app web seguirá publicada para computadora y iPhone.

### Estado del proyecto — 2026-10-07
- Nuevo documento `ESTADO_PROYECTO.md` para retomar el proyecto sin perder contexto: objetivo, qué funciona y qué falta, estructura de archivos y funciones, decisiones (incluido lo descartado), reglas de trabajo, cómo correr y probar, problemas resueltos y pendientes en orden.

### Plan de código del dispositivo — 2026-10-07
- Nuevo documento `PLAN_CODIGO_DISPOSITIVO.md` con todo lo acordado para programar cuando lleguen los componentes: decisiones, componentes y pines propuestos, cálculo, comportamiento del dispositivo (botón sincronizado, alarma corta, dormir sin sol, silenciar y dormir desde la app), canales Bluetooth, cambios en la app web, APK de Android y orden de trabajo.

---

## 5. Dispositivo físico

### Selección de componentes (propuesta) — 2026-10-04

Decisiones generales:
- El dispositivo es el "cerebro": mide, calcula y avisa con sonido y en la pantalla, aunque no haya celular cerca. La app configura el perfil, muestra los datos y también avisa.
- El botón "Ya me reapliqué" del dispositivo y el de la app se sincronizan en ambos sentidos.
- Primero Android; iPhone se evaluará después (opción gratuita: navegador Bluefy).
- Prototipo con módulos ya armados, sin diseñar una PCB.

#### Tabla comparativa de componentes

| Componente | Decisión | A favor | En contra | Precio aprox. |
|---|---|---|---|---|
| Placa Seeed XIAO ESP32-C3 | ✅ Usar | Muy pequeña, Bluetooth de bajo consumo, carga batería por USB-C, barata | Pocos pines (suficientes); lectura analógica imprecisa; hay que conectarle su antena | 5 USD |
| Sensor UV GUVA-S12SD | ❌ Descartado | Barato y simple | Señal analógica débil y con ruido en la ESP32-C3; requiere calibrar a mano | 3–5 USD |
| Sensor UV LTR390-UV | ✅ Usar | Digital (I2C), lectura estable, fórmula de índice UV documentada por el fabricante | Algo más caro | 5–8 USD |
| Pantalla OLED 0.96" 128×64 I2C (SSD1306, 4 pines) | ✅ Usar | Barata, nítida, bajo consumo, comparte cables con el sensor | Se lee mal bajo el sol directo (se compensa con sonido y pantalla hundida en la carcasa) | 3–5 USD |
| Buzzer pasivo en módulo de 3 pines (con transistor incluido) | ✅ Usar | Suena bien y fuerte, se conecta con 3 cables, sin piezas extra | Ninguno importante | 1–2 USD |
| Batería LiPo 3.7 V 500 mAh | ✅ Usar | La placa la carga sola; aprox. 10 h de uso | Hay que soldarla; mejor comprarla en México (envío aéreo restringido) | 4–6 USD |
| Botón pulsador | ✅ Usar | Botón físico "Ya me reapliqué" | Ninguno | < 1 USD |
| Interruptor deslizable | ✅ Usar | Apagar el dispositivo sin desconectar la batería | Ninguno | < 1 USD |
| Placa de expansión Seeed XIAO (alternativa) | Opcional | Ya trae pantalla OLED 0.96", buzzer, botón, conector de batería y conectores Grove: casi sin soldar | Más grande (carcasa más grande) y más cara | 16–18 USD |

#### Tipos de buzzer y qué tan difícil es conectarlos

| Tipo | Cómo suena | Conexión | Dificultad | Piezas extra |
|---|---|---|---|---|
| Buzzer en placa de expansión XIAO | Bien (pasivo, tono a elegir) | Ya viene conectado | ⭐ Muy fácil | Ninguna |
| **Módulo buzzer pasivo de 3 pines (con transistor)** — recomendado | Bien y fuerte; se elige el tono | 3 cables: VCC, GND y señal | ⭐ Muy fácil | Ninguna |
| Módulo buzzer activo de 3 pines | Un solo pitido fijo, chillón; más bajo a 3.3 V | 3 cables: VCC, GND y señal | ⭐ Muy fácil | Ninguna |
| Buzzer pasivo suelto (2 patas) directo a la placa | Se oye bajito | 2 cables | ⭐ Muy fácil | Ninguna |
| Buzzer pasivo suelto + transistor | Bien y fuerte | Transistor, resistencia y buzzer en una placa perforada | ⭐⭐ Media | Transistor S8050 o 2N2222 + resistencia 1 kΩ |
| Bocina pequeña + amplificador MAX98357A | El mejor; puede reproducir sonidos grabados | 5 cables al amplificador y 2 a la bocina | ⭐⭐⭐ Difícil | Amplificador + bocina 8 Ω |

### Decisiones de componentes — 2026-10-05
- Placa: XIAO ESP32C3 (preferida) o XIAO ESP32C6; el programa funcionará con ambas.
- Descartadas: XIAO ESP32S3 (gasta más y carga muy lento), FireBeetle 2 ESP32-C6 (demasiado grande) y el buzzer KY-006 (sin transistor, suena bajo).
- Batería: LiPo 3.7 V 1500 mAh, compatible con las dos XIAO.
- Para pruebas en mesa se pueden usar las placas ESP32-C6 DevKit y ESP32 DevKit que ya se tienen.

### Compras y decisiones finales — 2026-10-06
- Pedido hecho en AliExpress: Seeed Studio XIAO ESP32C3 con antena, pantalla OLED 0.96" blanca (SSD1306) y sensor UV LTR390. Llegada estimada: 10 a 25 de octubre.
- Placa definitiva: **XIAO ESP32C3**.
- Batería definitiva: **LiPo 3.7 V 1500 mAh** (UNIT Electronics), compatible también con la XIAO ESP32C6.
- Pendiente de pedir en UNIT Electronics: 2 buzzers UNIT DevLab 80 dB, 2 interruptores deslizables y la batería.
- Se propuso que la placa sea el "cerebro" (mide, calcula y avisa aunque el celular no esté) y la app envíe los datos del usuario y muestre el estado; pendiente de confirmar.

### Decisión: la placa es el "cerebro" — 2026-10-07
- Se confirmó que **la placa es el cerebro**: mide el UV con el sensor, hace la cuenta y avisa con el buzzer y la pantalla OLED aunque el celular esté lejos, apagado o con la app cerrada.
- Se descartó que la app fuera el cerebro: con la pantalla apagada el teléfono congela la app y el aviso no llegaría; además, en iPhone dependería de tener Bluefy abierto.
- Qué hace cada parte:
  - **App → placa:** envía tipo de piel, FPS, resistencia al agua, sudor o agua y lugar. La placa los guarda en su memoria y los sigue usando sin el celular.
  - **Nubes:** con el dispositivo ya no hace falta elegir el cielo, porque el sensor mide el UV que de verdad pasa entre las nubes.
  - **Lugar:** se sigue usando, porque el sensor apunta hacia arriba y no mide bien el reflejo del suelo (arena, agua, nieve).
  - **Placa → app:** manda el UV medido, cuánto falta para reaplicar, si ya toca reaplicar y la batería.
  - **Botón "Ya me reapliqué" sincronizado:** si se presiona en el celular se silencia el buzzer y se quita la alerta del dispositivo; si se presiona en el dispositivo se quita la alerta del celular.
- El programa de la placa se hará **cuando llegue la placa**.

### Cómo va a funcionar el dispositivo — 2026-10-07
Diseño acordado para cuando se programe la placa:
- **Datos del usuario:** la app envía a la placa el tipo de piel, FPS, resistencia al agua, sudor o agua y lugar del **perfil activo**. La placa los guarda en su memoria y los sigue usando aunque se apague o el celular no esté.
- **Cambio de perfil:** si se elige otro perfil en la app con el dispositivo conectado, la placa recibe los datos del nuevo y **la cuenta empieza desde cero** (es otra persona). Si se cambia sin conexión, se envía al volver a conectarse. La pantalla puede mostrar el nombre del perfil activo.
- **Nubes y UV de tu zona:** con el dispositivo no se usan; el sensor mide el UV real donde está la persona, incluidas las nubes. El lugar sí se sigue aplicando (reflejo del suelo).
- **Botón "Ya me reapliqué" sincronizado:** presionarlo en el celular calla el buzzer, quita la alerta del dispositivo y reinicia la cuenta; presionarlo en el dispositivo quita la alerta del celular. Si la app web estaba congelada, se pone al día al abrirla.
- **Para que no suene todo el día:**
  1. **Alarma corta:** al tocar reaplicar, el buzzer suena unos 10 segundos y se calla; si no se presiona el botón, lo recuerda cada 10 minutos, máximo 3 veces, y después deja solo la alerta en la pantalla.
  2. **Se duerme sola sin sol:** si el sensor no detecta sol durante 30 minutos (dentro de casa, de noche, en la mochila), la placa se duerme (pantalla, buzzer y Bluetooth apagados) y despierta al presionar el botón.
  3. **Desde la app:** botón **"Silenciar"** (calla el buzzer sin reiniciar la cuenta) y botón **"Dormir dispositivo"**. Una vez dormido, se despierta con el botón del dispositivo, no desde la app, porque el Bluetooth queda apagado para ahorrar batería.
- **Apagado total:** con el interruptor deslizable, que desconecta la batería.
- Se descartó que la placa se apague sola al perder la conexión con el celular, porque dejaría de avisar justo cuando el celular está lejos.

### Base para la XIAO ESP32C3 — 2026-10-08
- Se empezó a diseñar la carcasa por los **soportes (bases) de cada componente**, para que al llegar las piezas solo haya que cambiar algunas medidas.
- El usuario hizo en SolidWorks una base con el hueco del USB-C en forma de "U" abierta por arriba, agrandado 0.3 mm por lado (en la cota se veía 0.20; revisar cuál quedó).
- Observaciones a su diseño: el plástico del cable USB-C (11–13 × 6–7 mm) es más grande que el conector, así que la pared frente al USB-C debe ser delgada o tener un rebaje por fuera; los puntos BAT+ y BAT− están **debajo** de la placa y necesitan espacio para las soldaduras y una salida para los cables; no tapar los botones BOOT y RESET ni el conector de la antena. Se sugirió usar **Variables globales** (Herramientas → Ecuaciones) en SolidWorks.
- Versión en **FreeCAD 1.1** (`carcasa/base_xiao/`): el script `generar_base_xiao.py` crea `base_xiao.FCStd` con una hoja **"Medidas"** (placa, USB-C, holgura, paredes, hueco bajo la placa, ranura de cables), y exporta `base_xiao.step` (para SolidWorks o CATIA) y `base_xiao.stl` (para imprimir). Al cambiar un número de la hoja, la pieza se actualiza sola.
- Medidas iniciales de la hoja técnica (hay que comprobarlas con calibrador): placa 21 × 17.8 mm, grosor 1 mm, USB-C 8.94 × 3.26 mm. Base resultante: 24.2 × 21.6 × 6.7 mm.
- El usuario cambió su base de SolidWorks a una placa "volando" sobre patas (esquinas y una barra al centro) con espacio abajo para las soldaduras y ventanas para sacar los cables. El grosor bajo el USB-C quedó en 1 mm (suficiente).
- **Cambio de pines:** como las patas quedan bajo los pines de las 4 esquinas (D0, 5V, D6 y D7), no se usará ninguno. El buzzer pasa de D2 a **D3 (GPIO5)** y la medición de batería (mejora a futuro) de D0 a **D2 (GPIO4)**. Quedan: botón D1, SDA D4, SCL D5, 3V3 y GND.
- Revisión de la base del usuario: el USB-C, las ventanas para los cables y las patas de las esquinas quedaron bien. El usuario corrigió la barra del centro (soldaduras BAT+ y BAT−), el tamaño del marco y el redondeo de las esquinas del hueco. **Pendiente:** una "barra" que se ponga y se quite para sujetar la placa por arriba, después de probar el soporte.
- Base corregida: marco más delgado, 4 patas en las esquinas y una pata central de 7.5 mm (en lugar de la barra). El espacio bajo la placa se deja abierto a propósito para pasar cables; el saliente se imprimirá con soportes de Ultimaker Cura. El usuario piensa agregar otro hueco atrás para cables.
- Con la foto de la parte de abajo de la XIAO se vio que BAT+ y BAT− están a la mitad del largo (a la altura de D2–D3), corridos hacia el lado de D0–D6, justo sobre la orilla de la pata central. **Decisión:** se quita la pata central y la placa queda solo sobre las **4 patas de las esquinas** (la placa es pequeña y rígida); patas de al menos 2.5 × 2.5 mm y todas de la misma altura. Abajo queda libre el espacio para las soldaduras y los cables.

### Base para el sensor LTR390 — 2026-10-09
- El módulo comprado es del diseño de **Adafruit** (con dos conectores blancos STEMMA QT). Adafruit no tiene modelo 3D de él en `Adafruit_CAD_Parts`; las medidas exactas se sacaron del diseño de su placa (https://github.com/adafruit/Adafruit-LTR390-PCB): placa **25.4 × 17.78 mm**; 4 agujeros de 2.5 mm a 2.54 mm de cada orilla (separación 20.32 × 12.7 mm); fila de 6 pines centrada a 2.54 mm de una orilla larga; sensor exactamente al centro; conectores blancos en los lados cortos, del mismo lado que el sensor (sobresalen unos 3 mm, hay que dejarles hueco en la tapa).
- Diseño del usuario en SolidWorks: hueco de la placa con 0.3 mm de holgura y pared de 1.6 mm (exterior 29.2 × 21.6 mm), altura total 3 mm; la placa se apoya en el fondo y queda al ras de la pared (no hace sombra al sensor). Bajo la fila de pines, un hueco que atraviesa el fondo (unos 16.2 × 4.5 mm) para las soldaduras; 4 pernos de 2.2 mm en los agujeros de las esquinas.
- Los cables se sueldan directo (pasan por abajo y se sueldan por arriba), sin la tira de pines, para que la cara de arriba quede plana. Se usan VIN (a 3V3), GND, SCL (D5) y SDA (D4).

### Base para la pantalla OLED — 2026-10-09
- El usuario ya tiene una base para la OLED 0.96" de un proyecto anterior y la va a reutilizar. Cuidados: sujetar la placa y nunca el vidrio (va pegado con cinta), no doblar ni aplastar la cinta flexible del vidrio, y dejar espacio para los componentes de atrás.

### Base para la batería — 2026-10-09
- Batería LiPo 1500 mAh "103050" = 10 × 30 × 50 mm; cable y circuito de protección en un lado corto.
- Base: hueco **52 × 32 mm** (1 mm de holgura por lado), pared 1.6 mm (exterior 55.2 × 35.2 mm), fondo 1.2 mm, hueco de **6 mm de profundidad** (altura total 7.2 mm), salida del cable de 8 mm en un lado corto.
- Cuidados: nada que la presione o la pique, 1 mm de aire arriba porque se infla un poco, sujetarla con algo suave (cinta doble cara espumosa o pestaña con espacio), lejos de la XIAO y del sol directo. Comprobar el largo al recibirla (algunas miden 52–55 mm).

### Base para el buzzer — 2026-10-12
- Módulo UNIT DevLab: placa **23.88 × 10.16 mm**, buzzer cuadrado (~9 × 9 mm) en un extremo con la salida del sonido arriba (círculo con cruz), un agujero al centro y 3 pines (+5V, Signal, GND) en el otro extremo; todos los componentes por arriba.
- Base: hueco **24.5 × 10.8 mm**, pared 1.6 mm (exterior 27.7 × 14.0 mm), altura 3.0 mm, hueco de 1.6 mm de profundidad (placa al ras), fondo 1.4 mm, perno al centro y hueco de 8 × 4 mm bajo los pines.
- El buzzer debe mirar a una pared con 5–7 agujeros de 1.5–2 mm frente a la salida del sonido, con 0.5–1 mm de aire. Se alimenta con 3V3 (suena algo más bajo que a 5 V); se probará en mesa.
- Nuevo documento `carcasa/MEDIDAS_BASES.md` con la tabla de medidas de todas las bases.

### Primera impresión de las bases — 2026-10-12
- Se imprimieron en PLA morado las bases de la XIAO, el sensor, la batería, el buzzer y la OLED (la del proyecto anterior), antes de lo previsto en el cronograma (30 oct).
- Ajustes acordados en el diseño: pernos del sensor de 2.2 mm (no 2.4), perno del buzzer de 2.7 mm provisional, salida del cable de la batería de 8 mm y hueco de 8 × 4 mm bajo los pines del buzzer.
- Las piezas se probarán con los componentes cuando lleguen; mientras, se miden los huecos impresos con calibrador para saber qué tan exacta es la impresora.
- El usuario midió las piezas impresas con calibrador y **salieron con las medidas del diseño**: la impresora es exacta y se mantiene la holgura de 0.3 mm. Se agregó al diseño de la batería la ranura en "U" de 8 × 6 mm para el cable.

### Pedido en UNIT Electronics — 2026-10-10
- Se hizo el pedido en UNIT Electronics: 2 módulos zumbadores pasivos 80 dB (UNIT DevLab), 2 interruptores deslizables y la batería LiPo de 1500 mAh. Con esto ya están pedidos todos los componentes del dispositivo.

### Corrección: placas para pruebas — 2026-10-11
- El usuario **no tiene una ESP32-C6 DevKit** (lo anotado el 2026-10-05 era un error). El programa se hará solo para la **XIAO ESP32C3**.

### Bases corregidas y reimpresas — 2026-10-12
- Se hicieron las 3 correcciones (pernos de 2.2 mm en la base del sensor, salida del cable de 8 mm en la de la batería y hueco de 8 × 4 mm bajo los pines del buzzer), se reimprimieron las bases y se midieron con calibrador: **quedaron bien**.
- Falta probarlas con los componentes reales cuando lleguen, y siguen pendientes la base del botón, el lugar del interruptor y de la antena, y la "barra" de la XIAO.

### Llegada de componentes y placa prestada — 2026-10-13
- Ya llegaron el **sensor UV LTR390** y la **pantalla OLED**. El **buzzer** y la **batería LiPo** llegan esta semana; la XIAO ESP32C3, a más tardar el 25 de octubre.
- Para empezar a probar el sensor y la pantalla antes de que llegue la XIAO, el usuario pedirá **prestada una placa ESP32 de desarrollo**. Recomendada: la **ESP32-C6 DevKit**, por ser de la misma familia que la ESP32-C3 (mismo tipo de procesador y Bluetooth 5). Los programas de prueba se adaptarán a sus pines y después se pasan a la XIAO.

### Pieza de prueba de tolerancias diseñada — 2026-10-13
- El usuario ya diseñó la pieza de prueba de tolerancias; falta imprimirla y medirla (Jira DT-62, en curso).

### Programa de prueba del sensor y la pantalla — 2026-10-13
- `dispositivo/src/main.cpp` ahora es la **prueba del sensor UV y la pantalla OLED**: busca qué piezas responden en el I2C (sensor en 0x53, pantalla en 0x3C o 0x3D), lee el índice UV cada segundo y lo muestra en la pantalla (número grande y nivel: Bajo, Moderado, Alto, Muy alto o Extremo) y en el Monitor Serie. Si una pieza no responde, lo avisa.
- Índice UV = cuentas del sensor ÷ 2300 (hoja técnica del LTR390 con ganancia 18x y 20 bits); se ajustará con la calibración.
- Nuevo `dispositivo/src/pines.h` con los pines de cada placa: XIAO ESP32C3 (SDA D4, SCL D5, botón D1, buzzer D3) y ESP32-C6 prestada (SDA GPIO23, SCL GPIO22, botón GPIO2, buzzer GPIO19). Al cambiar de placa en PlatformIO, el programa usa sus pines solo.
- Compila sin errores ni avisos para las dos placas. Falta probarlo con la placa.

### Cálculo de la dosis en la placa — 2026-10-13
- Nueva librería `dispositivo/lib/CalculoUV` con el **mismo cálculo que la app** (`lib/modelo.dart`): dosis por tipo de piel (200, 250, 350, 450, 600, 1000 J/m²), × FPS × 0.3 × 0.6; tope de 120 min (80 o 40 con sudor o agua); solo cuenta con UV de 1 o más; factor de lugar (ciudad y parque 1.0, agua 1.1, playa 1.25, nieve 1.8). **Las nubes no se aplican**, porque el sensor ya mide el UV real.
- 12 pruebas en `dispositivo/test/test_calculo` con los mismos casos que las pruebas de la app (playa +25 %, nieve avisa antes, tipo 2 con FPS 15 avisa a los 45 min con UV 10, sudor o agua, sin sol no cuenta, etc.). Compilan; **se corren con la placa conectada** (`pio test -e esp32c6`), porque la computadora no tiene compilador de C++ para correrlas ahí.

### Diagrama de conexiones — 2026-10-13
- Nuevo `DIAGRAMA_CONEXIONES.md` con el dibujo `dispositivo/diagrama_conexiones.svg` (se ve en GitHub) y las tablas de conexión de la **XIAO ESP32C3** y de la **ESP32-C6 prestada**.
- Todo va a **3V3** (el pin 5V de la XIAO solo tiene voltaje con USB). Sensor y pantalla comparten 3V3, GND, SDA (D4) y SCL (D5); buzzer en D3; botón entre D1 y GND; batería: rojo (+) a la pata del centro del interruptor, una pata lateral a BAT+, negro (−) a BAT− (abajo de la XIAO).

### Programa del dispositivo: pantalla, alarma, botón y modo dormir — 2026-10-13
- Primer programa completo de la placa (`dispositivo/src/main.cpp` y módulos), sin Bluetooth todavía:
  - Lee el sensor cada segundo, cuenta la dosis con el perfil guardado y muestra en la **pantalla**: perfil y FPS, índice UV grande con su nivel, barra de avance y "Faltan X min" (o "Sin sol: en pausa").
  - **Alarma corta:** al tocar reaplicar, melodía de ~10 s y alerta "HORA DE REAPLICAR" parpadeando; lo recuerda cada 10 min, máximo 3 veces.
  - **Botón** = "Ya me reapliqué" (cuenta desde cero, melodía corta).
  - **Modo dormir** tras 30 min sin sol; despierta con el botón y sigue con la cuenta. Con el interruptor, la cuenta empieza de cero (el perfil se conserva).
  - **Perfil guardado** en la memoria flash de la placa.
  - Órdenes por el Monitor Serie para probar sin la app (`r`, `s`, `d`, `p`, `uv 7.5`).
- Nueva librería `lib/Avisos` (alarma corta y modo dormir) con 6 pruebas en `test/test_avisos`.
- Nuevos entornos: `demo_*` (cada segundo cuenta como 1 minuto) y `prueba_sensor_*` (el programa de prueba del sensor y la pantalla, ahora aparte).
- Compila sin errores en la XIAO (RAM 4.5 %, memoria 28 %) y en la ESP32-C6. Falta comprobar con la placa el despertar con el botón y el sonido.
- Se descartó por ahora el simulador Wokwi: no tiene el sensor LTR390 y pide una cuenta; en su lugar están las órdenes del Monitor Serie.

### Bluetooth en la placa — 2026-10-13
- La placa se anuncia por Bluetooth como **"Sensor UV"** con tres canales: **Configuración** (la app manda el perfil y el lugar; la placa lo guarda), **Estado** (la placa manda cada segundo el UV, el avance, los minutos que faltan, si toca reaplicar y si está silenciada) y **Órdenes** ("reaplicado", "silenciar", "dormir"; la placa avisa "reaplicado" cuando se presiona su botón).
- Si llega el perfil de otra persona, la cuenta empieza de cero y la pantalla muestra su nombre. Al desconectarse, vuelve a anunciarse sola para reconectar.
- El formato de los mensajes está en `dispositivo/lib/Protocolo`, con 6 pruebas (`test/test_protocolo`); también se puede leer con nRF Connect.
- Compila en la XIAO (memoria del programa 53 %) y en la ESP32-C6 (63 %). Falta probar la conexión con la placa real.

### Prueba de componentes con la ESP32-C6 prestada — 2026-10-14
- Al usuario le prestan una **ESP32-C6 (módulo WROOM-1)** el 2026-10-15 para probar todas las piezas antes de que llegue la XIAO.
- El programa de prueba ahora prueba **cada pieza**: sensor UV, pantalla, buzzer (melodías y tonos de 500 a 4000 Hz para ver cuál suena más fuerte), botón (cuenta las veces) y dormir/despertar con el botón. Entornos renombrados de `prueba_sensor_*` a **`prueba_componentes_*`** (archivo `src/prueba_componentes.cpp`).
- Nueva guía paso a paso **`GUIA_PRUEBA_COMPONENTES.md`**: qué llevar, cómo revisar la placa, conexiones de cada pieza, qué debe pasar, programa completo en modo demo, Bluetooth con la app y una lista para anotar resultados.
- Compilan sin errores `prueba_componentes_esp32c6`, `esp32c6`, `demo_esp32c6`, `prueba_componentes_xiao` y `xiao_esp32c3`.

---

## 6. Mejoras a futuro

Ideas para después del prototipo final (XIAO ESP32C3, sensor LTR390, pantalla OLED 0.96", buzzer UNIT DevLab, batería de 1500 mAh y carcasa de PLA). Cada una indica la fecha en que se anotó.

### App para iPhone — anotada 2026-10-07
- Opción gratuita: usar la app web dentro del navegador **Bluefy**, que sí permite Bluetooth. Funciona mientras la app está abierta; con la pantalla apagada avisa el dispositivo.
- Opción completa: app nativa de iPhone con avisos en segundo plano. Requiere una Mac y la cuenta de desarrollador de Apple (99 USD al año), o el programa para universidades de Apple si la Ibero está inscrita.

### Carga solar del dispositivo — anotada 2026-10-07
- Agregar un panel solar pequeño (5 V, 0.5–1 W) en la carcasa para que la batería se cargue mientras el dispositivo está al sol.
- La XIAO ESP32C3 no tiene entrada solar: se necesita un **módulo cargador solar** entre el panel y la batería (por ejemplo, uno basado en el chip CN3065 o CN3791).
- El panel y el sensor UV van arriba; el diseño debe cuidar que el panel no le haga sombra al sensor.

### Ahorro de batería — anotada 2026-10-07
- Apagar la pantalla OLED después de unos segundos sin usarla y encenderla al presionar el botón.
- Dormir la placa entre lecturas del sensor (modo de bajo consumo) para que la batería dure varios días.

### Nivel de batería — anotada 2026-10-07
- Medir el voltaje de la batería con un divisor de voltaje (2 resistencias de 220 kΩ) en un pin de la XIAO y mostrar el porcentaje en la pantalla y en la app.
- Avisar con un tono distinto cuando la batería esté baja.

### Calibración del sensor con el UV de tu zona — anotada 2026-10-07
- La ventana de teflón (PTFE) de la carcasa reduce un poco la luz UV que llega al sensor.
- Comparar la lectura del sensor con el índice UV de Open-Meteo en un día despejado para calcular un factor de corrección.

### Aviso por vibración — anotada 2026-10-07
- Agregar un motor de vibración pequeño para avisar en lugares ruidosos (playa, alberca) o cuando no se quiere hacer ruido.

### Carcasa más resistente — anotada 2026-10-07
- El PLA sirve para el prototipo, pero se deforma con el calor (55–60 °C, por ejemplo dentro de un coche o al sol en la playa). Para la versión final: **PETG o ASA**, en un color claro.
- Proteger contra salpicaduras de agua y arena (empaques o tapas en el puerto USB-C y el botón).

### Actualizar el programa sin cable — anotada 2026-10-07
- Actualizar el programa de la placa desde la app por Bluetooth (o por Wi-Fi), sin conectarla a la computadora.

### Historial de exposición al sol — anotada 2026-10-07
- Guardar cuánto sol recibió la persona cada día y mostrarlo en gráficas en la app.

### Consejos según el nivel de UV — anotada 2026-10-07
- Mostrar recomendaciones cuando el UV es alto o extremo: buscar sombra, usar sombrero y lentes, hidratarse.

### Mejoras de la app — anotada 2026-10-07
- App nativa de Android con avisos y actualización en segundo plano (detalle en `PENDIENTES_ANDROID.md`).
- Mostrar el nombre de la ciudad junto al clima.
- Cuentas de usuario para ver los mismos perfiles en todos los dispositivos.

### Miniaturizar el dispositivo — anotada 2026-10-07
- Diseñar una PCB propia que una todos los componentes para hacer el dispositivo más pequeño y fácil de armar.

---

## 7. Jira (cronograma)

### Organización del proyecto en Jira — 2026-10-07
- Se conectó Jira (sitio `iberopuebla-dreamteam-01234.atlassian.net`, proyecto **DreamTeam ÑAÑAÑA**, clave **DT**).
- Las tareas de ejemplo que trae Jira (DT-3, DT-4 y DT-6) se cerraron y se marcaron como "(no usar)", porque no se pudieron borrar sin permisos especiales.
- **Epic DT-1 "Componentes Electrónicos"** (2 al 24 de octubre):
  - DT-7 "Pedir componentes en AliExpress" (2 al 6 de octubre), con la lista de lo pedido.
  - DT-8 "Pedir componentes en UNIT Electronics" (2 al 20 de octubre), con la lista y los enlaces.
  - DT-5, antes "Comprar componentes", ahora "Probar componentes" (21 al 24 de octubre).
- **Epic DT-2 "App"** (2 de octubre al 1 de noviembre): cronograma de cómo debería avanzar la app desde cero hasta tener la página terminada (sin pruebas con Bluetooth), con 11 tareas y 33 subtareas, todas con fecha de inicio y de vencimiento:
  1. Investigación del tema (2–6 oct)
  2. Preparar herramientas de desarrollo (5–7 oct)
  3. Diseño de la interfaz (7–10 oct)
  4. Logo e identidad visual (9–12 oct)
  5. Imágenes e ilustraciones (11–13 oct)
  6. Cálculo y simulador del sensor (12–16 oct)
  7. Desarrollo de pantallas principales (15–21 oct)
  8. Perfiles, test de piel y ayuda del FPS (20–24 oct)
  9. Lugar, clima y ubicación (23–27 oct)
  10. App instalable y publicación (26–29 oct)
  11. Pruebas y correcciones finales (28 oct – 1 nov)
- El cronograma se ve como diagrama de barras en la vista **Cronograma** de Jira.

### Cronograma de la carcasa — 2026-10-08
- La epic **DT-3** (antes "(no usar) Quality assurance testing") se reabrió y se renombró **"Carcasa"**: del **25 de octubre al 13 de noviembre**.
- Diseño en **SolidWorks o CATIA**, empezando con los modelos 3D de internet de cada componente y ajustando con las medidas reales (la XIAO llega a más tardar el 25 de octubre). Impresión en PLA en las impresoras de la universidad, **en las noches**.
- Primero se diseñan las **bases de cada componente** para que no se muevan dentro de la carcasa; la prueba de las bases es el **sábado 31 de octubre** (día libre completo), con los archivos listos el viernes 30.
- 6 tareas (DT-53 a DT-58) y 23 subtareas (DT-59 a DT-81), todas con fecha de inicio y de vencimiento:
  1. Modelos 3D y preparación (25–27 oct): modelos 3D, medir con calibrador, comprar PTFE 0.5 mm y tornillos M2, pieza de prueba de tolerancias.
  2. Bases de los componentes (27–31 oct): XIAO y antena, sensor, OLED, buzzer/botón/interruptor, batería, imprimir el 30 en la noche, probar y corregir el sábado 31.
  3. Diseño de la carcasa (1–4 nov): acomodo y cables, cuerpo y tapa, aberturas.
  4. Primera impresión (4–6 nov).
  5. Ajustes y segunda impresión (7–10 nov).
  6. Carcasa final (11–13 nov), con el 13 como día de margen.

### Pedido de UNIT finalizado — 2026-10-10
- DT-8 "Pedir componentes en UNIT Electronics" se marcó como **Finalizada**.

### Probar componentes, nuevas fechas — 2026-10-10
- DT-5 "Probar componentes" se movió del 21–24 al **25–28 de octubre**, porque la XIAO llega a más tardar el 25. La epic DT-1 ahora termina el 28 de octubre.

### Diseño de la interfaz completo — 2026-10-10
- Las subtareas DT-27 (bocetos de las pantallas), DT-28 (navegación para celular y computadora) y DT-29 (textos y aviso médico) se marcaron como **Finalizadas**, porque ya están hechas en la app. No hay bocetos aparte: el diseño se hizo directo en código; si se piden, se usan capturas de la app.

### App al día en Jira — 2026-10-10
- Como la app ya está hecha y publicada, se marcaron como **Finalizadas** las tareas DT-12 a DT-18 (logo, imágenes, cálculo, pantallas, perfiles y test de piel, lugar y clima, app instalable y publicación) y sus subtareas pendientes (DT-38 a DT-49).
- Queda pendiente solo **DT-19 "Pruebas y correcciones finales"** (28 oct – 1 nov) con DT-50, DT-51 y DT-52.

### Cronograma hasta la entrega final — 2026-10-11
- Entrega final del proyecto: **4 de diciembre**. Meta: terminar todo **a más tardar el 27 de noviembre** (una semana antes).
- **DT-4** (antes "(no usar) Penetration testing IOS gateway") se reabrió como epic **"Programa del dispositivo"** (22 oct – 20 nov), con 7 tareas (DT-82 a DT-88) y 22 subtareas (DT-93 a DT-114):
  1. Guía de Arduino IDE 2 y diagrama de conexiones (22–25 oct)
  2. Sensor, cálculo y pantalla (29 oct – 3 nov)
  3. Buzzer, botón, alarma corta y modo dormir (3–6 nov)
  4. Bluetooth en la placa (6–10 nov)
  5. App: conectar el dispositivo (9–13 nov)
  6. APK de Android (13–18 nov)
  7. Pruebas del programa (18–20 nov)
- **DT-6** (antes la historia "(no usar) CRFFG") se cambió a epic y se reabrió como **"Armado, pruebas y presentación"** (14–27 nov), con 4 tareas (DT-89 a DT-92) y 11 subtareas (DT-115 a DT-125):
  1. Armado final en la carcasa (14–16 nov)
  2. Pruebas reales al sol: calibración con Open-Meteo, duración de la batería, alcance del Bluetooth (17–21 nov)
  3. Correcciones finales (21–24 nov)
  4. Entregables: fotos, video, documento y presentación (23–27 nov)
- Del 28 de noviembre al 4 de diciembre queda como margen.
- Ya no queda ninguna tarea "(no usar)": las 5 epics del proyecto son Componentes Electrónicos, App, Carcasa, Programa del dispositivo y Armado, pruebas y presentación.

### Guía de Arduino IDE terminada — 2026-10-11
- DT-93 "Guía para instalar Arduino IDE 2, el soporte de la ESP32 y las librerías" se marcó como **Finalizada** (se adelantó; estaba para el 22–23 de octubre).

### Avance de las bases en Jira — 2026-10-12
- **DT-68** "Dejar listos los archivos de las bases e imprimirlas en la noche" → **Finalizada**, con un comentario: impresión de prueba del 12 de octubre (antes de lo previsto) y las 3 correcciones pendientes (pernos del sensor, salida del cable de la batería, hueco de los pines del buzzer).
- **DT-54** "2. Bases de los componentes" y **DT-63** "Base de la placa XIAO y su antena" → **En curso** (falta el lugar de la antena y la "barra").
- **DT-65** "Marco de la pantalla OLED" → **Finalizada** (se reutiliza la base de un proyecto anterior).
- A pedido del usuario: **DT-64** (base del sensor), **DT-66** (bases del buzzer, botón e interruptor) y **DT-67** (compartimento de la batería) → **Finalizada**. Las correcciones antes de la impresión definitiva siguen anotadas en `carcasa/MEDIDAS_BASES.md` (y en DT-68); la base del botón y el interruptor (en la pared de la carcasa) aún están pendientes.

### Avance de la carcasa y del programa en Jira — 2026-10-12
- **DT-59** "Descargar los modelos 3D de los componentes" → **Finalizada** (se usaron los modelos de la XIAO, el LTR390 de Adafruit, el buzzer y la batería dibujada como caja).
- **DT-53** "1. Modelos 3D y preparación" y la epic **DT-3 "Carcasa"** → **En curso** (las bases empezaron el 8 de octubre, antes de la fecha planeada del 25).
- **DT-82** "1. Guía de Arduino IDE 2 y diagrama de conexiones" y la epic **DT-4 "Programa del dispositivo"** → **En curso** (la guía ya está hecha; falta el diagrama).

### Pendientes del usuario y Arduino IDE en curso — 2026-10-12
- Arduino IDE 2 ya está **descargado**; falta instalar lo necesario para programar la XIAO (placas ESP32, librerías y verificar el programa de prueba). **DT-95** "Instalar Arduino IDE 2 y probar la placa con un programa de ejemplo" → **En curso**.
- Siguen pendientes: reimprimir las bases con las correcciones (DT-69), imprimir la pieza de prueba de tolerancias (DT-62) y comprar la lámina de PTFE y los tornillos M2 (DT-61).
- Por indicación del usuario, **las fechas del cronograma no se cambian** aunque se adelante trabajo: solo se marcan las tareas como "En curso".

### Bases reimpresas en Jira — 2026-10-12
- **DT-69** "Probar las bases, corregir y reimprimir (sábado)" → **Finalizada** (fechas sin cambiar). DT-54 sigue **En curso** porque falta DT-63 (antena y "barra" de la XIAO).

### Pieza de tolerancias imprimiéndose — 2026-10-12
- El usuario está imprimiendo la pieza de prueba de tolerancias. **DT-62** → **En curso** (fechas sin cambiar).

### Nueva epic de entregables — 2026-10-13
- Se creó la epic **DT-126 "Entregables y documentación"** para los documentos, mapas mentales, collages y demás materiales que hay que entregar. Por ahora sin tareas ni fechas.

### Primeros entregables — 2026-10-13
- En la epic DT-126 "Entregables y documentación" se agregaron **DT-127 "Entrega de Collage"** y **DT-128 "Entregar metodología"**, las dos con fecha del **9 de octubre**.
- DT-127 y DT-128 se marcaron como **Finalizadas** (ya se entregaron).

### Fechas importantes — 2026-10-13
- Nueva epic **DT-129 "Fechas importantes"**: cada entrega o evento es una tarea con inicio y fin el mismo día.
- Primera fecha: **DT-130 "Entrega de Avance de proyecto final con observaciones"** el **30 de octubre** (descripción: "Innovation Lab").
- Las demás fechas se agregan cuando el usuario las indique.

### Preparación del avance en el cronograma — 2026-10-13
- En la epic DT-126 "Entregables y documentación" se agregó **DT-131 "Preparar el avance del proyecto final"** (28–29 oct), para la entrega del 30 de octubre (DT-130), con 3 subtareas: fotos y capturas (DT-132, 28 oct), documento o presentación (DT-133, 28–29 oct) y revisar y ensayar (DT-134, 29 oct).

### Carcasa adelantada — 2026-10-13
- Como las bases ya se imprimieron y corrigieron, a pedido del usuario se adelantó el cronograma de la carcasa (DT-3 ahora va del **19 de octubre al 7 de noviembre**, antes hasta el 13). Las impresiones solo se hacen entre semana, porque la universidad no abre en domingo:
  - DT-55 Diseño de la carcasa: **19–22 oct** (acomodo 19–20, cuerpo y tapa 20–21, aberturas 21–22).
  - DT-56 Primera impresión: **23–27 oct** (imprimir el **viernes 23** en la noche, armar 24–26, lista de correcciones 26–27). Así el prototipo 1 llega al avance del 30 de octubre.
  - DT-57 Ajustes y segunda impresión: **31 oct – 4 nov** (corregir 31 oct – 1 nov, imprimir el lunes 2, probar 3–4).
  - DT-58 Carcasa final: **5–7 nov** (PTFE e impresión final el jueves 5, armado el 6, margen el sábado 7).
- DT-53 y DT-54 (preparación y bases) conservan sus fechas.

### Pendientes menores fuera de Jira — 2026-10-13
- Por decisión del usuario, los pendientes menores (base del botón e interruptor, "barra" de la XIAO, cables y termofit, soldar para las pruebas, pruebas con la ESP32-C6 prestada, nRF Connect) **no se agregan a Jira**: se llevan en la lista de pendientes de `ESTADO_PROYECTO.md`.

### Tareas renombradas por el cambio a VS Code — 2026-10-13
- **DT-82** → "1. Guía de programación (VS Code + PlatformIO) y diagrama de conexiones" y **DT-95** → "Instalar VS Code + PlatformIO y probar la placa con un programa de ejemplo" (fechas sin cambiar).

### Programa del sensor en curso — 2026-10-13
- **DT-96** "Leer el índice UV del sensor LTR390" → **En curso** (programa de prueba listo; fechas sin cambiar).

### Diagrama terminado — 2026-10-13
- **DT-94** "Diagrama de conexiones (XIAO ESP32C3)" → **Finalizada**; **DT-97** "Cálculo de la dosis igual que en la app" → **En curso** (falta correr las pruebas en la placa). Fechas sin cambiar.

### Programa del dispositivo en curso — 2026-10-13
- **En curso** (fechas sin cambiar): DT-83 y DT-84 con sus subtareas DT-98 (pantalla), DT-99 (alarma corta), DT-100 (botón), DT-101 (dormir), y DT-103 (guardar el perfil en la placa).

### Bluetooth de la placa en curso — 2026-10-13
- **En curso** (fechas sin cambiar): DT-85 "Bluetooth en la placa" y DT-102 "Canales Configuración, Estado y Órdenes".

### App conectada al dispositivo en curso — 2026-10-13
- **En curso** (fechas sin cambiar): DT-86 "App: conectar el dispositivo" con DT-105 (botón Conectar), DT-106 (datos de la placa y perfil) y DT-107 (botón sincronizado, Silenciar y Dormir). Falta probar con la placa real (DT-108).
