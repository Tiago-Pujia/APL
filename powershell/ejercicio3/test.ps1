# --- Configuración Inicial ---
Clear-Host

# Configurar la ruta al script que queremos probar
try {
    # $PSScriptRoot es una variable automática que apunta al directorio del script actual
    $ScriptRoot = $PSScriptRoot
    if (-not $ScriptRoot) {
        # Fallback por si se ejecuta desde la consola ISE
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    }
    $ScriptToTest = Join-Path $ScriptRoot "ejercicio3.ps1"

    if (-not (Test-Path $ScriptToTest)) {
        throw "No se pudo encontrar 'ejercicio3.ps1' en el directorio '$ScriptRoot'. Asegúrate de que ambos scripts estén en la misma carpeta."
    }
}
catch {
    Write-Host "Error fatal de configuración: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Directorio base para todas las pruebas
$TestEnvBaseDir = Join-Path $ScriptRoot "test_environment"


# --- Funciones de Ayuda para Pruebas ---

Function Setup-TestEnvironment {
    Write-Host "--- Preparando entorno de pruebas en '$TestEnvBaseDir' ---" -ForegroundColor Cyan
    
    # Limpiar entorno anterior si existe
    if (Test-Path $TestEnvBaseDir) {
        Remove-Item -Path $TestEnvBaseDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Crear estructura
    $null = New-Item -Path $TestEnvBaseDir -ItemType Directory

    # Escenario 1: Logs con datos
    $logsOkDir = Join-Path $TestEnvBaseDir "logs_ok"
    $null = New-Item -Path $logsOkDir -ItemType Directory
    Set-Content -Path (Join-Path $logsOkDir "log1.log") -Value @"
2023-01-01 ERROR: Fallo en el sistema.
2023-01-01 WARNING: Conexión lenta.
2023-01-01 ERROR: Otro error. error en línea.
"@
    # Contenido: 4 "error" (contando mayúsculas), 1 "warning"
    
    Set-Content -Path (Join-Path $logsOkDir "log2.log") -Value @"
2023-01-02 INFO: Sistema iniciado.
2023-01-02 WARNING: Disco casi lleno.
"@
    # Contenido: 0 "error", 1 "warning"

    Set-Content -Path (Join-Path $logsOkDir "ignore.txt") -Value "error error error"
    # Contenido: Debería ser ignorado

    # Escenario 2: Directorio vacío
    $logsEmptyDir = Join-Path $TestEnvBaseDir "logs_empty_dir"
    $null = New-Item -Path $logsEmptyDir -ItemType Directory

    # Escenario 3: Directorio sin archivos .log
    $logsNoLogsDir = Join-Path $TestEnvBaseDir "logs_no_logs"
    $null = New-Item -Path $logsNoLogsDir -ItemType Directory
    Set-Content -Path (Join-Path $logsNoLogsDir "readme.md") -Value "Contiene error pero no es .log"
}

Function Cleanup-TestEnvironment {
    Write-Host "--- Limpiando entorno de pruebas ---" -ForegroundColor Cyan
    if (Test-Path $TestEnvBaseDir) {
        Remove-Item -Path $TestEnvBaseDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Entorno '$TestEnvBaseDir' eliminado."
    }
}

Function Run-Test {
    param (
        [string]$TestName,
        [hashtable]$Params,
        [string[]]$ExpectedSubstrings,
        [bool]$ShouldFail = $false,
        [string]$ExpectedErrorString
    )

    Write-Host "`n[TEST] $TestName" -ForegroundColor Yellow
    
    $output = ""
    $exitCode = 0
    $errorMessage = ""
    $testPassed = $true

    # Limpiar el stream de errores
    $Error.Clear()

    try {
        # Ejecutar el script capturando TODO (stdout y stderr) en $output
        # ESTA ES LA FORMA CORRECTA de llamar al script dinámicamente usando "splatting" (@Params)
        # Evita los problemas de pasar argumentos como un string.
        $output = & $ScriptToTest @Params 2>&1
        $exitCode = $LASTEXITCODE
    }
    catch {
        # Captura errores terminantes (aunque el script usa Write-Error, que no es terminante)
        $errorMessage = $_.Exception.Message
    }

    # Convertir la salida (que puede ser un array de líneas) a un solo string
    $outputString = $output -join "`n"
    
    # Revisar si hubo errores no terminantes (Write-Error)
    if ($Error.Count -gt 0) {
        $errorMessage = $Error[0].ToString()
    }

    # --- Lógica de Aserción ---

    if ($ShouldFail) {
        # La prueba DEBE fallar
        if (($exitCode -eq 0) -and ($errorMessage -eq "")) {
            Write-Host "  [FAIL] Se esperaba que el script fallara, pero terminó exitosamente." -ForegroundColor Red
            $testPassed = $false
        } else {
            # El script falló como se esperaba. ¿Contiene el mensaje de error correcto?
            $actualError = $outputString + $errorMessage
            if ($actualError -like "*$ExpectedErrorString*") {
                Write-Host "  [PASS] El script falló como se esperaba con el mensaje: ...$ExpectedErrorString..." -ForegroundColor Green
            } else {
                Write-Host "  [FAIL] El script falló, pero con un mensaje de error inesperado." -ForegroundColor Red
                Write-Host "    ESPERADO (que contenga): $ExpectedErrorString"
                Write-Host "    RECIBIDO: $actualError"
                $testPassed = $false
            }
        }
    }
    else {
        # La prueba NO debe fallar
        
        # --- LÓGICA DE ASERCIÓN MODIFICADA ---
        # Primero, verificar si la salida contiene alguno de los mensajes de error conocidos
        # del script 'ejercicio3.ps1'. Esto es más fiable que $exitCode,
        # ya que Select-String (usado en ejercicio3.ps1) puede establecer $exitCode=1 si no
        # encuentra coincidencias, lo cual es un resultado "exitoso" para nosotros.
        
        $knownErrorPatterns = @(
            "Debe ingresar al menos una palabra",
            "Debe ingresar un directorio",
            "no existe",
            "No se encontraron archivos '.log'"
        )
        
        $errorFound = $false
        foreach ($pattern in $knownErrorPatterns) {
            # Usamos -like para ser flexibles con el formateo de Write-Error
            if ($outputString -like "*$pattern*") {
                $errorFound = $true
                break
            }
        }

        if ($errorFound) {
            # Si encontramos un mensaje de error real, la prueba falla.
            Write-Host "  [FAIL] Se esperaba que el script terminara exitosamente, pero falló." -ForegroundColor Red
            Write-Host "    ERROR (detectado en la salida): $outputString"
            $testPassed = $false
        } else {
            # Si no hay errores, el script tuvo éxito (incluso si $exitCode=1).
            # Ahora, verificar que la salida contenga lo esperado.
            
            # 1. Tomar la salida completa
            $comparisonOutput = $outputString
            
            # 2. Quitar todos los espacios alrededor de los dos puntos (:)
            $comparisonOutput = $comparisonOutput -replace '\s*:\s*', ':'
            
            # 3. Reemplazar múltiples espacios en otros lugares con uno solo
            $comparisonOutput = $comparisonOutput -replace '\s+', ' '
            
            
            $allSubstringsFound = $true
            foreach ($substring in $ExpectedSubstrings) {
                
                # 4. Normalizar el substring esperado DE LA MISMA MANERA
                $comparisonSubstring = $substring -replace '\s*:\s*', ':'
                $comparisonSubstring = $comparisonSubstring -replace '\s+', ' '
                
                
                if ($comparisonOutput -notlike "*$comparisonSubstring*") {
                    Write-Host "  [FAIL] La salida no contiene el texto esperado (incluso normalizando espacios)." -ForegroundColor Red
                    Write-Host "    ESPERADO (normalizado): $comparisonSubstring"
                    Write-Host "    RECIBIDO (normalizado): $comparisonOutput"
                    Write-Host "    ---"
                    Write-Host "    RECIBIDO (original): $outputString"
                    $allSubstringsFound = $false
                    $testPassed = $false
                    break
                }
            }
            if ($allSubstringsFound) {
                Write-Host "  [PASS] El script se ejecutó y la salida contiene todos los valores esperados." -ForegroundColor Green
                
                # Formatear la salida para que sea fácil de leer en la consola
                $indentedOutput = $outputString.Split("`n") | ForEach-Object { "      | $_" } # '      | ' es un buen indentador
                
                Write-Host "    --- Salida Recibida ---" -ForegroundColor Gray
                Write-Host ($indentedOutput -join "`n") -ForegroundColor Gray
                Write-Host "    -----------------------" -ForegroundColor Gray
            }
        }
    }
    
    # Actualizar contadores globales
    if ($testPassed) {
        $Global:TestResults.Pass++
    } else {
        $Global:TestResults.Fail++
    }
}

# --- Ejecución de Pruebas ---

# Inicializar entorno
Setup-TestEnvironment
$Global:TestResults = @{ Pass = 0; Fail = 0 }
$logsOkDir = Join-Path $TestEnvBaseDir "logs_ok"

# --- Tests de Éxito ---

Run-Test -TestName "Conteo exitoso (múltiples palabras y archivos)" -Params @{
    Palabras = @("error", "warning")
    Directorio = $logsOkDir
} -ExpectedSubstrings @(
    "Archivo: log1.log",
    "error : 4",
    "warning : 1",
    "Archivo: log2.log",
    "error : 0",
    "warning : 1"
) -ShouldFail $false

Run-Test -TestName "Conteo de palabra inexistente" -Params @{
    Palabras = @("fatal")
    Directorio = $logsOkDir
} -ExpectedSubstrings @(
    "Archivo: log1.log",
    "fatal : 0",
    "Archivo: log2.log",
    "fatal : 0"
) -ShouldFail $false

# --- Tests de Fallo (Validaciones) ---

Run-Test -TestName "Error: Directorio no existe" -Params @{
    Palabras = @("error")
    Directorio = (Join-Path $TestEnvBaseDir "dir_no_existe")
} -ShouldFail $true -ExpectedErrorString "no existe"

Run-Test -TestName "Error: Directorio está vacío" -Params @{
    Palabras = @("error")
    Directorio = (Join-Path $TestEnvBaseDir "logs_empty_dir")
} -ShouldFail $true -ExpectedErrorString "No se encontraron archivos '.log'"

Run-Test -TestName "Error: Directorio sin archivos .log" -Params @{
    Palabras = @("error")
    Directorio = (Join-Path $TestEnvBaseDir "logs_no_logs")
} -ShouldFail $true -ExpectedErrorString "No se encontraron archivos '.log'"

Run-Test -TestName "Error: Parámetro -Palabras está vacío" -Params @{
    Palabras = @("")
    Directorio = $logsOkDir
} -ShouldFail $true -ExpectedErrorString "empty string"

# --- Resumen y Limpieza ---

Write-Host "`n"
Write-Host "-------------------------------------" -ForegroundColor Cyan
Write-Host "Resumen de Pruebas" -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan
Write-Host "  PASARON: $($Global:TestResults.Pass)" -ForegroundColor Green
Write-Host "  FALLARON: $($Global:TestResults.Fail)" -ForegroundColor Red
Write-Host "-------------------------------------"

# Limpiar
Cleanup-TestEnvironment
