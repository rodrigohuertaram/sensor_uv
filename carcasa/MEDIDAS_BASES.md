# Medidas de las bases de los componentes

Última actualización: 2026-10-12 (bases corregidas y reimpresas)

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
| Pieza (largo × ancho) | 21 × 17.8 | 25.4 × 17.78 | 50 × 30 (10 de grosor) | 23.88 × 10.16 (medido: 24 de largo) |
| Hueco | 21.6 × 18.4 | 26.84 × 18.4 (0.72 de holgura en las puntas; posiblemente el modelo 3D usado es más largo que 25.4; sirve igual porque lo ubican los pernos) | 52 × 32 (1 de holgura por lado) | **25.5** × 10.8 (2026-10-19: con 24.5 entraba justo; alargar 0.5 de cada extremo) |
| Exterior | hueco + 2 × 2.0 de pared | ~30.0 × 21.6 | 55.2 × 35.2 | 28.7 × 14.0 |
| Altura total | por confirmar | 3.0 | 7.2 | 3.0 |
| Profundidad del hueco | 2.5 desde arriba hasta donde se apoya la placa | 1.6 (placa al ras) | 6.0 | 1.6 (placa al ras) |
| Fondo | por confirmar | 1.4 | 1.2 | 1.4 |
| Cómo se apoya | 4 patas en las esquinas (mín. 2.5 × 2.5, todas iguales); sin pata central | Directo en el fondo | Directo en el fondo | Directo en el fondo |
| Espacio bajo la placa | 3.0 (patas; soldaduras de BAT+ y BAT−) | — | — | — |
| Fijación | "Barra" que se pone y se quita (pendiente) | 4 pernos de **2.5** de diámetro × 1.6 de alto (versión final 2026-10-20; antes 2.7 había quedado firme, la diferencia probablemente es de la impresión) | Cinta doble cara espumosa o pestaña con espacio | 1 perno al centro de **2.7** (provisional; después: agujero medido − 0.3) × 1.6 de alto |
| Posición de los pernos | — | Centros a 3.26 y 2.85 de las paredes del hueco (centrados); separación 20.32 × 12.7 | — | Al centro del agujero de la placa (medir) |
| Hueco para cables | Ventanas abajo (y otra atrás, opcional) | 16.2 × 4.5, atraviesa el fondo, bajo la fila de 6 pines | Ranura en "U" abierta arriba: 8 de ancho × 6 de alto (hasta el fondo), centrada en un lado corto (13.6 de cada orilla), del lado de la XIAO; esquinas de abajo con radio 1 | 8 × 4, atraviesa el fondo, bajo los 3 pines |
| Detalles | Hueco del USB-C con 0.3 alrededor del conector; 1 de pared bajo el conector; no tapar BOOT, RESET ni la antena | Conectores blancos sobresalen ~3 arriba (hueco en la tapa); sensor al centro | No presionar; 1 de aire arriba; lejos de la XIAO y del sol | Sonido sale por el círculo con cruz: mirar a pared con 5–7 agujeros de 1.5–2, con 0.5–1 de aire |

La pantalla OLED: base nueva del usuario (placa 26.7 × 26.6 + 0.3 por lado) con **pernos de 2.4** en los agujeros de las esquinas (comprobado 2026-10-14: queda firme).

XIAO: no tiene agujeros, así que no lleva pernos. Propuesta (2026-10-14): **puente** de 1–1.2 sobre el USB-C (0.2–0.3 de holgura) + **pestaña de presión** (1 de grueso, ≥5 de alto, ceja de 0.5) del lado de D8–D10; la "barra" queda de respaldo.

## Lo que hay que medir al recibir cada pieza

- **XIAO:** largo, ancho y grosor de la placa; tamaño del USB-C.
- **LTR390:** separación de los agujeros y grosor de la placa (en las copias puede cambiar).
- **Batería:** largo real (algunas 103050 miden 52–55 por el circuito de protección).
- **Buzzer:** diámetro del agujero central y distancia a la orilla, distancia de la fila de pines al extremo, altura del buzzer y grosor de la placa.

## Pendientes

