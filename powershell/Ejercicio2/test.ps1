# Script para probar ejercicio2.ps1
# Este script debe ejecutarse en la misma carpeta que ejercicio2.ps1

# --- Función Auxiliar de Pruebas ---
function Run-Test {
    param (
        [string]$TestNombre,
        [string]$Comando,
        [string]$ResultadoEsperado, # "Error" o "Exitoso"
        [string]$MatrizParaMostrar, # Opcional: ruta de la matriz a mostrar
        [string]$ReporteParaMostrar # Opcional: ruta del reporte a mostrar
    )

    Write-Host "--- PRUEBA: $TestNombre ---" -ForegroundColor Cyan
    Write-Host "COMANDO: pwsh -Command `"$Comando`""

    # Mostrar matriz de entrada si se especificó
    if ($MatrizParaMostrar -and (Test-Path $MatrizParaMostrar)) {
        Write-Host "--- CONTENIDO MATRIZ ($MatrizParaMostrar) ---" -ForegroundColor DarkGray
        Get-Content $MatrizParaMostrar | Write-Host
        Write-Host "-------------------------------" -ForegroundColor DarkGray
    }

    # Ejecutar el comando en un proceso 'pwsh' separado.
    # Redirigimos toda la salida (stdout y stderr) a $null para mantener limpia la consola.
    # El script ejercicio2.ps1 usa 'exit 1' para los errores lógicos (matriz inválida)
    # y PowerShell automáticamente genera un error para parámetros faltantes/incorrectos.
    # Por lo tanto, podemos usar $LASTEXITCODE para ver si el proceso falló.
    pwsh -Command $Comando *>$null
    
    # $LASTEXITCODE captura el código de salida del último proceso (pwsh).
    # 0 significa éxito. Cualquier otro número (generalmente 1) significa error.
    $Exitoso = $LASTEXITCODE -eq 0
    $ResultadoObtenido = if ($Exitoso) { "Exitoso" } else { "Error" }

    Write-Host "ESPERADO: $ResultadoEsperado"
    Write-Host "OBTENIDO: $ResultadoObtenido"

    if ($ResultadoObtenido -eq $ResultadoEsperado) {
        Write-Host "RESULTADO: PASS" -ForegroundColor Green

        # Mostrar reporte si la prueba fue exitosa y se especificó
        if ($Exitoso -and $ReporteParaMostrar) {
            if (Test-Path $ReporteParaMostrar) {
                Write-Host "--- CONTENIDO REPORTE ($ReporteParaMostrar) ---" -ForegroundColor DarkGray
                Get-Content $ReporteParaMostrar | Write-Host
                Write-Host "-------------------------------" -ForegroundColor DarkGray
            } else {
                Write-Host "ADVERTENCIA: No se encontró el archivo de reporte '$ReporteParaMostrar' para mostrar." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "RESULTADO: FAIL" -ForegroundColor Red
    }
    Write-Host ("-"*60)
    Write-Host ""
}

# --- 1. CONFIGURACIÓN DEL ENTORNO ---
Write-Host "--- CONFIGURANDO ENTORNO DE PRUEBA ---" -ForegroundColor Yellow
$RutaScript = ".\ejercicio2.ps1"

# Crear archivos de matriz de prueba
"0,5,10`n5,0,2`n10,2,0" | Out-File "matriz_valida.txt" -Encoding utf8
"0,1`n1,0,3" | Out-File "matriz_no_cuadrada.txt" -Encoding utf8
"0,A`nA,0" | Out-File "matriz_no_numerica.txt" -Encoding utf8
"0,-5`n-5,0" | Out-File "matriz_negativa.txt" -Encoding utf8
"1,5`n5,0" | Out-File "matriz_diagonal_no_cero.txt" -Encoding utf8
"0,5`n8,0" | Out-File "matriz_no_simetrica.txt" -Encoding utf8
Write-Host "Archivos de matriz de prueba creados."
Write-Host ""


# --- 2. EJECUCIÓN DE PRUEBAS DE PARÁMETROS ---
Write-Host "--- EJECUTANDO PRUEBAS DE PARÁMETROS ---" -ForegroundColor Yellow

# Pruebas de parámetros obligatorios
Run-Test "Error: Falta -hub O -camino" "$RutaScript -matriz 'matriz_valida.txt' -separador ','" "Error"

# Prueba de parámetros mutuamente excluyentes
Run-Test "Error: Parámetros mutuamente excluyentes (-hub y -camino)" "$RutaScript -matriz 'matriz_valida.txt' -separador ',' -hub -camino" "Error"

# Pruebas de ValidateScript (vacíos)
Run-Test "Error: -matriz está vacío" "$RutaScript -matriz '' -separador ',' -hub" "Error"
Run-Test "Error: -separador está vacío" "$RutaScript -matriz 'matriz_valida.txt' -separador '' -hub" "Error"

# Prueba de ValidateScript (archivo no existe)
Run-Test "Error: -matriz el archivo no existe" "$RutaScript -matriz 'archivo_inexistente.txt' -separador ',' -hub" "Error"


# --- 3. EJECUCIÓN DE PRUEBAS DE LÓGICA (validarMatriz) ---
Write-Host "--- EJECUTANDO PRUEBAS DE VALIDACIÓN DE MATRIZ ---" -ForegroundColor Yellow

Run-Test "Error: Matriz no cuadrada" "$RutaScript -matriz 'matriz_no_cuadrada.txt' -separador ',' -hub" "Error"
Run-Test "Error: Matriz no numérica" "$RutaScript -matriz 'matriz_no_numerica.txt' -separador ',' -hub" "Error"
Run-Test "Error: Matriz con valor negativo" "$RutaScript -matriz 'matriz_negativa.txt' -separador ',' -hub" "Error"
Run-Test "Error: Matriz con diagonal no cero" "$RutaScript -matriz 'matriz_diagonal_no_cero.txt' -separador ',' -hub" "Error"
Run-Test "Error: Matriz no simétrica" "$RutaScript -matriz 'matriz_no_simetrica.txt' -separador ',' -hub" "Error"

# --- 4. PRUEBA DE CASO EXITOSO ---
Write-Host "--- EJECUTANDO PRUEBA DE CASO EXITOSO ---" -ForegroundColor Yellow

$matrizValida = "matriz_valida.txt"
# El script principal crea el reporte basado en el nombre de la matriz
$reporteGenerado = "informe_$( [System.IO.Path]::GetFileNameWithoutExtension($matrizValida) ).md"

Run-Test "Exitoso: Matriz válida (-hub) Y MOSTRAR SALIDA" `
    "$RutaScript -matriz '$matrizValida' -separador ',' -hub" `
    "Exitoso" `
    -MatrizParaMostrar $matrizValida `
    -ReporteParaMostrar $reporteGenerado

Run-Test "Exitoso: Matriz válida (-camino) Y MOSTRAR SALIDA" `
    "$RutaScript -matriz '$matrizValida' -separador ',' -camino" `
    "Exitoso" `
    -MatrizParaMostrar $matrizValida `
    -ReporteParaMostrar $reporteGenerado


# --- 5. LIMPIEZA ---
Write-Host "--- LIMPIANDO ENTORNO DE PRUEBA ---" -ForegroundColor Yellow
Remove-Item "matriz_*.txt" -ErrorAction SilentlyContinue
# Limpiar los archivos de informe generados por las corridas exitosas
Remove-Item "informe_matriz_valida.md" -ErrorAction SilentlyContinue
Write-Host "Archivos de prueba y reportes generados eliminados."
Write-Host "--- PRUEBAS COMPLETADAS ---" -ForegroundColor Yellow

