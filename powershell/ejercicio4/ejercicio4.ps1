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
    Se ejecuta en segundo plano liberando la terminal.

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
    Inicia el monitoreo del directorio en segundo plano usando eventos de PowerShell.

.EXAMPLE
    ./ejercicio4.ps1 -repo ./myrepo -kill
    Detiene el monitoreo del directorio.

.EXAMPLE
    Get-Content ./audit.log -Wait -Tail 20
    Ver logs en tiempo real del monitoreo.
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

# === LÓGICA PRINCIPAL ===
try {
    # Validar que el parámetro Repo no esté vacío
    if (-not $repo) { throw "El parámetro -repo es obligatorio" }
    
    # Convertir rutas relativas a absolutas para consistencia
    $absoluteRepoPath = (Resolve-Path -LiteralPath $repo -ErrorAction Stop).Path
    
    # --- Lógica para detener el monitoreo (-Kill) ---
    if ($kill) {
        $watcherId = Get-WatcherIdentifier -repoPath $absoluteRepoPath
        $jobName = "GitAudit_Job_$watcherId"
        
        # Detener job si existe
        $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
        if ($job) {
            Stop-Job -Name $jobName -ErrorAction SilentlyContinue
            Remove-Job -Name $jobName -Force -ErrorAction SilentlyContinue
            Write-Host "`n Monitoreo detenido exitosamente." -ForegroundColor Green
            Write-Host "  Directorio: $absoluteRepoPath" -ForegroundColor Cyan
            Write-Host "  Job '$jobName' eliminado." -ForegroundColor Cyan
            Write-Host "  Los logs se mantienen intactos.`n" -ForegroundColor Yellow
        } else {
            Write-Host "`n No se encontró monitoreo activo para el directorio: $absoluteRepoPath" -ForegroundColor Yellow
            Write-Host "  Tip: Use 'Get-Job' para ver todos los jobs activos.`n" -ForegroundColor DarkGray
        }
        
        exit 0
    }

    # --- Lógica para iniciar el monitoreo ---
    if ($configuracion -and $log) {
        # Validar y resolver rutas de configuración y log
        if (-not (Test-Path -LiteralPath $configuracion)) { 
            throw "El archivo de configuración no existe: $configuracion" 
        }
        $absoluteConfigFile = (Resolve-Path -LiteralPath $configuracion).Path
        
        $absoluteLogFile = $log
        if (-not [System.IO.Path]::IsPathRooted($log)) {
            $absoluteLogFile = Join-Path -Path (Get-Location) -ChildPath $log
        }
        
        # Generar identificador único para este directorio
        $watcherId = Get-WatcherIdentifier -repoPath $absoluteRepoPath
        $jobName = "GitAudit_Job_$watcherId"
        
        # Verificar si ya existe un job corriendo para este directorio
        $existingJob = Get-Job -Name $jobName -ErrorAction SilentlyContinue
        if ($existingJob) {
            Write-Host "`n Ya existe un monitoreo activo para este directorio." -ForegroundColor Red
            Write-Host "  Directorio: $absoluteRepoPath" -ForegroundColor Cyan
            Write-Host "  Job Name:   $jobName" -ForegroundColor Cyan
            Write-Host "  Estado:     $($existingJob.State)" -ForegroundColor Yellow
            Write-Host "`n  Use el siguiente comando para detenerlo:" -ForegroundColor DarkGray
            Write-Host "  .\ejercicio4.ps1 -repo '$repo' -kill`n" -ForegroundColor White
            exit 1
        }
        
        # Crear el ScriptBlock que se ejecutará en segundo plano
        $monitoringScript = {
            param($RepoPath, $ConfigFile, $LogFile)
            
            # === Funciones necesarias dentro del job ===
            
            function Get-WatcherIdentifier {
                param([string]$repoPath)
                $hash = [System.BitConverter]::ToString(
                    [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                        [System.Text.Encoding]::UTF8.GetBytes($repoPath.ToLower())
                    )
                ).Replace("-", "").Substring(0, 16)
                return "GitAudit_$hash"
            }
            
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
            }
            
            function Get-Patterns {
                param([string]$ConfigFile)
                
                if (-not (Test-Path $ConfigFile)) {
                    Write-AuditLog -Message "Archivo de configuración no encontrado: $ConfigFile" -LogPath $LogFile -Level "ERROR"
                    return @()
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
            
            # === Inicio del monitoreo ===
            
            try {
                # Validar parámetros
                if (-not (Test-Path $RepoPath)) { 
                    throw "El repositorio no existe: $RepoPath" 
                }
                if (-not (Test-Path $ConfigFile)) { 
                    throw "El archivo de configuración no existe: $ConfigFile" 
                }
                
                # Crear archivo de log si no existe
                if (-not (Test-Path $LogFile)) {
                    New-Item -Path $LogFile -ItemType File -Force | Out-Null
                }
                
                # Leer patrones de configuración
                $patterns = @(Get-Patterns -ConfigFile $ConfigFile)
                
                Write-AuditLog -Message "=== MONITOREO INICIADO ===" -LogPath $LogFile -Level "INFO"
                Write-AuditLog -Message "Repositorio: $RepoPath" -LogPath $LogFile -Level "INFO"
                Write-AuditLog -Message "Patrones cargados: $($patterns.Count)" -LogPath $LogFile -Level "INFO"
                Write-AuditLog -Message "Patrones: $($patterns -join ', ')" -LogPath $LogFile -Level "INFO"
                
                # Crear FileSystemWatcher
                $watcher = New-Object System.IO.FileSystemWatcher
                $watcher.Path = $RepoPath
                $watcher.Filter = "*.*"
                $watcher.IncludeSubdirectories = $true
                $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite
                
                # Obtener identificador único para este watcher
                $watcherId = Get-WatcherIdentifier -repoPath $RepoPath
                
                # Crear el script block que se ejecutará cuando ocurra un evento
                # Necesitamos capturar las variables en el scope actual
                $capturedLogFile = $LogFile
                $capturedPatterns = $patterns
                
                $actionScript = {
                    param($sender, $eventArgs)
                    
                    $filePath = $eventArgs.FullPath
                    $fileNameOnly = Split-Path $filePath -Leaf
                    
                    # Ignorar directorios, archivos del directorio .git y archivos temporales
                    if ((Test-Path $filePath -PathType Container) -or 
                        $fileNameOnly -match "^\.git" -or 
                        $fileNameOnly -match "^\.") { return }
                    if ($fileNameOnly -match "(\.tmp|\.lock|~)$") { return }
                    
                    # Usar las variables del scope del job
                    $jobLogFile = $Event.MessageData.LogFile
                    $jobPatterns = $Event.MessageData.Patterns
                    
                    # Función Write-AuditLog inline
                    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    $logEntry = "[$timestamp] [INFO] Archivo modificado: $($eventArgs.Name) (evento: $($eventArgs.ChangeType))"
                    Add-Content -Path $jobLogFile -Value $logEntry
                    
                    # Escanear el archivo
                    if (Test-Path $filePath -PathType Leaf) {
                        Start-Sleep -Milliseconds 300
                        
                        try {
                            $content = Get-Content $filePath -ErrorAction SilentlyContinue
                            
                            foreach ($patron in $jobPatterns) {
                                if ([string]::IsNullOrWhiteSpace($patron)) { continue }
                                
                                try {
                                    if ($content -match $patron) {
                                        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                                        $alertEntry = "[$timestamp] [ALERTA] Alerta: patrón '$patron' encontrado en el archivo '$fileNameOnly'."
                                        Add-Content -Path $jobLogFile -Value $alertEntry
                                    }
                                } catch {
                                    # Silenciar errores de regex inválido
                                }
                            }
                        } catch {
                            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                            $errorEntry = "[$timestamp] [ERROR] Error al escanear $filePath : $($_.Exception.Message)"
                            Add-Content -Path $jobLogFile -Value $errorEntry
                        }
                    }
                }
                
                # Registrar los eventos de cambio de archivo
                $eventNames = @("Created", "Changed", "Renamed")
                
                # Crear MessageData para pasar datos al evento
                $messageData = @{
                    LogFile = $LogFile
                    Patterns = $patterns
                }
                
                foreach ($eventName in $eventNames) {
                    $eventSourceIdentifier = "$watcherId`_$eventName"
                    
                    # Desuscribir si ya existe una suscripción previa (limpieza)
                    Get-EventSubscriber -SourceIdentifier $eventSourceIdentifier -ErrorAction SilentlyContinue | 
                        Unregister-Event -Force -ErrorAction SilentlyContinue
                    
                    # Registrar el nuevo evento con MessageData
                    Register-ObjectEvent -InputObject $watcher -EventName $eventName `
                        -SourceIdentifier $eventSourceIdentifier `
                        -MessageData $messageData `
                        -Action $actionScript | Out-Null   
                    
                    Write-AuditLog -Message "Evento '$eventName' registrado" -LogPath $LogFile -Level "INFO"
                }
                
                # Habilitar el watcher
                $watcher.EnableRaisingEvents = $true
                
                Write-AuditLog -Message "Monitoreo activo en segundo plano" -LogPath $LogFile -Level "INFO"
                
                # Mantener el script en ejecución
                try {
                    while ($true) {
                        Start-Sleep -Seconds 1
                    }
                } finally {
                    # Limpieza de eventos y watcher
                    Write-AuditLog -Message "Deteniendo monitoreo..." -LogPath $LogFile -Level "INFO"
                    
                    $watcher.EnableRaisingEvents = $false
                    $watcher.Dispose()
                    
                    # Desuscribir todos los eventos de este watcher
                    foreach ($eventName in $eventNames) {
                        $eventSourceIdentifier = "$watcherId`_$eventName"
                        Get-EventSubscriber -SourceIdentifier $eventSourceIdentifier -ErrorAction SilentlyContinue | 
                            Unregister-Event -Force -ErrorAction SilentlyContinue
                    }
                    
                    Write-AuditLog -Message "=== MONITOREO DETENIDO ===" -LogPath $LogFile -Level "INFO"
                }
                
            } catch {
                Write-AuditLog -Message "ERROR FATAL: $($_.Exception.Message)" -LogPath $LogFile -Level "ERROR"
                throw
            }
        }
        
        # Iniciar el job en segundo plano
        $job = Start-Job -Name $jobName -ScriptBlock $monitoringScript -ArgumentList $absoluteRepoPath, $absoluteConfigFile, $absoluteLogFile
        
        # Esperar un momento para verificar que el job inició correctamente
        Start-Sleep -Milliseconds 500
        $jobState = (Get-Job -Name $jobName).State
        
        if ($jobState -eq "Failed") {
            $errorInfo = Receive-Job -Name $jobName 2>&1
            Remove-Job -Name $jobName -Force
            Write-Host "`n Error al iniciar el monitoreo:" -ForegroundColor Red
            Write-Host "  $errorInfo`n" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║    Monitoreo iniciado en segundo plano exitosamente    ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host "`n Directorio monitoreado:" -ForegroundColor Cyan
        Write-Host "   $absoluteRepoPath" -ForegroundColor White
        Write-Host "`n Job Information:" -ForegroundColor Cyan
        Write-Host "   Job ID:   $($job.Id)" -ForegroundColor White
        Write-Host "   Job Name: $jobName" -ForegroundColor White
        Write-Host "   Estado:   $jobState" -ForegroundColor Green
        Write-Host "`n Archivo de logs:" -ForegroundColor Cyan
        Write-Host "   $absoluteLogFile" -ForegroundColor White
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "Comandos útiles:" -ForegroundColor Yellow
        Write-Host "  Ver todos los jobs activos:" -ForegroundColor DarkGray
        Write-Host "    Get-Job" -ForegroundColor White
        Write-Host "`n  Ver logs en tiempo real:" -ForegroundColor DarkGray
        Write-Host "    Get-Content '$absoluteLogFile' -Wait -Tail 20" -ForegroundColor White
        Write-Host "`n  Detener este monitoreo:" -ForegroundColor DarkGray
        Write-Host "    .\ejercicio4.ps1 -repo '$repo' -kill" -ForegroundColor White
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray
        
        exit 0
        
    } elseif ($configuracion -or $log) {
        throw "Debe especificar tanto -configuracion como -log para iniciar el monitoreo"
    } else {
        Write-Host "`nUso del script de monitoreo:" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "`nIniciar monitoreo en segundo plano:" -ForegroundColor Green
        Write-Host "  .\ejercicio4.ps1 -repo <ruta> -configuracion <archivo> -log <archivo>" -ForegroundColor Cyan
        Write-Host "`nEjemplo:" -ForegroundColor Green
        Write-Host "  .\ejercicio4.ps1 -repo ./myrepo -configuracion ./patrones.conf -log ./audit.log" -ForegroundColor White
        Write-Host "`nDetener monitoreo:" -ForegroundColor Green
        Write-Host "  .\ejercicio4.ps1 -repo <ruta> -kill" -ForegroundColor Cyan
        Write-Host "`nVer ayuda completa:" -ForegroundColor Green
        Write-Host "  .\ejercicio4.ps1 -help" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host ""
        exit 1
    }

} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host "ScriptStackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
    exit 1
}