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

echo -e "\nTest 1: " './ejercicio2.sh -m mapa_transporte.txt -s "|"'
./ejercicio2.sh -m mapa_transporte.txt -s "|"


#Esta en un lugar que no deberia
#pero no queria crear varios archivos de mapa
cat <<EOL > mapa_transporte.txt
0,10,0,5
10,0,0,7
0,0,0,8
5,7,8,0
EOL

echo -e "\nTest 2: " './ejercicio2.sh -m mapa_transporte.txt -s "," -u'
./ejercicio2.sh -m mapa_transporte.txt -s "," -u

#Mas de lo mismo...
cat <<EOL > mapa_transporte.txt
0|10|0|0
10|0|4|0
0|4|0|0
0|0|0|0
EOL

echo -e "\nTest 3: " './ejercicio2.sh -m mapa_transporte.txt -s "|" -c 1 4'
./ejercicio2.sh -m mapa_transporte.txt -s "|" -c 1 4

cat <<EOL > mapa_transporte.txt
0}10}9}0
10}0}4}0
9}4}0}7
0}0}7}0
EOL

echo -e "\nTest 4: " './ejercicio2.sh -m mapa_transporte.txt -s "}" -c 4 1'
./ejercicio2.sh -m mapa_transporte.txt -c 4 1 -s "}" 

cat <<EOL > mapa_transporte.txt
0|0|0|0|8|2
0|0|6|9|4|11
0|6|0|0|7|8
0|9|0|0|6|0
8|4|7|6|0|5
2|11|8|0|5|0
EOL
echo -e "\nTest 5: " './ejercicio2.sh -m mapa_transporte.txt -s "|" -c 4 6'
./ejercicio2.sh -m mapa_transporte.txt -s "|" -c 4 6


cat <<EOL > mapa_transporte.txt
0|3|7|2|5|1|4|6|8|0
3|0|6|4|7|2|5|3|1|8
7|6|0|5|2|8|1|4|3|6
2|4|5|0|9|3|7|2|6|1
5|7|2|9|0|6|8|4|2|3
1|2|8|3|6|0|5|7|4|9
4|5|1|7|8|5|0|6|2|3
6|3|4|2|4|7|6|0|9|5
8|1|3|6|2|4|2|9|0|7
0|8|6|1|3|9|3|5|7|0
EOL
echo -e "\nTest 6: " './ejercicio2.sh -m mapa_transporte.txt -s "|" -u'
./ejercicio2.sh -m mapa_transporte.txt -s "|" -u

# Limpiar entorno de prueba
# --------------------------
rm -f mapa_transporte.txt
echo -e "\nArchivo de prueba eliminado"