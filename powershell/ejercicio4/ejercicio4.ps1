
# EJERCICIO 4
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

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

.PARAMETER status
    Muestra el estado de los monitores activos.

.PARAMETER kill
    Flag para detener el demonio en ejecución.

.PARAMETER help
    Muestra esta ayuda y sale.

.EXAMPLE
    ./ejercicio4.ps1 -repo /home/user/myrepo -configuracion ./patrones.conf
    Inicia el monitoreo del repositorio en segundo plano.

.EXAMPLE
    ./ejercicio4.ps1 -status
    Muestra todos los monitores activos.

.EXAMPLE
    ./ejercicio4.ps1 -repo /home/user/myrepo -kill
    Detiene el monitoreo del repositorio.

.EXAMPLE
    ./ejercicio4.ps1 -repo /home/user/myrepo -configuracion ./patrones.conf -alerta 10 -log ./custom.log
    Inicia el monitoreo con configuración personalizada.
    
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
    [string]$log = "./audit.log",

    [Parameter(Mandatory=$false)]
    [Alias("a")]
    [int]$alerta = 5,

    [Parameter(Mandatory=$false)]
    [Alias("k")]
    [switch]$kill,

    [Parameter(Mandatory=$false)]
    [Alias("s")]
    [switch]$status,

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
$pidDir = "$HOME/.git_monitor_pids"
if (-not (Test-Path $pidDir)) { 
    New-Item -ItemType Directory -Path $pidDir | Out-Null 
}

# === Funciones auxiliares ===

