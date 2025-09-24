#!/usr/bin/env pwsh

Write-Output "Ejecutando tests..."

# Crear entorno de prueba
$testDir = Join-Path $PSScriptRoot "test"
if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
New-Item -ItemType Directory -Path $testDir | Out-Null

# Crear archivo de prueba
@"
101|2025-07-01 10:22:33|Telefono|5.5|4
102|2025-07-01 12:23:11|Email|120|5
103|2025-07-01 22:34:43|Chat|2.1|3
104|2025-06-30 23:11:10|Telefono|7.8|2
"@ | Set-Content -Path (Join-Path $testDir "2025-07-01.txt")

Write-Output "`nTest 1: salida por pantalla"
.\ejercicio1.ps1 -directorio $testDir -pantalla

Write-Output "`nTest 2: salida a archivo"
.\ejercicio1.ps1 -directorio $testDir -archivo resultados.json

# Limpiar
Remove-Item $testDir -Recurse -Force
Remove-Item resultados.json -Force -ErrorAction SilentlyContinue
Write-Output "`nEntorno de prueba eliminado."
