#!/bin/bash
# Archivo: test.sh
# Corre pruebas sobre el script principal con matrices de ejemplo

SCRIPT="./ejercicio2.sh"

# Función auxiliar para limpiar archivos generados
cleanup() {
    rm -f matriz.txt mala.txt informe.matriz.md
}

# Arrancamos limpio
cleanup

# =========================
# Tests con matriz válida
# =========================
cat > matriz.txt <<EOF
0|15|7|5
15|0|3|7
7|3|0|8
5|7|8|0
EOF
echo "Matriz utilizada:"
cat matriz.txt

echo "== Test 1: faltan argumentos =="
$SCRIPT -m matriz.txt -s "|" || echo "OK: falló como se esperaba"

echo -e "\n== Test 2: hub correcto (se genera informe.matriz.md) =="

$SCRIPT -m matriz.txt -s "|" -u
if [[ -f informe.matriz.md ]]; then
    echo "Informe generado: informe.matriz.md"
    cat informe.matriz.md
fi
cleanup

cat > matriz.txt <<EOF
0-15-7-5
15-0-3-7
7-3-0-8
5-7-8-0
EOF
echo "Matriz utilizada:"
cat matriz.txt

echo -e "\n== Test 3: camino correcto (se genera informe.matriz.md) =="
$SCRIPT -m matriz.txt -s "-" -c 1 2

if [[ -f informe.matriz.md ]]; then
    echo "Informe generado: informe.matriz.md"
    cat informe.matriz.md
fi

echo -e "\n== Test 4: matriz con decimales (válida) =="
cat > matriz.txt <<EOF
0|1.5|2.3
1.5|0|4.7
2.3|4.7|0
EOF
echo "Matriz utilizada:"
cat matriz.txt
$SCRIPT -m matriz.txt -s "|" -u

if [[ -f informe.matriz.md ]]; then
    echo "Informe generado: informe.matriz.md"
    cat informe.matriz.md
fi

cleanup

# =========================
# Tests de error
# =========================

echo -e "\n== Test 5: error archivo inexistente =="
$SCRIPT -m inexistente.txt -s "|" -u || echo "OK: detectó archivo inexistente"

echo -e "\n== Test 6: error sin separador =="
cat > matriz.txt <<EOF
0|1
1|0
EOF
echo "Matriz utilizada:"
cat matriz.txt
$SCRIPT -m matriz.txt -u || echo "OK: faltó separador"
cleanup

echo -e "\n== Test 7: error matriz no simétrica =="
cat > matriz.txt <<EOF
0|1|2
4|0|5
6|7|0
EOF
echo "Matriz utilizada:"
cat matriz.txt
$SCRIPT -m matriz.txt -s "|" -u || echo "OK: matriz inválida detectada"
cleanup

echo -e "\n== Test 8: error usando hub y camino juntos =="
cat > matriz.txt <<EOF
0|1
1|0
EOF
echo "Matriz utilizada:"
cat matriz.txt
$SCRIPT -m matriz.txt -s "|" -u -c 1 2 || echo "OK: detectó parámetros conflictivos"

echo -e "\n== Test 9: camino con un solo número (debería fallar) =="
$SCRIPT -m matriz.txt -s "|" -c 1 || echo "OK: detectó menos de dos números"

echo -e "\n== Test 10: camino con tres números (debería fallar) =="
$SCRIPT -m matriz.txt -s "|" -c 0 2 3 || echo "OK: detectó más de dos números"
cleanup

echo -e "\n== Test 11: help =="
$SCRIPT -h


