#!/bin/bash

mkdir logs_prueba

cat > logs_prueba/sistema1.log <<EOF
Error: falta memoria
Advertencia: proceso lento
Error: conexión rechazada
EOF

cat > logs_prueba/sistema2.log <<EOF
Info: inicio correcto
Error: disco lleno
Advertencia: alto uso de CPU
EOF

echo -e "Directorio creado: logs_prueba\n"

echo -e "Archivos a examinar:\n"
echo -e "sistema1.log"
cat logs_prueba/sistema1.log

echo -e "\nsistema2.log"
cat logs_prueba/sistema2.log

echo -e "\n===== TEST 1: ejecución normal ====="
./ejercicio3.sh -d logs_prueba -p "Error,Advertencia"

echo -e "\n===== TEST 2: solo errores (debe fallar) ====="
./ejercicio3.sh -d logs_prueba -p "Error"

echo -e "\n===== TEST 3: ayuda ====="
./ejercicio3.sh -h

echo -e "\n===== TEST 4: parámetros inválidos (debe fallar) ====="
./ejercicio3.sh -x

echo -e "\n===== TEST 5: directorio vacío (debe fallar) ====="
mkdir -p logs_vacio
./ejercicio3.sh -d logs_vacio -p "Error,Advertencia"

echo -e "\n===== TEST 6: directorio inexistente (debe fallar) ====="
./ejercicio3.sh -d no_existe -p "Error"

echo -e "\n===== TEST 7: palabras que no aparecen ====="
./ejercicio3.sh -d logs_prueba -p "Inexistente,OtraPalabra"


mkdir -p "logs con espacios"

# Crear primer archivo con espacios en el nombre
cat > "logs con espacios/sistema principal.log" <<EOF
Error: falta memoria
Advertencia: proceso lento
Error: conexión rechazada
EOF

# Crear segundo archivo con espacios en el nombre
cat > "logs con espacios/sistema secundario.log" <<EOF
Info: inicio correcto
Error: disco lleno
Advertencia: alto uso de CPU
EOF

echo -e "\n===== TEST 8: Nombres con espacios ====="
./ejercicio3.sh -d "logs con espacios" -p "Error"

rm -rf logs_prueba
rm -rf logs_vacio
rm -rf "logs con espacios"