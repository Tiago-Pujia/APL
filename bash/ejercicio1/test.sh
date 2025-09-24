#!/bin/bash

echo "===== Iniciando batería de tests ====="

# Ruta base
BASE=$(pwd)

# Función auxiliar para ejecutar un test
run_test() {
    echo -e "\n--- $1 ---"
    shift
    "$@"
    echo "Código de salida: $?"
}

# 1. Crear entorno válido
TESTDIR="$BASE/test"
rm -rf "$TESTDIR"
mkdir -p "$TESTDIR"

cat <<EOL > "$TESTDIR/2025-07-01.txt"
101|2025-07-01 10:22:33|Telefono|5.5|4
102|2025-07-01 12:23:11|Email|120|5
103|2025-07-01 22:34:43|Chat|2.1|3
104|2025-06-30 23:11:10|Telefono|7.8|2
EOL

# 2. Crear entorno inválido
TESTDIR_INV="$BASE/test_inval"
rm -rf "$TESTDIR_INV"
mkdir -p "$TESTDIR_INV"

cat <<EOL > "$TESTDIR_INV/2025-07-02.txt"
201|2025-07-02 11:00:00|Telefono|abc|4    # Tiempo no numérico
202|2025-07-02 11:10:00|Chat|3.2|xyz      # Nota no numérica
malformato|solo2campos
EOL

# ---- Tests ----

run_test "Test 1: salida por pantalla (datos válidos)" \
    ./ejercicio1.sh -d "$TESTDIR" -p

run_test "Test 2: salida a archivo (datos válidos)" \
    ./ejercicio1.sh -d "$TESTDIR" -a resultados.json

run_test "Test 3: directorio inexistente" \
    ./ejercicio1.sh -d "$BASE/no_existe" -p

run_test "Test 4: datos inválidos (formato y valores no numéricos)" \
    ./ejercicio1.sh -d "$TESTDIR_INV" -p

run_test "Test 5: sin especificar -a ni -p" \
    ./ejercicio1.sh -d "$TESTDIR"

run_test "Test 6: usar -a y -p al mismo tiempo" \
    ./ejercicio1.sh -d "$TESTDIR" -p -a resultados.json

run_test "Test 7: mostrar ayuda con -h" \
    ./ejercicio1.sh -h

# ---- Limpieza ----
rm -rf "$TESTDIR" "$TESTDIR_INV"
rm -f resultados.json
echo -e "\n archivos limpiados."

echo -e "\n===== Fin de los tests ====="