~~Hacer las correcciones de las piezas y reimprimirlas~~ → **hecho 2026-10-12** el sensor y la batería: el usuario corrigió, reimprimió y midió las piezas con calibrador; quedaron bien. **Falta el buzzer.** Correcciones:
- **Sensor:** cambiar los agujeros de las esquinas por **4 pernos de 2.2 mm** de diámetro × 1.6 mm de alto.
- **Batería:** agregar la **salida del cable de 8 mm** de ancho en uno de los lados cortos (del lado donde quede la XIAO).
- **Buzzer (PENDIENTE, 2026-10-13):** agregar el **hueco de 8 × 4 mm** bajo los 3 pines, atravesando el fondo, en el extremo contrario al buzzer: 8 a lo ancho (1.4 de cada pared larga), 4 a lo largo (de 0.84 a 4.84 desde la pared del extremo).

**Por imprimir (2026-10-13):**
- **Reimprimir la carcasa** (anotado 2026-10-16) con estas modificaciones:
  1. ~~Agrandar el hueco del sensor~~ (hecho).
  2. ~~Hueco de la pantalla con los pernos directo en la carcasa~~ (hecho).
  3. **Agrandar hacia atrás unos 12–13 mm** para la batería (10 de batería + 1 de aire + 1.2 de repisa); por dentro al menos 52 × 32 en ese plano.
  4. **Acomodar la batería** acostada atrás, paralela a la cara de enfrente, con una **repisa** de 1.2 que la separe de la electrónica (con ranura para el cable) y el lado del cable hacia la XIAO.
  5. **Tapa de atrás deslizable**: rieles de 1 × 1.2 en las paredes laterales, tapa de 2 con 0.2–0.3 de holgura, tope en un extremo, que salga hacia abajo (no hacia el sensor); asegurarla con 1 tornillo M2 (agujero de 1.7 en un poste) o con un seguro giratorio que use un tornillo M2 como eje. No tapar el USB-C ni el interruptor.
- **Corregir la base de la OLED** (anotado 2026-10-19).
- **Pantalla OLED: checar los pernos dentro de la carcasa** (anotado 2026-10-19): que sean de **2.4 mm** (la medida que quedó firme), que coincidan con los agujeros de la pantalla y que no presionen el vidrio ni la cinta flexible.
  - **Cómo probarlo (idea del usuario, 2026-10-20):** "cortar" la carcasa en SolidWorks para dejar **solo la parte donde va la pantalla** (con sus pernos) e imprimir esa pieza de prueba, para no desperdiciar filamento ni tiempo. Si la pantalla entra bien, se aplican las mismas medidas a la carcasa completa.
- ~~Corregir y volver a imprimir la base del sensor~~ → **quedó bien (2026-10-20)** con pernos de **Ø2.5** (nota: antes había quedado firme con 2.7 y el diseño revisado tenía 2.6; la diferencia probablemente es de la impresión). Diseño: hueco 26.84 × 18.40, pernos a 3.22 y 2.81 de las paredes (separación ~20.40 × 12.78), hueco de pines 16.24 × 4.54.
- **Pieza de prueba de los pernos y tolerancias** (DT-62): placa de 50 × 20 × 3 con huecos de 10.4 / 10.6 / 10.8 (2 de profundidad) y pernos de Ø2.0 / 2.2 / 2.4 × 1.6; cubo de 10 × 10 × 3; placa de 1.6 de grueso con 3 agujeros de 2.5.
- ~~Base del buzzer corregida~~ → **quedó bien (2026-10-19)**: hueco alargado a **25.5 mm** (0.5 de cada extremo, para que el perno siga centrado) y hueco de los pines de **5 × 8 mm** (o 5.5 × 8) pegado a la pared del extremo.

Otros pendientes:
- Base del **botón** (soporte por dentro + émbolo impreso).
- Lugar de la **antena** de la XIAO (pegada por dentro de una pared, lejos de la batería).
- **Interruptor:** va atornillado por dentro de una pared de la carcasa (ranura para la palanca + 2 agujeros M2); medir palanca y separación de agujeros.
- "Barra" para sujetar la XIAO por arriba.
