#!/bin/bash

# Inicializar variables
# --------------------------

matriz=""
hub="false"
camino="false"
separador="|"
ORIGEN=""
DESTINO=""

# Leer parámetros
# --------------------------
while getopts 'm:ucs:' opt; do
    case "$opt" in
        m) matriz="$OPTARG" ;;
        u) hub="true" ;;
        c) 
            camino="true"
            # Sacar los dos próximos argumentos posicionales
            shift $((OPTIND-1))
            if [[ $# -lt 2 ]]; then
                echo "Error: -c requiere 2 números (origen y destino)"
                exit 1
            fi
            ORIGEN="$1"
            DESTINO="$2"
            # Ajustar OPTIND para que getopts siga correctamente
            OPTIND=1
            shift 2
            ;;
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
if [[ "$camino" = true ]]; then

    #CAMBIAR procesamiento_arch.awk a dijkstra.awk

    salida=$(awk -f procesamiento_arch.awk -v FS="$separador" -v ORIGEN="$ORIGEN" -v DESTINO="$DESTINO" "$matriz")
fi
if [[ "$hub" = true ]]; then
    salida=$(awk -f hub.awk -v FS="$separador" "$matriz")
fi
echo $salida

#   Cosas dignas de nombrar: 
#
#       - TODO: Help, parametros largos, guardar salida en archivo,
#               tests como la gente.
#       
#       - Esta hecha la logica jodida, falta pasar a un archivo
#         y dejar las cosas prolijas  
#
#       - No se como cambiar el nombre del archivo de git :)
#         cambiar procesamiento_arch.awk a dijkstra.awk             