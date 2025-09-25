#!/usr/bin/env pwsh
Write-Output "===== Iniciando batería de tests ====="

# Ruta base (carpeta donde está el script de test)
$BASE = $PSScriptRoot

# Función auxiliar para ejecutar un test
function Run-Test {
    param (
        [string]$Descripcion,
        [string]$Comando
    )

    Write-Output "`n--- $Descripcion ---"
    try {
        Invoke-Expression $Comando
        Write-Output "Código de salida: $LASTEXITCODE"
    } catch {
        Write-Output "Error capturado: $_"
        Write-Output "Código de salida: $LASTEXITCODE"
    }
}

# 1. Crear entorno válido
$TESTDIR = Join-Path $BASE "test"
if (Test-Path $TESTDIR) { Remove-Item $TESTDIR -Recurse -Force }
New-Item -ItemType Directory -Path $TESTDIR | Out-Null

@"
101|2025-07-01 10:22:33|Telefono|5.5|4
102|2025-07-01 12:23:11|Email|120|5
103|2025-07-01 22:34:43|Chat|2.1|3
104|2025-06-30 23:11:10|Telefono|7.8|2
"@ | Set-Content -Path (Join-Path $TESTDIR "2025-07-01.txt")

# 2. Crear entorno inválido
$TESTDIR_INV = Join-Path $BASE "test_inval"
if (Test-Path $TESTDIR_INV) { Remove-Item $TESTDIR_INV -Recurse -Force }
New-Item -ItemType Directory -Path $TESTDIR_INV | Out-Null

@"
201|2025-07-02 11:00:00|Telefono|abc|4    # Tiempo no numérico
202|2025-07-02 11:10:00|Chat|3.2|xyz      # Nota no numérica
malformato|solo2campos
"@ | Set-Content -Path (Join-Path $TESTDIR_INV "2025-07-02.txt")

# ---- Tests ----
Run-Test "Test 1: salida por pantalla (datos válidos)" `
    ".\ejercicio1.ps1 -directorio `"$TESTDIR`" -pantalla"

Run-Test "Test 2: salida a archivo (datos válidos)" `
    ".\ejercicio1.ps1 -directorio `"$TESTDIR`" -archivo resultados.json"

Run-Test "Test 3: directorio inexistente" `
    ".\ejercicio1.ps1 -directorio `"$BASE/no_existe`" -pantalla"

Run-Test "Test 4: datos inválidos (formato y valores no numéricos)" `
    ".\ejercicio1.ps1 -directorio `"$TESTDIR_INV`" -pantalla"

Run-Test "Test 5: sin especificar -archivo ni -pantalla" `
    ".\ejercicio1.ps1 -directorio `"$TESTDIR`""

Run-Test "Test 6: usar -pantalla y -archivo al mismo tiempo" `
    ".\ejercicio1.ps1 -directorio `"$TESTDIR`" -pantalla -archivo resultados.json"

Run-Test "Test 7: mostrar ayuda con -h" `
    ".\ejercicio1.ps1 -h"

# ---- Limpieza ----
Remove-Item $TESTDIR -Recurse -Force
Remove-Item $TESTDIR_INV -Recurse -Force
Remove-Item resultados.json -Force -ErrorAction SilentlyContinue

Write-Output "`nArchivos limpiados."
Write-Output "`n===== Fin de los tests ====="
