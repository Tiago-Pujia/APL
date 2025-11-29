# EJERCICIO 4
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Demonio de análisis de seguridad basado en eventos de PowerShell

.DESCRIPTION
    Script demonio que monitorea un repositorio o directorio detectando credenciales o datos
    sensibles usando FileSystemWatcher y Register-EngineEvent. Implementa un sistema de
    eventos basado en PowerShell que reacciona automáticamente a cambios de archivos.

.PARAMETER repo
    Ruta del directorio a monitorear (obligatorio).

.PARAMETER configuracion
    Ruta del archivo de configuración con patrones a buscar (obligatorio).

.PARAMETER log
    Ruta del archivo de logs donde se registran los eventos (opcional).

.PARAMETER kill
    Flag para detener el monitoreo en ejecución para un directorio.

.PARAMETER help
    Muestra esta ayuda y sale.

.EXAMPLE
    ./ejercicio4.ps1 -repo ./myrepo -configuracion ./patrones.conf -log ./audit.log
    Inicia el monitoreo del directorio usando eventos de PowerShell.

.EXAMPLE
    ./ejercicio4.ps1 -repo ./myrepo -kill
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
    [string]$log,

    [Parameter(Mandatory=$false)]
    [Alias("k")]
    [switch]$kill,

    [Alias('h')]
    [switch]$help
)

# Mostrar ayuda si se solicita
if ($help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

# === Funciones Auxiliares ===

# Genera un identificador único para el watcher basado en la ruta
function Get-WatcherIdentifier {
    param([string]$repoPath)
    $hash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($repoPath.ToLower())
        )
    ).Replace("-", "").Substring(0, 16)
    return "GitAudit_$hash"
}

# Función para registrar eventos en el log con nivel y timestamp
function Write-AuditLog {
    param(
        [string]$Message,
        [string]$LogPath,
        [ValidateSet("INFO", "ALERTA", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logEntry
    
    $color = switch ($Level) {
        "ALERTA" { "Yellow" }
        "ERROR" { "Red" }
        default { "Green" }
    }
    Write-Host $logEntry -ForegroundColor $color
}

# Función para cargar patrones desde archivo de configuración
function Get-Patterns {
    param([string]$ConfigFile)
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Archivo de configuración no encontrado: $ConfigFile" -ForegroundColor Red
        return $null
    }
    
    $patterns = @()
    $lines = Get-Content $ConfigFile
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $patterns += $line
        }
    }
    
    return $patterns
}

# Función para escanear un archivo en busca de patrones
function Scan-FileForPatterns {
    param(
        [string]$FilePath,
        [string[]]$Patterns,
        [string]$LogPath
    )
    
    if (-not (Test-Path $FilePath -PathType Leaf)) { return }
    
    # Esperar un poco para asegurar que el archivo esté completamente escrito
    Start-Sleep -Milliseconds 300
    
    try {
        $content = Get-Content $FilePath -ErrorAction SilentlyContinue
        
        foreach ($patron in $Patterns) {
            if ([string]::IsNullOrWhiteSpace($patron)) { continue }
            
            try {
                if ($content -match $patron) {
                    $logEntry = "Alerta: patrón '$patron' encontrado en el archivo '$(Split-Path $FilePath -Leaf)'."
                    Write-AuditLog -Message $logEntry -LogPath $LogPath -Level "ALERTA"
                }
            } catch {
                # Silenciar errores de regex inválido
            }
        }
    } catch {
        Write-AuditLog -Message "Error al escanear $FilePath : $($_.Exception.Message)" -LogPath $LogPath -Level "ERROR"
    }
}

# === Función para iniciar el monitoreo usando FileSystemWatcher ===

