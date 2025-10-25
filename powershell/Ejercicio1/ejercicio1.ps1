#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Procesador de encuestas de satisfacción

.DESCRIPTION
    Este script procesa archivos de texto que contienen registros de encuestas de 
    satisfacción de clientes, con formato de campos fijos separados por pipe (|). 
    Calcula el tiempo de respuesta promedio y la nota de satisfacción promedio 
    por canal de atención y por día. Los resultados se muestran en pantalla o 
    se guardan en un archivo JSON.

.PARAMETER directorio
    Ruta del directorio que contiene los archivos de encuestas a procesar.
    (Acepta rutas relativas o absolutas y rutas con espacios.)

.PARAMETER archivo
    Ruta completa del archivo JSON de salida.

.PARAMETER pantalla
    Muestra la salida por pantalla en formato JSON.

.PARAMETER help
    Muestra esta ayuda y sale.

.EXAMPLE
    ejercicio1.ps1 -directorio .\datos -pantalla

.EXAMPLE
    ejercicio1.ps1 -directorio "C:\Mis Encuestas" -archivo resultado.json

.EXAMPLE
    ejercicio1.ps1 -h

.NOTES
    Las opciones -archivo y -pantalla son mutuamente excluyentes.
    El script valida que el directorio exista y que las lineas de los archivos
    tengan el formato: ID|FECHA|CANAL|TIEMPO|NOTA

    Autores:
    - Tiago Pujia
    - Bautista Rios Di Gaeta
    - Santiago Manghi Scheck
    - Tomas Agustín Nielsen
#>

param (
    [Parameter(Position=0, Mandatory=$false)]
    [string]$directorio,

    [Parameter(Position=1)]
    [string]$archivo,

    [switch]$pantalla,

    [Alias('h')]
    [switch]$help
)

# Si pidieron help, mostramos la ayuda integrada
if ($help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit [int]0
}

# Validaciones previas
if (-not (Test-Path $directorio -PathType Container)) {
    Write-Error "El directorio '$directorio' no existe."
    exit [int]1
}

if ($archivo -and $pantalla) {
    Write-Error "No puede usar -archivo y -pantalla al mismo tiempo."
    exit [int]1
}

if (-not $archivo -and -not $pantalla) {
    Write-Error "Debe especificar -archivo o -pantalla."
    exit [int]1
}

# Función auxiliar para formatear números:
# - Si es entero, devuelve entero.
# - Si es decimal, redondea a 2 decimales.
function Format-Number {
    param([double]$n)
    if ($n -eq [math]::Round($n,0)) {
        return [math]::Round($n,0)
    } else {
        return [math]::Round($n,2)
    }
}

# Procesamiento seguro
try {
    $datos = @()

    $files = Get-ChildItem -Path $directorio -File -ErrorAction Stop

    foreach ($file in $files) {
        # Leer líneas; si hay error con un archivo, lo saltamos con advertencia
        try {
            $lines = Get-Content -Path $file.FullName -ErrorAction Stop
        } catch {
            Write-Warning "No se pudo leer '$($file.FullName)': $_"
            continue
        }

        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $campos = $line -split '\|'
            if ($campos.Count -ne 5) {
                Write-Warning "Formato inválido en $($file.Name): '$line'"
                continue
            }

            $fechaFull = $campos[1].Trim()
            $fecha = ($fechaFull -split '\s+')[0]
            $canal  = $campos[2].Trim()

            $tiempo = 0.0
            $nota   = 0.0
            if (-not [double]::TryParse($campos[3].Trim(), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$tiempo)) {
                Write-Warning "Tiempo inválido en $($file.Name): '$line'"
                continue
            }
            if (-not [double]::TryParse($campos[4].Trim(), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$nota)) {
                Write-Warning "Nota inválida en $($file.Name): '$line'"
                continue
            }

            $datos += [PSCustomObject]@{
                Fecha  = $fecha
                Canal  = $canal
                Tiempo = $tiempo
                Nota   = $nota
                Origen = $file.Name
            }
        }
    }

    # Si no hay datos válidos
    if ($datos.Count -eq 0) {
        $vacio = @{} 
        if ($pantalla) {
            $vacio | ConvertTo-Json -Depth 3 | Write-Output
        } else {
            $vacio | ConvertTo-Json -Depth 3 | Out-File -FilePath $archivo -Encoding utf8
            Write-Output "Resultados guardados en $archivo (vacío - no se encontraron registros válidos)"
        }
        exit [int]0
    }

    # Agrupar primeramente por fecha y luego por canal para construir JSON anidado
    $json = @{}
    foreach ($grupoFecha in ($datos | Group-Object -Property Fecha)) {
        $fecha = $grupoFecha.Name
        $json[$fecha] = @{}

        foreach ($grupoCanal in ($grupoFecha.Group | Group-Object -Property Canal)) {
            $canal = $grupoCanal.Name
            $avgTiempo = ($grupoCanal.Group | Measure-Object -Property Tiempo -Average).Average
            $avgNota   = ($grupoCanal.Group | Measure-Object -Property Nota -Average).Average

            $avgTiempo = Format-Number $avgTiempo
            $avgNota   = Format-Number $avgNota

            $json[$fecha][$canal] = @{
                tiempo_respuesta_promedio  = $avgTiempo
                nota_satisfaccion_promedio = $avgNota
            }
        }
    }

    # Salida final
    if ($pantalla) {
        $json | ConvertTo-Json -Depth 5 | Write-Output
    } else {
        $json | ConvertTo-Json -Depth 5 | Out-File -FilePath $archivo -Encoding utf8
        Write-Output "Resultados guardados en $archivo"
    }

    exit [int]0

} catch {
    Write-Error "Ocurrió un error durante el procesamiento: $_"
    exit [int]1
}