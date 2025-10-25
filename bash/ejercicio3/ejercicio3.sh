#!/bin/bash

# EJERCICIO 3
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

ayuda(){
echo "
NOMBRE
    ejercicio3.sh - Contador de eventos en logs de sistemas

SINOPSIS
    ejercicio3.sh [OPCIÓN]... -d DIRECTORIO -p PALABRAS

DESCRIPCIÓN
    Este script analiza todos los archivos de logs (.log) en un directorio para
    contar la ocurrencia de eventos específicos basados en palabras clave.
    Las búsquedas son case-insensitive.

PARÁMETROS OBLIGATORIOS
    -d, --directorio DIRECTORIO
        Ruta del directorio de logs a analizar.

    -p, --palabras PALABRAS
        Lista de palabras clave a contabilizar, separadas por comas.
        Ejemplo: "error,warning,invalid"

PARÁMETROS OPCIONALES
    -h, --help
        Muestra esta ayuda y sale.

NOTAS
    - Utiliza AWK para el procesamiento eficiente de los archivos de log
    - Las búsquedas no distinguen entre mayúsculas y minúsculas
    - Procesa todos los archivos con extensión .log en el directorio especificado

EJEMPLOS
    ./ejercicio3.sh -d /var/log -p "error,fail,invalid"
    ./ejercicio3.sh --directorio ./logs --palabras "warning,timeout,connection"
    ./ejercicio3.sh -d /app/logs -p "exception,crash,denied"
"
}

# Conteo de eventos en logs de sistemas
# Inicializo variables
directorio=""
palabras=""

#Leer parametros
options=$(getopt -o d:p:h --l help,directorio:,palabra: -- "$@" 2> /dev/null)
if [ "$?" != "0" ] # equivale a:  if test "$?" != "0"
then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"
while true
do
    case "$1" in # switch ($1) { 
        -d | --directorio) # case "-e":
            directorio="$2"
            shift 2

            echo "El parámetro -d o --directorio es: $directorio"
            ;;
        -p | --palabras)
            palabras="$2"
            shift 2
            
            echo "El parámetro -p o --palabras tiene las siguientes palabras: $palabras"
            ;;
        -h | --help)
            cat help.txt
            exit 0
            ;;
        --) # case "--":
            shift
            break
            ;;
        *) # default: 
            echo "error"
            exit 1
            ;;
    esac
done

# Verificar si el directorio existe
if [ ! -d "$directorio" ]; then
    echo -e "\nError: el directorio '$directorio' no existe."
    exit 1
fi

# Verificar si el directorio contiene archivos .log
shopt -s nullglob  # hace que el patrón *.log expanda a vacío si no hay coincidencias
archivos=("$directorio"/*.log)
if [ ${#archivos[@]} -eq 0 ]; then
    echo -e "\nAdvertencia: el directorio '$directorio' no contiene archivos .log."
    exit 1
fi


echo "-----------------------------------------------"
echo "analizando eventos en logs de sistemas"
echo "-----------------------------------------------"


for archivo in "$directorio"/*.log; do
    echo -e "\narchvivo: $archivo"
    awk -v lista="$palabras" -f buscarPalabras.awk "$archivo" 
done
