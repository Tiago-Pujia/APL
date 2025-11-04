# EJERCICIO 4
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Demonio para monitorear cambios en directorios usando FileSystemWatcher.

.DESCRIPTION
    Este script funciona como un demonio que monitorea un directorio en busca de cambios
    usando FileSystemWatcher. Cuando detecta modificaciones, escanea los archivos
    cambiados en busca de patrones definidos en un archivo de configuración y genera
    alertas en un archivo de log.

.PARAMETER repo
    Ruta del directorio a monitorear.

.PARAMETER configuracion
    Ruta del archivo de configuración con patrones a buscar.

.PARAMETER log
    Ruta del archivo de logs (opcional, por defecto: ./daemon.log).

.PARAMETER kill
    Flag para detener el demonio en ejecución.

.PARAMETER help
    Muestra esta ayuda y sale.

.EXAMPLE
    ./ejercicio4.ps1 -repo /home/user/mydir -configuracion ./patrones.conf
    Inicia el monitoreo del directorio en segundo plano.

.EXAMPLE
    ./ejercicio4.ps1 -repo /home/user/mydir -kill
    Detiene el monitoreo del directorio.
#>

param(
    [Parameter(Mandatory=$false)]
    [Alias("r")]
    [string]$repo,

    [Parameter(Mandatory=$false)]
    [Alias("c")]
    [string]$configuracion,

    [Parameter(Mandatory=$false)]
    [Alias("l")]
    [string]$log = $null,

    [Parameter(Mandatory=$false)]
    [Alias("k")]
    [switch]$kill,

    [Alias('h')]
    [switch]$help,

    [Parameter(Mandatory=$false)]
    [switch]$__daemon  # Parámetro interno para el proceso daemon
)

# Mostrar ayuda si se solicita
if ($help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

# === Directorio para almacenar info de monitores activos ===
$pidDir = "$HOME/.dir_monitor_pids"
if (-not (Test-Path $pidDir)) {
    New-Item -ItemType Directory -Path $pidDir | Out-Null
}

# === Funciones auxiliares ===

function Get-PidFile {
    param([string]$dirPath)
    $hash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($dirPath)
        )
    ).Replace("-", "").Substring(0, 16)
    return Join-Path $pidDir "monitor_$hash.pid"
}

function Write-Log {
    param([string]$message, [string]$logFile)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $message"
}

function Get-Patterns {
    param([string]$configFile)
    
    if (-not (Test-Path $configFile)) {
        Write-Host "Archivo de configuración no encontrado: $configFile" -ForegroundColor Red
        exit 1
    }
    
    $patterns = @()
    $lines = Get-Content $configFile
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            if ($line.StartsWith("regex:")) {
                $patterns += @{
                    Type    = "regex"
                    Pattern = $line.Substring(6)
                    Display = $line
                }
            } else {
                $patterns += @{
                    Type    = "simple"
                    Pattern = $line
                    Display = $line
                }
            }
        }
    }
    
    return $patterns
}

function Scan-FileContent {
    param(
        [string]$filePath,
        [array]$patterns,
        [string]$logFile,
        [string]$changeType
    )

    try {
        Start-Sleep -Milliseconds 300
        
        if (-not (Test-Path $filePath -PathType Leaf)) {
             return
        }

        $content = Get-Content $filePath -ErrorAction Stop
        
        $matchesFound = 0
        foreach ($pattern in $patterns) {
            $found = $false
            try {
                if ($pattern.Type -eq "regex") {
                    # -match contra un array devuelve las líneas que coinciden
                    if ($content -match $pattern.Pattern) { $found = $true }
                } else {
                    # -match contra un array devuelve las líneas que coinciden
                    if ($content -match [regex]::Escape($pattern.Pattern)) { $found = $true }
                }
                
                if ($found) {
                    $matchesFound++
                    $msg = "Alerta: patrón '{0}' encontrado en el archivo '{1}'." -f $pattern.Display, $filePath
                    Write-Log -message $msg -logFile $logFile
                }
            }
            catch {
                # Silencioso
            }
        }
    }
    catch {
        # Silencioso
    }
}

