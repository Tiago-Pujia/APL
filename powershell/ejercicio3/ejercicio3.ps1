<#
.SYNOPSIS
    ejercicio3.ps1 -Palabras <string[]> -Directorio <string> [-help]

.DESCRIPTION
    Este script analiza todos los archivos de logs (.log) en un directorio para
    contar la ocurrencia total de eventos específicos basados en palabras clave.
    Las búsquedas no distinguen entre mayúsculas y minúsculas.

.PARAMETER -Palabras
    Lista de palabras clave a contabilizar. Es obligatorio.
    Ejemplo: -Palabras "error", "warning", "invalid"

.PARAMETER -Directorio
    Ruta del directorio de logs a analizar. Es obligatorio.

.PARAMETER -help
    Muestra esta ayuda y sale. (Añadido automáticamente por Get-Help)

.NOTES
    - Utiliza Select-String de PowerShell para el procesamiento de archivos.
    - Las búsquedas no distinguen entre mayúsculas y minúsculas (comportamiento por defecto).
    - Procesa todos los archivos con extensión .log en el directorio especificado.

.EXAMPLE
    ./ejercicio3.ps1 -Palabras "error", "fail", "invalid" -Directorio /var/log
    Busca las palabras "error", "fail", e "invalid" en los logs de /var/log.

.EXAMPLE
    ./ejercicio3.ps1 -Palabras "warning", "timeout" -Directorio ./logs
    Busca "warning" y "timeout" en los archivos .log del subdirectorio ./logs.

.INPUTS
    System.String[]
    System.String

.OUTPUTS
    System.String (a la consola)
#>

# EJERCICIO 3
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

Param(
    [Parameter(Mandatory = $false)]
    [switch]$help,
    [Parameter(Mandatory = $True)]
    [string[]] $Palabras,
    [Parameter(Mandatory = $True)]
    [string] $Directorio
)


# --- Validaciones ---
if ($help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit [int]0
}

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
        # 1. Usar -AllMatches para encontrar todas las ocurrencias en cada línea.
        #    Esto devuelve objetos MatchInfo.
        $matchInfoObjects = Get-Content $archivo.Fullname | Select-String -Pattern $item -AllMatches

        [int] $cant = 0
        
        # 2. Verificar si se encontró algo
        if ($matchInfoObjects) {
            # 3. Cada objeto $matchInfo tiene una propiedad .Matches (una colección de todas las coincidencias en esa línea)
            #    Al acceder a .Matches en la colección completa ($matchInfoObjects.Matches),
            #    PowerShell lo "desenvuelve" en una única lista de *todas* las coincidencias.
            # 4. Contamos el total de esa lista.
            $cant = ($matchInfoObjects.Matches).Count
        }
        
        Write-Output("$item : $cant")
    }
}

