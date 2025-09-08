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
        u) hub="true" ;;
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
if [[ $? -ne 0 ]]; then # Comprobar q sea cuadrada, simetrica y numerica
    echo -e "Error al leer la matriz:\n$salida"
    exit 1
fi

# Procesar archivos
# --------------------------

# Ejecutar el script awk para procesar los archivos en el directorio dado
ORIGEN="A"
DESTINO="D"
salida=$(awk -f procesamiento_arch.awk -v FS="$separador" -v ORIGEN="$ORIGEN" -v DESTINO="$DESTINO" "$matriz")

echo $salida

#   Cosas dignas de nombrar: 
#
#       - Puse el algoritmo de dijkstra en procesamiento archivo,
#         pero talvez sería mejor darle su propio archivo awk
#         ya que solo hace cálculo de caminos, no hub
#
#       - Fue bastante gpteado, costó entender como se hace el
#         algoritmo
#
#       - Cambie cosas en el test, son un insulto a lo lindo en la vida,
#         modificar mas tarde