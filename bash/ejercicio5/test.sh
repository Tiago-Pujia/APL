#!/bin/bash

# EJERCICIO 5
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

echo "===== Iniciando tests para ejercicio5.sh ====="

# Ruta base
BASE=$(pwd)

# Función auxiliar para ejecutar un test con cache aislada
run_test() {
    local test_name="$1"
    shift
    
    echo -e "\n--- $test_name ---"
    
    # Crear cache temporal único para este test
    local test_cache=$(mktemp)
    echo "{}" > "$test_cache"
    
    # Ejecutar comando con cache temporal
    ARCHIVO_CACHE="$test_cache" bash "$@"
    local exit_code=$?
    
    # Limpiar cache temporal
    rm -f "$test_cache"
    
    echo "Código de salida: $exit_code"
    return $exit_code
}

# Backup del archivo de cache original si existe
if [[ -f "archivo_cache.json" ]]; then
    mv "archivo_cache.json" "archivo_cache.json.backup"
fi

# ---- Tests ----

# Tests básicos de ayuda y validación
run_test "Test 1: Mostrar ayuda (-h)" \
    ejercicio5.sh -h

run_test "Test 2: Mostrar ayuda (--help)" \
    ejercicio5.sh --help

run_test "Test 3: Sin parámetros obligatorios" \
    ejercicio5.sh

run_test "Test 4: Solo -n sin TTL" \
    ejercicio5.sh -n argentina

run_test "Test 5: Solo TTL sin países" \
    ejercicio5.sh -t 60

run_test "Test 6: TTL no numérico" \
    ejercicio5.sh -n argentina -t abc

run_test "Test 7: TTL cero" \
    ejercicio5.sh -n argentina -t 0

run_test "Test 8: TTL negativo" \
    ejercicio5.sh -n argentina -t -10

# Tests con países (cada uno con cache limpia)
run_test "Test 9: Un país válido" \
    ejercicio5.sh -n argentina -t 300

run_test "Test 10: Múltiples países válidos" \
    ejercicio5.sh -n argentina,brasil,chile -t 300

run_test "Test 11: País con espacios" \
    ejercicio5.sh -n "united states" -t 300

run_test "Test 12: País con números" \
    ejercicio5.sh -n pais123 -t 300

run_test "Test 13: País con símbolos" \
    ejercicio5.sh -n "país@incorrecto" -t 300

run_test "Test 14: País inexistente" \
    ejercicio5.sh -n paisquenoexiste -t 300

run_test "Test 15: Países válidos e inválidos" \
    ejercicio5.sh -n "argentina,pais123,brasil" -t 300

# Test especial de cache
echo -e "\n--- Test 16: Verificar caché ---"
cache_file=$(mktemp)
echo "{}" > "$cache_file"

echo "Primera ejecución (debe consultar API):"
ARCHIVO_CACHE="$cache_file" bash ejercicio5.sh -n france -t 300 | head -10

echo -e "\nSegunda ejecución (debe usar caché):"
ARCHIVO_CACHE="$cache_file" bash ejercicio5.sh -n france -t 300 | head -10

rm -f "$cache_file"

# Tests con formato largo
run_test "Test 17: Formato largo de parámetros" \
    ejercicio5.sh --nombre mexico --ttl 300

run_test "Test 18: Múltiples países formato largo" \
    ejercicio5.sh --nombre spain,france,italy --ttl 300

# ---- Limpieza ----
echo -e "\n===== Limpieza ====="

# Restaurar archivo de cache original si existía
if [[ -f "archivo_cache.json.backup" ]]; then
    mv "archivo_cache.json.backup" "archivo_cache.json"
    echo "Archivo cache original restaurado"
else
    rm -f "archivo_cache.json"
    echo "Archivo cache temporal eliminado"
fi

echo -e "\n===== Fin de los tests ====="