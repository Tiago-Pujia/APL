
# Crear archivo de prueba para matriz en ASCII
"0,10,0,5`n10,0,0,7`n0,0,0,8`n5,7,8,0" | Out-File mapa_transporte.txt
Write-Host "Archivo mapa_transporte.txt creado`n"

# Función auxiliar para ejecutar pruebas

# --- PRUEBAS ---

# Caso válido: hub una estación
"`nHub con archivo válido y separador válido, un hub unico"
    ".\ejercicio2.ps1 -matriz mapa_transporte.txt -hub -separador ','"
.\ejercicio2.ps1 -matriz mapa_transporte.txt -hub -separador ','


# Caso válido: hub varias estaciones
"0,10,0,5`n10,0,15,7`n0,15,0,8`n5,7,8,0" | Out-File mapa_transporte.txt
"`nHub con archivo válido y separador válido, hub multiple"
    ".\ejercicio2.ps1 -matriz mapa_transporte.txt -hub -separador ','"
.\ejercicio2.ps1 -matriz mapa_transporte.txt -hub -separador ','

# Caso válido: camino
"`nCamino con dos números"
    ".\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador ','"
    .\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador ','

# Error: archivo no existe
    "`nArchivo inexistente"
    ".\ejercicio2.ps1 -matriz noexiste.txt -hub -separador ','"
    .\ejercicio2.ps1 -matriz noexiste.txt -hub -separador ','

# Error: camino con un solo número
     "`nCamino con 1 número"
    ".\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 5 -separador '|'"
    .\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 5 -separador '|'

# Error: camino con 3 números
     "`nCamino con 3 números"
    ".\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,2,3 -separador ';'"
    .\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,2,3 -separador ';'

# Error: usar hub y camino a la vez
     "`nHub y camino juntos"
    ".\ejercicio2.ps1 -matriz mapa_transporte.txt -hub -camino 1,2 -separador ','"
    .\ejercicio2.ps1 -matriz mapa_transporte.txt -hub -camino 1,2 -separador ','

# Error: matriz invalida
    "0,10,7,5`n10,0,0,7`n0,0,0,8`n5,7,8,0" | Out-File mapa_transporte.txt
    "`nMatriz Inválida"
    "`n.\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador ','"
    .\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador ','

# Caso Válido: Con |
    "0|15|7|5`n15|0|3|7`n7|3|0|8`n5|7|8|0" | Out-File mapa_transporte.txt
    "`n.\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador '|'"
    .\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador '|'

# Caso Válido: Matriz de 10x10
    "0|58|35|7|26|92|84|30|59|61`n58|0|16|94|53|33|15|3|34|98`n35|16|0|55|44|68|2|51|62|81`n7|94|55|0|72|21|31|36|97|23`n26|53|44|72|0|12|40|63|17|99`n92|33|68|21|12|0|75|90|60|77`n84|15|2|31|40|75|0|41|8|13`n30|3|51|36|63|90|41|0|29|57`n59|34|62|97|17|60|8|29|0|74`n61|98|81|23|99|77|13|57|74|0" | Out-File "mapa_Gigante.txt"
    .\ejercicio2.ps1 -matriz mapa_Gigante.txt -hub -separador '|'
    Remove-Item -Path "mapa_Gigante.txt"


"`nBorrando entorno de prueba"
Remove-Item -Path "mapa_transporte.txt"