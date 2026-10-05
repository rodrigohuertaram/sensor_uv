# Historial de cambios — Sensor UV

Registro de todo lo que se ha hecho en la aplicación y en el dispositivo físico. Lo más reciente va arriba.

---

## 2026-10-04

### Selección de componentes del dispositivo (propuesta, aún sin comprar)

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

### Aviso médico en cada apertura
- El aviso médico ahora aparece cada vez que se abre la app, no solo la primera vez.
- Se quitó el guardado de "aviso aceptado", que ya no hace falta.

### Aviso médico
- Al abrir la app por primera vez aparece un aviso que se debe aceptar:
  - Los resultados son estimaciones estadísticas basadas en datos e investigación existente y pueden variar entre personas.
  - La app no sustituye una consulta médica; se recomienda acudir con un médico o dermatólogo para confirmar el tipo de piel y la información.
- Una vez aceptado, el aviso no vuelve a aparecer en ese dispositivo (se guarda en el navegador).
- Botón "Aviso médico" en la pantalla de inicio para volver a leerlo.
- Nota fija en "Mi perfil", junto al tipo de piel: elegirlo es una estimación y un dermatólogo puede confirmarlo.

### Publicación en GitHub
- App publicada en https://rodrigohuertaram.github.io/sensor_uv/ (repositorio: https://github.com/rodrigohuertaram/sensor_uv).
- Se preparó el proyecto para publicarse en GitHub Pages.
- Publicación automática: cada vez que se suben cambios a GitHub, la app se compila y se publica sola.
- Ajuste del manifiesto para que la app instalada funcione bien desde la dirección de GitHub.

### Versión web responsiva e instalable
- Diseño adaptable:
  - Celular: barra de navegación inferior.
  - Tablet y computadora: menú lateral, y las pantallas de Inicio y Mi perfil en dos columnas.
- Instalación en celular y computadora ("Agregar a inicio"):
  - Botón "Instalar app" que abre el aviso de instalación del navegador (Android, Chrome y Edge).
  - En iPhone, o navegadores sin ese aviso, el botón muestra los pasos para agregarla a inicio.
- Funciona sin internet una vez abierta (service worker).
- Icono nuevo (sol blanco sobre fondo naranja), nombre "Sensor UV" y colores de la app.
- Pantalla de carga naranja mientras la app arranca.

### Entorno de desarrollo
- Se verificó la licencia y los paquetes del SDK de Android.
- Se configuraron `ANDROID_HOME`, `ANDROID_SDK_ROOT` y `JAVA_HOME`, y se agregaron al PATH las herramientas de Android, Java y Flutter.

### Versión inicial
- App Flutter con el cálculo de cuándo reaplicar bloqueador según índice UV, tipo de piel, FPS, sudor o agua y resistencia al agua.
- Pantalla de inicio con índice UV, minutos restantes, botón "Ya me puse bloqueador" y alerta de reaplicar.
- Pantalla "Mi perfil" con los datos del usuario.
- El índice UV se simula con un control deslizante mientras no está conectado el sensor por Bluetooth.
