# Base para la Seeed Studio XIAO ESP32C3 (soporte dentro de la carcasa).
#
# Genera:
#   base_xiao.FCStd  -> modelo de FreeCAD con la hoja "Medidas" (cambias un número
#                       y la pieza se actualiza sola al recalcular, Ctrl+R)
#   base_xiao.step   -> para abrir en SolidWorks o CATIA
#   base_xiao.stl    -> para imprimir
#
# Cómo correrlo (PowerShell, desde la carpeta del proyecto):
#   & "C:\Program Files\FreeCAD 1.1\bin\freecadcmd.exe" carcasa\base_xiao\generar_base_xiao.py
#
# Ejes: X = largo de la placa (el USB-C está en X = 0), Y = ancho, Z = altura.
# Todas las medidas en milímetros. Las marcadas "MEDIR" son de la hoja técnica y
# hay que comprobarlas con el calibrador cuando llegue la placa.

import os

import FreeCAD as App
import Import
import Part  # noqa: F401  (registra los objetos Part::)

MEDIDAS = [
    # (nombre, valor, descripción)
    # --- Placa XIAO ESP32C3 ---
    ("placa_largo", 21.0, "Largo de la placa, del USB-C al otro extremo (MEDIR)"),
    ("placa_ancho", 17.8, "Ancho de la placa (MEDIR)"),
    ("pcb_grosor", 1.0, "Grosor de la placa sin componentes (MEDIR)"),
    # --- Conector USB-C de la placa ---
    ("usb_ancho", 8.94, "Ancho del conector USB-C (MEDIR)"),
    ("usb_alto", 3.26, "Alto del conector USB-C (MEDIR)"),
    ("usb_elevacion", 0.0, "Distancia de la cara de arriba de la placa a la parte baja del conector (MEDIR)"),
    ("usb_desplazamiento_y", 0.0, "Corrimiento del conector respecto al centro del ancho (0 = centrado)"),
    # --- Impresión ---
    ("holgura", 0.3, "Espacio extra por lado para que entren las piezas (probar 0.2 a 0.4)"),
    # --- Base ---
    ("pared", 1.6, "Grosor de las paredes de los lados y de atrás"),
    ("pared_frontal", 1.0, "Grosor de la pared del USB-C (delgada para que entre el plástico del cable)"),
    ("suelo", 1.2, "Grosor del fondo"),
    ("hueco_inferior", 2.0, "Espacio bajo la placa para las soldaduras BAT+ y BAT- y sus cables"),
    ("repisa", 1.0, "Ancho del borde donde se apoya la placa"),
    ("borde_sobre_placa", 2.5, "Cuánto sube la pared por encima de la placa (abraza la parte baja del USB-C)"),
    ("ranura_ancho", 4.0, "Ancho de la ranura de atrás para los cables de la batería"),
    ("ranura_desplazamiento_y", 0.0, "Corrimiento de la ranura respecto al centro (0 = centrada)"),
]

# Cuánto se pasan los cortes de la pieza para que no queden capas de 0 mm.
EXTRA = 0.5

carpeta = os.path.dirname(os.path.abspath(__file__))
doc = App.newDocument("base_xiao")

# --- Hoja de medidas ---
hoja = doc.addObject("Spreadsheet::Sheet", "Medidas")
hoja.set("A1", "Medida")
hoja.set("B1", "Valor (mm)")
hoja.set("C1", "Descripción")
for fila, (nombre, valor, descripcion) in enumerate(MEDIDAS, start=2):
    hoja.set(f"A{fila}", nombre)
    hoja.set(f"B{fila}", str(valor))
    hoja.setAlias(f"B{fila}", nombre)
    hoja.set(f"C{fila}", descripcion)
hoja.setColumnWidth("A", 190)
hoja.setColumnWidth("C", 560)

# Medidas derivadas (fórmulas de la hoja, así también se actualizan solas).
derivadas = [
    ("interior_largo", "=placa_largo + 2 * holgura", "Largo del hueco de la placa"),
    ("interior_ancho", "=placa_ancho + 2 * holgura", "Ancho del hueco de la placa"),
    ("base_largo", "=pared_frontal + interior_largo + pared", "Largo total de la base"),
    ("base_ancho", "=2 * pared + interior_ancho", "Ancho total de la base"),
    ("altura_repisa", "=suelo + hueco_inferior", "Altura donde se apoya la placa"),
    ("base_alto", "=altura_repisa + pcb_grosor + borde_sobre_placa", "Alto total de la base"),
    ("usb_hueco_ancho", "=usb_ancho + 2 * holgura", "Ancho del hueco del USB-C"),
    ("usb_hueco_alto", "=usb_alto + 2 * holgura", "Alto del hueco del USB-C"),
    ("usb_centro_y", "=pared + interior_ancho / 2 + usb_desplazamiento_y", "Centro del USB-C (Y)"),
    ("usb_centro_z", "=altura_repisa + pcb_grosor + usb_elevacion + usb_alto / 2", "Centro del USB-C (Z)"),
]
inicio = len(MEDIDAS) + 3
hoja.set(f"A{inicio}", "Calculadas (no cambiar)")
for fila, (nombre, formula, descripcion) in enumerate(derivadas, start=inicio + 1):
    hoja.set(f"A{fila}", nombre)
    hoja.set(f"B{fila}", formula)
    hoja.setAlias(f"B{fila}", nombre)
    hoja.set(f"C{fila}", descripcion)
