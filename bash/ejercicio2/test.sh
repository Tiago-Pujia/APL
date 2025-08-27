#!/bin/bash

# Crear archivos de prueba
# --------------------------

#   A B C D
#A 0
#B   0
#C     0
#D       0

#0 = Misma estacion/no existe la conexion

cat <<EOL > mapa_transporte.txt
0|10|0|5
10|0|4|0
0|4|0|8
5|0|8|0
EOL

echo -e "Archivos de prueba creados en $(pwd)\n"

# Ejecutar tests
# --------------------------
echo -e "\nIniciando tests con archivo de prueba..."

echo -e "\nTest 1: " './ejercicio2.sh -m mapa_transporte.txt -s a"|"'
./ejercicio2.sh -m mapa_transporte.txt -s "|"

echo -e "\nTest 2: " './ejercicio2.sh -m mapa_transporte.txt -s "|" -h'
./ejercicio2.sh -m mapa_transporte.txt -s "|" -h

echo -e "\nTest 3: " './ejercicio2.sh -m mapa_transporte.txt -s "|" -c'
./ejercicio2.sh -m mapa_transporte.txt -s "|" -c

# Limpiar entorno de prueba
# --------------------------
rm -f mapa_transporte.txt
echo -e "\nArchivo de prueba eliminado"