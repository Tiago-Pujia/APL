#!/bin/bash

# EJERCICIO 5
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

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

ayuda(){
cat <<'EOF'
NOMBRE
    ejercicio5.sh - Buscador de información de países

SINOPSIS
    ejercicio5.sh [OPCIÓN]... -n PAÍS(ES) -t SEGUNDOS

DESCRIPCIÓN
    Consulta información de países utilizando la API REST Countries y almacena
    los resultados en una caché con tiempo de vida (TTL) individual por registro.

PARÁMETROS OBLIGATORIOS
    -n, --nombre PAÍS(ES)
        Nombre(s) de los países a buscar. Múltiples nombres se separan por comas.
        Ejemplo: "argentina,brasil,chile"
    -t, --ttl SEGUNDOS
        Tiempo en segundos que se guardarán los resultados en caché.
        Ejemplo: "60"

PARÁMETROS OPCIONALES
    -h, --help
        Muestra esta ayuda y sale.

EJEMPLOS
    ./ejercicio5.sh -n argentina -t 60
    ./ejercicio5.sh --nombre spain,france --ttl 7200
    ./ejercicio5.sh -n japan,canada,mexico -t 1800
EOF
}


# Consulta API
consultar_api() {
    local pais="$1"
    local url="https://restcountries.com/v3.1/name/$pais"
    local resultadoAPI
    resultadoAPI=$(curl -s "$url")
    if [[ -z "$resultadoAPI" || "$resultadoAPI" == "[]" ]]; then
        echo "Error: No se encontró información para '$pais'." >&2
        return 1
    fi
    echo "$resultadoAPI" | jq '.[0]'
}

# Guarda en caché 
guardar_cache() {
    local pais="$1"
    local datos="$2"
    local ttl_local="$3"
    local ts=$(date +%s)
    local tmp=$(mktemp)

    # Si el archivo está vacío o corrupto, lo reinicia
    if ! jq empty "$archivo_cache" &>/dev/null; then
        echo "{}" > "$archivo_cache"
    fi

    jq --arg pais "$pais" --argjson datos "$datos" --arg ts "$ts" --arg ttl "$ttl_local" \
       '. + {($pais): {timestamp: ($ts|tonumber), ttl: ($ttl|tonumber), data: $datos}}' \
       "$archivo_cache" > "$tmp" && mv "$tmp" "$archivo_cache"
}

# Consulta caché 
consultar_cache() {
    local pais="$1"
    local ahora=$(date +%s)

    # Verifica que el país esté en la caché
    if jq -e --arg pais "$pais" '.[$pais]' "$archivo_cache" &>/dev/null; then
        local ts ttl_guardado
        ts=$(jq -r --arg pais "$pais" '.[$pais].timestamp' "$archivo_cache")
        ttl_guardado=$(jq -r --arg pais "$pais" '.[$pais].ttl' "$archivo_cache")

        # Verifica si sigue vigente
        if (( ahora - ts < ttl_guardado )); then
            jq -c --arg pais "$pais" '.[$pais].data' "$archivo_cache"
            return 0
        fi
    fi
    return 1
}

#-----------------------------<PROGRAMA>-----------------------------

# Crear archivo de caché si no existe
[[ ! -f "$archivo_cache" ]] && echo "{}" > "$archivo_cache"

# Parsear parámetros
options=$(getopt -o n:t:h --long nombre:,ttl:,help -- "$@" 2>/dev/null)
if [[ $? -ne 0 ]]; then
    echo 'Opciones incorrectas. Use -h para ayuda.'
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
        -n|--nombre)
            IFS=',' read -r -a nombres <<< "$2"
            shift 2;;
        -t|--ttl)
            ttl="$2"
            shift 2;;
        -h|--help)
            ayuda; exit 0;;
        --)
            shift; break;;
        *)
            echo "Error en parámetros"; exit 1;;
    esac
done

# Validaciones
if [[ ${#nombres[@]} -eq 0 ]]; then
    echo "Error: Debe ingresar al menos un país con -n" >&2
    exit 1
fi

if ! [[ "$ttl" =~ ^[0-9]+$ ]] || [[ $ttl -le 0 ]]; then
    echo "Error: Debe indicar un TTL válido (entero > 0) con -t" >&2
    exit 1
fi


for pais in "${nombres[@]}"; do
    pais=$(echo "$pais" | xargs)  

    if ! [[ "$pais" =~ ^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$ ]]; then
        echo "Error: El nombre del país '$pais' solo puede contener letras y espacios." >&2
        continue
    fi
 # Consultar cache
    if resultado=$(consultar_cache "$pais"); then
        echo "Datos desde caché:"
    else # Consulto API
        echo "Consultando API para '$pais'..."
        if resultado=$(consultar_api "$pais"); then
            guardar_cache "$pais" "$resultado" "$ttl"
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
