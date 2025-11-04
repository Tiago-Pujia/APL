#!/usr/bin/env pwsh

# EJERCICIO 4 
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

<#
.SYNOPSIS
    Script de prueba (test harness) para ejercicio4.ps1.
.DESCRIPTION
    Este script automatiza la configuración, ejecución y limpieza
    para probar el demonio de monitoreo de archivos (ejercicio4.ps1).
    
    Pasos que realiza:
    1.  Crea un entorno de prueba temporal (directorio, config, log).
    2.  Prueba el parámetro -help.
    3.  Inicia el demonio apuntando al directorio temporal (CON ESPACIOS).
    4.  Verifica que el archivo .pid del demonio se haya creado.
    5.  Crea y modifica archivos para disparar los patrones (simple y regex).
    6.  Lee el archivo de log para verificar que las alertas se registraron.
    7.  Detiene el demonio usando el parámetro -kill.
    8.  Elimina el entorno de prueba temporal.
#>

# --- Configuración ---
$scriptPrincipal = ".\ejercicio4.ps1"

# --- Función Auxiliar ---
# Esta función replica la lógica de Get-PidFile de tu script principal
# para que el script de pruebas sepa qué archivo .pid buscar.
function Get-TestPidFile {
    param([string]$dirPath)
    
    # Asegurarnos de que tenemos la ruta absoluta, tal como lo haría el daemon
    $absPath = (Resolve-Path $dirPath).Path
    
    $pidDir = "$HOME/.dir_monitor_pids"
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($absPath)
    )
    $hashString = [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(0, 16)
    return Join-Path $pidDir "monitor_$hashString.pid"
}


# 1. --- Configurar Entorno de Prueba ---
Write-Host "--- 1. Configurando entorno de prueba ---" -ForegroundColor Cyan

$tempDir = Join-Path $env:TEMP "daemon test $(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -ErrorAction Stop | Out-Null

$testRepoDir = Join-Path $tempDir "repo a monitorear"
$configFile = Join-Path $tempDir "patrones.conf"
$logFile = Join-Path $tempDir "test_daemon.log"

New-Item -ItemType Directory -Path $testRepoDir | Out-Null
Write-Host "Directorio de repositorio creado en: $testRepoDir"

$patterns = @(
    '# Archivo de configuración de prueba',
    'PALABRA_SECRETA',
    'regex:\b(ERROR|FAIL|CRITICAL)\b',
    'regex:password\s*=\s*\S+'      
)
Set-Content -Path $configFile -Value ($patterns -join "`n")
Write-Host "Archivo de configuración creado en: $configFile"
Write-Host "`n"

# Variable para guardar la ruta al PID file y usarla en la limpieza
$pidFileParaLimpieza = $null

