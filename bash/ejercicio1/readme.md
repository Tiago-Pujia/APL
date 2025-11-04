# Explicación Código del Ejercicio 1

Este proyecto consiste en un conjunto de scripts en **Bash** y **AWK** para procesar encuestas de clientes. El objetivo es calcular el **tiempo de respuesta promedio** y la **nota de satisfacción promedio** por canal de atención y por día, generando un **JSON final**.

- [Explicación Código del Ejercicio 1](#explicación-código-del-ejercicio-1)
  - [Requisitos](#requisitos)
  - [Estructura del Proyecto](#estructura-del-proyecto)
  - [Funcionamiento del Programa](#funcionamiento-del-programa)
    - [`ejercicio1.sh`](#ejercicio1sh)
    - [`procesamiento_arch.awk`](#procesamiento_archawk)
    - [`test.sh`](#testsh)


## Requisitos

- Tener instalado el gestor del formato JSON

~~~sh
sudo apt install jq
~~~

- Tener instalado el gestor para archivos awk

~~~sh
sudo apt install gawk
~~~

## Estructura del Proyecto

~~~
ejercicio1
├── ejercicio1.sh           -> Script principal para ejecutar el análisis
├── procesamiento_arch.awk  -> Script AWK que procesa los archivos y calcula promedios
├── test/                   -> Carpeta opcional para archivos de prueba
  └── 2025-07-01.txt        -> Ejemplo de archivo de encuestas
~~~

## Funcionamiento del Programa

### `ejercicio1.sh`

Archivo principal que debe ejecutar el usuario. Este, comprende los parametros enviados, los valida y llama al archivo `procesamiento_arch.awk` que realiza el procesamiento registro por registro. Con el resultado retornado, lo parseamos a JSON y se entrega el resultado al usuario.

Sigue la siguiente secuencia

1. Recibe los párametros:
    - `-d <directorio>`   -> ruta donde se encuentran los archivos de encuestas
    - `-p`                -> mostrar el resultado en pantalla
    - `-a <archivo>`      -> guardar el resultado en un archivo JSON

2. Realiza validaciones sobre los parametros
3. Realiza procesamiento:
    1. Ejecuta `procesamiento_arch.awk` para procesar todos los archivos del directorio y obtiene la salida.
    2. Pasa la salida por `jq '.'` para formatear el JSON de manera legible (indentado y con saltos de línea).
4. El archivo obtenido lo muestra por consola o lo guarda en un archivo (segun -p)

### `procesamiento_arch.awk`

Recorre los registros uno por uno del archivo a procesar. Se tiene un par de matrices asociativas (o simulacion de la misma) guardadas por la clave fecha (dia) + canal (email, telefono, chat), las matrices son las siguientes:
- suma_tiempo[(fecha, canal)]  -> suma de tiempos
- suma_nota[(fecha, canal)]    -> suma de notas
- cuenta[(fecha, canal)]       -> cantidad de registros

Por cada linea del archivo a procesar. Se extrae la fecha y canal para formar la clave, nos dirigimos a su respectiva posición de cada matrices y sumamos los valores necesarios.

Una vez procesado cada registro. Debemos transformar las matrices al formato JSON.

### `test.sh`

Este bash pone a prueba los archivos anteriormente descriptos. Para esto, realiza lo siguiente:
1. Crea una carpeta `test/`
2. Crea lotes de pruebas donde van a ser guardados en la carpeta test
3. Se llama a `./ejercicio1.sh` con los archivos de prueba, uno mostrando por pantalla y otro guardando en archivo
4. Se elimina el directorio, lotes y resultado json