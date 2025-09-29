Param(
    [Parameter(Mandatory = $false)]
    [switch]$help,
    [Parameter(Mandatory = $True, Position = 1)]
    [String] $repo,
    [Parameter(Mandatory = $True, Position = 2)]
    [string] $configuracion,
    [Parameter(Mandatory = $True, Position = 3)]
    [string] $log,
    [Parameter(Mandatory = $False, Position = 4)]
    [switch] $kill #se activa si se pone, sino queda como false
)

if($help) {
    cat help.txt
    exit 0
}

if($kill){
    #matar el daemon
    $pidFile = "/tmp/daemon_$($repo -replace '/', '_').pid"
    if(Test-Path $pidFile){
        $pidObtenido = Get-Content $pidFile
        Stop-Process -Id $pidObtenido -Force
        Remove-Item $pidFile
        Write-Output "Daemon detenido (PID: $pidObtenido)"
    }else{
        Write-Output "No hay ningun daemone ejecutandose"
    }
}
else{
    #creo un archivo PID
    $pidFile = "/tmp/daemon_$($repo -replace '/', '_').pid"
    $currentPID = $PID

    #verifico si hay uno corriendo
    if(Test-Path $pidFile){
        Write-Output "Ya existe un daemon en este repo"
        exit 1
    }
    
    #Guardo el PID
    $currentPID | Out-File -FilePath $pidFile
    Write-Output "Daemon iniciado con PID: $currentPID"
    Write-Output "Entrando al loop"
    while ($true) {
        Write-Output "Probando - PID: $currentPID - $(Get-Date -Format 'HH:mm:ss')"
        Start-Sleep -Seconds 5
    }
}


