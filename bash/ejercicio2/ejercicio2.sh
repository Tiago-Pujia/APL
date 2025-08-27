#!/bin/bash

# Inicializar variables
# --------------------------

matriz=""
hub="false"
camino="false"
separador="|"

# Leer parámetros
# --------------------------

while getopts 'm:hcs:' opt; do
    case "$opt" in
        m) matriz="$OPTARG" ;;
        h) hub="true" ;;
        c) camino="true" ;;
        s) separador="$OPTARG" ;;
        \?) echo "Opción inválida"; exit 1 ;;
    esac
done

# Validaciones
# --------------------------
if [[ -z "$separador" ]]; then # Comprobar cadena vacia
    echo "Debe especificar separador con -s"
    exit 1
fi

if [[ -z "$matriz" ]]; then # Comprobar cadena vacia
    echo "Debe especificar un directorio con -m"
    exit 1
fi

if [[ ! -f "$matriz" ]]; then # Comprobar si el directorio existe
    echo "El archivo '$matriz' no existe"
    exit 1
fi

if [[ "$hub" = true && "$camino" = true ]]; then
    echo "No puede usar -c y -h al mismo tiempo"
    exit 1
fi

salida=$(awk -v SEP="$separador" -f validar_matriz.awk "$matriz")
if [[ 1 -eq salida ]]; then # Comprobar q sea cuadrada, simetrica y numerica
    echo "Error al leer la matriz. Cantidad de errores: $salida"
    exit 1
fi

# Procesar archivos
# --------------------------

# Ejecutar el script awk para procesar los archivos en el directorio dado
salida=$(./procesamiento_arch.awk "$matriz")

echo $salida