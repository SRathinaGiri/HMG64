# SaveString() – Análisis funcional (IDE Legacy HMG)

# Objetivo

`SaveString()` es una función de persistencia de bajo nivel.

Su única responsabilidad es escribir una cadena de texto en un archivo.

No conoce el formato FMG.

No conoce proyectos.

No conoce formularios.

No conoce el diseñador.

Es simplemente un servicio de escritura.

---

# Firma


PROCEDURE SaveString( cFileName, cString, lUTF8 )


## Parámetros

### cFileName

Ruta completa del archivo a generar.

Ejemplo


C:\Proyecto\Main.fmg


---

### cString

Contenido completo a escribir.

Generalmente corresponde al texto FMG generado por `Save()` o por `NewForm()`.

---

### lUTF8

Bandera para escribir el archivo con BOM UTF-8.

Actualmente no se utiliza.

La primera instrucción del procedimiento hace:


lUTF8 := NIL


por lo que cualquier valor recibido queda descartado.

---

# Flujo

El procedimiento actual se reduce a una sola llamada:


HB_MEMOWRIT( cFileName, cString )


y retorna inmediatamente.

---

# Implementación original

Se conserva comentada la implementación antigua.

El flujo era:


FCREATE()

↓

(opcional)
Escribir BOM UTF-8

↓

FWRITE()

↓

FCLOSE()


Posteriormente fue reemplazada por:


HB_MEMOWRIT()


que encapsula todo el proceso.

---

# Funciones llamadas

Actualmente


HB_MEMOWRIT()


Implementación antigua (comentada)


FCREATE()

FWRITE()

FCLOSE()


---

# Variables locales


nOutFile


Actualmente no se utiliza.

Permanece únicamente por compatibilidad con la versión anterior.

---

# Dependencias

No depende del diseñador.

No depende del proyecto.

No depende del Workspace.

No utiliza variables globales.

---

# Responsabilidad

✔ Escribir un archivo de texto.

Nada más.

---

# Relación con NewForm()

Dentro de `NewForm()` esta función es utilizada para crear el archivo FMG inicial.

El flujo es:


NewForm()

↓

Construcción del texto FMG

↓

SaveString()

↓

Main.fmg


---

# Relación con Save()

El procedimiento `Save()` también puede utilizar este servicio una vez generado el contenido completo del formulario.


Save()

↓

Genera FMG

↓

SaveString()

↓

Archivo actualizado


---

# Observaciones

La implementación actual es mucho más simple que la original.

El parámetro `lUTF8` quedó obsoleto.

El código comentado indica que en versiones anteriores existió la intención de soportar archivos UTF-8 con BOM, pero esa funcionalidad nunca llegó a utilizarse.

---

# Problemas de arquitectura

No presenta problemas importantes.

Es una función pequeña y con una única responsabilidad.

Lo único cuestionable es mantener código muerto y parámetros sin uso.

---

# Propuesta de refactor

Mantener una abstracción de persistencia.

Ejemplo conceptual:


FileSystem

WriteText()

ReadText()

FileExists()

Delete()

Copy()


El diseñador nunca debería escribir archivos directamente.

Simplemente solicitaría:


FileSystem.WriteText()


De esta manera el mecanismo de almacenamiento podría cambiar en el futuro (por ejemplo, documentos temporales, proyectos comprimidos o almacenamiento remoto) sin modificar el resto del diseñador.
