# Guía: probar los componentes con la ESP32-C6 prestada

Creada: 2026-10-14. Para probar **cada pieza por separado** con la ESP32-C6 (módulo **ESP32-C6-WROOM-1**) antes de que llegue la XIAO. Después se prueba el programa completo y el Bluetooth con la app.

Conexiones completas: `DIAGRAMA_CONEXIONES.md`. Cómo usar VS Code y PlatformIO: `GUIA_VSCODE_PLATFORMIO.md`.

---

## 0. Antes de empezar

**Llevar:** la ESP32-C6, cable USB-C **de datos**, sensor LTR390, pantalla OLED, buzzer, botón, protoboard y cables (jumpers), la computadora con VS Code.

**Revisar la placa:** debe tener **dos** conectores USB-C ("USB" y "UART") y los números **2, 3, 19, 22 y 23** impresos junto a sus pines. Si no los encuentras (algunas placas de otras marcas acomodan los pines distinto), toma una foto de la placa por los dos lados y mándasela a Claude antes de conectar nada: solo hay que cambiar `dispositivo/src/pines.h`.

**Reglas:**
- Conectar y desconectar cables **con la placa desconectada del USB**.
- Todo va a **3V3**, nunca a 5V.
- **No conectar la batería** (esta placa no tiene cargador).
- No usar los pines 4, 5, 8, 9 y 15.

---

## 1. Cargar el programa de prueba

1. En VS Code abre la carpeta `dispositivo`.
2. Abajo, clic en el entorno y elige **`env:prueba_componentes_esp32c6`**.
3. Conecta la placa por el puerto **"USB"**.
4. Clic en **→ (Upload)**. Si se queda en "Connecting....", usa el modo de carga (paso 7 de `GUIA_VSCODE_PLATFORMIO.md`).
5. Clic en **🔌 (Serial Monitor)**. Si no sale nada, presiona **RESET** en la placa.

Este programa sirve aunque falten piezas: dice cuáles responden y cuáles no. Puedes conectarlas **una por una** y presionar RESET cada vez.

---

## 2. Conectar y probar cada pieza

### a) Sensor UV y pantalla (comparten los 4 cables)
| Pieza | Pin de la ESP32-C6 |
|---|---|
| VIN / VCC | **3V3** |
| GND | **GND** |
| SDA | **23** |
| SCL | **22** |

✅ **Funciona si** el Serial Monitor dice `Encontrada en 0x53 <- sensor UV LTR390`, `Encontrada en 0x3C <- pantalla OLED`, `Pantalla OLED: OK` y `Sensor LTR390: OK`, y la pantalla muestra el índice UV.
- Adentro el UV debe estar cerca de **0**. Junto a una ventana o afuera debe subir (al mediodía en Puebla, entre 6 y 11).
- Si dice "Nada": revisa 3V3, GND y que **SDA y SCL no estén al revés**.

### b) Buzzer
| Buzzer | Pin de la ESP32-C6 |
|---|---|
| VCC (+) | **3V3** |
| Signal (S) | **19** |
| GND (−) | **GND** |

✅ **Funciona si** al presionar RESET suenan **dos pitidos cortos**.
- En el Serial Monitor escribe `a` + Enter: suena la melodía "hora de reaplicar". `l`: melodía "listo".
- Escribe `t`: suenan tonos de 500 a 4000 Hz. **Anota cuál se oye más fuerte** (sirve para ajustar las melodías).

### c) Botón
| Botón | Pin de la ESP32-C6 |
|---|---|
| Una pata | **2** |
| La otra pata | **GND** |

✅ **Funciona si** cada vez que lo presionas suena "listo" y la pantalla dice `Boton: 1 veces`, `2 veces`… (sube **de uno en uno**; si salta de 2 en 2, avisa a Claude).

### d) Dormir y despertar con el botón
1. Escribe `d` + Enter. La pantalla dice "Durmiendo..." y se apaga.
2. El Serial Monitor se desconecta (es normal: la placa está dormida).
3. Presiona el botón.

✅ **Funciona si** la placa se enciende sola, suenan los dos pitidos y la pantalla dice **`Desperto: OK`** (vuelve a abrir el Serial Monitor si hace falta: debe decir `Desperte con el boton`).

---

## 3. Programa completo

Con todas las piezas conectadas:
1. Elige **`env:demo_esp32c6`** (cada segundo cuenta como 1 minuto, para no esperar horas) → **Upload** → **Serial Monitor**.
2. Escribe `p` + Enter: muestra el perfil y la cuenta.
3. Si no hay sol, escribe `uv 8` + Enter (fija un UV de 8 a mano).
4. Espera: la barra avanza y en unos segundos sale **"HORA DE REAPLICAR"** con la melodía (~10 s).
5. Presiona el botón: se calla, suena "listo" y la cuenta empieza de cero.

Otras órdenes: `s` silenciar, `d` dormir, `r` "ya me reapliqué".

## 4. Bluetooth con la app

1. Con el programa completo cargado, abre la app en **Chrome** (computadora o Android): https://rodrigohuertaram.github.io/sensor_uv/
2. En la tarjeta **"Tu dispositivo"** toca **Conectar** y elige **"Sensor UV"**.
3. Comprueba:
   - La app muestra el UV que mide la placa y la pantalla muestra **"BT"** arriba.
   - Al cambiar el tipo de piel o el FPS en "Mi perfil", la pantalla de la placa cambia.
   - **"Ya me reapliqué"** en la app → la placa reinicia la cuenta. El botón de la placa → la app quita su alerta.
   - **Silenciar** y **Dormir** desde la app.
- Opcional: con **nRF Connect** en el celular se ve el dispositivo "Sensor UV" y sus tres canales.

---

## 5. Qué anotar para Claude

Copia esto y llénalo:

```
Placa: ESP32-C6 (¿dos USB-C? sí/no)
Sensor (0x53): OK / no
Pantalla (0x3C): OK / no
UV adentro: ___   UV afuera: ___ (hora: ___)
Buzzer: suena / no — tono más fuerte: ___ Hz — ¿volumen suficiente?: ___
Botón: cuenta de uno en uno: sí / no
Dormir y despertar con el botón: OK / no
Programa completo (demo): alerta, melodía y botón OK / no
Bluetooth con la app: conecta / no — qué falló: ___
```

Si algo falla, manda una foto de las conexiones y lo que dice el Serial Monitor.