# === Inicio del monitoreo (proceso daemon) ===

function Start-Monitor {
    param(
        [string]$dirPath,
        [string]$configFile,
        [string]$logFile
    )

    if (-not (Test-Path $dirPath)) {
        Write-Log -message "ERROR: Directorio no encontrado: $dirPath" -logFile $logFile
        exit 1
    }

    $pidFile = Get-PidFile $dirPath
    if (Test-Path $pidFile) {
        Write-Log -message "ERROR: Ya hay un monitoreo activo para este directorio" -logFile $logFile
        exit 1
    }

    $patterns = Get-Patterns $configFile

    $global:MonitorLogFile = $logFile
    $global:MonitorPatterns = $patterns

    $info = @{
        PID          = $PID
        Directory    = $dirPath
        StartTime    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        LogFile      = $logFile
        PatternCount = $patterns.Count
    }
    $info | ConvertTo-Json | Set-Content $pidFile


    $watcher = $null
    $eventSubscriptions = $null 

    try {
        
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $dirPath
        $watcher.IncludeSubdirectories = $true
        $watcher.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, Size'
        
        $action = {

            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $name = $Event.SourceEventArgs.Name
            
            if ((Test-Path $path -PathType Container) -or ($name -match '~$|\.tmp$|^\.')) {
                return
            }
            
            Scan-FileContent -filePath $path -patterns $global:MonitorPatterns -logFile $global:MonitorLogFile -changeType $changeType
        }

        $eventSubscriptions = @(
            Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action -SourceIdentifier "DirMonitor.Created"
            Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action -SourceIdentifier "DirMonitor.Changed"
            Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $action -SourceIdentifier "DirMonitor.Renamed"
        )

        $watcher.EnableRaisingEvents = $true

        do
        {
            Wait-Event -Timeout 1
            
            if (-not (Test-Path $pidFile)) {
                 break
            }
        } while ($true)

    }
    catch {

    }
    finally {
        if ($eventSubscriptions) {
            foreach ($eventJob in $eventSubscriptions) {
                Unregister-Event -SourceIdentifier $eventJob.Name -ErrorAction SilentlyContinue
            }
        }
        if ($watcher) {
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
        }

        if (Test-Path $pidFile) {
            Remove-Item $pidFile -Force
        }
        
        Remove-Variable -Name "MonitorLogFile" -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name "MonitorPatterns" -Scope Global -ErrorAction SilentlyContinue

    }
}

function Stop-Monitor {
    param([string]$dirPath)

    $pidFile = Get-PidFile $dirPath
    if (-not (Test-Path $pidFile)) {
        Write-Host "No hay monitoreo activo para este directorio." -ForegroundColor Red
        exit 1
    }

    $info = Get-Content $pidFile | ConvertFrom-Json
    $monitorPID = $info.PID
    
    Write-Host "Deteniendo monitoreo (PID: $monitorPID)..." -ForegroundColor Yellow

    try {
        $process = Get-Process -Id $monitorPID -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $monitorPID -Force
            Write-Host "Proceso (PID: $monitorPID) detenido forzosamente." -ForegroundColor Green
        } else {
            Write-Host "El proceso ya no está corriendo. Limpiando archivo PID..." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "No se pudo detener el proceso: $_" -ForegroundColor Red
    }
    finally {
        if (Test-Path $pidFile) {
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        }
    }
}


