# !/bin/bash

# ========================================
# Ejercicio 1: Análisis de resultados de encuestas de satisfacción de clientes
#
# Se requiere un script para analizar los resultados de encuestas de satisfacción de clientes de un servicio de atención al cliente. Los datos se registran diariamente en archivos de texto, con cada encuesta en una línea
#
# El archivo de registro tiene un formato de campos fijos, donde la posición de cada campo indica su significado, y los campos están separados por un pipe (|). El nombre del archivo tendrá la fecha de registro de las encuestas.
#
# Formato: ID_ENCUESTA|FECHA|CANAL|TIEMPO_RESPUESTA|NOTA_SATISFACCION
# Campos:
# • ID_ENCUESTA: numérico
# • FECHA: texto (yyyy-mm-dd hh:mm:ss)
# • CANAL: texto (Teléfono, Email, Chat)
# • TIEMPO_RESPUESTA: numérico (en minutos)
# • NOTA_SATISFACCION: numérico (de 1 a 5)
#
# Ejemplo:
# 101|2025-07-01 10:22:33|Telefono|5.5|4
# 102|2025-07-01 12:23:11|Email|120|5
# 103|2025-07-01 22:34:43|Chat|2.1|3
# 104|2025-06-30 23:11:10|Telefono|7.8|2
#
# Se requiere un script que procese todos los archivos de encuestas en un directorio, calcule el tiempo de respuesta promedio y la nota de satisfacción promedio por canal de atención y por día. El resultado debe ser un archivo o una impresión en pantalla, ambas en formato JSON.
#
# Parámetros:
# -d / --directorio -> Ruta del directorio con los archivos de encuestas a procesar
# -a / --archivo    -> Ruta completa del archivo JSON de salida. No se puede usar con -p / -pantalla
# -p / --pantalla   -> Muestra la salida por pantalla. No se puede usar con -a / -archivo.
# ========================================

pantalla=false

while getopts 'd:a:p' opt; do
    case "$opt" in
        d) directorio="$OPTARG" ;;
        a) archivo="$OPTARG" ;;
        p) pantalla=true ;;
        \?) echo "Opción inválida"; exit 1 ;;
    esac
done

echo "Directorio: $directorio"
echo "Archivo: $archivo"
echo "Pantalla: $pantalla"