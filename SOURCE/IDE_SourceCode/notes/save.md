# Save.prg – Análisis funcional (IDE Legacy HMG)

# Objetivo

`Save()` es el serializador principal del diseñador.

Su responsabilidad es convertir el formulario actualmente cargado en memoria nuevamente al lenguaje FMG y escribir el archivo correspondiente.

En otras palabras:

```
Objetos del Diseñador
        │
        ▼
Serialización
        │
        ▼
Texto FMG
        │
        ▼
Archivo .FMG
```

Es la operación inversa de `_Open()`.

---

# Firma

```text
FUNCTION Save( lView )
```

## Parámetro

```
lView
```

Bandera utilizada durante el guardado.

No participa en la construcción del formulario.

---

# Variables locales

Se observan variables destinadas principalmente a la generación del código FMG.

## Buffer principal

```
Code
```

Es la variable más importante.

Todo el archivo FMG se construye concatenando texto sobre esta variable.

Finalmente será grabado en disco.

---

## Variables auxiliares

```
aTemp

i

j

k

idx

a

b

x

ImageFlag

PageMap

WindowType

RetVal
```

La mayoría se utilizan para recorrer controles, páginas de Tabs, imágenes y estructuras internas.

---

# Flujo general

## 1. Verificación del diseñador

Comprueba que exista una ventana de diseño.

```
IsWindowDefined()
```

Si no existe:

```
MsgStop()

RETURN NIL
```

---

## 2. Verificación del formulario

Comprueba que exista un formulario abierto.

```
OpenFormName
```

Si está vacío termina inmediatamente.

---

## 3. Obtener tipo de ventana

Lee

```
DesignForm + "WindowType"
```

Esto determina qué tipo de DEFINE WINDOW debe escribir.

Ejemplos:

```
STANDARD

MAIN

CHILD

PANEL
```

---

## 4. Crear encabezado

Comienza la construcción del FMG.

Inicialmente escribe algo similar a:

```
DEFINE WINDOW TEMPLATE
```

y luego agrega todas las propiedades.

---

## 5. Serialización de propiedades

Las propiedades se obtienen utilizando principalmente:

```
GetProperty()

__MVGET()
```

Ejemplos:

```
Row

Col

Width

Height

VirtualWidth

VirtualHeight

Title

Icon

Cursor

Visible

TopMost

AutoRelease

MaxButton

MinButton

SysMenu

TitleBar
```

---

## 6. Serialización de eventos

También escribe todos los eventos.

Ejemplos

```
ON INIT

ON RELEASE

ON SIZE

ON PAINT

ON MOUSEMOVE

ON MOUSECLICK

ON MAXIMIZE

ON MINIMIZE
```

---

## 7. Serialización de propiedades especiales

Entre otras:

```
BACKCOLOR

NOTIFYICON

NOTIFYTOOLTIP
```

y muchas otras dependiendo del tipo de control.

---

## 8. Recorrido de controles

Después de generar la ventana principal, el procedimiento recorre todos los controles existentes.

Cada control es convertido nuevamente a su definición FMG.

Ejemplo conceptual:

```
DEFINE BUTTON

DEFINE LABEL

DEFINE GRID

DEFINE TAB

DEFINE IMAGE

...
```

---

## 9. Cierre

Finaliza escribiendo

```
END WINDOW
```

y luego guarda el contenido generado.

---

# Variables globales utilizadas

Entre las más importantes aparecen:

```
DesignForm

OpenFormName

aMsgs
```

además de todas las propiedades almacenadas mediante

```
__MVGET()
```

---

# Funciones importantes detectadas

Obtención de propiedades

```
GetProperty()

__MVGET()
```

---

Ventanas

```
IsWindowDefined()
```

---

Mensajes

```
MsgStop()
```

---

Persistencia

(se observa posteriormente la escritura del archivo FMG)

---

# Modelo utilizado

La función no serializa directamente controles.

Hace algo diferente.

Consulta continuamente:

```
GetProperty()

__MVGET()
```

Esto indica que el diseñador mantiene un modelo interno de propiedades y Save() únicamente lo transforma en texto.

---

# Arquitectura observada

```
Designer Objects
        │
        ▼
Property System
        │
        ▼
Save()
        │
        ▼
FMG Text
        │
        ▼
Archivo
```

---

# Responsabilidades

✔ Verificar que exista un diseñador.

✔ Obtener todas las propiedades.

✔ Convertirlas al lenguaje FMG.

✔ Escribir el archivo.

No modifica el formulario.

No interpreta FMG.

No crea controles.

---

# Dependencias

Save() depende de:

* DesignForm
* Sistema de propiedades (`GetProperty` / `__MVGET`)
* Modelo interno del diseñador
* Sistema de escritura de archivos

---

# Relación con _Open()

Ambos procedimientos forman el núcleo del diseñador:

```
_Open()

FMG
 │
 ▼
Parser
 │
 ▼
Objetos del Diseñador

──────────────────────────

Save()

Objetos del Diseñador
 │
 ▼
Serializador
 │
 ▼
FMG
```

Uno reconstruye el formulario desde texto y el otro reconstruye el texto a partir del formulario.

---

# Problemas de arquitectura

## Serialización manual

El archivo se construye concatenando cadenas:

```
Code := Code + ...
```

Este enfoque dificulta el mantenimiento y la incorporación de nuevas propiedades.

---

## Conocimiento del formato

Save() conoce el lenguaje FMG en detalle.

Cada nuevo control obliga a modificar directamente este procedimiento.

---

## Acoplamiento

La función depende de:

* ventana
* propiedades
* controles
* modelo interno

No existe un serializador independiente.

---

# Propuesta de refactor

Separar el proceso en módulos especializados:

1. **FormSerializer**

   * Convierte el formulario completo a un documento intermedio.

2. **ControlSerializer**

   * Cada tipo de control sabe escribir sus propias propiedades.

3. **FMGWriter**

   * Genera el texto final con la sintaxis FMG.

La arquitectura quedaría:

```
Designer Model
        │
        ▼
FormSerializer
        │
        ├── WindowSerializer
        ├── ButtonSerializer
        ├── GridSerializer
        ├── TabSerializer
        ├── LabelSerializer
        └── ...

                │
                ▼

FMGWriter

                │
                ▼

Archivo .FMG
```

Con este enfoque, agregar un nuevo control moderno (por ejemplo `ModernButton` o `ModernFlyout`) requeriría únicamente implementar su serializador, sin modificar el motor principal de guardado.