function Get-PidFile {
    param([string]$repoPath)
    $hash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($repoPath)
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

function Get-CurrentBranch {
    param([string]$repoPath)
    
    Push-Location $repoPath
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    Pop-Location
    
    return $branch
}

function Get-LastCommitHash {
    param([string]$repoPath)
    
    Push-Location $repoPath
    $hash = git rev-parse HEAD 2>$null
    Pop-Location
    
    return $hash
}

function Get-ModifiedFilesInCommit {
    param([string]$repoPath, [string]$commitHash)
    
    Push-Location $repoPath
    $files = git diff-tree --no-commit-id --name-only -r $commitHash 2>$null
    Pop-Location
    
    return $files
}

function Get-FileContentAtCommit {
    param([string]$repoPath, [string]$commitHash, [string]$filePath)
    
    Push-Location $repoPath
    $content = git show "${commitHash}:${filePath}" 2>$null
    Pop-Location
    
    return $content
}

function Scan-FileContent {
    param(
        [string]$content,
        [string]$filePath,
        [array]$patterns,
        [string]$logFile,
        [string]$commitHash
    )
    
    if (-not $content) { return }

    foreach ($pattern in $patterns) {
        $found = $false
        
        if ($pattern.Type -eq "regex") {
            if ($content -match $pattern.Pattern) { $found = $true }
        } else {
            if ($content -match [regex]::Escape($pattern.Pattern)) { $found = $true }
        }
        
        if ($found) {
            $msg = "🚨 ALERTA: Patrón '$($pattern.Display)' encontrado en '$filePath' (commit: $($commitHash.Substring(0,7)))"
            Write-Log -message $msg -logFile $logFile
        }
    }
}

# === Inicio del monitoreo (proceso daemon) ===
function Start-Monitor {
    param(
        [string]$repoPath,
        [string]$configFile,
        [string]$logFile,
        [int]$delay
    )

    if (-not (Test-Path (Join-Path $repoPath ".git"))) {
        Write-Log -message "ERROR: No es un repositorio Git válido: $repoPath" -logFile $logFile
        exit 1
    }

    $pidFile = Get-PidFile $repoPath
    if (Test-Path $pidFile) {
        Write-Log -message "ERROR: Ya hay un monitoreo activo para este repositorio" -logFile $logFile
        exit 1
    }

    $patterns = Get-Patterns $configFile
    $currentBranch = Get-CurrentBranch $repoPath
    if (-not $currentBranch) {
        Write-Log -message "ERROR: No se pudo determinar la rama actual" -logFile $logFile
        exit 1
    }

    $lastKnownCommit = Get-LastCommitHash $repoPath
    if (-not $lastKnownCommit) {
        Write-Log -message "ERROR: No hay commits en el repositorio" -logFile $logFile
        exit 1
    }

    # Guardar información del monitor
    $info = @{
        PID           = $PID
        Repo          = $repoPath
        Branch        = $currentBranch
        LastCommit    = $lastKnownCommit
        StartTime     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        LogFile       = $logFile
    }
    $info | ConvertTo-Json | Set-Content $pidFile

    Write-Log -message "Monitoreo iniciado en '$repoPath' rama '$currentBranch' (PID: $PID, Patrones: $($patterns.Count))" -logFile $logFile

    # Loop principal de monitoreo
    try {
        while ($true) {
            Start-Sleep -Seconds $delay
            
            if (-not (Test-Path $pidFile)) {
                Write-Log -message "Monitoreo detenido externamente" -logFile $logFile
                break
            }

            $currentCommit = Get-LastCommitHash $repoPath
            
            if ($currentCommit -ne $lastKnownCommit) {
                Write-Log -message "Nuevo commit detectado: $currentCommit" -logFile $logFile
                
                Push-Location $repoPath
                $newCommits = git rev-list "$lastKnownCommit..$currentCommit" 2>$null
                Pop-Location
                
                if ($newCommits) {
                    $commitsList = if ($newCommits -is [array]) { 
                        [array]::Reverse($newCommits)
                        $newCommits 
                    } else { 
                        @($newCommits) 
                    }
                    
                    foreach ($commit in $commitsList) {
                        $modifiedFiles = Get-ModifiedFilesInCommit -repoPath $repoPath -commitHash $commit
                        
                        if ($modifiedFiles) {
                            foreach ($file in $modifiedFiles) {
                                if ($file -match '^\.git/') { continue }
                                
                                $content = Get-FileContentAtCommit -repoPath $repoPath -commitHash $commit -filePath $file
                                
                                if ($content) {
                                    Scan-FileContent -content $content -filePath $file -patterns $patterns -logFile $logFile -commitHash $commit
                                }
                            }
                        }
                    }
                }
                
                $lastKnownCommit = $currentCommit
                $info.LastCommit = $lastKnownCommit
                $info | ConvertTo-Json | Set-Content $pidFile
            }
        }
    }
    catch {
        Write-Log -message "Error en el loop principal: $_" -logFile $logFile
    }
    finally {
        if (Test-Path $pidFile) {
            Remove-Item $pidFile -Force
        }
        Write-Log -message "Monitoreo finalizado" -logFile $logFile
    }
}

# === Detener monitoreo ===
function Stop-Monitor {
    param([string]$repoPath)

    $pidFile = Get-PidFile $repoPath
    if (-not (Test-Path $pidFile)) {
        Write-Host "❌ No hay monitoreo activo para este repositorio." -ForegroundColor Red
        exit 1
    }

    $info = Get-Content $pidFile | ConvertFrom-Json
    $monitorPID = $info.PID
    
    Write-Host "🛑 Deteniendo monitoreo (PID: $monitorPID)..." -ForegroundColor Yellow

    try {
        $process = Get-Process -Id $monitorPID -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $monitorPID -Force
            Write-Host "✓ Proceso detenido" -ForegroundColor Green
        } else {
            Write-Host "⚠ El proceso ya no está corriendo" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠ No se pudo detener el proceso: $_" -ForegroundColor Yellow
    }

    Remove-Item $pidFile -Force
    Write-Host "✓ Monitoreo detenido para '$repoPath'" -ForegroundColor Green
    
    if ($info.LogFile) {
        Write-Log -message "Monitoreo detenido para $repoPath" -logFile $info.LogFile
    }
}

# === Mostrar estado de monitores ===
function Show-Status {
    $pidFiles = Get-ChildItem -Path $pidDir -Filter "monitor_*.pid" -ErrorAction SilentlyContinue
    
    if (-not $pidFiles) {
        Write-Host "ℹ No hay monitores activos" -ForegroundColor Cyan
        return
    }
    
    Write-Host "`n📊 Monitores activos:" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Gray
    
    foreach ($pidFile in $pidFiles) {
        try {
            $info = Get-Content $pidFile.FullName | ConvertFrom-Json
            $process = Get-Process -Id $info.PID -ErrorAction SilentlyContinue
            
            $status = if ($process) { "🟢 Activo" } else { "🔴 Detenido" }
            
            Write-Host "`n$status" -ForegroundColor $(if ($process) { "Green" } else { "Red" })
            Write-Host "  PID:        $($info.PID)"
            Write-Host "  Repo:       $($info.Repo)" -ForegroundColor Cyan
            Write-Host "  Rama:       $($info.Branch)" -ForegroundColor Cyan
            Write-Host "  Inicio:     $($info.StartTime)" -ForegroundColor Gray
            Write-Host "  Log:        $($info.LogFile)" -ForegroundColor Gray
            Write-Host "  Último:     $($info.LastCommit.Substring(0,7))" -ForegroundColor Gray
            
            if (-not $process) {
                Write-Host "  ⚠ El proceso no está corriendo, pero el archivo PID existe" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "`n🔴 Error leyendo: $($pidFile.Name)" -ForegroundColor Red
            Write-Host "  $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
}

# === Lanzar proceso daemon ===
function Start-Daemon {
    param(
        [string]$repoPath,
        [string]$configFile,
        [string]$logFile,
        [int]$delay
    )

    # Verificaciones previas
    if (-not (Test-Path (Join-Path $repoPath ".git"))) {
        Write-Host "❌ No es un repositorio Git válido: $repoPath" -ForegroundColor Red
        exit 1
    }

    try {
        $gitVersion = git --version
        Write-Host "✓ Git detectado: $gitVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Git no está instalado o no está en el PATH" -ForegroundColor Red
        exit 1
    }

    $pidFile = Get-PidFile $repoPath
    if (Test-Path $pidFile) {
        Write-Host "⚠ Ya hay un monitoreo activo para este repositorio." -ForegroundColor Yellow
        Write-Host "  Use -kill para detenerlo primero." -ForegroundColor Yellow
        exit 1
    }

    $patterns = Get-Patterns $configFile
    Write-Host "✓ Cargados $($patterns.Count) patrones de búsqueda" -ForegroundColor Green

    $currentBranch = Get-CurrentBranch $repoPath
    if (-not $currentBranch) {
        Write-Host "❌ No se pudo determinar la rama actual" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Monitoreando rama: $currentBranch" -ForegroundColor Green

    # Lanzar proceso en segundo plano
    $scriptPath = $MyInvocation.PSCommandPath
    
    # Preparar argumentos para el proceso daemon
    $daemonArgs = @(
        "-File", $scriptPath,
        "-__daemon",
        "-repo", $repoPath,
        "-configuracion", $configFile,
        "-log", $logFile,
        "-alerta", $delay
    )

    Write-Host "`n🚀 Lanzando daemon en segundo plano..." -ForegroundColor Cyan

    # Iniciar proceso en segundo plano
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6 -or $null -eq $IsWindows) {
        # Windows
        $process = Start-Process -FilePath "pwsh" -ArgumentList $daemonArgs -WindowStyle Hidden -PassThru
    } else {
        # Linux/macOS - usar & para proceso en background
        $cmd = "pwsh $($daemonArgs -join ' ') > /dev/null 2>&1 &"
        Invoke-Expression $cmd
        $process = $null
    }

    # Esperar un momento para verificar que el daemon inició correctamente
    Start-Sleep -Seconds 2

    if (Test-Path $pidFile) {
        $info = Get-Content $pidFile | ConvertFrom-Json
        Write-Host "✓ Daemon iniciado exitosamente" -ForegroundColor Green
        Write-Host "  PID:        $($info.PID)" -ForegroundColor Cyan
        Write-Host "  Repositorio: $repoPath" -ForegroundColor Cyan
        Write-Host "  Rama:       $currentBranch" -ForegroundColor Cyan
        Write-Host "  Log:        $logFile" -ForegroundColor Cyan
        Write-Host "  Intervalo:  $delay segundos" -ForegroundColor Cyan
        Write-Host "`n💡 Use './ejercicio4.ps1 -status' para ver el estado" -ForegroundColor Gray
        Write-Host "💡 Use './ejercicio4.ps1 -repo $repoPath -kill' para detener" -ForegroundColor Gray
    } else {
        Write-Host "⚠ El daemon pudo no haber iniciado correctamente" -ForegroundColor Yellow
        Write-Host "  Revise el archivo de log: $logFile" -ForegroundColor Yellow
    }
}

# === LOGICA PRINCIPAL ===

# Si es el proceso daemon interno
if ($__daemon) {
    Start-Monitor -repoPath $repo -configFile $configuracion -logFile $log -delay $alerta
    exit 0
}

# Mostrar estado
if ($status) {
    Show-Status
    exit 0
}

# Detener monitoreo
if ($kill) {
    if (-not $repo) {
        Write-Host "❌ Debe especificar el repositorio con -repo para detener el monitoreo" -ForegroundColor Red
        Write-Host "   Ejemplo: ./ejercicio4.ps1 -repo /ruta/repositorio -kill" -ForegroundColor Gray
        exit 1
    }
    
    $repoFull = Resolve-Path $repo -ErrorAction SilentlyContinue
    if (-not $repoFull) {
        Write-Host "❌ Ruta de repositorio inválida: $repo" -ForegroundColor Red
        exit 1
    }
    
    Stop-Monitor -repoPath $repoFull
    exit 0
}

# Iniciar monitoreo
if (-not $repo -or -not $configuracion) {
    Write-Host "❌ Faltan parámetros requeridos`n" -ForegroundColor Red
    Write-Host "Uso:" -ForegroundColor Yellow
    Write-Host "  ./ejercicio4.ps1 -repo <ruta> -configuracion <archivo> [-log <archivo>] [-alerta <segundos>]"
    Write-Host "  ./ejercicio4.ps1 -status"
    Write-Host "  ./ejercicio4.ps1 -repo <ruta> -kill`n"
    Write-Host "Ejemplos:" -ForegroundColor Cyan
    Write-Host "  ./ejercicio4.ps1 -repo /home/user/myrepo -configuracion ./patrones.conf"
    Write-Host "  ./ejercicio4.ps1 -status"
    Write-Host "  ./ejercicio4.ps1 -repo /home/user/myrepo -kill"
    Write-Host "  Get-Help ./ejercicio4.ps1 -Full`n"
    exit 1
}

# Resolver rutas
$repoFull = Resolve-Path $repo -ErrorAction SilentlyContinue
$confFull = Resolve-Path $configuracion -ErrorAction SilentlyContinue

if (-not $repoFull) {
    Write-Host "❌ Repositorio no encontrado: $repo" -ForegroundColor Red
    exit 1
}

if (-not $confFull) {
    Write-Host "❌ Archivo de configuración no encontrado: $configuracion" -ForegroundColor Red
    exit 1
}

# Lanzar daemon
Start-Daemon -repoPath $repoFull -configFile $confFull -logFile $log -delay $alerta
