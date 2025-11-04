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
        Write-Host "DEBUG: Consultando URL: $url" -ForegroundColor Yellow
        $resultado = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        if (-not $resultado) {
            Write-Host "Error: No se encontró información para '$pais'." -ForegroundColor Red
            return $null
        }
        return $resultado[0]
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "Error: No se encontró información para '$pais'." -ForegroundColor Red
        } else {
            Write-Host "Error al consultar API para '$pais': $($_.Exception.Message)" -ForegroundColor Red
        }
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
    
    # Cargar cache existente o crear nuevo
    $cache = @{}
    if (Test-Path $archivoCache) {
        try {
            $contenido = Get-Content -Path $archivoCache -Raw -ErrorAction Stop
            if (-not [string]::IsNullOrWhiteSpace($contenido) -and (consultarExistenciaCache $contenido)) {
                $cache = $contenido | ConvertFrom-Json -AsHashtable
            }
        } catch {
            Write-Host "Advertencia: No se pudo cargar el cache existente, creando nuevo." -ForegroundColor Yellow
            $cache = @{}
        }
    }

    # Crear nueva entrada
    $entry = @{
        timestamp = $ts
        ttl       = $ttlEntrada
        data      = $datos
    }

    $cache[$pais] = $entry

    try {
        $cache | ConvertTo-Json -Depth 10 | Set-Content -Path $archivoCache -Encoding UTF8
    } catch {
        Write-Host "Error al guardar en cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function consultarCache {
    param([string]$pais)
    
    if (-not (Test-Path $archivoCache)) {
        return $null
    }

    $ahora = [int][double]::Parse((Get-Date -UFormat %s))

    try {
        $contenido = Get-Content -Path $archivoCache -Raw -ErrorAction Stop
        if (-not $contenido -or -not (consultarExistenciaCache $contenido)) { 
            return $null 
        }
        $cache = $contenido | ConvertFrom-Json -AsHashtable
    } catch {
        return $null
    }

    if ($null -eq $cache -or -not $cache.ContainsKey($pais)) {
        return $null
    }

    $entry = $cache[$pais]
    if ($null -eq $entry.timestamp -or $null -eq $entry.ttl) {
        return $null
    }

    # Compara con el TTL guardado en la entrada
    if (($ahora - [int]$entry.timestamp) -lt [int]$entry.ttl) {
        return $entry.data
    }
    
    return $null
}

# -----------------------------<PROGRAMA PRINCIPAL>-----------------------------

# Inicializar variable de éxito
$script:success = $true

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
$nombres = @()
foreach ($n in $nombre) {
    $nombres += $n -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

$paisesProcesados = 0

try {
    foreach ($pais in $nombres) {
        # Validación más flexible de nombres de países
        if ($pais -notmatch '^[a-zA-ZñÑáéíóúÁÉÍÓÚüÜ\s\-]+$') {
            Write-Host "Error: El nombre del país '$pais' contiene caracteres no válidos." -ForegroundColor Red
            $script:success = $false
            continue
        }

        $resultado = consultarCache $pais
        if ($resultado) {
            Write-Host "Datos desde caché para '$pais':" -ForegroundColor Green
        } else {
            Write-Host "Consultando API para '$pais'..." -ForegroundColor Yellow
            $resultado = consultarAPI $pais
            if (-not $resultado) {
                $script:success = $false
                continue
            }
            guardarCache -pais $pais -datos $resultado -ttlEntrada $ttl
        }

        # Mostrar resultados
        $nombrePais   = $resultado.name.common -as [string]
        $capital      = if ($resultado.capital -and $resultado.capital.Count -gt 0) { $resultado.capital[0] } else { "N/A" }
        $region       = $resultado.region -as [string]
        $poblacion    = if ($resultado.population) { $resultado.population.ToString() } else { "N/A" }
        $monedaCodigo = $null
        $monedaNombre = "N/A"

        try {
            if ($resultado.currencies) {
                $monedaCodigo = $resultado.currencies.PSObject.Properties.Name | Select-Object -First 1
                if ($monedaCodigo) {
                    $monedaNombre = $resultado.currencies.$monedaCodigo.name
                }
            }
        } catch { 
            $monedaNombre = "N/A" 
        }

        Write-Host "  País: $nombrePais"
        Write-Host "  Capital: $capital"
        Write-Host "  Región: $region"
        Write-Host "  Población: $poblacion"
        if ($monedaCodigo) {
            Write-Host "  Moneda: $monedaNombre ($monedaCodigo)"
        } else {
            Write-Host "  Moneda: $monedaNombre"
        }
        Write-Host ""
        $paisesProcesados++
    }
} catch {
    Write-Host "Error inesperado: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Determinar código de salida basado en si se procesó al menos un país exitosamente
if ($paisesProcesados -gt 0) {
    exit 0
} else {
    exit 1
}