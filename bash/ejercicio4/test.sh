#!/bin/bash

echo "===== Iniciando tests ====="

BASE=$(pwd)

# Función auxiliar
run_test() {
    echo -e "\n--- $1 ---"
    shift
    "$@"
    echo "Código de salida: $?"
}

# 1. Preparar entorno válido
TEST_REPO="$BASE/test_repo"
rm -rf "$TEST_REPO"
mkdir -p "$TEST_REPO"
echo "const password = '1234';" > "$TEST_REPO/archivo1.js"
echo "clave = 9876" > "$TEST_REPO/archivo2.txt"

CONFIG="$BASE/patrones.conf"

# 2. Preparar entorno inválido
TEST_REPO_INV="$BASE/test_repo_inval"
rm -rf "$TEST_REPO_INV"
mkdir -p "$TEST_REPO_INV"

# 3. Crear archivo de config vacío
EMPTY_CONFIG="$BASE/config_vacio.conf"
> "$EMPTY_CONFIG"

# ---- Tests ----

run_test "Test 1: falta repositorio (-r)" \
    ./ejercicio4.sh -c "$CONFIG"

run_test "Test 2: repositorio inexistente" \
    ./ejercicio4.sh -r "$BASE/no_existe" -c "$CONFIG"

run_test "Test 3: falta archivo de configuración" \
    ./ejercicio4.sh -r "$TEST_REPO"

run_test "Test 4: archivo de configuración vacío" \
    ./ejercicio4.sh -r "$TEST_REPO" -c "$EMPTY_CONFIG"

run_test "Test 5: mostrar ayuda con -h" \
    ./ejercicio4.sh -h

run_test "Test 6: iniciar demonio válido" \
    ./ejercicio4.sh -r "$TEST_REPO" -c "$CONFIG"

# Espera un momento y modifica un archivo para disparar alerta
sleep 2
echo "mi password es secreto" >> "$TEST_REPO/archivo2.txt"
sleep 2

run_test "Test 7: detener demonio con -k" \
    ./ejercicio4.sh -r "$TEST_REPO" -k

# ---- Limpieza ----
rm -rf "$TEST_REPO" "$TEST_REPO_INV"
rm -f "$EMPTY_CONFIG" /tmp/daemon.log /tmp/daemon/daemon.pid

echo -e "\n===== Fin de los tests ====="
