#!/bin/bash

# Inicializar variables
# --------------------------

matriz=""
hub="false"
camino="false"
separador=""


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
            echo "
            NOMBRE
                ejercicio2.sh - Analizador de rutas en mapa de transporte

            SINOPSIS
                ejercicio2.sh [OPCIÓN]... -m ARCHIVO

            DESCRIPCIÓN
                Este script analiza rutas en una red de transporte público representada como
                una matriz de adyacencia donde los valores representan el tiempo de viaje
                entre estaciones. Puede determinar el hub de la red o encontrar el camino
                más corto entre estaciones usando el algoritmo de Dijkstra.

            PARÁMETROS OBLIGATORIOS
                -m, --matriz ARCHIVO
                    Ruta del archivo de la matriz de adyacencia.

                -s, --separador CARÁCTER
                    Carácter utilizado como separador de columnas en la matriz (por defecto: espacio).

            PARÁMETROS OPCIONALES (EXCLUYENTES)
                -u, --hub
                    Determina qué estación es el "hub" de la red (mayor número de conexiones).
                    No compatible con --camino.

                -c, --camino
                    Encuentra el camino más corto en tiempo entre todas las estaciones.
                    No compatible con --hub.

                -h, --help
                    Muestra esta ayuda y sale.

            NOTAS
                - El archivo de matriz debe ser cuadrado y simétrico con valores numéricos enteros o decimales positivos
                - Un valor 0 indica que no hay conexión directa entre estaciones
                - Las opciones --hub y --camino son mutuamente excluyentes

            EJEMPLOS
                ./ejercicio2.sh -m mapa.txt --hub -s \"|\"
                ./ejercicio2.sh --matriz transporte.txt --camino --separador \",\"
                ./ejercicio2.sh -m datos.csv -c -s \";\"
            "
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

    salida+=$(awk -f procesamiento_arch.awk -v FS="$separador" "$matriz")
fi
if [[ "$hub" = true ]]; then
    salida+=$(awk -f hub.awk -v FS="$separador" "$matriz")
fi

base=$(basename "$matriz" .txt)
echo -e "$salida\n" > "informe.${base}.md"

