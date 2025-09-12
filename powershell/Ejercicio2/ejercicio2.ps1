
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
        $filas += , ($linea -split $separador | ForEach-Object { $_.Trim() })
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

$valido = validarMatriz -path $matriz -separador $separador

if($valido -eq $false){
    Write-Host "La matriz no es valida`n"
    exit
}
else {
    Write-Host "La matriz es valida`n"
    exit
}


    