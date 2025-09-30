#!/usr/bin/env pwsh


Write-Host "`n=== INICIANDO PRUEBAS EJERCICIO 4 ===" -ForegroundColor Cyan
Write-Host "Demonio de Monitoreo Git - Detección de Credenciales`n" -ForegroundColor Cyan

# Función auxiliar para mostrar el resultado de las pruebas
function Show-TestResult {
    param(
        [string]$testName,
        [string]$command,
        [bool]$shouldSucceed = $true
    )
    Write-Host "`n--- $testName ---" -ForegroundColor Yellow
    Write-Host "Comando: $command" -ForegroundColor Gray
    Write-Host "Resultado esperado: " -NoNewline -ForegroundColor Gray
    if ($shouldSucceed) {
        Write-Host "ÉXITO" -ForegroundColor Green
    } else {
        Write-Host "ERROR CONTROLADO" -ForegroundColor Magenta
    }
    Write-Host ""
}

# --- CONFIGURACIÓN INICIAL ---
Write-Host "Preparando entorno de pruebas..." -ForegroundColor Cyan

# Limpiar entorno previo
$testDir = "./test-ejercicio4"
if (Test-Path $testDir) {
    Remove-Item -Recurse -Force $testDir
}

# Crear directorio de pruebas
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Set-Location $testDir