# === Lanzar proceso daemon ===
function Start-Daemon {
    param(
        [string]$dirPath,
        [string]$configFile,
        [string]$logFile
    )

    if (-not (Test-Path $dirPath)) {
        Write-Host "Directorio no encontrado: $dirPath" -ForegroundColor Red
        exit 1
    }

    $pidFile = Get-PidFile $dirPath
    if (Test-Path $pidFile) {
        Write-Host "Ya hay un monitoreo activo para este directorio." -ForegroundColor Yellow
        Write-Host "   Use -kill para detenerlo primero." -ForegroundColor Yellow
        exit 1
    }

    $patterns = Get-Patterns $configFile
    Write-Host "Cargados $($patterns.Count) patrones de búsqueda" -ForegroundColor Green

    $scriptPath = $MyInvocation.PSCommandPath
    
    # Construimos una sola cadena de argumentos, poniendo comillas dobles
    # alrededor de todas las rutas que puedan contener espacios.
    $argString = "-File `"$scriptPath`" -__daemon -repo `"$dirPath`" -configuracion `"$configFile`" -log `"$finalLogPath`""

    Write-Host "`nLanzando daemon en segundo plano..." -ForegroundColor Cyan
    Write-Host "Comando: pwsh $argString" -ForegroundColor Gray

    # Pasamos la cadena de texto completa a -ArgumentList
    Start-Process -FilePath "pwsh" -ArgumentList $argString -NoNewWindow
    
    Write-Host "Esperando la creación del archivo PID del demonio..."
    Start-Sleep -Seconds 3

    if (Test-Path $pidFile) {
        $info = Get-Content $pidFile | ConvertFrom-Json
        Write-Host "   Daemon iniciado exitosamente" -ForegroundColor Green
        Write-Host "   PID:          $($info.PID)" -ForegroundColor Cyan
        Write-Host "   Directorio:   $dirPath" -ForegroundColor Cyan
        Write-Host "   Log:          $logFile" -ForegroundColor Cyan
        Write-Host "   Patrones:     $($info.PatternCount)" -ForegroundColor Cyan
        Write-Host "Use './ejercicio4.ps1 -repo `"$dirPath`" -kill' para detener" -ForegroundColor Gray
    } else {
        Write-Host "El daemon pudo no haber iniciado correctamente" -ForegroundColor Yellow
        Write-Host "   Revise el archivo de log para más detalles: $logFile" -ForegroundColor Yellow
    }
}

# === LOGICA PRINCIPAL ===

if ($__daemon) {
    Start-Monitor -dirPath $repo -configFile $configuracion -logFile $log
    exit 0
}

if ($kill) {
    if (-not $repo) {
        Write-Host "Debe especificar el directorio con -repo para detener el monitoreo" -ForegroundColor Red
        exit 1
    }
    
    $dirFull = Resolve-Path $repo -ErrorAction SilentlyContinue
    if (-not $dirFull) {
        Stop-Monitor -dirPath $repo
    } else {
        Stop-Monitor -dirPath $dirFull.Path
    }
    exit 0
}

if (-not $repo -or -not $configuracion) {
    Get-Help $MyInvocation.MyCommand.Path
    exit 1
}

$dirFull = Resolve-Path $repo -ErrorAction SilentlyContinue
$confFull = Resolve-Path $configuracion -ErrorAction SilentlyContinue

$finalLogPath = $null

if (-not $log) {
    $baseName = Split-Path -Leaf $dirFull.Path
    $logFileName = "${baseName}.log"
    $finalLogPath = Join-Path $env:TEMP $logFileName
    
    Write-Host "No se especificó log. Usando log automático: $finalLogPath" -ForegroundColor Cyan
} else {
    if ([System.IO.Path]::IsPathRooted($log)) {
        $finalLogPath = $log
    } else {
        $finalLogPath = Convert-Path $log -ErrorAction SilentlyContinue
    }
}


if (-not $dirFull) {
    Write-Host "Directorio no encontrado: $repo" -ForegroundColor Red
    exit 1
}

if (-not $confFull) {
    Write-Host "Archivo de configuración no encontrado: $configuracion" -ForegroundColor Red
    exit 1
}

if (-not $finalLogPath) {
    Write-Host "Ruta de log inválida: $log" -ForegroundColor Red
    exit 1
}

Start-Daemon -dirPath $dirFull.Path -configFile $confFull.Path -logFile $finalLogPath