#!/bin/bash

# EJERCICIO 1
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

# Help
# --------------------------

ayuda(){
    echo "
NOMBRE
    ejercicio1.sh - Procesador de encuestas de satisfacción

SINOPSIS
    ejercicio1.sh [OPCIÓN]...

DESCRIPCIÓN
    Este script procesa archivos de texto que contienen registros de encuestas de 
    satisfacción de clientes, con formato de campos fijos separados por pipe (|). 
    Calcula el tiempo de respuesta promedio y la nota de satisfacción promedio 
    por canal de atención y por día. Los resultados se muestran en pantalla o 
    se guardan en un archivo JSON.

PARÁMETROS
    -d, --directorio DIR
        Ruta del directorio que contiene los archivos de encuestas a procesar.

    -a, --archivo ARCHIVO
        Ruta completa del archivo JSON de salida.

    -p, --pantalla
        Muestra la salida por pantalla en formato JSON.

    -h, --help
        Muestra esta ayuda y sale.

NOTA
    Las opciones -a/--archivo y -p/--pantalla son mutuamente excluyentes.

EJEMPLOS
    ./ejercicio1.sh -d /ruta/encuestas -p
    ./ejercicio1.sh --directorio ./datos --archivo resultado.json
"
}

# Inicializar variables
# --------------------------

directorio=""
archivo=""
pantalla=false

# Leer parámetros
# --------------------------

OPTS=$(getopt -o d:a:ph --long directorio:,archivo:,pantalla,help -n 'ejercicio1' -- "$@")

if [ $? != 0 ]; then
    echo "Error en los parámetros. Use -h o --help para ayuda."
    exit 1
fi

eval set -- "$OPTS"

while true; do
    case "$1" in
        -d|--directorio) directorio="$2"; shift 2 ;;
        -a|--archivo)    archivo="$2";    shift 2 ;;
        -p|--pantalla)   pantalla=true;   shift   ;;
        -h|--help)       ayuda; exit 0    ;;
        --) shift; break ;;
        *) echo "Opción inválida: $1"; exit 1 ;;
    esac
done

# Validaciones
# --------------------------

if [[ -z "$directorio" ]]; then # Comprobar cadena vacia
    echo "Debe especificar un directorio con -d"
    exit 1
fi

if [[ ! -d "$directorio" ]]; then # Comprobar si el directorio existe
    echo "El directorio '$directorio' no existe" >&2
    exit 1
fi

if [[ -n "$archivo" && "$pantalla" = true ]]; then
    echo "No puede usar -a y -p al mismo tiempo"
    exit 1
fi

if [[ -z "$archivo" && "$pantalla" = false ]]; then
    echo "Debe especificar -a o -p"
    exit 1
fi

# Verificar si jq está instalado
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' no está instalado. Es necesario para formatear la salida JSON."
    exit 1
fi

# --- Procesar archivos ---

# Expandir todos los archivos dentro del directorio
# Esto crea un array con la lista de entradas (archivos o directorios)
files=("$directorio"/*)
if [ ${#files[@]} -eq 0 ]; then # Verificar si el array está vacío (no hay archivos)
    salida="{}"
    echo "No hay archivos en el directorio especificado"
else # Si hay archivos, procesarlos con awk y formatear con jq
    salida=$(awk -f procesamiento_arch.awk "${files[@]}" | jq '.' 2>/dev/null)
    
    if [[ -z "$salida" ]]; then
        salida="{}"
        echo "Error al procesar los archivos o salida vacía"
    fi
fi

# --- Salida ---
if [[ "$pantalla" = true ]]; then
    echo "$salida"
else
    echo "$salida" > "$archivo"
    echo "Resultados guardados en $archivo"
fi