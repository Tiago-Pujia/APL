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
        -d|--directorio)
            directorio="$2"
            shift 2
            ;;
        -a|--archivo)
            archivo="$2"
            shift 2
            ;;
        -p|--pantalla)
            pantalla=true
            shift
            ;;
        -h|--help)
            cat help.txt
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Opción inválida: $1"
            echo "Use -h o --help para ayuda."
            exit 1
            ;;
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

# Procesar archivos
# --------------------------

salida=$(./procesamiento_arch.awk "$directorio"/* | jq '.')
    # 1. Ejecutar el script awk para procesar los archivos en el directorio dado
    # 2. Pasar la salida a jq para formatearla como JSON

if [[ "$pantalla" = true ]]; then
    echo "$salida"
else
    echo "$salida" > "$archivo"
    echo "Resultados guardados en $archivo"
fi