# --- Inicio del Bloque de Pruebas (con limpieza asegurada) ---
try {

    # 2. --- TEST: Mostrar Ayuda ---
    Write-Host "--- 2. TEST: Probar parámetro -help ---" -ForegroundColor Yellow
    
    $scriptPrincipalPath = (Resolve-Path $scriptPrincipal).Path
    $helpArgs = "-File `"$scriptPrincipalPath`" -help"
    
    Start-Process -FilePath "pwsh" -ArgumentList $helpArgs -Wait -NoNewWindow
    Write-Host "Prueba de ayuda completada."
    Read-Host "Presiona Enter para continuar..."
    Write-Host "`n"

    # 3. --- TEST: Iniciar el Daemon ---
    Write-Host "--- 3. TEST: Iniciar el Daemon (probando ruta con espacios) ---" -ForegroundColor Yellow
    $comandoInicio = "$scriptPrincipal -repo `"$testRepoDir`" -configuracion `"$configFile`" -log `"$logFile`""
    Write-Host "Ejecutando: $comandoInicio"
    
    # Ejecutamos el script. Este lanzará el proceso daemon y terminará.
    # El propio script (ejercicio4.ps1) imprimirá si fue exitoso o no.
    & $scriptPrincipal -repo $testRepoDir -configuracion $configFile -log $logFile
    
    Write-Host "Esperando 5 segundos a que el daemon se estabilice..."
    Start-Sleep -Seconds 5

    # **CAMBIO: Verificamos el archivo PID, no el LOG**
    $pidFileParaLimpieza = Get-TestPidFile -dirPath $testRepoDir
    
    if (Test-Path $pidFileParaLimpieza) {
        $pidInfo = Get-Content $pidFileParaLimpieza | ConvertFrom-Json
        Write-Host "VERIFICACIÓN: El archivo PID se ha creado (PID: $($pidInfo.PID))." -ForegroundColor Green
        Write-Host "El Daemon se está ejecutando."
    } else {
        Write-Host "FALLO: El archivo PID no se encontró en $pidFileParaLimpieza" -ForegroundColor Red
        Write-Host "El daemon no pudo iniciarse. Abortando pruebas." -ForegroundColor Red
        return
    }
    Write-Host "`n"
    
    # 4. --- TEST: Disparar el monitor (Patrón Simple) ---
    Write-Host "--- 4. TEST: Disparar monitor (Crear archivo .log con patrón simple) ---" -ForegroundColor Yellow
    $testFile1 = Join-Path $testRepoDir "otro_log.log"
    $content1 = "Este archivo contiene la PALABRA_SECRETA."
    Write-Host "Creando archivo: $testFile1"
    Set-Content -Path $testFile1 -Value $content1
    
    Start-Sleep -Seconds 2 
    
    # 5. --- TEST: Disparar el monitor (Patrón Regex) ---
    Write-Host "--- 5. TEST: Disparar monitor (Modificar archivo con patrón regex) ---" -ForegroundColor Yellow
    $testFile2 = Join-Path $testRepoDir "log_de_app.log"
    Write-Host "Creando archivo: $testFile2"
    Set-Content -Path $testFile2 -Value "Todo funciona bien."
    Start-Sleep -Seconds 2 
    
    Write-Host "Modificando archivo para disparar regex 'ERROR'..."
    Add-Content -Path $testFile2 -Value "¡Oh no, ha ocurrido un ERROR!"
    
    Start-Sleep -Seconds 2
    Write-Host "`n"

# 6. --- TEST: Verificar el archivo de Log ---
    Write-Host "--- 6. TEST: Verificar el archivo de log (AHORA sí debería existir) ---" -ForegroundColor Yellow
    
    if (Test-Path $logFile) {
        $logContent = Get-Content $logFile
        Write-Host "Contenido del log ($logFile):"
        $logContent | Write-Host
        
        Write-Host "`n--- Verificaciones de Alertas ---"
        
        # FIX: Usar comillas simples para que la cadena sea literal
        if ($logContent | Select-String -Pattern 'PALABRA_SECRETA' -SimpleMatch -Quiet) {
            Write-Host "VERIFICACIÓN (Simple): Patrón 'PALABRA_SECRETA' encontrado en el log." -ForegroundColor Green
        } else {
            Write-Host "FALLO (Simple): Patrón 'PALABRA_SECRETA' NO encontrado en el log." -ForegroundColor Red
        }
        
        # FIX: Usar comillas simples para que \b sea literal
        if ($logContent | Select-String -Pattern 'regex:\b(ERROR|FAIL|CRITICAL)\b' -SimpleMatch -Quiet) {
            Write-Host "VERIFICACIÓN (Regex): Patrón 'regex:...' (ERROR) encontrado en el log." -ForegroundColor Green
        } else {
            Write-Host "FALLO (Regex): Patrón 'regex:...' (ERROR) NO encontrado en el log." -ForegroundColor Red
        }
    } else {
        Write-Host "FALLO: El archivo de log no existe. Las alertas no se registraron." -ForegroundColor Red
    }
    
    Read-Host "Presiona Enter para continuar y detener el daemon..."
    Write-Host "`n"
}
catch {
    Write-Host "--- ERROR INESPERADO DURANTE LA PRUEBA ---" -ForegroundColor Red
    Write-Error $_.Exception.Message
}
finally {
    # 7. --- LIMPIEZA: Detener el Daemon ---
    Write-Host "--- 7. LIMPIEZA: Detener el Daemon ---" -ForegroundColor Yellow
    $comandoKill = "$scriptPrincipal -repo `"$testRepoDir`" -kill"
    Write-Host "Ejecutando: $comandoKill"
    
    & $scriptPrincipal -repo $testRepoDir -kill
    Start-Sleep -Seconds 2

    Write-Host "Limpiando entorno de prueba..."
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Directorio temporal eliminado: $tempDir"
    }
    
    # Limpieza extra por si el -kill falló y el .pid quedó huérfano
    if ($pidFileParaLimpieza -and (Test-Path $pidFileParaLimpieza)) {
        Write-Host "Limpiando archivo PID huérfano..." -ForegroundColor Gray
        Remove-Item $pidFileParaLimpieza -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "`n--- PRUEBAS FINALIZADAS ---" -ForegroundColor Cyan
}