# Crear archivo de patrones
@"
password
API_KEY
secret
token
aws_access_key
regex:API_KEY\s*=\s*['"].*['"]
regex:password\s*[:=]\s*['"]\w+['"]
regex:\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b
"@ | Out-File -FilePath patrones.conf -Encoding UTF8

Write-Host "✓ Archivo de patrones creado" -ForegroundColor Green

# Crear repositorio de prueba
New-Item -ItemType Directory -Path test-repo -Force | Out-Null
Set-Location test-repo
git init | Out-Null
git config user.email "test@example.com" | Out-Null
git config user.name "Test User" | Out-Null
"# Repositorio de Prueba" | Out-File -FilePath README.md -Encoding UTF8
git add README.md | Out-Null
git commit -m "Initial commit" | Out-Null
Set-Location ..

Write-Host "✓ Repositorio de prueba creado`n" -ForegroundColor Green

# Copiar script al directorio de pruebas
Copy-Item ../script4.ps1 . -Force

# --- PRUEBAS ---

# Prueba 1: Iniciar demonio correctamente
Show-TestResult -testName "Prueba 1: Iniciar demonio con parámetros válidos" `
    -command "./script4.ps1 -repo ./test-repo -configuracion ./patrones.conf -log $PWD/audit.log -alerta 5" `
    -shouldSucceed $true

Start-Process pwsh -ArgumentList "-NoProfile", "-Command", "./script4.ps1 -repo ./test-repo -configuracion ./patrones.conf -log $PWD/audit.log -alerta 5" -WorkingDirectory $PWD
Start-Sleep -Seconds 2

if (Test-Path audit.log) {
    Write-Host "✓ Demonio iniciado correctamente" -ForegroundColor Green
    Write-Host "Log inicial:" -ForegroundColor Gray
    Get-Content audit.log
} else {
    Write-Host "✗ ERROR: No se creó el archivo de log" -ForegroundColor Red
}

# Prueba 2: Detectar credenciales en archivo .env
Show-TestResult -testName "Prueba 2: Detectar credenciales en archivo .env" `
    -command "Crear .env con credenciales y hacer commit" `
    -shouldSucceed $true

Set-Location test-repo
@"
DATABASE_URL=postgresql://admin:super_secret_pass@localhost/mydb
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
API_KEY="sk-live-1234567890abcdefghijklmnopqrstuvwxyz"
SECRET_TOKEN=ghp_AbCdEfGhIjKlMnOpQrStUvWxYz123456
"@ | Out-File -FilePath .env -Encoding UTF8

git add .env | Out-Null
git commit -m "Add environment variables" | Out-Null
Set-Location ..

Write-Host "Esperando detección (10 segundos)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

Write-Host "`nAlertas detectadas:" -ForegroundColor Yellow
Get-Content audit.log | Select-String "Alerta:"

# Prueba 3: Detectar credenciales en archivo Python
Show-TestResult -testName "Prueba 3: Detectar credenciales en archivo Python" `
    -command "Crear secrets.py con credenciales" `
    -shouldSucceed $true

Set-Location test-repo
@"
# Database credentials
DB_HOST = 'localhost'
DB_PASSWORD = 'my_super_secret_password_123'
DB_USER = 'admin'

# API Keys
API_KEY = 'sk-1234567890abcdefghijklmnopqrstuvwxyz'
AWS_ACCESS_KEY = 'AKIAIOSFODNN7EXAMPLE'
SECRET_TOKEN = 'ghp_AbCdEfGhIjKlMnOpQrStUvWxYz123456'
"@ | Out-File -FilePath secrets.py -Encoding UTF8

git add secrets.py | Out-Null
git commit -m "Add secrets configuration" | Out-Null
Set-Location ..

Write-Host "Esperando detección (10 segundos)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

Write-Host "`nAlertas detectadas:" -ForegroundColor Yellow
Get-Content audit.log | Select-String "Alerta:" | Select-Object -Last 5

# Prueba 4: Detectar múltiples patrones en JSON
Show-TestResult -testName "Prueba 4: Detectar múltiples patrones en config.json" `
    -command "Crear config.json con múltiples credenciales" `
    -shouldSucceed $true

Set-Location test-repo
@"
{
  "database": {
    "host": "localhost",
    "password": "super_secret_db_password",
    "user": "admin",
    "port": 5432
  },
  "api": {
    "API_KEY": "sk-test-1234567890abcdefghijklmnopqrstuvwxyz",
    "secret": "my_api_secret_token_123"
  },
  "aws": {
    "aws_access_key": "AKIAIOSFODNN7EXAMPLE",
    "region": "us-east-1"
  },
  "email": "admin@company.com"
}
"@ | Out-File -FilePath config.json -Encoding UTF8

git add config.json | Out-Null
git commit -m "Add configuration file" | Out-Null
Set-Location ..

Write-Host "Esperando detección (10 segundos)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

Write-Host "`nAlertas detectadas:" -ForegroundColor Yellow
Get-Content audit.log | Select-String "Alerta:" | Select-Object -Last 8

# Prueba 5: Intentar iniciar segundo demonio (debe fallar)
Show-TestResult -testName "Prueba 5: Intentar iniciar segundo demonio para el mismo repositorio" `
    -command "./script4.ps1 -repo ./test-repo -configuracion ./patrones.conf -alerta 5" `
    -shouldSucceed $false

Write-Host "Resultado:" -ForegroundColor Gray
./script4.ps1 -repo ./test-repo -configuracion ./patrones.conf -log $PWD/audit.log -alerta 5 2>&1

# Prueba 6: Error - Repositorio no existe
Show-TestResult -testName "Prueba 6: Error - Repositorio no existe" `
    -command "./script4.ps1 -repo ./repo-inexistente -configuracion ./patrones.conf -alerta 5" `
    -shouldSucceed $false

Write-Host "Resultado:" -ForegroundColor Gray
./script4.ps1 -repo ./repo-inexistente -configuracion ./patrones.conf -log $PWD/audit.log -alerta 5 2>&1

# Prueba 7: Error - Archivo de configuración no existe
Show-TestResult -testName "Prueba 7: Error - Archivo de configuración no existe" `
    -command "./script4.ps1 -repo ./test-repo -configuracion ./inexistente.conf -alerta 5" `
    -shouldSucceed $false

Write-Host "Resultado:" -ForegroundColor Gray
./script4.ps1 -repo ./test-repo -configuracion ./inexistente.conf -log $PWD/audit.log -alerta 5 2>&1

# Prueba 8: Error - Faltan parámetros obligatorios
Show-TestResult -testName "Prueba 8: Error - Faltan parámetros obligatorios" `
    -command "./script4.ps1 -repo ./test-repo" `
    -shouldSucceed $false

Write-Host "Resultado:" -ForegroundColor Gray
./script4.ps1 -repo ./test-repo 2>&1

# Prueba 9: Detener demonio correctamente
Show-TestResult -testName "Prueba 9: Detener demonio con -kill" `
    -command "./script4.ps1 -repo ./test-repo -kill" `
    -shouldSucceed $true

Write-Host "Resultado:" -ForegroundColor Gray
./script4.ps1 -repo ./test-repo -kill

# Prueba 10: Intentar detener demonio que no existe
Show-TestResult -testName "Prueba 10: Intentar detener demonio inexistente" `
    -command "./script4.ps1 -repo ./test-repo -kill" `
    -shouldSucceed $false

Write-Host "Resultado:" -ForegroundColor Gray
./script4.ps1 -repo ./test-repo -kill 2>&1


# --- LIMPIEZA ---
    Set-Location ..
    Remove-Item -Recurse -Force $testDir
    Write-Host " Entorno de pruebas eliminado" -ForegroundColor Green


Write-Host "`n=== PRUEBAS FINALIZADAS ===" -ForegroundColor Cyan
