#!/usr/bin/env pwsh

# EJERCICIO 3
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

Param(
    [Parameter(Mandatory = $false)]
    [switch]$help,
    [Parameter(Mandatory = $True, Position = 1)]
    [string[]] $Palabras,
    [Parameter(Mandatory = $True, Position = 2)]
    [string] $Directorio
)

if($help) {
    Get-Content help.txt
    exit 0
}

# --- Validaciones ---
if (-not $Palabras -or $Palabras.Count -eq 0 -or [string]::IsNullOrWhiteSpace($Palabras[0])) {
    Write-Error "Debe ingresar al menos una palabra a buscar."
    exit 1
}

if (-not $Directorio -or [string]::IsNullOrWhiteSpace($Directorio)) {
    Write-Error "Debe ingresar un directorio de logs."
    exit 1
}

if (-not (Test-Path $Directorio)) {
    Write-Error "El directorio '$Directorio' no existe."
    exit 1
}

$ArchivosLog = Get-ChildItem -Path $Directorio -Filter "*.log" -File
if (-not $ArchivosLog) {
    Write-Error "No se encontraron archivos '.log' en el directorio '$Directorio'."
    exit 1
}

Write-Output "Se procede a buscar $Palabras en $Directorio"

Write-Output "-------------------------------------"
Write-Output "Analizando eventos en logs de sistema"
Write-Output "-------------------------------------"


foreach ($archivo in $ArchivosLog) {
    Write-Output "`nArchivo: $($archivo.Name)"
    foreach ($item in $Palabras)
    {
        [int] $cant = (Get-Content $archivo.Fullname | Select-String -Pattern $item).count
            Write-Output("$item : $cant")
    }
}

