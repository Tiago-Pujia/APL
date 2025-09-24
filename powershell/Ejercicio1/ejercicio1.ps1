#!/usr/bin/env pwsh
param (
    [Parameter(Position=0)]
    [string]$directorio,

    [Parameter(Position=1)]
    [string]$archivo,

    [switch]$pantalla,

    [Alias('h')]
    [switch]$help
)

# Si pidieron help, mostramos help.txt (cat help.txt) si existe.
if ($help) {
    $helpPath = Join-Path $PSScriptRoot 'help.txt'
    if (Test-Path $helpPath) {
        Get-Content $helpPath | ForEach-Object { Write-Output $_ }
    } else {
        # Si no existe help.txt, mostramos la ayuda integrada
        Get-Help -Full $MyInvocation.MyCommand.Path | Out-String | Write-Output
    }
    exit 0
}

# Validaciones previas
if (-not $directorio) {
    Write-Error "Debe especificar un directorio con -directorio."
    exit 1
}

if (-not (Test-Path $directorio -PathType Container)) {
    Write-Error "El directorio '$directorio' no existe."
    exit 1
}

if ($archivo -and $pantalla) {
    Write-Error "No puede usar -archivo y -pantalla al mismo tiempo."
    exit 1
}

if (-not $archivo -and -not $pantalla) {
    Write-Error "Debe especificar -archivo o -pantalla."
    exit 1
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
            if (-not [double]::TryParse($campos[3].Trim(), [ref]$tiempo)) {
                Write-Warning "Tiempo inválido en $($file.Name): '$line'"
                continue
            }
            if (-not [double]::TryParse($campos[4].Trim(), [ref]$nota)) {
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
        exit 0
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

            $json[$fecha][$canal] = @{
                tiempo_respuesta_promedio  = [math]::Round($avgTiempo,2)
                nota_satisfaccion_promedio = [math]::Round($avgNota,2)
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

} catch {
    Write-Error "Ocurrió un error durante el procesamiento: $_"
    exit 1
}
