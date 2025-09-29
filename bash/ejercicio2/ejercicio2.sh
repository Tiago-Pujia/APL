#!/bin/bash

# Inicializar variables
# --------------------------

matriz=""
hub="false"
camino="false"
separador=""
ORIGEN=""
DESTINO=""

options=$(getopt -o m:ucs:h --l matriz:,hub,camino,separador:,help -- "$@" 2> /dev/null)

if [[ "$?" -ne "0" ]]; # equivale a:  if test "$?" != "0"
then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
        -m|--matriz)
            matriz="$2"
            shift 2
            ;;
        -u|--hub)
            hub="true"
            shift 
            ;;
        -c|--camino)
            camino="true"
            shift 
            ;;
        -s|--separador)
            separador="$2"
            shift 2
            ;;
        -h|--help)
            #ayuda
            cat help.txt
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Opción inválida: $1"
            exit 1
            ;;
    esac
done

# Validaciones
# --------------------------

if [[ "$camino" == "true" ]]; then
    # Verificar que existan $1 y $2
    if [[ -z "${1:-}" || -z "${2:-}" ]]; then
        echo "Error: --camino requiere 2 números (origen y destino)."
        exit 1
    fi

    ORIGEN="$1"
    DESTINO="$2"

    # Validación: enteros positivos
    if ! [[ "$ORIGEN" =~ ^[0-9]+$ && "$DESTINO" =~ ^[0-9]+$ ]]; then
        echo "Error: ORIGEN y DESTINO deben ser enteros positivos."
        exit 1
    fi

    # Verificar que no haya un tercer argumento
    if [[ -n "${3:-}" ]]; then
        echo "Error: se recibieron más de 2 números para --camino."
        exit 1
    fi
    shift 2  # Consumir ORIGEN y DESTINO
fi

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

if [[ "$hub" = false && "$camino" = false ]]; then
    echo "Debe incluir -c o -u, -h para ayuda"
    exit 1
fi

if [[ "$hub" = true && "$camino" = true ]]; then
    echo "No puede usar -c y -u al mismo tiempo"
    exit 1
fi

salida=$(awk -v SEP="$separador" -f validar_matriz.awk "$matriz")
if [[ $? -ne 0 ]]; then # Comprobar q sea cuadrada, simetrica y numerica
    echo -e "Error al leer la matriz:\n$salida"
    exit 1
fi

# Procesar archivos
# --------------------------

salida="## Informe de análisis de red de transporte\n"

# Ejecutar el script awk para procesar los archivos en el directorio dado
if [[ "$camino" = true ]]; then

    #CAMBIAR procesamiento_arch.awk a dijkstra.awk

    salida+=$(awk -f procesamiento_arch.awk -v FS="$separador" -v ORIGEN="$ORIGEN" -v DESTINO="$DESTINO" "$matriz")
fi
if [[ "$hub" = true ]]; then
    salida+=$(awk -f hub.awk -v FS="$separador" "$matriz")
fi

base=$(basename "$matriz" .txt)
echo -e "$salida\n" > "informe.${base}.md"

