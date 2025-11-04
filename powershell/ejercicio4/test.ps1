# ===============================================
# SCRIPT DE PRUEBA MANUAL para ejercicio4.ps1 (Versión "Silenciosa")
# =Nota: El log se generará en este mismo directorio
# ===============================================

# --- 0. Funciones de Ayuda ---

function Log-TestResult {
    param(
        [bool]$Exito,
        [string]$MensajeExito,
        [string]$MensajeFalla
    )
    if ($Exito) {
        Write-Host "[ÉXITO] $MensajeExito" -ForegroundColor Green
    } else {
        Write-Host "[FALLA] $MensajeFalla" -ForegroundColor Red
    }
}

# Copiamos esta función de tu script para predecir el nombre del archivo PID
function Get-PidFile-Test {
    param([string]$dirPath, [string]$pidBaseDir)
    $hash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($dirPath)
        )
    ).Replace("-", "").Substring(0, 16)
    return Join-Path $pidBaseDir "monitor_$hash.pid"
}

# --- 1. Configuración del Entorno de Prueba ---

Write-Host "--- Configurando entorno de prueba ---" -ForegroundColor Cyan

$ScriptAbsPath = (Resolve-Path "ejercicio4.ps1").Path
$TestTempDir = Join-Path $env:TEMP "test_monitor_$(Get-Random)"

$RepoDir = Join-Path $TestTempDir "mi_repo_prueba"
$ConfigFile = Join-Path $TestTempDir "test_patrones.conf"
$PidDir = "$HOME/.dir_monitor_pids"

$LogFile = Join-Path $PWD "daemon.log"
Write-Host "El archivo de log de PRUEBA se generará en: $LogFile" -ForegroundColor Cyan

$PatronesDePrueba = @(
    "API_KEY_SECRETA"
    "regex:contraseña"
)

New-Item -ItemType Directory -Path $TestTempDir -Force | Out-Null
New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
$PatronesDePrueba | Set-Content -Path $ConfigFile
$PidFile = Get-PidFile-Test -dirPath $RepoDir -pidBaseDir $PidDir

Write-Host "Limpiando ejecuciones anteriores (si existen)..."
if (Test-Path $PidFile) {
    Write-Host "Se encontró un PID antiguo. Intentando detener el proceso..."
    & $ScriptAbsPath -repo $RepoDir -kill -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (Test-Path $PidFile) {
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    }
}
if (Test-Path $LogFile) { Remove-Item $LogFile }
Write-Host "Entorno listo en: $TestTempDir"

# --- 2. Inicio del Script de Prueba ---

try {
    Write-Host "`n--- TEST 1: Iniciar el demonio ---" -ForegroundColor Yellow
    
    # El script de prueba *inicia* el demonio usando el nombre de log "test_audit.log"
    Start-Process "pwsh" -ArgumentList "-File `"$ScriptAbsPath`" -repo `"$RepoDir`" -configuracion `"$ConfigFile`" -log `"$LogFile`"" -NoNewWindow
    Write-Host "Esperando 5 segundos a que el demonio se inicialice..."
    Start-Sleep -Seconds 5
    
    # --- PRUEBA DE INICIO SIMPLIFICADA ---
    # Ya no podemos leer el log. La única prueba de éxito es que el PID exista.
    $pidExiste = Test-Path $PidFile
    Log-TestResult $pidExiste "El archivo PID se creó correctamente." "El archivo PID no se encontró en $PidFile"

    if (-not $pidExiste) {
        throw "El demonio no pudo iniciar (no se creó el PID). Abortando pruebas."
    }
    # --- FIN DE LA SIMPLIFICACIÓN ---

    # -----------------------------------------------
    Write-Host "`n--- TEST 2: Evento 'Created' (Patrón simple) ---" -ForegroundColor Yellow
    
    $file1 = Join-Path $RepoDir "archivo_con_key.txt"
    "Este archivo contiene la API_KEY_SECRETA" | Set-Content -Path $file1
    Write-Host "Archivo creado. Esperando 4 segundos para la detección..."
    Start-Sleep -Seconds 4
    
    # Esta prueba sigue siendo válida, busca la ALERTA en el log
    $alertaCreada = Select-String -Path $LogFile -Pattern "Alerta: patrón 'API_KEY_SECRETA'.*en el archivo" -Quiet -ErrorAction SilentlyContinue
    Log-TestResult $alertaCreada "Log detectó 'ALERTA' para 'API_KEY_SECRETA' en evento 'Created'." "El log NO detectó la alerta para el archivo creado."
    
    # -----------------------------------------------
    Write-Host "`n--- TEST 3: Evento 'Changed' (Patrón Regex) ---" -ForegroundColor Yellow
    
    $file2 = Join-Path $RepoDir "archivo_sensible.ini"
    "user=admin" | Set-Content -Path $file2
    Write-Host "Archivo limpio creado. Esperando 2s..."
    Start-Sleep -Seconds 2 
    
    "mi contraseña está aquí" | Add-Content -Path $file2
    Write-Host "Archivo modificado con patrón. Esperando 4s para la detección..."
    Start-Sleep -Seconds 4
    
    # Esta prueba sigue siendo válida, busca la ALERTA en el log
    $alertaModificada = Select-String -Path $LogFile -Pattern "Alerta: patrón 'regex:contraseña'.*en el archivo" -Quiet -ErrorAction SilentlyContinue
    Log-TestResult $alertaModificada "Log detectó 'ALERTA' para 'regex:contraseña' en evento 'Changed'." "El log NO detectó la alerta para el archivo modificado."

    # -----------------------------------------------
    Write-Host "`n--- TEST 4: Detener el demonio ---" -ForegroundColor Yellow
    
    & $ScriptAbsPath -repo $RepoDir -kill
    Write-Host "Comando -kill enviado. Esperando 3 segundos para la detención..."
    Start-Sleep -Seconds 3
    
    # --- PRUEBA DE DETENCIÓN SIMPLIFICADA ---
    # Ya no podemos verificar el log "Monitoreo finalizado".
    # La única prueba de éxito es que el PID haya sido eliminado.
    $pidExiste = Test-Path $PidFile
    Log-TestResult (-not $pidExiste) "El archivo PID fue eliminado correctamente." "El archivo PID NO fue eliminado."
    # --- FIN DE LA SIMPLIFICACIÓN ---
}
catch {
    Write-Host "`n!!! ERROR CRÍTICO EN LA PRUEBA !!!" -ForegroundColor Red
    Write-Host $_
}
finally {
    # --- 3. Limpieza Final ---
    Write-Host "`n--- Limpiando entorno de prueba (directorio temporal) ---" -ForegroundColor Cyan
    
    if (Test-Path $PidFile) {
        Write-Host "Forzando detención final..."
        & $ScriptAbsPath -repo $RepoDir -kill -ErrorAction SilentlyContinue
    }
    
    if (Test-Path $TestTempDir) {
        Write-Host "Eliminando $TestTempDir"
        Remove-Item -Path $TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "--- PRUEBA FINALIZADA ---"
    Write-Host "El archivo 'daemon.log' se conservó en este directorio para revisión." -ForegroundColor Green
}