#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Demonio para monitorear cambios en repositorios Git y buscar patrones específicos.

.DESCRIPTION
    Este script funciona como un demonio que monitorea un repositorio Git en busca de cambios.
    Cuando detecta modificaciones, escanea los archivos cambiados en busca de patrones
    definidos en un archivo de configuración y genera alertas en un archivo de log.

.PARAMETER repo
    Ruta del repositorio Git a monitorear.

.PARAMETER configuracion
    Ruta del archivo de configuración con patrones a buscar.

.PARAMETER log
    Ruta del archivo de logs (opcional, por defecto: ./audit.log).

.PARAMETER alerta
    Intervalo en segundos para verificar cambios (opcional, por defecto: 10).

.PARAMETER kill
    Flag para detener el demonio en ejecución.

.PARAMETER help
    Muestra esta ayuda y sale.

.EXAMPLE
    ./audit.ps1 -repo /home/user/myrepo -configuracion ./patrones.conf -alerta 10

.EXAMPLE
    ./audit.ps1 -repo /home/user/myrepo -kill

.EXAMPLE
    ./audit.ps1 -help
#>

# EJERCICIO 4
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

param(
    [Parameter(Mandatory=$false)]
    [Alias("r")]
    [string]$repo,

    [Parameter(Mandatory=$false)]
    [Alias("c")]
    [string]$configuracion,

    [Parameter(Mandatory=$false)]
    [Alias("l")]
    [string]$log = "./audit.log",

    [Parameter(Mandatory=$false)]
    [Alias("a")]
    [int]$alerta = 10,

    [Parameter(Mandatory=$false)]
    [Alias("k")]
    [switch]$kill,

    [Alias('h')]
    [switch]$help
)

# Si pidieron help, mostramos la ayuda integrada
if ($help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit [int]0
}

# Directorio para almacenar PIDs de demonios
$pidDir = "$HOME/.git_monitor_pids"
if (-not (Test-Path $pidDir)) {
    New-Item -ItemType Directory -Path $pidDir -Force | Out-Null
}

# Función para obtener el archivo PID basado en el repositorio
function Get-PidFile {
    param([string]$repoPath)
    $repoHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($repoPath))
    $hashString = [System.BitConverter]::ToString($repoHash).Replace("-", "").Substring(0, 16)
    return Join-Path $pidDir "monitor_$hashString.pid"
}

# Función para verificar si un proceso está corriendo
function Test-ProcessRunning {
    param([int]$daemonPid)
    try {
        $process = Get-Process -Id $daemonPid -ErrorAction SilentlyContinue
        return $null -ne $process
    } catch {
        return $false
    }
}

# Función para detener el demonio
function Stop-Daemon {
    param([string]$repoPath)
    
    $pidFile = Get-PidFile -repoPath $repoPath
    
    if (-not (Test-Path $pidFile)) {
        Write-Host "❌ No hay ningún demonio en ejecución para este repositorio." -ForegroundColor Red
        exit 1
    }
    
    $daemonPid = Get-Content $pidFile
    
    if (Test-ProcessRunning -daemonPid $daemonPid) {
        try {
            Stop-Process -Id $daemonPid -Force
            Write-Host "✓ Demonio detenido (PID: $daemonPid)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error al detener el proceso: $_" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠ El proceso no está en ejecución. Limpiando archivo PID..." -ForegroundColor Yellow
    }
    
    Remove-Item $pidFile -Force
    exit 0
}

# Función para cargar patrones del archivo de configuración
function Get-Patterns {
    param([string]$configFile)
    
    if (-not (Test-Path $configFile)) {
        Write-Host "❌ Archivo de configuración no encontrado: $configFile" -ForegroundColor Red
        exit 1
    }
    
    $patterns = @()
    $lines = Get-Content $configFile
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            if ($line.StartsWith("regex:")) {
                $patterns += @{
                    Type = "regex"
                    Pattern = $line.Substring(6)
                    Display = $line
                }
            } else {
                $patterns += @{
                    Type = "simple"
                    Pattern = $line
                    Display = $line
                }
            }
        }
    }
    
    return $patterns
}

