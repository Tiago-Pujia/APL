
# Crear archivo de prueba para matriz en ASCII
"0,10,0,5`n10,0,0,7`n0,0,0,8`n5,7,8,0" | Out-File mapa_transporte.txt
Write-Host "Archivo mapa_transporte.txt creado`n"

# Función auxiliar para ejecutar pruebas

# --- PRUEBAS ---

# Caso válido: hub
"`nHub con archivo válido y separador válido"
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
    "`n.\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador ','"
    .\ejercicio2.ps1 -matriz mapa_transporte.txt -camino 1,3 -separador ','

"`nBorrando entorno de prueba"
Remove-Item -Path "mapa_transporte.txt"