# SortFormList() – Análisis funcional (IDE Legacy HMG)

# Objetivo

`SortFormList()` ordena alfabéticamente la lista de formularios del proyecto mostrada en el IDE.

Su responsabilidad es:

* Ordenar visualmente la lista de formularios.
* Mantener seleccionado el formulario recién agregado o el indicado por el parámetro.

No crea formularios.

No modifica archivos.

No guarda el proyecto.

No modifica el diseñador.

---

# Firma


PROCEDURE SortFormList( value )


## Parámetro


value


Puede ser:

* Numérico → índice que debe quedar seleccionado.
* Otro tipo → busca automáticamente el último formulario agregado y lo selecciona.

---

# Variables locales


i
j
aux
last


## i

Índice del primer recorrido.

---

## j

Índice del segundo recorrido.

---

## aux

Variable temporal utilizada durante el intercambio de elementos.

---

## last

Guarda el último elemento existente antes del ordenamiento para poder localizarlo nuevamente una vez finalizado.

---

# Flujo

## 1. Obtener el último formulario


last := Project.List_2.Item( Project.List_2.ItemCount )


No necesariamente es el último alfabéticamente.

Es simplemente el último agregado.

---

## 2. Ordenar

Utiliza dos bucles anidados.


FOR i

    FOR j

        IF Item(i) > Item(j)

            Intercambiar

        ENDIF

    NEXT

NEXT


El algoritmo utilizado corresponde a un ordenamiento cuadrático (intercambio directo).

La comparación es insensible a mayúsculas utilizando:


HMG_UPPER()


---

## 3. Restaurar la selección

### Caso 1

Si `value` es numérico:


Project.List_2.Value := value


La selección queda exactamente en el índice indicado.

---

### Caso 2

Si no es numérico:

Busca nuevamente el formulario almacenado en:


last


y selecciona la nueva posición donde quedó luego del ordenamiento.

---

# Variables globales utilizadas

Únicamente:


Project.List_2


El procedimiento trabaja directamente sobre el ListBox del IDE.

No existe una colección independiente de formularios.

---

# Funciones utilizadas


HMG_UPPER()

ALLTRIM()

VALTYPE()


No llama a ninguna función del diseñador.

---

# Responsabilidad

✔ Ordenar la lista.

✔ Restaurar la selección.

Nada más.

---

# Observaciones

El algoritmo utilizado es un ordenamiento O(n²).

Para la cantidad habitual de formularios de un proyecto HMG (decenas o pocos cientos) su rendimiento es suficiente.

---

# Descubrimiento importante

El procedimiento no trabaja sobre una estructura de datos del proyecto.

Trabaja directamente sobre:


Project.List_2


Es decir:


ListBox del IDE
        =
Modelo del Proyecto


La interfaz gráfica y el modelo de datos están completamente acoplados.

No existe una clase o estructura denominada "Proyecto" que contenga la colección de formularios.

---

# Problemas de arquitectura

## Acoplamiento Vista / Modelo

El control visual almacena la información del proyecto.

Esto dificulta reutilizar la lógica sin una interfaz gráfica.

---

## Algoritmo manual

El ordenamiento se implementa mediante bucles e intercambio de elementos.

Hoy podría delegarse a un mecanismo de ordenación de colecciones.

---

## Dependencia directa del IDE

La función conoce la existencia de:


Project.List_2


No puede reutilizarse fuera del IDE.

---

# Propuesta de refactor

Separar claramente el modelo del proyecto de su representación visual.

Arquitectura sugerida:


Workspace
        │
        ▼
ProjectDocument
        │
        ├── Forms[]
        ├── Resources[]
        ├── Includes[]
        └── Settings
                │
                ▼
ProjectExplorer
                │
                ▼
TreeView / ListView


El ordenamiento debería realizarse sobre `ProjectDocument.Forms[]`.

El explorador simplemente reflejaría ese estado, sin contener los datos del proyecto.
