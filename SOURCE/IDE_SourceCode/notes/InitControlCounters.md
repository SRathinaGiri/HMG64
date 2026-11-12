# InitControlCounters() – Análisis funcional (IDE Legacy HMG)

# Objetivo

`InitControlCounters()` reinicia todos los contadores internos utilizados por el diseñador de formularios.

Estos contadores permiten asignar nombres automáticos a los controles creados durante la edición de un formulario.

Ejemplo:


Button_1
Button_2
Button_3

Label_1
Label_2

Grid_1


No crea controles.

No modifica el formulario.

No carga archivos.

Su única responsabilidad es inicializar el estado de numeración del diseñador.

---

# Firma


PROCEDURE InitControlCounters()


No recibe parámetros.

No devuelve valores.

---

# Variables utilizadas

La función trabaja exclusivamente con variables globales.

Cada una representa el contador de un tipo de control.

---

## Controles de datos


BrowseCount
TreeCount
GridCount
ListBoxCount
ComboBoxCount


---

## Controles de entrada


TextBoxCount
EditBoxCount
SpinnerCount
DatePickerCount
IpAddressCount


---

## Controles visuales


ButtonCount
CheckButtonCount
LabelCount
FrameCount
ImageCount
AnimateCount
HyperLinkCount


---

## Controles especiales


PlayerCount
ProgressBarCount
SliderCount
MonthCalendarCount
RichEditCount
TimerCount
ActiveXCount


---

## Controles de selección


CheckBoxCount
RadioGroupCount


---

## Estado del diseñador

Además aparece:


CurrentControl


Este valor se reinicia a:


0


Indicando que inicialmente no existe ningún control seleccionado.

---

# Flujo

La función es extremadamente simple.


Contador := 0


para cada tipo de control.

No existe ninguna otra lógica.

---

# Funciones llamadas

Ninguna.

---

# Dependencias

Ninguna.

Únicamente modifica variables globales.

---

# Responsabilidad

✔ Reiniciar la numeración automática.

✔ Reiniciar el control actualmente seleccionado.

Nada más.

---

# Observaciones de diseño

El IDE Legacy mantiene un contador independiente para cada tipo de control.

Ejemplo:


ButtonCount

LabelCount

GridCount

TreeCount

ImageCount


Cuando el usuario inserta un nuevo control, el diseñador probablemente realiza una operación equivalente a:


ButtonCount++

Nombre = "Button_" + HB_NTOS(ButtonCount)


Esto explica por qué los nombres generados automáticamente son secuenciales por categoría.

---

# Problemas de arquitectura

## Variables globales

El diseñador depende de más de veinte variables globales.

Cada vez que aparece un nuevo tipo de control es necesario:

* declarar una nueva variable
* inicializarla aquí
* modificar el generador de nombres

El sistema no es extensible.

---

## Sin metadatos

Toda la información está distribuida en variables independientes.

No existe una colección que describa los tipos de controles disponibles.

---

# Propuesta de refactor

Reemplazar todos los contadores por un registro dinámico.

Ejemplo conceptual:


ControlCounters

Button          -> 0
Label           -> 0
Grid            -> 0
Tree            -> 0
Image           -> 0
ModernButton    -> 0
ModernFlyout    -> 0


El acceso sería mediante un único administrador:


NextControlName( "Button" )


que devolvería:


Button1

Button2

Button3


---

# Arquitectura propuesta

DesignerHost
        │
        ▼
ControlNameManager
        │
        ├── RegisterType()
        ├── NextName()
        ├── Reset()
        ├── GetCounter()
        └── SetCounter()


De esta forma el diseñador no necesitaría conocer cuántos tipos de controles existen.

Bastaría registrar uno nuevo:


RegisterType( "ModernButton" )

RegisterType( "ModernPanel" )

RegisterType( "ModernFlyout" )


y el sistema comenzaría automáticamente a generar nombres válidos sin modificar el código del administrador.
