#!/bin/bash

# ejercicio3_test.sh - Script de pruebas para ejercicio3.sh
# Crea archivos de log de prueba y ejecuta el script con diferentes casos

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para crear directorio de logs de prueba
crear_logs_prueba() {
    local dir="$1"
    
    print_info "Creando directorio de logs de prueba: $dir"
    mkdir -p "$dir"
    
    # Crear archivos de log con diferentes patrones
    cat > "$dir/system.log" << EOF
2024-01-15 10:00:01 INFO System started successfully
2024-01-15 10:05:23 ERROR Database connection failed
2024-01-15 10:10:45 WARNING High memory usage detected
2024-01-15 10:15:12 ERROR Invalid user credentials
2024-01-15 10:20:33 INFO Backup completed
2024-01-15 10:25:47 WARNING Disk space low
2024-01-15 10:30:15 ERROR File not found
2024-01-15 10:35:29 INFO User login successful
EOF

    cat > "$dir/application.log" << EOF
2024-01-15 11:00:01 DEBUG Application initialized
2024-01-15 11:05:23 ERROR Null pointer exception
2024-01-15 11:10:45 WARNING Request timeout
2024-01-15 11:15:12 INFO Processing completed
2024-01-15 11:20:33 ERROR Invalid input format
2024-01-15 11:25:47 WARNING Retry attempt
2024-01-15 11:30:15 FATAL System crash detected
2024-01-15 11:35:29 INFO Recovery successful
EOF

    cat > "$dir/network.log" << EOF
2024-01-15 12:00:01 INFO Network interface up
2024-01-15 12:05:23 ERROR Connection refused
2024-01-15 12:10:45 WARNING Packet loss detected
2024-01-15 12:15:12 ERROR DNS resolution failed
2024-01-15 12:20:33 INFO VPN connected
2024-01-15 12:25:47 WARNING High latency
2024-01-15 12:30:15 ERROR Invalid certificate
2024-01-15 12:35:29 INFO Firewall updated
EOF

    # Crear un archivo con diferentes casos (case insensitive test)
    cat > "$dir/case_test.log" << EOF
2024-01-15 13:00:01 error lowercase error
2024-01-15 13:05:23 ERROR uppercase ERROR
2024-01-15 13:10:45 Error mixed Error
2024-01-15 13:15:12 eRrOr weird case eRrOr
2024-01-15 13:20:33 WARNING test warning
2024-01-15 13:25:47 warning another warning
EOF

    print_success "Archivos de log creados en: $dir"
}

# Función para limpiar archivos de prueba
limpiar_pruebas() {
    local dir="$1"
    if [ -d "$dir" ]; then
        print_info "Limpiando archivos de prueba en: $dir"
        rm -rf "$dir"
        print_success "Limpieza completada"
    fi
}

# Función para verificar resultado
verificar_resultado() {
    local resultado="$1"
    local esperado="$2"
    local test_name="$3"
    
    if [ "$resultado" -eq "$esperado" ]; then
        print_success "TEST PASSED: $test_name (Esperado: $esperado, Obtenido: $resultado)"
        return 0
    else
        print_error "TEST FAILED: $test_name (Esperado: $esperado, Obtenido: $resultado)"
        return 1
    fi
}

