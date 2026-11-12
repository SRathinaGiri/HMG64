# NewForm.prg – Análisis funcional (IDE Legacy HMG)

## Objetivo

`NewForm()` es el punto de entrada del IDE para crear un nuevo formulario (.FMG).

Su responsabilidad es:

* Solicitar el nombre del formulario (o utilizar el recibido por parámetro).
* Validar que el formulario pueda crearse.
* Crear un archivo FMG mínimo.
* Agregarlo al proyecto.
* Actualizar el IDE.
* Abrir el diseñador del formulario.

No contiene lógica del diseñador gráfico; solamente prepara el entorno y delega la edición a `_Open()`.

---

# Firma

 
Function NewForm( cNewForm )
 

## Parámetro

 
cNewForm
 

Opcional.

* Si no existe:

  * solicita el nombre mediante `InputBox()`.
* Si existe:

  * utiliza directamente ese nombre.

---

# Variables locales

 
Result
i
cFormContent
lRetVal := .T.
 

## Result

Nombre final del formulario.

Ejemplo:

 
Clientes.fmg
 

---

## i

Índice utilizado para recorrer la lista de formularios del proyecto.

---

## cFormContent

Contiene el texto completo del archivo FMG que será grabado.

Ejemplo:

 
DEFINE WINDOW TEMPLATE ...
END WINDOW
 

---

## lRetVal

Valor de retorno.

Siempre devuelve:

 
.T.
 

salvo cuando la función termina antes con `Return NIL` o `Return(.F.)`.

---

# Variables globales utilizadas

## ProjectName

Verifica que exista un proyecto abierto.

Si está vacío:

 
MsgStop(...)
Return NIL
 

---

## _HMG_SYSDATA[257]

Bandera utilizada durante la creación.

La función:

 
_HMG_SYSDATA[257] := .F.
 

Luego verifica si otro proceso modificó ese valor.

---

## Project.List_2

Lista de formularios del proyecto.

Se utiliza para:

* verificar duplicados
* agregar el nuevo formulario

---

## Project.Tab_1

Selecciona la pestaña "Forms".

 
Project.Tab_1.Value := 2
 

---

## Properties.Title

Actualiza el título de la ventana de propiedades.

---

## DesignForm

Comprueba si el diseñador ya está abierto.

---

## SelectedControlName

Restaura la selección cuando se cancela la creación.

---

## aMsgs[]

Tabla de mensajes del IDE.

Todos los textos visibles provienen de aquí.

---

# Flujo completo

## 1. Inicialización

 
InitControlCounters()
 

Reinicia los contadores internos utilizados por el diseñador.

---

## 2. Validación del proyecto
 
ProjectName
 

Debe existir un proyecto.

---

## 3. Obtener nombre

Si no existe parámetro:

 
InputBox(...)
 

Si existe:

 
Result := cNewForm
 

---

## 4. Cancelación

Si el usuario cancela:

 
SelectControl()
DrawGrid()
Return NIL
 

---

## 5. Nombre vacío

También restaura la selección anterior y termina.

---

## 6. Normalización

El nombre siempre termina en:

 
.fmg
 

---

## 7. Verificar duplicados

Recorre:

 
Project.List_2
 

Si encuentra el mismo nombre:

 
MsgStop(...)
Return NIL
 

---

## 8. Construcción del FMG

Genera un formulario mínimo.

Básicamente:

 
DEFINE WINDOW TEMPLATE
...
END WINDOW
 

La única diferencia entre ambos bloques es que uno incluye:

 
MAIN
 

cuando `cNewForm` fue recibido como parámetro.

---

## 9. Escritura del archivo

Si el archivo existe:

 
MsgYesNo()
 

Si acepta:

 
SaveString()
 

Si no existe:

 
SaveString()
 

---

## 10. Registrar el formulario

 
Project.List_2.AddItem()
 

---

## 11. Ordenar

 
SortFormList()
 

---

## 12. Guardar proyecto

 
SaveProject()
 
 
---

## 13. Actualizar IDE

Selecciona la pestaña de formularios.

Actualiza el título de propiedades.

---

## 14. Cerrar diseñador anterior

 
DoMethod( DesignForm , "Release" )
 

---

## 15. Abrir el nuevo formulario

Delega completamente al editor mediante:

 
_Open( Result )
 

Aquí comienza realmente el diseñador.

---

# Funciones llamadas

## Inicialización

 
InitControlCounters()
 

---

## Entrada

 
InputBox()
 

---

## Mensajes

 
MsgStop()

MsgYesNo()
 

---

## Ventanas

 
_IsWindowDefined()

DoMethod()
 

---

## Diseño

 
SelectControl()

DrawGrid()
 

---

## Archivos

 
File()

SaveString()
 

---

## Proyecto
 
 
SortFormList()

SaveProject()
 

---

## Editor

 
_Open()
 

---

# Dependencias

La función depende de:

* Project
* DesignForm
* Properties
* _HMG_SYSDATA
* aMsgs
* SelectedControlName

---

# Responsabilidades

✔ Crear el FMG.

✔ Agregarlo al proyecto.

✔ Abrir el editor.

No realiza ninguna operación gráfica del diseñador.

---

# Punto de entrada del diseñador

El verdadero editor comienza en:


_Open( Result )
 

Toda la lógica de:

* abrir el FMG
* interpretar DEFINE WINDOW
* crear objetos
* mostrar el formulario
* seleccionar controles
* mover controles
* redimensionar
* dibujar manejadores
* guardar cambios

queda fuera de `NewForm()` y debe encontrarse en `_Open()` y las funciones que este invoque.

---

# Observaciones para el refactor

`NewForm()` mezcla lógica de interfaz del IDE (InputBox, mensajes, pestañas y listas del proyecto) con la creación física del archivo `.FMG`. En un diseño moderno conviene separar estas responsabilidades en tres capas:

1. **Project Manager**: altas, bajas y registro de formularios dentro del proyecto.
2. **FMG Serializer**: creación y escritura del contenido inicial del archivo `.FMG`.
3. **Designer Host**: apertura del diseñador mediante una interfaz clara (por ejemplo, `Designer.OpenForm()`), desacoplando el editor visual del IDE.
