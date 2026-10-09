# Plan de código del dispositivo — Sensor UV

Creado: 2026-10-07

Todo lo acordado para programar **cuando lleguen los componentes**: el programa de la placa (firmware), los cambios en la app y la app nativa de Android (APK). **No se empieza a programar hasta tener la placa.**

Cuando se acuerde algo nuevo para el código, se agrega aquí (con su fecha) además de en `HISTORIAL.md`.

Documentos relacionados: `ESTADO_PROYECTO.md` (estado general), `HISTORIAL.md` (sección 5 "Cómo va a funcionar el dispositivo"), `PENDIENTES_ANDROID.md` (app nativa).

---

## 1. Decisiones de base

| Tema | Decisión | Fecha |
|---|---|---|
| Quién calcula | **La placa es el cerebro**: mide, calcula y avisa aunque el celular no esté. La app configura y muestra. | 2026-10-07 |
| Cuándo se programa | Cuando llegue la placa (AliExpress, 10–25 oct). | 2026-10-07 |
| App de Android | **APK gratis, sin Play Store**, compilado en GitHub Actions; se hace junto con el código del dispositivo. | 2026-10-07 |
| iPhone | App web dentro de **Bluefy** (Web Bluetooth), gratis. | 2026-10-05 |
| Entorno | Arduino IDE 2 con el soporte de placas ESP32 de Espressif. | 2026-10-05 |
| Placas | Objetivo: **Seeed XIAO ESP32C3**. Pruebas en mesa: **ESP32-C6 DevKit** (el usuario la tiene). El código debe funcionar en las dos. | 2026-10-06 |

## 2. Componentes

- Placa Seeed Studio XIAO ESP32C3 (con antena externa, siempre conectada).
- Sensor UV **LTR390** (I2C).
- Pantalla **OLED 0.96" 128×64 SSD1306 I2C**, 4 pines, blanca.
- Buzzer **Módulo Zumbador Pasivo 80 dB – UNIT DevLab** (VCC / Signal / GND, trae transistor; se le pueden tocar melodías).
- **Botón** pulsador de 2 patas ("Ya me reapliqué" / despertar).
- **Interruptor deslizable SPDT** en la línea de la batería (apagado total).
- Batería **LiPo 3.7 V 1500 mAh 103050** (protegida, JST PH 2 mm) a BAT+/BAT− de la XIAO.

**Pines propuestos para la XIAO ESP32C3 (se confirman en el diagrama de conexiones):**
- I2C compartido por sensor y pantalla: **SDA = D4 (GPIO6)**, **SCL = D5 (GPIO7)**, 3V3 y GND.
- **Botón: D1 (GPIO3)** a GND con resistencia interna (pull-up). Debe ir en GPIO0–GPIO5, porque solo esos pines pueden despertar a la ESP32-C3 del sueño profundo.
- **Buzzer: D3 (GPIO5)** (señal PWM).
- Reservado para medir la batería (mejora a futuro): **D2 (GPIO4)** con divisor de 2 × 220 kΩ (debe ser un pin que lea voltaje con el ADC1: D0, D1 o D2).
- **No usar los pines de las 4 esquinas** (D0, 5V, D6 y D7): las patas de la base de la XIAO quedan debajo (cambio del 2026-10-08; antes el buzzer iba en D2 y la batería en D0). D0 (GPIO2), D8 (GPIO8) y D9 (GPIO9) además son pines de arranque de la ESP32-C3 y conviene dejarlos libres.

## 3. Cálculo (idéntico a `lib/modelo.dart`)

- DEM por tipo de piel: `[0, 200, 250, 350, 450, 600, 1000]` J/m² (índice = tipo 1–6).
- `limiteDosis = dem[tipo] * fps * 0.3 * 0.6` (factor de aplicación 0.3 y margen de seguridad 0.6).
- Tope de tiempo: **120 min**; con sudor o agua: **80 min** si la resistencia al agua es ≥ 80, si no **40 min**.
- Cada segundo: `uvEfectivo = uvSensor * factorLugar`; si `uvEfectivo >= 1`, `dosis += 0.025 * uvEfectivo * dt` (dt en segundos).
- Toca reaplicar cuando `dosis >= limiteDosis` o cuando se llega al tope de tiempo.
- **Factor de lugar** (sí se aplica, porque el sensor apunta hacia arriba y no mide el reflejo del suelo): ciudad 1.0, parque 1.0, agua 1.1, playa 1.25, nieve 1.8.
- **Nubes: NO se aplican** en la placa; el sensor ya mide el UV que pasa entre las nubes.
- Índice UV del LTR390: con la fórmula del fabricante (datasheet: ganancia 18×, resolución 20 bits, sensibilidad 2300 cuentas por punto de índice UV). Verificar contra la librería y el datasheet al programar; después, calibrar con la ventana de PTFE (ver Mejoras a futuro).
- Si se cambian estas constantes, **cambiar también `lib/modelo.dart`** (y al revés).

## 4. Comportamiento del dispositivo

