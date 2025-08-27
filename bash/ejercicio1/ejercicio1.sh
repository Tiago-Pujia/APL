#!/bin/bash

# Inicializar variables
# --------------------------

directorio=""
archivo=""
pantalla=false

# Leer parámetros
# --------------------------

while getopts 'd:a:p' opt; do
    case "$opt" in
        d) directorio="$OPTARG" ;;
        a) archivo="$OPTARG" ;;
        p) pantalla=true ;;
        \?) echo "Opción inválida"; exit 1 ;;
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