function Start-RepositoryMonitoring {
    param(
        [string]$RepoPath,
        [string]$ConfigFile,
        [string]$LogFile
    )
    
    # Validar parámetros
    if (-not (Test-Path $RepoPath)) { throw "El repositorio no existe: $RepoPath" }
    if (-not (Test-Path $ConfigFile)) { throw "El archivo de configuración no existe: $ConfigFile" }
    
    # Crear archivo de log si no existe
    if (-not (Test-Path $LogFile)) {
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
    }
    
    # Leer patrones de configuración
    $patterns = @(Get-Patterns -ConfigFile $ConfigFile)
    
    Write-AuditLog -Message "Iniciando monitoreo del repositorio: $RepoPath" -LogPath $LogFile -Level "INFO"
    Write-AuditLog -Message "Patrones a buscar: $($patterns -join ', ')" -LogPath $LogFile -Level "INFO"
    
    # Crear FileSystemWatcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $RepoPath
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite
    
    # Obtener identificador único para este watcher
    $watcherId = Get-WatcherIdentifier -repoPath $RepoPath
    
    # Crear el script block que se ejecutará cuando ocurra un evento
    $actionScript = {
        param($eventArgs)
        
        $filePath = $eventArgs.FullPath
        $fileNameOnly = Split-Path $filePath -Leaf
        
        # Ignorar directorios, archivos del directorio .git y archivos temporales
        if ((Test-Path $filePath -PathType Container) -or 
            $fileNameOnly -match "^\.git" -or 
            $fileNameOnly -match "^\.") { return }
        if ($fileNameOnly -match "(\.tmp|\.lock|~)$") { return }
        
        Write-AuditLog -Message "Archivo modificado: $($eventArgs.Name) (evento: $($eventArgs.ChangeType))" -LogPath $using:LogFile -Level "INFO"
        
        # Escanear el archivo modificado
        Scan-FileForPatterns -FilePath $filePath -Patterns $using:patterns -LogPath $using:LogFile
    }
    
    # Registrar los eventos de cambio de archivo
    $eventNames = @("Created", "Changed", "Renamed")
    
    foreach ($eventName in $eventNames) {
        $eventSourceIdentifier = "$watcherId`_$eventName"
        
        # Desuscribir si ya existe una suscripción previa (limpieza)
        Get-EventSubscriber -SourceIdentifier $eventSourceIdentifier -ErrorAction SilentlyContinue | 
            Unregister-Event -Force -ErrorAction SilentlyContinue
        
        # Registrar el nuevo evento
        Register-ObjectEvent -InputObject $watcher -EventName $eventName `
            -SourceIdentifier $eventSourceIdentifier -Action $actionScript | Out-Null
        
        Write-AuditLog -Message "Evento '$eventName' registrado para FileSystemWatcher" -LogPath $LogFile -Level "INFO"
    }
    
    # Habilitar el watcher
    $watcher.EnableRaisingEvents = $true
    
    Write-AuditLog -Message "Monitoreo activo. Presiona Ctrl+C para detener." -LogPath $LogFile -Level "INFO"
    Write-Host "`nMonitoreo en tiempo real activo. Presiona Ctrl+C para detener." -ForegroundColor Green
    
    # Mantener el script en ejecución
    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    } finally {
        # Limpieza de eventos y watcher
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
        
        # Desuscribir todos los eventos de este watcher
        foreach ($eventName in $eventNames) {
            $eventSourceIdentifier = "$watcherId`_$eventName"
            Get-EventSubscriber -SourceIdentifier $eventSourceIdentifier -ErrorAction SilentlyContinue | 
                Unregister-Event -Force -ErrorAction SilentlyContinue
        }
        
        Write-AuditLog -Message "Monitoreo detenido. Limpieza completada." -LogPath $LogFile -Level "INFO"
    }
}

# === LÓGICA PRINCIPAL ===
try {
    # Validar que el parámetro Repo no esté vacío
    if (-not $repo) { throw "El parámetro -repo es obligatorio" }
    
    # Convertir rutas relativas a absolutas para consistencia
    $absoluteRepoPath = (Resolve-Path -LiteralPath $repo -ErrorAction Stop).Path
    
    # --- Lógica para detener el monitoreo (-Kill) ---
    if ($kill) {
        $watcherId = Get-WatcherIdentifier -repoPath $absoluteRepoPath
        $eventNames = @("Created", "Changed", "Renamed")
        $foundAny = $false
        
        foreach ($eventName in $eventNames) {
            $eventSourceIdentifier = "$watcherId`_$eventName"
            $subscribers = @(Get-EventSubscriber -SourceIdentifier $eventSourceIdentifier -ErrorAction SilentlyContinue)
            
            if ($subscribers.Count -gt 0) {
                $foundAny = $true
                $subscribers | Unregister-Event -Force
                Write-Host "Evento '$eventSourceIdentifier' desinscrito." -ForegroundColor Green
            }
        }
        
        if ($foundAny) {
            Write-Host "Monitoreo detenido exitosamente para el repositorio: $absoluteRepoPath" -ForegroundColor Green
        } else {
            Write-Host "No se encontraron eventos en ejecución para el repositorio: $absoluteRepoPath" -ForegroundColor Yellow
        }
        
        exit 0
    }

    # --- Lógica para iniciar el monitoreo ---
    if ($configuracion -and $log) {
        # Validar y resolver rutas de configuración y log
        if (-not (Test-Path -LiteralPath $configuracion)) { throw "El archivo de configuración no existe: $configuracion" }
        $absoluteConfigFile = (Resolve-Path -LiteralPath $configuracion).Path
        
        $absoluteLogFile = $log
        if (-not [System.IO.Path]::IsPathRooted($log)) {
            $absoluteLogFile = Join-Path -Path (Get-Location) -ChildPath $log
        }
        
        # Iniciar el monitoreo con eventos
        Start-RepositoryMonitoring -RepoPath $absoluteRepoPath -ConfigFile $absoluteConfigFile -LogFile $absoluteLogFile
    } elseif ($configuracion -or $log) {
        throw "Debe especificar tanto -configuracion como -log"
    } else {
        Write-Host "Uso para iniciar monitoreo:" -ForegroundColor Yellow
        Write-Host "  .\ejercicio4.ps1 -repo <ruta> -configuracion <archivo> -log <archivo>" -ForegroundColor Cyan
        Write-Host "`nUso para detener monitoreo:" -ForegroundColor Yellow
        Write-Host "  .\ejercicio4.ps1 -repo <ruta> -kill" -ForegroundColor Cyan
        exit 1
    }

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "ScriptStackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}