#!/bin/bash

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
            ayuda
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

echo "-----------------------------------------------"
echo "analizando eventos en logs de sistemas"
echo "-----------------------------------------------"


for archivo in "$directorio"/*.log; do
    awk -v lista="$palabras" -f buscarPalabras.awk "$archivo" 
done