### Datos del usuario
- La app envía los datos del **perfil activo**: nombre, tipo de piel, FPS, resistencia al agua, sudor o agua y lugar.
- La placa los **guarda en su memoria** (sobreviven a apagarla) y los usa sin el celular.
- La placa guarda **solo el perfil activo**; los perfiles con nombre viven en el celular.
- **Cambio de perfil** con el dispositivo conectado → la placa recibe el nuevo perfil y **la cuenta empieza desde cero**. Si se cambia sin conexión, se envía al reconectar.
- La pantalla muestra el perfil activo (por ejemplo "Rodrigo · FPS 50").

### Pantalla OLED
- Normal: índice UV medido, minutos restantes o barra de avance, perfil activo.
- Al tocar reaplicar: alerta grande "Hora de reaplicar".

### Botón "Ya me reapliqué" (sincronizado)
- En el **dispositivo**: calla el buzzer, quita la alerta, reinicia la cuenta y avisa a la app (que quita su alerta).
- En el **celular**: la app manda la orden → la placa calla el buzzer, quita la alerta y reinicia la cuenta.
- Si la app web estaba congelada (pantalla apagada), al abrirla lee el estado y se pone al día.

### Para que no suene todo el día (opciones 1–3 aprobadas)
1. **Alarma corta:** al tocar reaplicar, el buzzer suena **~10 s** y se calla. Si no se presiona el botón, lo **recuerda cada 10 min, máximo 3 veces**; después solo queda la alerta en la pantalla.
2. **Se duerme sola sin sol:** si el sensor no detecta sol durante **30 min**, la placa entra en **sueño profundo** (pantalla, buzzer y Bluetooth apagados). **Despierta con el botón.**
3. **Desde la app:**
   - **"Silenciar"**: calla el buzzer **sin** reiniciar la cuenta.
   - **"Dormir dispositivo"**: la placa entra en sueño profundo. **No se puede despertar desde la app** (el Bluetooth queda apagado para ahorrar batería); se despierta con el botón del dispositivo.
- **Apagado total:** con el interruptor deslizable.
- **Descartado:** que la placa se apague sola al perder la conexión con el celular (dejaría de avisar justo cuando el celular está lejos) y la opción "Usar el dispositivo solo con el celular".

### Sonidos
- Melodías cortas y agradables con el buzzer pasivo (no un pitido fijo): una para "hora de reaplicar", otra corta de confirmación al presionar el botón.

## 5. Bluetooth (BLE)

Un servicio propio con tres canales:

| Canal | Sentido | Contenido |
|---|---|---|
| **Configuración** | app → placa | nombre del perfil, tipo de piel, FPS, resistencia al agua, sudor o agua, lugar |
| **Estado** | placa → app (cada segundo) | UV medido, avance (%), minutos restantes, toca reaplicar (sí/no), batería (cuando exista) |
| **Órdenes** | ambos sentidos | "ya me reapliqué", "silenciar", "dormir" |

- Nombre del dispositivo al buscarlo: "Sensor UV".
- Debe funcionar con Web Bluetooth (Chrome en Android y computadora; Bluefy en iPhone) y con el APK.

## 6. Cambios en la app

### App web (Flutter, la actual)
- Botón **"Conectar dispositivo"** (Web Bluetooth). Con el dispositivo conectado, la app **muestra lo que manda la placa** en lugar de calcular por su cuenta.
- Con el dispositivo conectado: **ocultar el cielo manual** y no usar "UV de tu zona" para el cálculo (el clima puede seguir mostrándose como información). El **lugar** sí se envía.
- Al cambiar de perfil o de datos del perfil: enviarlos a la placa.
- Botones **"Silenciar"** y **"Dormir dispositivo"**.
- Botón "Ya me reapliqué" sincronizado con el del dispositivo.
- Sin dispositivo, la app sigue funcionando sola como hoy (simulador o UV de tu zona).

### App nativa de Android (APK)
- Todo lo de `PENDIENTES_ANDROID.md`: segundo plano, conexión BLE con la pantalla apagada y reconexión automática, notificaciones "Hora de reaplicar", guardado de perfiles, ubicación nativa, icono y nombre "Sensor UV".
- **APK gratis compilado en GitHub Actions** (sin Play Store), con instrucciones de instalación.

## 7. Orden sugerido de trabajo (cuando lleguen los componentes)

1. Guía de Arduino IDE 2 (soporte ESP32 y librerías de LTR390, SSD1306 y BLE).
2. Diagrama de conexiones (XIAO ESP32C3 y ESP32-C6 DevKit).
3. Probar cada componente por separado (Jira DT-5, 21–24 oct): sensor, pantalla, buzzer, botón.
4. Programa de la placa: cálculo + pantalla + buzzer + botón + sueño.
5. Bluetooth en la placa.
6. "Conectar dispositivo" en la app web.
7. APK de Android.
8. Carcasa (PLA, ventana PTFE).

## 8. Ideas a futuro relacionadas (no se programan por ahora)

Ver `HISTORIAL.md` sección 6: nivel de batería (divisor en D2), ahorro de batería extra (apagar la pantalla tras unos segundos), calibración del sensor con Open-Meteo, vibración, actualización sin cable, historial de exposición, carga solar.
