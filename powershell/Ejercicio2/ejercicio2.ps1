#!/usr/bin/env pwsh

# EJERCICIO 2
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

Param (
    [Parameter(Mandatory = $True)]
    [string]
    [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) {
                throw "El parámetro -matriz no puede estar vacío."
            }
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "El archivo '$($_)' no existe."
            }
            $true  # necesario para que la validación pase
        })]
    $matriz,

    [Parameter(Mandatory = $True)]
    [string]
    [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) {
                throw "El parámetro -separador no puede estar vacío."
            }
            $true
        })]
    $separador,

    [Parameter(Mandatory = $True, ParameterSetName = "camino")]
    [int[]]
    [ValidateCount(2, 2)]
    $camino,

    [Parameter(Mandatory = $True, ParameterSetName = "hub")]
    [switch]
    $hub
)

function validarMatriz {
    param(
        [string]$path,
        [string]$separador
    )
    $contenidoMatriz = Get-Content -Path "$path"
    #Convertimos la matriz a un array de arrays
    $filas = @()
    foreach ($linea in $contenidoMatriz) {
        $filas += , ($linea -split [regex]::Escape($separador) | ForEach-Object { $_.Trim() })
    }
    $numFilas = $filas.Count
    $valido = $true

    # Chequeamos que sea cuadrada
    foreach ($fila in $filas) {
        if ($fila.Count -ne $numFilas) {
            Write-Host "Error: la matriz no es cuadrada."
            $valido = $false
            break
        }
    }
    for ($i = 0; $i -lt $numFilas; $i++) {
        for ($j = 0; $j -lt $numFilas; $j++) {
            $valor = $filas[$i][$j]

            # Chequeamos que sea numérico
            if (-not [double]::TryParse($valor, [ref]$null)) {
                Write-Host "Error: valor no numérico en fila $($i+1), columna $($j+1)."
                $valido = $false
                break
            }

            # Chequeamos que sea positivo
            if ([double]$valor -lt 0) {
                Write-Host "Error: valor negativo en fila $($i+1), columna $($j+1)."
                $valido = $false
                break
            }

            # Chequeamos diagonal 0
            if ($i -eq $j -and [double]$valor -ne 0) {
                Write-Host "Error: la diagonal debe ser 0 (fila $($i+1), columna $($j+1))."
                $valido = $false
                break
            }

            # Chequeamos simetría
            if ($i -ne $j -and [double]$valor -ne [double]$filas[$j][$i]) {
                Write-Host "Error: la matriz no es simétrica (fila $($i+1), columna $($j+1))."
                $valido = $false
                break
            }
        }
    }
    return $valido
}

function Dijkstra {
    param(
        [string]$matrizPath,         # Ruta al archivo con la matriz
        [int]$origen,                # Terminal de origen (1-indexado)
        [int]$destino,               # Terminal de destino (1-indexado)
        [string]$separador = ","     # Separador en el archivo
    )

    
    # 1. Leer matriz como array de arrays (cada línea es un array de enteros)
    $matriz = Get-Content $matrizPath | ForEach-Object {
        , (($_ -split [regex]::Escape($separador)) | ForEach-Object { [int]$_ })
    }

    # 2. Pasar a array bidimensional y marcar ceros fuera de diagonal como infinito
    $n = $matriz.Count
    $grafo = New-Object 'object[,]' $n, $n
    for ($i = 0; $i -lt $n; $i++) {
        for ($j = 0; $j -lt $n; $j++) {
            if ($i -ne $j -and [int]$matriz[$i][$j] -eq 0) {
                $grafo[$i, $j] = [int]::MaxValue
            }
            else {
                $grafo[$i, $j] = [int]($matriz[$i][$j])
            }
        }
    }

    # 3. Inicialización Dijkstra
    $dist = @()
    $prev = @()
    $visitado = @()
    for ($i = 0; $i -lt $n; $i++) {
        $dist += [int]::MaxValue
        $prev += -1
        $visitado += $false
    }
    $dist[$origen - 1] = 0   # El origen se pone en 0

    # 4. Algoritmo Dijkstra
    for ($k = 0; $k -lt $n; $k++) {
        # Seleccionar nodo no visitado con menor distancia
        $u = -1
        $min = [int]::MaxValue
        for ($i = 0; $i -lt $n; $i++) {
            if (-not $visitado[$i] -and $dist[$i] -lt $min) {
                $min = $dist[$i]
                $u = $i
            }
        }

        if ($u -eq -1) { break } # No hay más alcanzables
        $visitado[$u] = $true

        # Relajar vecinos
        for ($v = 0; $v -lt $n; $v++) {
            if (-not $visitado[$v] -and $grafo[$u, $v] -ne [int]::MaxValue) {
                $alt = $dist[$u] + $grafo[$u, $v]
                if ($alt -lt $dist[$v]) {
                    $dist[$v] = $alt
                    $prev[$v] = $u
                }
            }
        }
    }

    # 5. Reconstruir camino
    $camino = @()
    $u = $destino - 1
    if ($prev[$u] -ne -1 -or $u -eq ($origen - 1)) {
        while ($u -ne -1) {
            $camino = , ($u + 1) + $camino
            $u = $prev[$u]
        }
    }

    $resultado = "**Camino más corto: entre Estación $origen y Estación $($destino):**`n"
    # 6. Resultado
    if ($dist[$destino - 1] -eq [int]::MaxValue) {
        $resultado += "No existe camino entre $origen y $destino`n"
    }
    else {
        $resultado += "**Tiempo total:** $($dist[$destino-1]) minutos`n"
        $resultado += "**Ruta:** $($camino -join ' -> ')"
    }
    return $resultado
}

function hub {
    param(
        [string]$path,
        [string]$separador = ","
    )

    # Leer matriz como array de arrays
    $contenidoMatriz = Get-Content -Path $path
    $filas = @()
    foreach ($linea in $contenidoMatriz) {
        $filas += , ($linea -split [regex]::Escape($separador) | ForEach-Object { [int]($_.Trim()) })
    }

    $numFilas = $filas.Count
    $maxConexiones = 0
    $hubs = @()

    for ($i = 0; $i -lt $numFilas; $i++) {
        $conexiones = 0
        for ($j = 0; $j -lt $numFilas; $j++) {
            if ($i -ne $j -and $filas[$i][$j] -ne 0) {
                $conexiones++
            }
        }

        if ($conexiones -gt $maxConexiones) {
            $maxConexiones = $conexiones
            $hubs = @($i + 1)   # Terminal 1-indexado
        }
        elseif ($conexiones -eq $maxConexiones) {
            $hubs += ($i + 1)
        }
    }
    if ($hubs.Count -eq 1) {
        $resultado = "**Hub de la red:** Estación $hubs ($maxConexiones conexiones)`n"
    }
    else {
        $resultado = "**Hub de la red:** Estaciones $($hubs -join ', ') ($maxConexiones conexiones)`n"
    }
    return $resultado
}

$valido = validarMatriz -path $matriz -separador $separador

if ($valido -eq $false) {
    Write-Host "La matriz no es valida`n"
    exit
}

$resultado = "## Informe de análisis de red de transporte`n"
if ($hub -eq $false) {
    $resultado += Dijkstra -matrizPath $matriz -origen $camino[0] -destino $camino[1] -separador $separador
}
else {
    $resultado += hub -path $matriz -separador $separador
}
$nombreArchivo = "archivoinforme.$([System.IO.Path]::ChangeExtension($matriz, ".md"))"
$resultado | Out-File -FilePath "$nombreArchivo"

    