doc.recompute()


def caja(nombre, largo, ancho, alto, x, y, z):
    """Part::Box cuyas medidas y posición son fórmulas de la hoja."""
    obj = doc.addObject("Part::Box", nombre)
    for propiedad, expresion in (
        ("Length", largo), ("Width", ancho), ("Height", alto),
        ("Placement.Base.x", x), ("Placement.Base.y", y), ("Placement.Base.z", z),
    ):
        obj.setExpression(propiedad, expresion)
    return obj


def cilindro_x(nombre, radio, largo, x, y, z):
    """Part::Cylinder acostado a lo largo de X."""
    obj = doc.addObject("Part::Cylinder", nombre)
    obj.Placement.Rotation = App.Rotation(App.Vector(0, 1, 0), 90)
    for propiedad, expresion in (
        ("Radius", radio), ("Height", largo),
        ("Placement.Base.x", x), ("Placement.Base.y", y), ("Placement.Base.z", z),
    ):
        obj.setExpression(propiedad, expresion)
    return obj


m = "Medidas."
e = str(EXTRA)

cuerpo = caja("Cuerpo", m + "base_largo", m + "base_ancho", m + "base_alto", "0", "0", "0")

# Hueco donde entra la placa (desde la repisa hasta arriba).
hueco_placa = caja(
    "HuecoPlaca", m + "interior_largo", m + "interior_ancho",
    f"{m}pcb_grosor + {m}borde_sobre_placa + {e}",
    m + "pared_frontal", m + "pared", m + "altura_repisa",
)

# Espacio bajo la placa para las soldaduras de la batería.
hueco_inferior = caja(
    "HuecoInferior",
    f"{m}interior_largo - 2 * {m}repisa", f"{m}interior_ancho - 2 * {m}repisa",
    f"{m}hueco_inferior + 0.01",
    f"{m}pared_frontal + {m}repisa", f"{m}pared + {m}repisa", m + "suelo",
)

# Hueco del USB-C: forma de "U" (extremos redondos) abierta hacia arriba.
largo_usb = f"{m}pared_frontal + {m}holgura + 2 * {e}"
x_usb = f"-{e}"
radio_usb = f"{m}usb_hueco_alto / 2"
usb_centro = caja(
    "UsbCentro", largo_usb, f"{m}usb_hueco_ancho - {m}usb_hueco_alto", m + "usb_hueco_alto",
    x_usb, f"{m}usb_centro_y - ({m}usb_hueco_ancho - {m}usb_hueco_alto) / 2",
    f"{m}usb_centro_z - {m}usb_hueco_alto / 2",
)
usb_izq = cilindro_x(
    "UsbLadoIzq", radio_usb, largo_usb, x_usb,
    f"{m}usb_centro_y - ({m}usb_hueco_ancho - {m}usb_hueco_alto) / 2", m + "usb_centro_z",
)
usb_der = cilindro_x(
    "UsbLadoDer", radio_usb, largo_usb, x_usb,
    f"{m}usb_centro_y + ({m}usb_hueco_ancho - {m}usb_hueco_alto) / 2", m + "usb_centro_z",
)
usb_arriba = caja(
    "UsbAbierto", largo_usb, m + "usb_hueco_ancho", f"({m}base_alto > {m}usb_centro_z ? {m}base_alto - {m}usb_centro_z : 0) + {e}",
    x_usb, f"{m}usb_centro_y - {m}usb_hueco_ancho / 2", m + "usb_centro_z",
)

# Ranura de atrás para que salgan los cables de la batería por debajo de la placa.
ranura = caja(
    "RanuraCables", f"{m}pared + {m}repisa + 2 * {e}", m + "ranura_ancho",
    f"{m}base_alto - {m}suelo + {e}",
    f"{m}base_largo - {m}pared - {m}repisa - {e}",
    f"{m}pared + {m}interior_ancho / 2 + {m}ranura_desplazamiento_y - {m}ranura_ancho / 2",
    m + "suelo",
)

cortes = doc.addObject("Part::MultiFuse", "Cortes")
cortes.Shapes = [hueco_placa, hueco_inferior, usb_centro, usb_izq, usb_der, usb_arriba, ranura]
base = doc.addObject("Part::Cut", "BaseXiao")
base.Base = cuerpo
base.Tool = cortes
doc.recompute()

forma = base.Shape
if forma.isNull() or not forma.isValid() or len(forma.Solids) != 1:
    raise RuntimeError("La base no salió como una sola pieza válida; revisa las medidas.")

doc.saveAs(os.path.join(carpeta, "base_xiao.FCStd"))
Import.export([base], os.path.join(carpeta, "base_xiao.step"))
forma.exportStl(os.path.join(carpeta, "base_xiao.stl"))

caja_limite = forma.BoundBox
print(f"Base generada: {caja_limite.XLength:.2f} x {caja_limite.YLength:.2f} x {caja_limite.ZLength:.2f} mm, "
      f"volumen {forma.Volume:.0f} mm3")
