# _Open.prg – Análisis funcional (IDE Legacy HMG)

# Objetivo

`_Open()` es el núcleo del diseñador de formularios del IDE Legacy.

Su responsabilidad es:

* Abrir un archivo `.FMG`.
* Leer completamente su contenido.
* Interpretar el lenguaje FMG línea por línea.
* Reconstruir todos los objetos del formulario.
* Restaurar sus propiedades.
* Crear la ventana de diseño.
* Actualizar el Inspector de Propiedades.
* Preparar el formulario para su edición.

En términos modernos, `_Open()` combina el trabajo de:

* Loader
* Parser
* Object Factory
* Property Loader
* Designer Host

Todo en un único procedimiento.

---

# Firma

```text
PROCEDURE _Open( Arg )
```

## Parámetro

```text
Arg
```

Puede representar:

* nombre del archivo FMG
* ruta completa
* formulario a abrir desde el proyecto

---

# Variables locales

El procedimiento declara una enorme cantidad de variables.

Pueden clasificarse en grupos.

---

## 1. Variables del parser

Ejemplos

```text
Line
LineBuffer
NextToken
QuoteFlag
ClauseArgument
Code
LineCount
```

Responsabilidad:

* leer cada línea
* dividir tokens
* interpretar palabras clave

---

## 2. Estado del control actual

Ejemplos

```text
CurrentRow
CurrentCol
CurrentWidth
CurrentHeight
CurrentCaption
CurrentValue
CurrentPicture
CurrentFontName
CurrentFontSize
CurrentBackColor
CurrentFontColor
CurrentToolTip
```

Estas variables funcionan como un buffer temporal.

El parser carga todas las propiedades aquí y luego crea el control correspondiente.

---

## 3. Estado del formulario

Ejemplos

```text
WinRow
WinCol
Width
Height
VirtualWidth
VirtualHeight
WindowType
```

Representan la ventana actualmente abierta.

---

## 4. Estado del diseñador

Ejemplos

```text
Started
TimersLoaded
TabPageCount
CurrentMenuLevel
```

Controlan la reconstrucción del formulario.

---

## 5. Estado de componentes especiales

Existen buffers específicos para:

* Grid
* Browse
* Tree
* Toolbar
* Menu
* SplitBox
* NotifyMenu
* ContextMenu
* DropdownMenu
* StatusBar
* Timer
* Tab

Cada uno mantiene información temporal mientras el parser lee el FMG.

---

# Organización general

El procedimiento realiza aproximadamente estas etapas.

---

## 1. Inicialización

```text
InitControlCounters()
```

Reinicia los índices internos del diseñador.

---

## 2. Selección del archivo

Si no recibe un archivo:

```text
GetFile()
```

permite elegir un FMG.

---

## 3. Lectura

Utiliza

```text
HB_MEMOREAD()
```

para cargar el archivo completo en memoria.

No trabaja directamente sobre el disco.

---

## 4. Conversión

Divide el archivo en líneas utilizando:

* MlCount()
* MemoLine()

Esto produce un recorrido secuencial.

---

## 5. Parser

Esta es la parte más grande del procedimiento.

Cada línea es analizada para detectar instrucciones como:

```text
DEFINE WINDOW

DEFINE BUTTON

DEFINE GRID

DEFINE LABEL

DEFINE TAB

END WINDOW

END TAB

END GRID
```

Cada cláusula modifica el estado del objeto actual.

---

## 6. Buffer de propiedades

Antes de crear un control, todas las propiedades se almacenan en variables temporales.

Ejemplo

```text
CurrentRow

CurrentCaption

CurrentFontSize

CurrentVisible

CurrentToolTip
```

Cuando el parser encuentra el final de la definición, esas propiedades se transfieren al objeto del diseñador.

---

## 7. Creación de objetos

Los controles son creados dinámicamente.

Después se asignan propiedades mediante llamadas como:

```text
SetProperty()
```

---

## 8. Restauración

Una vez creados:

* posiciones
* tamaños
* colores
* fuentes
* eventos
* imágenes
* opciones

son restaurados desde el FMG.

---

## 9. Actualización del diseñador

Al finalizar:

* selecciona controles
* actualiza el Inspector
* refresca el formulario
* repinta la ventana

---

# Variables CurrentXXX

El diseño utiliza una enorme cantidad de variables llamadas

```text
Current...
```

Ejemplos

```text
CurrentCaption

CurrentWidth

CurrentHeight

CurrentValue

CurrentItems

CurrentHeaders

CurrentFields

CurrentPicture

CurrentFontName

CurrentFontSize

CurrentBackColor

CurrentVisible

CurrentHelpId

CurrentOnChange

CurrentOnGotFocus

CurrentOnLostFocus
```

Todas representan el estado del objeto que está siendo leído.

No pertenecen al control.

Son únicamente buffers del parser.

---

# Funciones importantes detectadas

Inicialización

```text
InitControlCounters()
```

---

Lectura

```text
HB_MEMOREAD()

MlCount()

MemoLine()
```

---

Conversión

```text
RemoveExtraSpaces()

StringToArray()
```

---

Propiedades

```text
SetProperty()

GetProperty()

GetControlIndex()
```

---

Selección

```text
SelectControl()
```

---

Redibujado

```text
RedrawWindow()
```

---

Actualización

```text
UpdateCombo()

UpdateDesignFormProperties()
```

---

Ventanas

```text
_IsWindowDefined()

IsWindowDefined()

DoMethod()
```

---

Persistencia

```text
Save()

QuerySave()
```

---

# Dependencias

El procedimiento depende de:

* Designer
* Property Inspector
* Control Factory
* Project
* FMG Parser
* Runtime HMG

Todo está fuertemente acoplado.

---

# Problemas de arquitectura

Desde una perspectiva moderna presenta varios inconvenientes.

## Parser y diseñador mezclados

El mismo procedimiento:

* interpreta texto
* crea objetos
* modifica la interfaz
* actualiza propiedades
* refresca la pantalla

Estas responsabilidades deberían estar separadas.

---

## Variables temporales

Más de un centenar de variables `CurrentXXX`.

Hoy sería preferible utilizar un objeto como:

```text
TControlDefinition
```

que concentre todas las propiedades del control.

---

## Acoplamiento

El parser conoce directamente:

* controles
* inspector
* ventana
* proyecto
* propiedades
* runtime

No existe separación entre modelo y vista.

---

## Escalabilidad

Agregar un nuevo control implica modificar `_Open()` directamente.

Una arquitectura basada en clases permitiría registrar nuevos controles sin alterar el parser principal.

---

# Propuesta de refactor

Separar `_Open()` en módulos especializados:

1. **FMGReader**

   * Lee el archivo.
   * Devuelve las líneas.

2. **FMGParser**

   * Convierte las líneas en objetos de definición.

3. **ControlFactory**

   * Instancia el tipo de control correspondiente.

4. **PropertyLoader**

   * Aplica las propiedades al control.

5. **DesignerSurface**

   * Gestiona la superficie de diseño, selección y edición.

6. **PropertyInspector**

   * Sincroniza las propiedades del objeto seleccionado.

7. **DesignerHost**

   * Coordina la apertura, carga y visualización del formulario.

Con esta división, el parser quedaría desacoplado de la interfaz gráfica y sería posible incorporar nuevos controles (por ejemplo, `ModernButton`, `ModernPanel`, `ModernFlyout` o `ModernWindow`) mediante un mecanismo de registro, sin modificar el código central del cargador.
