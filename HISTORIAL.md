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

---

## 4. Publicación y documentación

### Publicación en GitHub — 2026-10-04
- App publicada en https://rodrigohuertaram.github.io/sensor_uv/ (repositorio: https://github.com/rodrigohuertaram/sensor_uv).
- Publicación automática: cada vez que se suben cambios a GitHub, la app se compila y se publica sola.
- Ajuste del manifiesto para que la app instalada funcione bien desde la dirección de GitHub.

### Lista de pendientes para la app nativa de Android — 2026-10-05
- Nuevo documento `PENDIENTES_ANDROID.md` con todo lo que habrá que adaptar o agregar en la app nativa de Android (segundo plano, ubicación, guardado de perfiles, avisos, Bluetooth, icono y nombre). Se actualiza con cada cambio.

### Estado del proyecto — 2026-10-07
- Nuevo documento `ESTADO_PROYECTO.md` para retomar el proyecto sin perder contexto: objetivo, qué funciona y qué falta, estructura de archivos y funciones, decisiones (incluido lo descartado), reglas de trabajo, cómo correr y probar, problemas resueltos y pendientes en orden.

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
