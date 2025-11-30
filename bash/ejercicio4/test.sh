#!/bin/bash

# Para probar manualmente vi o nano funcionan bien
# Al usar Inotify requiere el kernel Linux, usar directorios en Linux.

echo "===== Iniciando tests ====="

BASE=$(pwd)

# Función auxiliar
run_test() {
    echo -e "\n--- $1 ---"
    shift
    "$@"
    echo -e "Código de salida: $?"
}

# 1. Preparar entorno válido

cat <<EOL > "patrones.conf"
# Patrones simples
clave
password
API_KEY
secret
token
aws_access_key

# Patrones regex
regex:API_KEY\s*=\s*['"].*['"]
regex:password\s*[:=]\s*['"]\w+['"]
regex:\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\ 
EOL

TEST_REPO="$BASE/test_repo"
rm -rf "$TEST_REPO"
rm -f "/tmp/daemon.log"
mkdir -p "$TEST_REPO"
echo "const password = '1234';" > "$TEST_REPO/archivo1.js"
LOG="$BASE/audit.log"

CONFIG="$BASE/patrones.conf"

# 2. Preparar entorno inválido
TEST_REPO_INV="$BASE/test_repo_inval"
rm -rf "$TEST_REPO_INV"
mkdir -p "$TEST_REPO_INV"

# 3. Crear archivo de config vacío
EMPTY_CONFIG="$BASE/config_vacio.conf"
> "$EMPTY_CONFIG"

# ---- Tests ----

run_test "Test 1: Iniciar demonio" \
    ./ejercicio4.sh -r "$TEST_REPO" -c "$CONFIG" -l "$LOG"

run_test "Test 2: falta repositorio (-r) (debe fallar)" \
    ./ejercicio4.sh -c "$CONFIG"

run_test "Test 3: repositorio inexistente (debe fallar)" \
    ./ejercicio4.sh -r "$BASE/no_existe" -c "$CONFIG"

run_test "Test 4: Iniciar demonio con uno ya ejecutandose" \
    ./ejercicio4.sh -r "$TEST_REPO" -c "$CONFIG"

echo -e "\n--- Test 5: Mostrar cambios y patrón ---"
echo "clave = 9876" | tee "$TEST_REPO/archivo2.txt" > /dev/null
sync
sleep 0.5
cat "$LOG"

run_test "Test 6: detener demonio con -k" \
    ./ejercicio4.sh -r "$TEST_REPO" -k

rm -rf "$CONFIG"
run_test "Test 7: falta archivo de configuración (debe fallar)" \
    ./ejercicio4.sh -r "$TEST_REPO" -c "$CONFIG"

touch "$CONFIG"
run_test "Test 8: archivo de configuración vacío (debe fallar)" \
    ./ejercicio4.sh -r "$TEST_REPO" -c "$EMPTY_CONFIG"

run_test "Test 9: mostrar ayuda con -h" \
    ./ejercicio4.sh -h

# ---- Limpieza ----
rm -rf "$TEST_REPO" "$TEST_REPO_INV"
rm -f "$EMPTY_CONFIG" /tmp/daemon.log /tmp/daemon/daemon.pid
rm -rf "$CONFIG"
rm -f "$LOG"

echo -e "\n===== Fin de los tests ====="