# Función para escribir en el log
function Write-Log {
    param(
        [string]$message,
        [string]$logFile
    )
        
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    
    # Asegurar que el directorio existe
    $logDir = Split-Path -Parent $logFile
    if ($logDir -and -not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Escribir al archivo
    Add-Content -Path $logFile -Value $logEntry -Force
}

# Función para escanear archivos
function Scan-Files {
    param(
        [string[]]$files,
        [array]$patterns,
        [string]$repoPath,
        [string]$logFile
    )
    
    foreach ($file in $files) {
        $fullPath = Join-Path $repoPath $file
        
        if (-not (Test-Path $fullPath) -or (Test-Path $fullPath -PathType Container)) {
            continue
        }
        
        try {
            $content = Get-Content $fullPath -Raw -ErrorAction SilentlyContinue
            
            if ($null -eq $content) {
                continue
            }
            
            foreach ($pattern in $patterns) {
                $found = $false
                
                if ($pattern.Type -eq "regex") {
                    if ($content -match $pattern.Pattern) {
                        $found = $true
                    }
                } else {
                    if ($content -match [regex]::Escape($pattern.Pattern)) {
                        $found = $true
                    }
                }
                
               if ($found) {
                $displayPattern = if ($pattern.Type -eq "regex") { $pattern.Display } else { $pattern.Pattern }
                $message = "Alerta: patrón '$displayPattern' encontrado en el archivo '$file'."
                Write-Log -message $message -logFile $logFile
                Write-Host "🚨 $message" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Log -message "Error al escanear archivo '$file': $_" -logFile $logFile
        }
    }
}

# Función principal del demonio
function Start-Daemon {
    param(
        [string]$repoPath,
        [string]$configFile,
        [string]$logFile,
        [int]$interval
    )
    
    # Validar repositorio
    if (-not (Test-Path $repoPath)) {
        Write-Host "❌ El repositorio no existe: $repoPath" -ForegroundColor Red
        exit 1
    }
    
    $gitDir = Join-Path $repoPath ".git"
    if (-not (Test-Path $gitDir)) {
        Write-Host "❌ El directorio no es un repositorio Git: $repoPath" -ForegroundColor Red
        exit 1
    }
    
    # Validar que no haya otro demonio corriendo
    $pidFile = Get-PidFile -repoPath $repoPath
    if (Test-Path $pidFile) {
        $existingPid = Get-Content $pidFile
        if (Test-ProcessRunning -daemonPid $existingPid) {
            Write-Host "❌ Ya existe un demonio en ejecución para este repositorio (PID: $existingPid)" -ForegroundColor Red
            exit 1
        } else {
            Remove-Item $pidFile -Force
        }
    }
    
    # Cargar patrones
    $patterns = Get-Patterns -configFile $configFile
    Write-Host "✓ Cargados $($patterns.Count) patrones de búsqueda" -ForegroundColor Green
    
    # Guardar PID del proceso actual
    $currentPid = $PID
    Set-Content -Path $pidFile -Value $currentPid
    Write-Host "✓ Demonio iniciado (PID: $currentPid)" -ForegroundColor Green
    Write-Host "📁 Repositorio: $repoPath" -ForegroundColor Cyan
    Write-Host "📋 Log: $logFile" -ForegroundColor Cyan
    Write-Host "⏱  Intervalo: $interval segundos" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log -message "Demonio iniciado. Monitoreando repositorio: $repoPath" -logFile $logFile
    
    # Obtener commit inicial
    Push-Location $repoPath
    $lastCommit = git rev-parse HEAD 2>$null
    Pop-Location
    
    # Loop principal de monitoreo
    while ($true) {
        Start-Sleep -Seconds $interval
        
        Push-Location $repoPath
        
        # Actualizar información del repositorio
        git fetch origin 2>&1 | Out-Null
        
        # Obtener commit actual
        $currentCommit = git rev-parse HEAD 2>$null
        
        # Verificar si hay cambios
        if ($currentCommit -ne $lastCommit) {
            Write-Host "🔍 Cambios detectados, escaneando..." -ForegroundColor Cyan
            
            # Obtener archivos modificados
            $changedFiles = git diff --name-only $lastCommit $currentCommit 2>$null
            
            if ($changedFiles) {
                $fileArray = $changedFiles -split "`n" | Where-Object { $_ }
                Write-Log -message "Detectados $($fileArray.Count) archivos modificados" -logFile $logFile
                
                Scan-Files -files $fileArray -patterns $patterns -repoPath $repoPath -logFile $logFile
            }
            
            $lastCommit = $currentCommit
        }
        
        Pop-Location
    }
}

# Script principal
if ($kill) {
    if (-not $repo) {
        Write-Host "❌ Debe especificar el repositorio con -repo para detener el demonio" -ForegroundColor Red
        exit 1
    }
    
    $repoFullPath = Resolve-Path $repo -ErrorAction SilentlyContinue
    if (-not $repoFullPath) {
        $repoFullPath = $repo
    }
    
    Stop-Daemon -repoPath $repoFullPath
} else {
    if (-not $repo -or -not $configuracion) {
        Write-Host "❌ Uso: ./audit.ps1 -repo <ruta> -configuracion <archivo> [-log <archivo>] [-alerta <segundos>]" -ForegroundColor Red
        Write-Host "        ./audit.ps1 -repo <ruta> -kill" -ForegroundColor Red
        exit 1
    }
    
    # Resolver rutas absolutas
    $repoFullPath = Resolve-Path $repo -ErrorAction SilentlyContinue
    if (-not $repoFullPath) {
        $repoFullPath = $repo
    }
    
    $configFullPath = Resolve-Path $configuracion -ErrorAction SilentlyContinue
    if (-not $configFullPath) {
        Write-Host "❌ Archivo de configuración no encontrado: $configuracion" -ForegroundColor Red
        exit 1
    }
    
    # Iniciar demonio
    Start-Daemon -repoPath $repoFullPath -configFile $configFullPath -logFile $log -interval $alerta
}   
