#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Buscador de información de países usando la API REST Countries.

.DESCRIPTION
    Consulta información de países utilizando la API REST Countries y almacena
    los resultados en una caché con tiempo de vida (TTL) configurable.
    Muestra información como capital, región, población y moneda.

.PARAMETER nombre
    Nombre(s) de los países a buscar. Múltiples nombres se separan por comas.

.PARAMETER ttl
    Tiempo en segundos que se guardarán los resultados en caché.

.PARAMETER help
    Muestra esta ayuda y sale.

.EXAMPLE
    .\ejercicio5.ps1 -nombre argentina -ttl 60

.EXAMPLE
    .\ejercicio5.ps1 -nombre spain,france -ttl 7200

.EXAMPLE
    .\ejercicio5.ps1 -nombre japan,canada,mexico -ttl 1800

.NOTES
    - Utiliza la API pública: https://restcountries.com/v3.1/name/
    - Los resultados en caché se invalidan automáticamente después del TTL
    - Soporta búsqueda de múltiples países simultáneamente
    - Autores: Tiago Pujia, Bautista Rios Di Gaeta, Santiago Manghi Scheck, Tomas Agustín Nielsen
#>

# EJERCICIO 5
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

Param(
    [Parameter(Mandatory=$false)] [string[]]$nombre,
    [Parameter(Mandatory=$false)] [int]$ttl,
    [Parameter(Mandatory=$false)] [switch]$help
)

# -----------------------------<FUNCIONES>-----------------------------

#Consulta a la API
function consultarAPI ($pais) {
    try {
        $url = "https://restcountries.com/v3.1/name/$pais"
        $resultado = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        if (-not $resultado) {
            Write-Host "Error: No se encontró información para '$pais'." -ForegroundColor Red
            return $null
        }
        return $resultado[0]
    }
    catch {
        Write-Host "Error al consultar API para '$pais'." -ForegroundColor Red
        return $null
    }
}

#Guarda a la memoria cache
function guardarCache($pais, $datos) {
    $ts = [int][double]::Parse((Get-Date -UFormat %s))
    $cache = Get-Content $archivoCache | ConvertFrom-Json

    $cache | Add-Member -NotePropertyName $pais -NotePropertyValue @{
        timestamp = $ts
        data      = $datos
    } -Force

    $cache | ConvertTo-Json -Depth 10 | Set-Content $archivoCache -Encoding UTF8
}
#Consulta a la memoria cache
function consultarCache ($pais) {
    $ahora = [int][double]::Parse((Get-Date -UFormat %s))
    $cache = Get-Content $archivoCache | ConvertFrom-Json

    if ($cache.PSObject.Properties.Name -contains $pais) {
        $ts = $cache.$pais.timestamp
        if ($ahora - $ts -lt $ttl) {
            return $cache.$pais.data
        }
    }
    return $null
}

# -----------------------------<PROGRAMA>-----------------------------

if ($help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

$archivoCache = "archivo_cache.json"

# Crear archivo cache si no existe
if (-not (Test-Path $archivoCache)) {
    "{}" | Set-Content $archivoCache -Encoding UTF8
}

# Validaciones
if (-not $nombre) {
    Write-Host "Error: Debe ingresar al menos un país con -nombre o -n" -ForegroundColor Red
    exit 1
}

if ($ttl -le 0) {
    Write-Host "Error: Debe indicar un TTL válido en segundos con -ttl" -ForegroundColor Red
    exit 1
}

#Comienza la ejecucion del programa
$nombres = $nombre -split ','

#Por cada nombre primero valida, luego consulta a la cache y en caso de que no lo encuentre, consulta a la API
foreach ($pais in $nombres) {
    $pais = $pais.Trim()

    if ($pais -notmatch '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$') {
        Write-Host "Error: El nombre del país solo puede contener letras y espacios." -ForegroundColor Red
        continue
    }

    $resultado = consultarCache $pais
    if ($resultado) {
        Write-Host "Datos desde caché:"
    }
    else {
        Write-Host "Consultando API..."
        $resultado = consultarAPI $pais
        if (-not $resultado) { continue }
        guardarCache $pais $resultado
    }

    # Mostrar resultados
    $nombrePais   = $resultado.name.common
    $capital      = $resultado.capital[0]
    $region       = $resultado.region
    $poblacion    = $resultado.population
    $monedaCodigo = $resultado.currencies.PSObject.Properties.Name | Select-Object -First 1
    $monedaNombre = $resultado.currencies.$monedaCodigo.name

    Write-Host "  País: $nombrePais"
    Write-Host "  Capital: $capital"
    Write-Host "  Región: $region"
    Write-Host "  Población: $poblacion"
    Write-Host "  Moneda: $monedaNombre ($monedaCodigo)"
    Write-Host
}