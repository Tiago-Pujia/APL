#!/bin/bash

#tail -f /tmp/daemon.log
#Para visualizar el pid del deamon ejecutar en terminal: cat /tmp/daemon/daemon.pid

#-------------------------------COSAS IMPORTANTES-------------------------------#
    # No testie con una rama de git en si...
    # Sos libre de testear porfavor :) 
    # Deberia funcionar bien

    # Debe ser un repositorio EN LINUX
    # inotify (lo que dice si cambio algo) trabaja con el kernel UNIX
    # pd: hacer sudo apt install inotify-tools
    # tambien agragar que se necesita en el help

    # Finalmente, son libres de cambiar cualquier cosa
    # AGREGAR TESTS QUE NO LOS HICE AAAAA 
    # (pidanle a chat gpt que los haga porque son re tediosos sino jajaj)
#-------------------------------------------------------------------------------#
LOG="/tmp/daemon.log"
PIDFILE="/tmp/daemon/daemon.pid"


#Funcion ayuda
ayuda(){
    cat help.txt
    exit 0
}


escanear_archivo() {
    local archivo="$1"
    local config_file="$2"

    while IFS= read -r patron || [[ -n "$patron" ]]; do      #Conseguimos patrones y los limpiamos
        patron="${patron%%$'\r'}"
        patron="$(echo -n "$patron" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" #Limpieza horrenda
       
        [[ -z "$patron" ]] && continue #Linea vacia
        
        # Si aparece al menos una vez, loguear UNA SOLA VEZ por archivo

        #regex
        if [[ "$patron" == regex:* ]]; then
            # Quitar el prefijo "regex:"
            patron="${patron#regex:}"
            if LC_ALL=C grep -qE -- "$patron" "$archivo" 2>/dev/null; then
                printf '[%s] %s\n' "$(date +"%Y-%m-%d %T")" \
                "Alerta: patrón '$patron' encontrado en el archivo $archivo" >> "$LOG"
            fi
        else
        #no regex
            if LC_ALL=C grep -qF -- "$patron" "$archivo" 2>/dev/null; then
                printf '[%s] %s\n' "$(date +"%Y-%m-%d %T")" \
                "Alerta: patrón '$patron' encontrado en el archivo $archivo" >> "$LOG"
            fi
        fi
    done < "$config_file"
}

daemon_loop() {
    local repo="$1"
    local config="$2"

    local exclude='(/\.git/|\.swp$|\.swx$|~$|\.swpx$|^/tmp/|^/var/tmp/)'    #para evitar leer basura
    local prev=""   #Para evitar leer lo mismo dos veces

    while IFS= read -r archivo; do
        # Evitar duplicados inmediatos
        if [[ "$archivo" == "$prev" ]]; then
            continue
        fi
        prev="$archivo"                              
        escanear_archivo "$archivo" "$config" #Escanea un archivo
    done < <(                                                        #Aca avisan si se le hicieron cosas (inotify)
        inotifywait -q -m -r -e create -e modify -e moved_to -e close_write --exclude "$exclude" "$repo" --format '%w%f'    
        #Y manda el archivo al while con el < <
    )
}

start() {
    local repo="$1"
    local config="$2"

    if [[ -f "$PIDFILE" ]]; then
        echo "El daemon ya está corriendo."
        exit 1
    fi

    touch "$LOG"

    daemon_loop "$repo" "$config" >> "$LOG" 2>&1 &

    PID=$!
    mkdir -p "$(dirname "$PIDFILE")"   # <- crea el directorio si no existe
    echo $PID > "$PIDFILE"

    echo "Daemon iniciado (PID $PID). Usando config: $config"
}



#Funcion que detiene el deamon
stop() {
    if [[ -f "$PIDFILE" ]]; then    #Si existe un daemon corriendo
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            pkill -TERM -P "$PID"   # mata hijos del daemon
            kill -TERM "$PID"   # mata el daemon
            rm -f "$PIDFILE"
            echo "Daemon detenido (PGID $PID)."
        else
            echo "No hay proceso con PID $PID, limpiando PIDFILE..."
            rm -f "$PIDFILE"
        fi
    else
        echo "El daemon no está corriendo."
    fi
}

#Ingreso de parametros
ACTION=""
CONFIG=""
REPO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--configuracion) CONFIG="$2"; shift 2 ;;
        -r|--repo) REPO="$2"; shift 2 ;;
        -k|--kill) ACTION="stop"; shift ;;
        -h|--help) ayuda ;;
        *) echo "Uso: $0 [-c config] [-k] [-h]"; exit 1 ;;
    esac
done

if [[ "$ACTION" == "stop" ]]; then
    stop
    exit
fi

if [[ -z "$REPO" ]]; then # Comprobar cadena vacia
    echo "Debe especificar un directorio con -r"
    exit 1
fi

if [[ ! -d "$REPO" ]]; then # Comprobar si el directorio existe
    echo "El directorio '$REPO' no existe" >&2
    exit 1
fi

if [[ -z "$CONFIG" ]]; then
    echo "Falta el archivo de configuración"
    exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "El archivo de configuración está vacío"
    exit 1
fi

start "$REPO" "$CONFIG" 
    exit 1
fi

start "$REPO" "$CONFIG" 
