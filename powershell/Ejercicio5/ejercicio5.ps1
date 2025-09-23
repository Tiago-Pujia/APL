#!/usr/bin/env pwsh

#USO:
# ./ejercicio5.ps1 -nombre 'pais1,pais2,...' -ttl segundos
# -----------------------------<PARÁMETROS>-----------------------------
Param(
    [Parameter(Mandatory=$true)] [string[]]$nombre,
    [Parameter(Mandatory=$true)] [int]$ttl,
    [Parameter(Mandatory=$false)] [switch]$help
)

# -----------------------------<FUNCIONES>-----------------------------

function mostrarAyuda {
    Write-Host "Uso: ./ejercicio5.ps1 -Nombre 'pais1,pais2,...' -TTL segundos"
    Write-Host
    Write-Host "Opciones:"
    Write-Host "  -n, --nombre   Nombre(s) de los países a buscar (separados por comas)"
    Write-Host "  -t, --ttl      Tiempo en segundos que se guardan los resultados en caché"
    Write-Host "  -h, --help     Muestra esta ayuda"
    exit
}

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
    $cache = Get-Content $ArchivoCache | ConvertFrom-Json

    $cache | Add-Member -NotePropertyName $pais -NotePropertyValue @{
        timestamp = $ts
        data      = $datos
    } -Force

    $cache | ConvertTo-Json -Depth 10 | Set-Content $ArchivoCache -Encoding UTF8
}
#Consulta a la memoria cache
function consultarCache ($pais) {
    $ahora = [int][double]::Parse((Get-Date -UFormat %s))
    $cache = Get-Content $ArchivoCache | ConvertFrom-Json

    if ($cache.PSObject.Properties.Name -contains $pais) {
        $ts = $cache.$pais.timestamp
        if ($ahora - $ts -lt $TTL) {
            return $cache.$pais.data
        }
    }
    return $null
}

# -----------------------------<PROGRAMA>-----------------------------

$archivoCache = "archivo_cache.json"

if ($Help) {
    mostrarAyuda
}

# Crear archivo cache si no existe
if (-not (Test-Path $archivoCache)) {
    "{}" | Set-Content $archivoCache -Encoding UTF8
}

# Validaciones
if (-not $nombre) {
    Write-Host "Error: Debe ingresar al menos un país con -nombre" -ForegroundColor Red
    exit 1
}

if ($TTL -le 0) {
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
    $nombre       = $resultado.name.common
    $capital      = $resultado.capital[0]
    $region       = $resultado.region
    $poblacion    = $resultado.population
    $monedaCodigo = $resultado.currencies.PSObject.Properties.Name | Select-Object -First 1
    $monedaNombre = $resultado.currencies.$monedaCodigo.name

    Write-Host "  País: $nombre"
    Write-Host "  Capital: $capital"
    Write-Host "  Región: $region"
    Write-Host "  Población: $poblacion"
    Write-Host "  Moneda: $monedaNombre ($monedaCodigo)"
    Write-Host
}
