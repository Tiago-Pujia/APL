#!/usr/bin/env pwsh
Write-Output "===== Iniciando batería de tests para ejercicio4.ps1 ====="

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

# 1. Crear entorno válido (repositorio de prueba)
$TESTDIR = Join-Path $BASE "test_repo"
if (Test-Path $TESTDIR) { Remove-Item $TESTDIR -Recurse -Force }
New-Item -ItemType Directory -Path $TESTDIR | Out-Null

# Crear archivos de prueba con contenido normal
@"
Este es un archivo de prueba seguro.
Sin información sensible.
"@ | Set-Content -Path (Join-Path $TESTDIR "archivo1.txt")

@"
Contenido de archivo dos.
Información normalizada.
"@ | Set-Content -Path (Join-Path $TESTDIR "archivo2.txt")

# 2. Crear archivo de configuración válido (patrones de búsqueda)
$CONFIGDIR = Join-Path $BASE "config"
if (Test-Path $CONFIGDIR) { Remove-Item $CONFIGDIR -Recurse -Force }
New-Item -ItemType Directory -Path $CONFIGDIR | Out-Null

@"
# Patrones de búsqueda para credenciales y datos sensibles
password
apikey
api_key
secret
token
credentials
"@ | Set-Content -Path (Join-Path $CONFIGDIR "patrones.conf")

# 3. Crear archivo de configuración con patrones regex
@"
# Patrones con regex
\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b
\d{3}-\d{2}-\d{4}
"@ | Set-Content -Path (Join-Path $CONFIGDIR "patrones_regex.conf")

# 4. Crear archivo de configuración inválido (vacío)
@"
# Solo comentarios
# Sin patrones de búsqueda
"@ | Set-Content -Path (Join-Path $CONFIGDIR "patrones_vacio.conf")

# 5. Crear directorio con archivos sensibles (para detectar patrones)
$TESTDIR_SENSIBLE = Join-Path $BASE "test_repo_sensible"
if (Test-Path $TESTDIR_SENSIBLE) { Remove-Item $TESTDIR_SENSIBLE -Recurse -Force }
New-Item -ItemType Directory -Path $TESTDIR_SENSIBLE | Out-Null

@"
Usuario: admin
Password: SuperSecret123
"@ | Set-Content -Path (Join-Path $TESTDIR_SENSIBLE "credentials.txt")

@"
API Token: sk-1234567890abcdef
Secret key: mysecretkey
"@ | Set-Content -Path (Join-Path $TESTDIR_SENSIBLE "tokens.txt")

# 6. Crear directorio para logs
$LOGDIR = Join-Path $BASE "logs"
if (Test-Path $LOGDIR) { Remove-Item $LOGDIR -Recurse -Force }
New-Item -ItemType Directory -Path $LOGDIR | Out-Null

# ---- Tests ----

Run-Test "Test 1: Mostrar ayuda" `
    ".\ejercicio4.ps1 -help"

Run-Test "Test 2: Iniciar monitoreo en segundo plano (datos válidos)" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR`" -configuracion `"$(Join-Path $CONFIGDIR 'patrones.conf')`" -log `"$(Join-Path $LOGDIR 'audit.log')`""

# Esperar un poco para que el job se inicie
Start-Sleep -Seconds 2

Run-Test "Test 3: Verificar que el job está ejecutándose" `
    "Get-Job | Where-Object { `$_.Name -like 'GitAudit_*' } | Select-Object Id, Name, State"

Run-Test "Test 4: Detener el monitoreo" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR`" -kill"

Run-Test "Test 5: Intentar detener un monitoreo inexistente" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR`" -kill"

Run-Test "Test 6: Directorio inexistente (debe fallar)" `
    ".\ejercicio4.ps1 -repo `"$BASE/no_existe`" -configuracion `"$(Join-Path $CONFIGDIR 'patrones.conf')`" -log `"$(Join-Path $LOGDIR 'test.log')`""

Run-Test "Test 7: Archivo de configuración inexistente (debe fallar)" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR`" -configuracion `"$BASE/no_existe.conf`" -log `"$(Join-Path $LOGDIR 'test.log')`""

Run-Test "Test 8: Sin especificar -configuracion y -log (debe mostrar uso)" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR`""

Run-Test "Test 9: Especificar solo -configuracion (debe fallar)" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR`" -configuracion `"$(Join-Path $CONFIGDIR 'patrones.conf')`""

Run-Test "Test 10: Monitoreo con archivo de configuración vacío (sin patrones)" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR_SENSIBLE`" -configuracion `"$(Join-Path $CONFIGDIR 'patrones_vacio.conf')`" -log `"$(Join-Path $LOGDIR 'empty_patterns.log')`""

Start-Sleep -Seconds 1

Run-Test "Test 11: Detener monitoreo del Test 10" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR_SENSIBLE`" -kill"

Run-Test "Test 12: Monitoreo que detecta patrones sensibles" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR_SENSIBLE`" -configuracion `"$(Join-Path $CONFIGDIR 'patrones.conf')`" -log `"$(Join-Path $LOGDIR 'sensible.log')`""

Start-Sleep -Seconds 2

Run-Test "Test 13: Verificar contenido del log de detección sensible" `
    "Get-Content `"$(Join-Path $LOGDIR 'sensible.log')`" -ErrorAction SilentlyContinue"

Run-Test "Test 14: Intentar iniciar otro monitoreo en el mismo repo (debe fallar)" `
    ".\ejercicio4.ps1 -repo `"$TESTDIR_SENSIBLE`" -configuracion `"$(Join-Path $CONFIGDIR 'patrones.conf')`" -log `"$(Join-Path $LOGDIR 'duplicate.log')`""

Run-Test "Test 15: Detener todos los monitoreos" `
    "`$jobs = @(Get-Job -Name 'GitAudit_Job_*' -ErrorAction SilentlyContinue); if (`$jobs.Count -gt 0) { `$jobs | Stop-Job -ErrorAction SilentlyContinue; `$jobs | Remove-Job -Force -ErrorAction SilentlyContinue; Write-Output `"Se detuvieron `$(`$jobs.Count) jobs`" } else { Write-Output 'No hay jobs activos para limpiar' }; `$LASTEXITCODE = 0"

# ---- Limpieza ----
Write-Output "`n--- Iniciando limpieza de archivos de prueba ---"

Remove-Item $TESTDIR -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $TESTDIR_SENSIBLE -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $CONFIGDIR -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $LOGDIR -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "Archivos de prueba limpios."
Write-Output "`n===== Fin de los tests ====="
