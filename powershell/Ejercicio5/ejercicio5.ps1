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


function consultarExistenciaCache {
    param($texto)
    try {
        $null = $texto | ConvertFrom-Json
        return $true
    } catch {
        return $false
    }
}

function consultarAPI {
    param([string]$pais)
    try {
        $url = "https://restcountries.com/v3.1/name/$([uri]::EscapeDataString($pais))"
        $resultado = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        if (-not $resultado) {
            Write-Host "Error: No se encontró información para '$pais'." -ForegroundColor Red
            return $null
        }
        return $resultado[0]
    } catch {
        Write-Host "Error al consultar API para '$pais': $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function guardarCache {
    param(
        [string]$pais,
        [psobject]$datos,
        [int]$ttlEntrada
    )

    $ts = [int][double]::Parse((Get-Date -UFormat %s))
    $cache = @{}

    try {
        $contenido = Get-Content -Path $archivoCache -Raw -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($contenido) -and (consultarExistenciaCache $contenido)) {
            $cache = $contenido | ConvertFrom-Json
        }
    } catch {
        $cache = @{}
    }

    $entry = @{
        timestamp = $ts
        ttl       = $ttlEntrada
        data      = $datos
    }

    if ($cache -is [System.Management.Automation.PSCustomObject]) {
        $cache | Add-Member -NotePropertyName $pais -NotePropertyValue $entry -Force
    } else {
        $cache.$pais = $entry
    }

    $cache | ConvertTo-Json -Depth 10 | Set-Content -Path $archivoCache -Encoding UTF8
}

function consultarCache {
    param([string]$pais)
    $ahora = [int][double]::Parse((Get-Date -UFormat %s))

    try {
        $contenido = Get-Content -Path $archivoCache -Raw -ErrorAction Stop
        if (-not $contenido -or -not (consultarExistenciaCache $contenido)) { return $null }
        $cache = $contenido | ConvertFrom-Json
    } catch {
        return $null
    }

    if ($null -eq $cache) { return $null }

    if ($cache.PSObject.Properties.Name -contains $pais) {
        $entry = $cache.$pais
        if ($null -eq $entry.timestamp -or $null -eq $entry.ttl) {
            return $null
        }

        # Compara con el TTL guardado en la entrada, no el actual
        if (($ahora - [int]$entry.timestamp) -lt [int]$entry.ttl) {
            return $entry.data
        } else {
            return $null
        }
    }
    return $null
}

# -----------------------------<PROGRAMA PRINCIPAL>-----------------------------

if ($help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

$archivoCache = "archivo_cache.json"

# Crear archivo de caché si no existe
if (-not (Test-Path $archivoCache)) {
    "{}" | Set-Content $archivoCache -Encoding UTF8
}

# Validaciones
if (-not $nombre) {
    Write-Host "Error: Debe ingresar al menos un país con -nombre o -n" -ForegroundColor Red
    exit 1
}

if ($null -eq $ttl -or $ttl -le 0) {
    Write-Host "Error: Debe indicar un TTL válido en segundos con -ttl (entero > 0)" -ForegroundColor Red
    exit 1
}

# Separar múltiples nombres
$nombres = $nombre -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

try {
    foreach ($pais in $nombres) {
        if ($pais -notmatch '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$') {
            Write-Host "Error: El nombre del país '$pais' solo puede contener letras y espacios." -ForegroundColor Red
            continue
        }

        $resultado = consultarCache $pais
        if ($resultado) {
            Write-Host "Datos desde caché para '$pais':"
        } else {
            Write-Host "Consultando API para '$pais'..."
            $resultado = consultarAPI $pais
            if (-not $resultado) { continue }
            guardarCache -pais $pais -datos $resultado -ttlEntrada $ttl
        }

        # Mostrar resultados
        $nombrePais   = $resultado.name.common -as [string]
        $capital      = if ($resultado.capital -and $resultado.capital.Count -gt 0) { $resultado.capital[0] } else { "N/A" }
        $region       = $resultado.region -as [string]
        $poblacion    = $resultado.population -as [string]
        $monedaCodigo = $null
        $monedaNombre = "N/A"

        try {
            if ($resultado.currencies) {
                $monedaCodigo = $resultado.currencies.PSObject.Properties.Name | Select-Object -First 1
                if ($monedaCodigo) {
                    $monedaNombre = $resultado.currencies.$monedaCodigo.name
                }
            }
        } catch { $monedaNombre = "N/A" }

        Write-Host "  País: $nombrePais"
        Write-Host "  Capital: $capital"
        Write-Host "  Región: $region"
        Write-Host "  Población: $poblacion"
        if ($monedaCodigo) {
            Write-Host "  Moneda: $monedaNombre ($monedaCodigo)"
        } else {
            Write-Host "  Moneda: $monedaNombre"
        }
        Write-Host
    }
} catch {
    Write-Host "Error inesperado: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
