# Medidas de las bases de los componentes

Última actualización: 2026-10-12

Regla de los pernos: **diámetro del perno = agujero de la placa − 0.3** (más delgado = más holgado).

Todas las medidas en milímetros. Las medidas de las placas vienen de las hojas técnicas o de las páginas de venta: **comprobarlas con calibrador** cuando lleguen las piezas y ajustar las bases.

## Reglas comunes

| Qué | Medida |
|---|---|
| Holgura (espacio entre la placa y la pared, por lado) | 0.3 (comprobar con la pieza de prueba: 0.2 / 0.3 / 0.4) |
| Pared | 1.6 (4 líneas con boquilla de 0.4); en la XIAO es de 2.0 |
| Exterior = placa + 2 × (holgura + pared) | placa + 3.8 |

## Tabla de las bases

| Medida | XIAO ESP32C3 | Sensor LTR390 | Batería LiPo 103050 | Buzzer UNIT DevLab |
|---|---|---|---|---|
| Pieza (largo × ancho) | 21 × 17.8 | 25.4 × 17.78 | 50 × 30 (10 de grosor) | 23.88 × 10.16 |
| Hueco | 21.6 × 18.4 | 26.84 × 18.4 (0.72 de holgura en las puntas; posiblemente el modelo 3D usado es más largo que 25.4; sirve igual porque lo ubican los pernos) | 52 × 32 (1 de holgura por lado) | 24.5 × 10.8 |
| Exterior | hueco + 2 × 2.0 de pared | ~30.0 × 21.6 | 55.2 × 35.2 | 27.7 × 14.0 |
| Altura total | por confirmar | 3.0 | 7.2 | 3.0 |
| Profundidad del hueco | 2.5 desde arriba hasta donde se apoya la placa | 1.6 (placa al ras) | 6.0 | 1.6 (placa al ras) |
| Fondo | por confirmar | 1.4 | 1.2 | 1.4 |
| Cómo se apoya | 4 patas en las esquinas (mín. 2.5 × 2.5, todas iguales); sin pata central | Directo en el fondo | Directo en el fondo | Directo en el fondo |
| Espacio bajo la placa | 3.0 (patas; soldaduras de BAT+ y BAT−) | — | — | — |
| Fijación | "Barra" que se pone y se quita (pendiente) | 4 pernos de **2.2** de diámetro × 1.6 de alto (no 2.4: los agujeros de la placa miden 2.5) | Cinta doble cara espumosa o pestaña con espacio | 1 perno al centro de **2.7** (provisional; después: agujero medido − 0.3) × 1.6 de alto |
| Posición de los pernos | — | Centros a 3.26 y 2.85 de las paredes del hueco (centrados); separación 20.32 × 12.7 | — | Al centro del agujero de la placa (medir) |
| Hueco para cables | Ventanas abajo (y otra atrás, opcional) | 16.2 × 4.5, atraviesa el fondo, bajo la fila de 6 pines | Salida de 8 de ancho en un lado corto | 8 × 4, atraviesa el fondo, bajo los 3 pines |
| Detalles | Hueco del USB-C con 0.3 alrededor del conector; 1 de pared bajo el conector; no tapar BOOT, RESET ni la antena | Conectores blancos sobresalen ~3 arriba (hueco en la tapa); sensor al centro | No presionar; 1 de aire arriba; lejos de la XIAO y del sol | Sonido sale por el círculo con cruz: mirar a pared con 5–7 agujeros de 1.5–2, con 0.5–1 de aire |

La pantalla OLED usa la base de un proyecto anterior del usuario (no se anotan sus medidas aquí).

## Lo que hay que medir al recibir cada pieza

- **XIAO:** largo, ancho y grosor de la placa; tamaño del USB-C.
- **LTR390:** separación de los agujeros y grosor de la placa (en las copias puede cambiar).
- **Batería:** largo real (algunas 103050 miden 52–55 por el circuito de protección).
- **Buzzer:** diámetro del agujero central y distancia a la orilla, distancia de la fila de pines al extremo, altura del buzzer y grosor de la placa.

## Pendientes

**Corregir antes de imprimir las bases definitivas** (la primera impresión del 2026-10-12 sirve solo de prueba):
- **Sensor:** cambiar los agujeros de las esquinas por **4 pernos de 2.2 mm** de diámetro × 1.6 mm de alto.
- **Batería:** agregar la **salida del cable de 8 mm** de ancho en uno de los lados cortos (del lado donde quede la XIAO).
- **Buzzer:** agregar el **hueco de 8 × 4 mm** bajo los 3 pines, atravesando el fondo, en el extremo contrario al buzzer.

Otros pendientes:
- Base del **botón** (soporte por dentro + émbolo impreso).
- Lugar de la **antena** de la XIAO (pegada por dentro de una pared, lejos de la batería).
- **Interruptor:** va atornillado por dentro de una pared de la carcasa (ranura para la palanca + 2 agujeros M2); medir palanca y separación de agujeros.
- "Barra" para sujetar la XIAO por arriba.
