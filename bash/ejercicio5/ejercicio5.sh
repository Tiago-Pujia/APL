#Estado: 
#    A la espera que lo testeen.

#Flujo de datos:
#1)Ingresar parametros y valida que no tenga numeros ni caracter especial (excepto la ñ)
#2)Por cada parametro:
#2.1)Busca el pais en el archivo json. Si no lo encuentra, pide a la API
#2.2)Extrae los parametros y lo imprime en pantalla
#3)Al finalizar, borra el archivo cache.

#Formatos de entrada:
#./ejercicio5.sh -n pais1,pais2,... -t segundos
#./ejercicio5.sh --nombre pais1,pais2,... --ttl segundos

#-----------------------------<VARIABLES>-----------------------------
archivo_cache="archivo_cache.json"
ttl=0
declare -a nombres

#-----------------------------<FUNCIONES>-----------------------------

#Funcion ayuda
ayuda(){
    cat help.txt
    exit 0
}


#Funcion para consultar API
consultar_api() {
    local pais="$1"
    resultadoAPI=$(curl -s "https://restcountries.com/v3.1/name/$pais")
    if [[ -z "$resultadoAPI" || "$resultadoAPI" == "[]" ]]; then
        echo "Error: No se encontró información para '$pais'."
        return 1
    fi
    echo "$resultadoAPI" | jq '.[0]'
}

#Funcion para guardar en cache
guardar_cache() {
    local pais="$1"
    local datos="$2"
    local ts=$(date +%s)

    tmp=$(mktemp)
    jq --arg pais "$pais" --argjson datos "$datos" --arg ts "$ts" \
       '. + {($pais): {timestamp: ($ts | tonumber), data: $datos}}' \
       "$archivo_cache" > "$tmp" && mv "$tmp" "$archivo_cache"
}
#Funcion para consultar cache
consultar_cache() {
    local pais="$1"
    local ahora=$(date +%s)

    if jq -e --arg pais "$pais" '.[$pais]' "$archivo_cache" >/dev/null; then
        ts=$(jq -r --arg pais "$pais" '.[$pais].timestamp' "$archivo_cache")
        if (( ahora - ts < ttl )); then
            jq -c --arg pais "$pais" '.[$pais].data' "$archivo_cache"
            return 0
        fi
    fi
    return 1
}



#-----------------------------<PROGRAMA>-----------------------------

#Si no existe el archivo lo creo. No se borra el existente.
if [[ ! -f "$archivo_cache" ]]; then
    echo "{}" > "$archivo_cache"
fi

#->Formato de entrada
options=$(getopt -o n:t:h --long nombre:,ttl:,help -- "$@" 2> /dev/null)
if [ "$?" != "0" ]; then
    echo 'Opciones incorrectas'
    exit 1
fi


eval set -- "$options"
while true
do
    case "$1" in
        -n|--nombre)
            IFS=',' read -r -a nombres <<< "$2"
            shift 2
            ;;
        -t|--ttl)
            ttl="$2"
            shift 2
            ;;
        -h|--help)
            ayuda
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "error"
            exit 1
            ;;
    esac
done


#Valido las entradas
if [[ ${#nombres[@]} -eq 0 ]]; then
    echo "Error: Debe ingresar al menos un país con -n"
    exit 1
fi

if ! [[ "$ttl" =~ ^[0-9]+$ ]] || [[ $ttl -le 0 ]]; then
    echo "Error: Debe indicar un TTL válido en segundos con -t"
    exit 1
fi


for pais in "${nombres[@]}"; do
    # Valido el nombre
    if ! [[ "$pais" =~ ^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$ ]]; then
        echo "Error: El nombre del país solo puede contener letras y espacios."
        continue
    fi

    # Consultar cache
    if resultado=$(consultar_cache "$pais"); then
        echo "Datos desde caché:"
    else # Consulto API
        echo "Consultando API..."
        if resultado=$(consultar_api "$pais"); then
            guardar_cache "$pais" "$resultado"
        else
            continue
        fi
    fi

    # Extraigo los campos y los imprimo
    nombre=$(echo "$resultado" | jq -r '.name.common')
    capital=$(echo "$resultado" | jq -r '.capital[0]')
    region=$(echo "$resultado" | jq -r '.region')
    poblacion=$(echo "$resultado" | jq -r '.population')
    moneda_codigo=$(echo "$resultado" | jq -r '.currencies | keys[0]')
    moneda_nombre=$(echo "$resultado" | jq -r ".currencies[\"$moneda_codigo\"].name")
    echo "  País: $nombre"
    echo "  Capital: $capital"
    echo "  Región: $region"
    echo "  Población: $poblacion"
    echo "  Moneda: $moneda_nombre ($moneda_codigo)"
    echo
done
