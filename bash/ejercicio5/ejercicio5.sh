#Estado: Prototipo acepta varios paises y busca todo. Genera un archivo Json con todos los campos pero no hace nada.

#1)Ingresar parametros (validarlos)
#2)Usar los parametros para la API que busque y guarde en archivo cache
#3)Proceso final (guardar archivo, mostrarlo)
#4)Limpieza


#Variables

for pais in $@;do
capital=""
region=""
poblacion=0
moneda=""

#valido
#que no este vacio
if [[ -z "$pais" ]]; then
    echo "Error: Debe ingresar el nombre de un país."
    continue
fi

# Que no contenga numeros ni caracter especiales
if ! [[ "$pais" =~ ^[a-zA-ZñÑ\s]+$ ]]; then
    echo "Error: El nombre del país solo puede contener letras y espacios."
    continue
fi


#Guardar en Json la busqueda:
curl -o test.json https://restcountries.com/v3.1/name/$pais

#consulto API
resultado=$(curl -s "https://restcountries.com/v3.1/name/$pais")

#Extraigo campos de interes
nombre=$(echo "$resultado" | jq -r '.[0].name.common')
capital=$(echo "$resultado" | jq -r '.[0].capital[0]')
region=$(echo "$resultado" | jq -r '.[0].region')
poblacion=$(echo "$resultado" | jq -r '.[0].population')
moneda_codigo=$(echo "$resultado" | jq -r '.[0].currencies | keys[0]')
moneda_nombre=$(echo "$resultado" | jq -r ".[0].currencies[\"$moneda_codigo\"].name")

echo "  Pais: $pais"
echo "  Capital: $capital"
echo "  Region: $region"
echo "  Poblacion: $poblacion"
echo "  Moneda: $moneda_nombre ($moneda_codigo)"

done
