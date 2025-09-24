#!/bin/bash

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
        -h|--help)       cat help.txt;    exit 0  ;;
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

# --- Procesar archivos ---

# Expandir todos los archivos dentro del directorio
# Esto crea un array con la lista de entradas (archivos o directorios)
files=("$directorio"/*)
if [ ${#files[@]} -eq 0 ]; then # Verificar si el array está vacío (no hay archivos)
    salida="{}"
    echo "No hay archivos en el directorio especificado"
else # Si hay archivos, procesarlos con awk y formatear con jq
    salida=$(./procesamiento_arch.awk "${files[@]}" | jq '.' 2>/dev/null)
    
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