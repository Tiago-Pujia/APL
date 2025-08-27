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
104|2025-07-01 09:15:00|Telefono|6.0|5
105|2025-07-01 14:40:21|Chat|3.2|4
106|2025-07-01 16:50:11|Email|100|4
EOL

cat <<EOL > 2025-07-02.txt
201|2025-07-02 08:10:11|Telefono|4.5|3
202|2025-07-02 09:22:33|Email|110|5
203|2025-07-02 11:33:44|Chat|1.8|2
204|2025-07-02 12:55:22|Telefono|5.2|4
205|2025-07-02 15:40:00|Chat|2.5|3
EOL

cat <<EOL > 2025-07-03.txt
301|2025-07-03 09:00:00|Email|130|5
302|2025-07-03 10:20:30|Telefono|6.8|4
303|2025-07-03 13:15:10|Chat|2.2|3
304|2025-07-03 14:00:00|Email|120|4
305|2025-07-03 18:30:45|Telefono|5.5|5
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