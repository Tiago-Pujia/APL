#!/usr/bin/env pwsh

# EJERCICIO 4
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

Write-Output "===== Iniciando tests para ejercicio5.ps1 ====="

# Ruta base
$BASE = $PSScriptRoot
$TEST_CACHE = Join-Path $BASE "test_cache.json"
$ORIGINAL_CACHE = Join-Path $BASE "archivo_cache.json"

# Función auxiliar para ejecutar un test
function Run-Test {
    param (
        [string]$Descripcion,
        [string]$Comando
    )

    Write-Output "`n--- $Descripcion ---"
    try {
        # Usar archivo de cache de test
        $env:TEST_MODE = "true"
        $env:TEST_CACHE_PATH = $TEST_CACHE
        
        Invoke-Expression $Comando
        Write-Output "Código de salida: $LASTEXITCODE"
    } catch {
        Write-Output "Error capturado: $_"
        Write-Output "Código de salida: $LASTEXITCODE"
    } finally {
        Remove-Item env:TEST_MODE -ErrorAction SilentlyContinue
        Remove-Item env:TEST_CACHE_PATH -ErrorAction SilentlyContinue
    }
}

# Backup del archivo de cache original si existe
if (Test-Path $ORIGINAL_CACHE) {
    Copy-Item $ORIGINAL_CACHE "$ORIGINAL_CACHE.backup" -Force
}

# Crear archivo de cache de test vacío
"{}" | Set-Content $TEST_CACHE -Encoding UTF8

# ---- Tests ----

# Test 1: Mostrar ayuda
Run-Test "Test 1: Mostrar ayuda (-help)" `
    ".\ejercicio5.ps1 -help"

# Test 2: Sin parámetros (debe fallar)
Run-Test "Test 2: Sin parámetros obligatorios" `
    ".\ejercicio5.ps1"

# Test 3: Solo -nombre sin -ttl (debe fallar)
Run-Test "Test 3: Solo -nombre sin TTL" `
    ".\ejercicio5.ps1 -nombre argentina"

# Test 4: Solo -ttl sin -nombre (debe fallar)
Run-Test "Test 4: Solo TTL sin países" `
    ".\ejercicio5.ps1 -ttl 60"

# Test 5: TTL inválido (no numérico)
Run-Test "Test 5: TTL no numérico" `
    ".\ejercicio5.ps1 -nombre argentina -ttl abc"

# Test 6: TTL inválido (cero)
Run-Test "Test 6: TTL cero" `
    ".\ejercicio5.ps1 -nombre argentina -ttl 0"

# Test 7: TTL inválido (negativo)
Run-Test "Test 7: TTL negativo" `
    ".\ejercicio5.ps1 -nombre argentina -ttl -10"

# Test 8: Un país válido
Run-Test "Test 8: Un país válido" `
    ".\ejercicio5.ps1 -nombre argentina -ttl 300"

# Test 9: Múltiples países válidos
Run-Test "Test 9: Múltiples países válidos" `
    ".\ejercicio5.ps1 -nombre argentina,brasil,chile -ttl 300"

# Test 10: País con espacios
Run-Test "Test 10: País con espacios" `
    ".\ejercicio5.ps1 -nombre 'united states' -ttl 300"

# Test 11: País con caracteres especiales (debe fallar)
Run-Test "Test 11: País con números" `
    ".\ejercicio5.ps1 -nombre pais123 -ttl 300"

# Test 12: País con caracteres especiales (debe fallar)
Run-Test "Test 12: País con símbolos" `
    ".\ejercicio5.ps1 -nombre 'país@incorrecto' -ttl 300"

# Test 13: País inexistente
Run-Test "Test 13: País inexistente" `
    ".\ejercicio5.ps1 -nombre paisquenoexiste -ttl 300"

# Test 14: Mezcla de países válidos e inválidos
Run-Test "Test 14: Países válidos e inválidos" `
    ".\ejercicio5.ps1 -nombre 'argentina,pais123,brasil' -ttl 300"

# Test 15: Verificar funcionamiento de caché (mismo país dos veces)
Write-Output "`n--- Test 15: Verificar caché ---"
Write-Output "Primera ejecución (debe consultar API):"
$env:TEST_CACHE_PATH = $TEST_CACHE
.\ejercicio5.ps1 -nombre france -ttl 300 | Select-Object -First 10
Write-Output "`nSegunda ejecución (debe usar caché):"
$env:TEST_CACHE_PATH = $TEST_CACHE
.\ejercicio5.ps1 -nombre france -ttl 300 | Select-Object -First 10
Remove-Item env:TEST_CACHE_PATH -ErrorAction SilentlyContinue

# Test 16: Múltiples países con formato de array
Run-Test "Test 16: Múltiples países como array" `
    ".\ejercicio5.ps1 -nombre @('spain','france','italy') -ttl 300"

# Test 17: País con caracteres especiales válidos (ñ y acentos)
Run-Test "Test 17: País con ñ y acentos" `
    ".\ejercicio5.ps1 -nombre 'españa,méxico' -ttl 300"

# Test 18: TTL muy grande
Run-Test "Test 18: TTL grande" `
    ".\ejercicio5.ps1 -nombre germany -ttl 86400"

# Test especial: Verificar que el archivo de cache se crea correctamente
Write-Output "`n--- Test Extra: Verificar archivo de cache ---"
$env:TEST_CACHE_PATH = $TEST_CACHE
.\ejercicio5.ps1 -nombre japan -ttl 600 | Out-Null
if (Test-Path $TEST_CACHE) {
    $cacheContent = Get-Content $TEST_CACHE -Raw | ConvertFrom-Json
    if ($cacheContent.japan) {
        Write-Output "Archivo de cache creado correctamente"
        Write-Output "Timestamp: $($cacheContent.japan.timestamp)"
        Write-Output "TTL: $($cacheContent.japan.ttl)"
    } else {
        Write-Output "Error: No se encontró entrada para Japan en cache"
    }
} else {
    Write-Output "Error: No se creó archivo de cache"
}
Remove-Item env:TEST_CACHE_PATH -ErrorAction SilentlyContinue

# ---- Limpieza ----
Write-Output "`n===== Limpieza ====="

# Eliminar archivo de cache de test
Remove-Item $TEST_CACHE -Force -ErrorAction SilentlyContinue

# Restaurar archivo de cache original si existía
if (Test-Path "$ORIGINAL_CACHE.backup") {
    Remove-Item $ORIGINAL_CACHE -Force -ErrorAction SilentlyContinue
    Move-Item "$ORIGINAL_CACHE.backup" $ORIGINAL_CACHE -Force
    Write-Output "Archivo cache original restaurado"
} else {
    Remove-Item $ORIGINAL_CACHE -Force -ErrorAction SilentlyContinue
    Write-Output "Archivo cache temporal eliminado"
}

Write-Output "`n===== Fin de los tests ====="