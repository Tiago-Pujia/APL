# Crear directorio de prueba
New-Item -ItemType Directory -Force -Path "logs_prueba"

# Crear archivo system.log con contenido variado
@"
Error: falta memoria
Advertencia: proceso lento
Info: inicio correcto
Error: conexión rechazada
Advertencia: alto uso de CPU
Error: disco lleno
Info: operación completada
"@ | Set-Content "logs_prueba/system.log"

# Buscar palabras claves
write-Host "`nTest 1: Uso correcto"
.\ejercicio3.ps1 "Error","Advertencia","Info","disco","memoria" logs_prueba  

# Crear directorio vacío
write-Host "`n"
New-Item -ItemType Directory -Force -Path "logs_vacio"

# Ejecutar
write-Host "`nTest 2: Directorio vacío"
.\ejercicio3.ps1 "Error" logs_vacio

# Crear directorio con otro archivo distinto
write-Host "`n"
New-Item -ItemType Directory -Force -Path "logs_sinlog"
"Este no es un log" | Set-Content "logs_sinlog/otro.txt"

# Ejecutar
write-Host "`nTest 3: Sin archivos .log"
.\ejercicio3.ps1 "Error" logs_sinlog

# Crear logs con contenido básico
write-Host "`n"
New-Item -ItemType Directory -Force -Path "logs_ocurrencias"
@"
Error: falta memoria
Advertencia: proceso lento
Info: inicio correcto
"@ | Set-Content "logs_ocurrencias/system.log"

# Ejecutar con palabra inocurrente
write-Host "`nTest 4: Palabra sin ocurrencias"
.\ejercicio3.ps1 "Inexistente" logs_ocurrencias

# Crear logs
write-Host "`n"
New-Item -ItemType Directory -Force -Path "logs_sinpalabras"
"Error: disco lleno" | Set-Content "logs_sinpalabras/system.log"

# Ejecutar sin palabras
write-Host "`nTest 5: Llamada sin palabras"
.\ejercicio3.ps1 "" logs_sinpalabras

Remove-Item "logs_ocurrencias" -Recurse -Force
Remove-Item "logs_prueba" -Recurse -Force
Remove-Item "logs_vacio" -Recurse -Force
Remove-Item "logs_sinlog" -Recurse -Force
Remove-Item "logs_sinpalabras" -Recurse -Force