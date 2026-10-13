# Guía para programar la placa en VS Code (PlatformIO) — Sensor UV

Creada: 2026-10-13

Esta es la forma **elegida** para programar el dispositivo (reemplaza a `GUIA_ARDUINO_IDE.md`, que queda solo como alternativa).
Sirve para la **XIAO ESP32C3** (placa final) y para la **ESP32-C6 DevKit** prestada.

**Ventaja:** con PlatformIO, Claude puede compilar y cargar el programa desde la terminal con la placa conectada a la computadora, y leer los mensajes de la placa.

---

## Dónde está el código

El programa de la placa vive en el **mismo repositorio** que la app, pero en su **propia carpeta**:

```
sensor_uv/
├── lib/            ← app (Flutter / Dart)
├── web/            ← app web
├── dispositivo/    ← programa de la placa (C++ / Arduino)
│   ├── platformio.ini   ← configuración: placas y librerías
│   └── src/main.cpp     ← el programa
└── ...
```

Son lenguajes distintos (la app en Dart, la placa en C++) y se compilan por separado, así que **no** pueden ir en el mismo archivo. Tenerlos en el mismo repositorio mantiene todo junto en GitHub y en el historial.

---

## Parte A — Sin la placa (se puede hacer ya)

### 1. Instalar la extensión PlatformIO
1. Abre **VS Code**.
2. En la barra de la izquierda, clic en **Extensiones** (el icono de cuadritos) o `Ctrl + Shift + X`.
3. Busca **`PlatformIO IDE`** e instala la que es de **PlatformIO** (icono de cabeza de hormiga).
4. Espera: la primera vez descarga sus herramientas (abajo a la derecha aparece "Installing PlatformIO Core"). Puede tardar varios minutos.
5. Cuando termine, pide **reiniciar VS Code** ("Reload Now"): acepta.
6. Debe aparecer el icono de PlatformIO (la hormiga) en la barra de la izquierda.

Si Windows pregunta por permisos del firewall, acepta.

### 2. Abrir el proyecto de la placa
1. **Archivo → Abrir carpeta…**
2. Elige **`C:\Innovacion_Frugal\App\sensor_uv\dispositivo`** (la carpeta `dispositivo`, **no** toda la carpeta `sensor_uv`).
3. Si VS Code pregunta si confías en los autores de la carpeta, elige **"Sí, confío"**.
4. PlatformIO lee `platformio.ini` y empieza a descargar lo necesario para las placas ESP32 y las librerías (Adafruit LTR390, Adafruit SSD1306 y Adafruit GFX). **La primera vez tarda bastante** (varios cientos de MB); mira el avance abajo a la derecha.

Las librerías se instalan **solas**: no hay que buscarlas a mano.

### Entornos (placas) que se pueden elegir
| Entorno | Para qué |
|---|---|
| `xiao_esp32c3` | Programa del dispositivo en la XIAO (la placa final) |
| `esp32c6` | Programa del dispositivo en la ESP32-C6 prestada |
| `demo_xiao_esp32c3`, `demo_esp32c6` | Igual, pero cada segundo cuenta como 1 minuto (para probar la alarma rápido o presentar) |
| `prueba_sensor_xiao`, `prueba_sensor_esp32c6` | Programa aparte que solo prueba el sensor UV y la pantalla |

### 3. Conocer la barra de abajo
En la barra azul de abajo aparecen los botones de PlatformIO:

| Icono | Qué hace |
|---|---|
| ✓ | **Build**: compilar (revisar que el programa no tenga errores) |
| → | **Upload**: cargar el programa a la placa |
| 🔌 | **Serial Monitor**: ver los mensajes de la placa |
| `env:xiao_esp32c3` | **Elegir la placa**: clic para cambiar entre `xiao_esp32c3` y `esp32c6` |

### 4. Comprobar que compila (sin placa)
1. Abajo, revisa que diga **`env:xiao_esp32c3`**.
2. Clic en **✓ (Build)**.
3. Se abre una terminal; al final debe decir **`SUCCESS`** en verde.
4. Cambia a **`env:esp32c6`** y repite ✓: también debe decir **`SUCCESS`**.

Si llegaste aquí, la computadora está lista. ✅ Si sale `FAILED` o texto en rojo, mándale una captura a Claude.

---

## Parte B — Con la placa

### 5. ESP32-C6 DevKit (prestada)
1. Conecta el cable USB-C al puerto que dice **"USB"** (no al que dice "UART" o "COM").
2. Abajo elige **`env:esp32c6`**.
3. Clic en **→ (Upload)**. PlatformIO encuentra el puerto solo.
4. Clic en **🔌 (Serial Monitor)**: debe aparecer cada segundo `Funcionando. Segundos desde que encendi: ...`

### 6. XIAO ESP32C3 (la final)
1. **Conecta la antena** (presiona hasta que haga "clic"). No usar Bluetooth sin antena.
2. Usa un **cable USB-C de datos** (muchos cables solo cargan).
3. Abajo elige **`env:xiao_esp32c3`**.
4. **→ (Upload)** y luego **🔌 (Serial Monitor)**.

### 7. Si no deja cargar el programa
Pon la placa en **modo de carga** a mano:
1. Mantén presionado **BOOT** (en la XIAO es el botón **B**).
2. Sin soltarlo, conecta el cable (o presiona y suelta **RESET**, en la XIAO el botón **R**).
3. Suelta **BOOT** y vuelve a dar **→ (Upload)**.
4. Al terminar, presiona **RESET** una vez.

| Problema | Solución |
|---|---|
| "No serial port found" / no encuentra la placa | Otro cable USB-C (de datos) u otro puerto de la computadora; modo de carga (paso 7) |
| El Serial Monitor no muestra nada | Presiona RESET; en la C6, revisa que estés en el puerto "USB" |
| Se queda en "Connecting...." | Modo de carga (paso 7) |

---

## Para Claude (compilar y cargar desde la terminal)
- **Ejecutar `pio` desde PowerShell, nunca desde Git Bash:** las herramientas de Espressif (`idf_tools.py`) fallan con "MSys/Mingw is not supported" y el compilador `riscv32-esp-elf-g++` queda instalado vacío. Si pasa, borrar `%USERPROFILE%\.platformio\packages\toolchain-riscv32-esp` (y `tool-esptoolpy`, `tool-riscv32-esp-elf-gdb`) y compilar otra vez desde PowerShell.
- Comprobado el 2026-10-13: el programa de prueba compila para `xiao_esp32c3` (RAM 4.3 %, Flash 23.6 %) y `esp32c6`.
- PlatformIO queda en `%USERPROFILE%\.platformio\penv\Scripts\pio.exe`.
- Compilar: `pio run -d dispositivo -e xiao_esp32c3` (o `-e esp32c6`).
- Cargar: `pio run -d dispositivo -e <placa> -t upload`.
- Mensajes de la placa: `pio device monitor -d dispositivo -e <placa>`.
- Los pines de cada placa se definirán al inicio del programa (o por placa en `platformio.ini`), para pasar de la ESP32-C6 a la XIAO cambiando solo la placa.
