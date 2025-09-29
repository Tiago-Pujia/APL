
Param(
    [Parameter(Mandatory = $false)]
    [switch]$help,
    [Parameter(Mandatory = $True, Position = 1)]
    [string[]] $Palabras,
    [Parameter(Mandatory = $True, Position = 2)]
    [string] $Directorio
)

if($help) {
    cat help.txt
    exit 0
}

Write-Output "Se procede a buscar $Palabras en $Directorio"

Write-Output "-------------------------------------"
Write-Output "Analizando eventos en logs de sistema"
Write-Output "-------------------------------------"

$Ruta = Join-Path -Path $Directorio -ChildPath "system.log"

foreach ($item in $Palabras)
{
    [int] $cant = (Get-Content $Ruta | Select-String -Pattern $item).count
        Write-Output("$item : $cant")
}

