#!/bin/bash

# Crear entorno de prueba
# --------------------------
if [[ -f ./test.sh ]]; then
    echo "Ejecutando tests..."
fi

mkdir -p test
cd test

# Crear archivos de prueba
# --------------------------
cat <<EOL > 2025-07-01.txt
101|2025-07-01 10:22:33|Telefono|5.5|4
102|2025-07-01 12:23:11|Email|120|5
103|2025-07-01 22:34:43|Chat|2.1|3
104|2025-06-30 23:11:10|Telefono|7.8|2
EOL

echo -e "Archivos de prueba creados en $(pwd)\n"
cd ..

# Ejecutar tests
# --------------------------
echo -e "\nIniciando tests con archivo de prueba..."

echo -e "\nTest 1: salida por pantalla"
./ejercicio1.sh -d ./test -p

echo -e "\nTest 2: salida a archivo"
./ejercicio1.sh -d ./test -a resultados.json

# Limpiar entorno de prueba
# --------------------------
rm -rf test # Eliminar el directorio de prueba
rm -f resultados.json # Eliminar archivo de resultados si existe
echo -e "\nEntorno de prueba eliminado."