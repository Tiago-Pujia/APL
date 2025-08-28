#Estado: 
    Prototipo acepta varios paises y busca todo. Genera un archivo Json donde se van guardando los resultados, se elimina al final del proceso.

#Flujo de datos:
#1)Ingresar parametros y valida que no tenga numeros ni caracter especial (excepto la ñ)
#2)Por cada parametro:
#2.1)Busca el pais en el archivo json. Si no lo encuentra, pide a la API
#2.2)Extrae los parametros y lo imprime en pantalla
#3)Al finalizar, borra el archivo cache.

#FALTA:
#Que acepte por parametro el tiempo de vida en cache
#Validar los datos con ese tiempo de vida
#Correguir un error del cual si la API no lo encuentra lanza un mensaje por pantalla.

#Variables

capital=""
region=""
poblacion=0
moneda=""
archivo_cache="archivo_cache.json"

if [[ ! -f "$archivo_cache" ]]; then
    echo "{}" > "$archivo_cache"
fi

for pais in $@;do


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

#Primero consulto al archivo
    if jq -e --arg pais "$pais" '.[$pais]' "$archivo_cache" >/dev/null; then
        echo "Datos desde cache: "
        resultado=$(jq -c --arg pais "$pais" '.[$pais]' "$archivo_cache")
    else 
    #consulto API
        resultadoAPI=$(curl -s "https://restcountries.com/v3.1/name/$pais")
            if [[ -z "$resultadoAPI" || "$resultadoAPI" == "[]" ]]; then
            echo "Error: No se encontró información para '$pais'."
            continue
        fi
        echo "Datos desde API: "
        #Vuelvo el formato de api al del script
        resultado=$(echo "$resultadoAPI" | jq '.[0]')  
        tmp=$(mktemp)
            jq --arg pais "$pais" --argjson datos "$resultado" \
           '. + {($pais): $datos}' "$archivo_cache" > "$tmp" && mv "$tmp" "$archivo_cache"
    
    fi

#Extraigo campos de interes
    nombre=$(echo "$resultado" | jq -r '.name.common')
    capital=$(echo "$resultado" | jq -r '.capital[0]')
    region=$(echo "$resultado" | jq -r '.region')
    poblacion=$(echo "$resultado" | jq -r '.population')
    moneda_codigo=$(echo "$resultado" | jq -r '.currencies | keys[0]')
    moneda_nombre=$(echo "$resultado" | jq -r ".currencies[\"$moneda_codigo\"].name")

echo "  Pais: $pais"
echo "  Capital: $capital"
echo "  Region: $region"
echo "  Poblacion: $poblacion"
echo "  Moneda: $moneda_nombre ($moneda_codigo)"

done

rm -f "$archivo_cache"
