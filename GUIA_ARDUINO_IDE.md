# Guía de Arduino IDE 2 — Sensor UV

Creada: 2026-10-11

> **Nota (2026-10-13):** se decidió programar en **VS Code con PlatformIO** (ver `GUIA_VSCODE_PLATFORMIO.md`). Esta guía queda solo como alternativa. El programa de prueba ahora está en `dispositivo/src/main.cpp` (para abrirlo en Arduino IDE habría que copiarlo a un archivo `.ino`).

Pasos para dejar lista la computadora para programar la **Seeed Studio XIAO ESP32C3**.
La **Parte A** se puede hacer **desde ya**, sin la placa. La **Parte B** es para cuando llegue.

---

## Parte A — Sin la placa (se puede hacer ya)

### 1. Instalar Arduino IDE 2
1. Entra a **https://www.arduino.cc/en/software** y descarga **Arduino IDE 2** para **Windows** (el instalador `.exe`).
   - La página puede pedir una donación: elige **"Just Download"** (es gratis).
2. Abre el instalador y acepta las opciones normales.
3. Si Windows pregunta si quieres instalar **controladores (drivers)** de Arduino, acepta.
4. *(Opcional)* Para tenerlo en español: **File → Preferences → Language → Español** y reinicia el programa.

### 2. Agregar las placas ESP32 (de Espressif)
1. Abre **Archivo → Preferencias**.
2. En **"URLs adicionales del gestor de placas"** pega:
   ```
   https://espressif.github.io/arduino-esp32/package_esp32_index.json
   ```
3. Clic en **Aceptar**.
4. Abre el **Gestor de placas** (el segundo icono de la barra de la izquierda, o **Herramientas → Placa → Gestor de placas**).
5. Busca **esp32** e instala **"esp32" de Espressif Systems** (la versión más nueva).
   - Pesa varios cientos de MB; tarda unos minutos.
   - **No** instales "Arduino ESP32 Boards" (es otra cosa).

### 3. Elegir la placa
**Herramientas → Placa → esp32 → XIAO_ESP32C3**

En el mismo menú **Herramientas**, revisa que **"USB CDC On Boot"** esté en **"Enabled"**. Si no, el Monitor Serie no muestra nada.

### 4. Instalar las librerías
Abre el **Gestor de bibliotecas** (tercer icono de la barra de la izquierda, o **Herramientas → Gestionar bibliotecas**) e instala:

| Buscar | Instalar | Para qué |
|---|---|---|
| `Adafruit LTR390` | **Adafruit LTR390 Library** | Sensor UV |
| `Adafruit SSD1306` | **Adafruit SSD1306** | Pantalla OLED |

Cuando pregunte si quieres instalar también las **dependencias** (por ejemplo *Adafruit BusIO* y *Adafruit GFX Library*), elige **"Instalar todo"**.

El **Bluetooth** ya viene incluido con las placas ESP32; no hay que instalar nada.

### 5. Comprobar que compila (sin placa)
1. Abre el programa de prueba del proyecto: **Archivo → Abrir →** `dispositivo\prueba_xiao\prueba_xiao.ino` (dentro de la carpeta del proyecto `sensor_uv`).
2. Clic en **Verificar** (el botón ✓ de arriba a la izquierda).
3. Abajo debe aparecer algo como **"El sketch usa ... bytes"** sin errores en rojo.
   - La primera vez tarda más (1–3 minutos).

Si llegaste aquí, la computadora ya está lista. ✅

---

## Parte B — Cuando llegue la XIAO

### 6. Antes de conectar
- **Conecta la antena** al conector pequeño de la placa (presiona hasta que haga "clic"). La XIAO ESP32C3 **no debe usar Bluetooth sin la antena**.
- Usa un **cable USB-C de datos**. Muchos cables solo cargan; con esos la computadora no detecta la placa.

### 7. Cargar el programa de prueba
1. Conecta la XIAO a la computadora.
2. **Herramientas → Puerto →** elige el que aparezca nuevo (por ejemplo `COM5`). La XIAO ESP32C3 usa el USB del propio chip: **no necesita drivers extra**.
3. Clic en **Subir** (la flecha → junto al ✓).
4. Abre el **Monitor Serie** (lupa arriba a la derecha) y elige **115200 baudios**.
5. Debe aparecer cada segundo: `Funcionando. Segundos desde que encendi: ...`

### 8. Si no aparece el puerto o no deja subir el programa
Pon la placa en **modo de carga** a mano:
1. Mantén presionado el botón **B (BOOT)**.
2. Sin soltarlo, conecta el cable USB-C (o presiona y suelta **R (RESET)**).
3. Suelta **BOOT**.
4. Vuelve a elegir el puerto y clic en **Subir**.
5. Al terminar, presiona **RESET** una vez para que arranque el programa.

Otros problemas comunes:
| Problema | Solución |
|---|---|
| No aparece ningún puerto | Prueba otro cable USB-C (debe ser de datos) u otro puerto USB de la computadora |
| El Monitor Serie no muestra nada | Revisa **USB CDC On Boot → Enabled** y 115200 baudios; presiona RESET |
| "Failed to connect to ESP32" | Usa el modo de carga a mano (paso 8) |

---

## Lo que sigue
- **Diagrama de conexiones** (Jira DT-94).
- **Probar componentes** (Jira DT-5, 25–28 oct): programas de prueba para el sensor, la pantalla, el buzzer y el botón, uno por uno.
- Todo lo acordado para el programa final está en `PLAN_CODIGO_DISPOSITIVO.md`.
