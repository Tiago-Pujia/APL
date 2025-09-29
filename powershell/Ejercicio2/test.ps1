# === SET COMPLETO DE TESTS PowerShell SIMPLES ===

# --- Matriz base ---
$matriz1 = "matriz1.txt"
@"
0|15|7|5
15|0|3|7
7|3|0|8
5|7|8|0
"@ | Out-File $matriz1

# --- Matriz con decimales ---
$matriz3 = "matriz3.txt"
@"
0|2.5|3.1
2.5|0|4.7
3.1|4.7|0
"@ | Out-File $matriz3

# --- Matriz inválida: no simétrica ---
$matriz4 = "matriz4.txt"
@"
0|2|2
2|0|-3
2|-3|2
"@ | Out-File $matriz4

Write-Host "`n===== TEST 1: Camino normal ====="
Write-Output "`nMatriz utilizada"
Get-Content $matriz1
./ejercicio2.ps1 -matriz $matriz1 -separador '|' -camino 1,3
Write-Output "`nInforme generado"
Get-Content "archivoinforme.matriz1.md"

Write-Host "`n===== TEST 2: Hub normal ====="
./ejercicio2.ps1 -matriz $matriz1 -separador "|" -hub
Get-Content "archivoinforme.matriz1.md"

Write-Host "`n===== TEST 3: Camino con 1 número (error) ====="
./ejercicio2.ps1 -matriz $matriz1 -separador "|" -camino 1

Write-Host "`n===== TEST 4: Camino con 3 números (error) ====="
./ejercicio2.ps1 -matriz $matriz1 -separador "|" -camino 1,2,3

Write-Host "`n===== TEST 5: Matriz con decimales ====="
Write-Output "`nMatriz utilizada"
Get-Content $matriz3
./ejercicio2.ps1 -matriz $matriz3 -separador "|" -camino 1,3
Write-Output "`nInforme generado"
Get-Content "archivoinforme.matriz3.md"

Write-Host "`n===== TEST 6: Separador vacío (error) ====="
./ejercicio2.ps1 -matriz $matriz3 -separador "" -camino 1,2

Write-Host "`n===== TEST 7: Hub y Camino juntos (error) ====="
./ejercicio2.ps1 -matriz $matriz3 -separador "|" -camino 1,2 -hub

Write-Host "`n===== TEST 8: Sin hub ni camino (error) ====="
./ejercicio2.ps1 -matriz $matriz3 -separador "|"

Write-Host "`n===== TEST 9: Matriz no simétrica / números negativos (error) ====="
Write-Output "`nMatriz utilizada"
Get-Content $matriz4
./ejercicio2.ps1 -matriz $matriz4 -separador "|" -hub

# --- Limpiar archivos ---
Remove-Item $matriz1 -ErrorAction SilentlyContinue
Remove-Item $matriz3 -ErrorAction SilentlyContinue
Remove-Item $matriz4 -ErrorAction SilentlyContinue
Remove-Item "archivoinforme.matriz1.md" -ErrorAction SilentlyContinue

Remove-Item "archivoinforme.matriz3.md" -ErrorAction SilentlyContinue