# Función principal de pruebas
ejecutar_pruebas() {
    local test_dir="./test_logs"
    local total_tests=0
    local passed_tests=0
    
    print_info "=== INICIANDO SUITE DE PRUEBAS ==="
    
    # Crear directorio de pruebas
    crear_logs_prueba "$test_dir"
    
    # Test 1: Búsqueda básica de errores
    print_info "Test 1: Búsqueda básica de 'error'"
    resultado=$(./ejercicio3.sh -d "$test_dir" -p "error" | grep -oP 'error:\s*\K\d+')
    verificar_resultado "$resultado" "8" "Búsqueda básica de error"
    ((total_tests++))
    [ $? -eq 0 ] && ((passed_tests++))
    
    # Test 2: Búsqueda múltiple de palabras
    print_info "Test 2: Búsqueda múltiple 'error,warning'"
    resultado_error=$(./ejercicio3.sh -d "$test_dir" -p "error,warning" | grep -oP 'error:\s*\K\d+')
    resultado_warning=$(./ejercicio3.sh -d "$test_dir" -p "error,warning" | grep -oP 'warning:\s*\K\d+')
    verificar_resultado "$resultado_error" "8" "Múltiples palabras - error"
    ((total_tests++))
    [ $? -eq 0 ] && ((passed_tests++))
    verificar_resultado "$resultado_warning" "8" "Múltiples palabras - warning"
    ((total_tests++))
    [ $? -eq 0 ] && ((passed_tests++))
    
    # Test 3: Case insensitive
    print_info "Test 3: Verificar case insensitive"
    resultado_case=$(./ejercicio3.sh -d "$test_dir" -p "error" | grep -oP 'error:\s*\K\d+')
    verificar_resultado "$resultado_case" "8" "Case insensitive"
    ((total_tests++))
    [ $? -eq 0 ] && ((passed_tests++))
    
    # Test 4: Palabra no encontrada
    print_info "Test 4: Palabra no existente"
    resultado=$(./ejercicio3.sh -d "$test_dir" -p "nonexistent" | grep -oP 'nonexistent:\s*\K\d+')
    verificar_resultado "$resultado" "0" "Palabra no encontrada"
    ((total_tests++))
    [ $? -eq 0 ] && ((passed_tests++))
    
    # Test 5: Directorio vacío
    print_info "Test 5: Directorio sin archivos .log"
    mkdir -p "${test_dir}_empty"
    resultado=$(./ejercicio3.sh -d "${test_dir}_empty" -p "error" 2>/dev/null | grep -oP 'error:\s*\K\d+')
    verificar_resultado "$resultado" "0" "Directorio vacío"
    ((total_tests++))
    [ $? -eq 0 ] && ((passed_tests++))
    rm -rf "${test_dir}_empty"
    
    # Test 6: Formato largo de parámetros
    print_info "Test 6: Formato largo --directorio --palabras"
    resultado=$(./ejercicio3.sh --directorio "$test_dir" --palabras "fatal,info" | grep -oP 'fatal:\s*\K\d+')
    verificar_resultado "$resultado" "1" "Formato largo de parámetros"
    ((total_tests++))
    [ $? -eq 0 ] && ((passed_tests++))
    
    # Mostrar resumen
    echo
    print_info "=== RESUMEN DE PRUEBAS ==="
    echo "Total de tests: $total_tests"
    echo "Tests pasados: $passed_tests"
    echo "Tests fallados: $((total_tests - passed_tests))"
    
    if [ $passed_tests -eq $total_tests ]; then
        print_success "¡TODAS LAS PRUEBAS PASARON!"
    else
        print_error "ALGUNAS PRUEBAS FALLARON"
    fi
    
    # Limpiar
    limpiar_pruebas "$test_dir"
    
    return $((total_tests - passed_tests))
}

# Función para verificar dependencias
verificar_dependencias() {
    if [ ! -f "./ejercicio3.sh" ]; then
        print_error "No se encuentra ejercicio3.sh en el directorio actual"
        print_info "Asegúrate de que este script esté en el mismo directorio que ejercicio3.sh"
        exit 1
    fi
    
    if [ ! -x "./ejercicio3.sh" ]; then
        print_info "Haciendo ejercicio3.sh ejecutable..."
        chmod +x ./ejercicio3.sh
    fi
}

# Menú de ayuda
mostrar_ayuda() {
    echo "Uso: $0 [OPCIONES]"
    echo
    echo "Ejecuta una suite de pruebas para ejercicio3.sh"
    echo
    echo "Opciones:"
    echo "  -h, --help     Muestra esta ayuda"
    echo "  -v, --verbose  Muestra output detallado"
    echo "  -q, --quiet    Modo silencioso"
    echo
}

# Procesar parámetros
VERBOSE=1
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            mostrar_ayuda
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=2
            shift
            ;;
        -q|--quiet)
            VERBOSE=0
            shift
            ;;
        *)
            print_error "Parámetro desconocido: $1"
            mostrar_ayuda
            exit 1
            ;;
    esac
done

# Ejecutar pruebas principales
print_info "Iniciando pruebas de ejercicio3.sh"
echo

verificar_dependencias
ejecutar_pruebas

exit $?