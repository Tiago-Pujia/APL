#!/bin/bash

# EJERCICIO 4
# - Tiago Pujia
# - Bautista Rios Di Gaeta
# - Santiago Manghi Scheck
# - Tomas Agustín Nielsen

#tail -f /tmp/daemon.log
#Para visualizar el pid del deamon ejecutar en terminal: cat /tmp/daemon/daemon.pid

LOG="/tmp/daemon.log"
PIDFILE=""  # Ahora se define dinámicamente


#Funcion ayuda
ayuda(){
echo "
NOMBRE
    ejercicio4.sh - Demonio de auditoría de seguridad para repositorios Git

SINOPSIS
    ejercicio4.sh [OPCIÓN]... -r REPOSITORIO -c ARCHIVO_CONFIG

DESCRIPCIÓN
    Demonio que monitorea un repositorio Git para detectar credenciales o datos
    sensibles en archivos modificados. Registra alertas en un archivo de log.

PARÁMETROS OBLIGATORIOS
    -r, --repo REPOSITORIO
        Ruta del repositorio Git a monitorear.

    -c, --configuracion ARCHIVO_CONFIG
        Ruta del archivo de configuración con patrones a buscar.

PARÁMETROS OPCIONALES
    -l, --log ARCHIVO_LOG
        Ruta del archivo de logs para alertas (por defecto: audit.log).

    -k, --kill
        Detiene el demonio en ejecución para el repositorio especificado.

    -h, --help
        Muestra esta ayuda y sale.

REQUISITOS
    - Es necesario tener instalado inotify-tools:
      sudo apt install inotify-tools

NOTAS
    - Ejecuta en segundo plano como demonio
    - Los patrones pueden ser palabras clave o expresiones regex
    - Valida que no haya más de una instancia por repositorio
    - Se debe especificar el mismo repositorio con --kill para detener

EJEMPLOS
    # Iniciar demonio
    ./ejercicio4.sh -r /home/user/repo -c patrones.conf -l auditoria.log
    
    # Detener demonio
    ./ejercicio4.sh -r /home/user/repo --kill
    
    # Configuración mínima
    ./ejercicio4.sh --repo ./mi-proyecto --configuracion seguridad.conf
"
}


escanear_archivo() {
    local archivo="$1"
    local config_file="$2"

    while IFS= read -r patron || [[ -n "$patron" ]]; do      #Conseguimos patrones y los limpiamos
        patron="${patron%%$'\r'}"
        patron="$(echo -n "$patron" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" #Limpieza horrenda
       
        [[ -z "$patron" ]] && continue #Linea vacia
        [[ "$patron" =~ ^# ]] && continue #Comentarios
        
        #regex
        if [[ "$patron" == regex:* ]]; then
            # Quitar el prefijo "regex:"
            patron="${patron#regex:}"
            # Buscar case-insensitive con grep -i y capturar todas las líneas que coinciden
            while IFS= read -r linea; do
                printf '[%s] %s\n' "$(date +"%Y-%m-%d %T")" \
                "Alerta: patrón '$patron' encontrado en el archivo $archivo" >> "$LOG"
            done < <(grep -iE -- "$patron" "$archivo" 2>/dev/null)
        else
        #no regex - búsqueda case-insensitive con grep -F -i
            # Buscar case-insensitive y capturar todas las líneas que coinciden
            while IFS= read -r linea; do
                printf '[%s] %s\n' "$(date +"%Y-%m-%d %T")" \
                "Alerta: patrón '$patron' encontrado en el archivo $archivo" >> "$LOG"
            done < <(grep -iF -- "$patron" "$archivo" 2>/dev/null)
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
        #Y manda el archivo al while con el < 
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
        -r|--repo) REPO="$2";            shift 2 ;;
        -k|--kill) ACTION="stop";        shift 1 ;;
        -l|--log) LOG="$2";              shift 2 ;;
        -h|--help) ayuda;                exit  0 ;;
        *) echo "Uso: $0 [-c config] [-k] [-h]"; exit 1 ;;
    esac
done

# Verificar inotify-tools
if ! command -v inotifywait &> /dev/null; then
    echo "Error: inotify-tools no está instalado."
    echo "Instala con: sudo apt install inotify-tools"
    exit 1
fi

if [[ "$ACTION" == "stop" ]]; then
    if [[ -z "$REPO" ]]; then
        echo "Debe especificar el repositorio con -r para detener el daemon"
        exit 1
    fi
    # Generar PIDFILE único para este repositorio
    REPO_HASH=$(echo -n "$(realpath "$REPO")" | md5sum | cut -d' ' -f1)
    PIDFILE="/tmp/daemon/daemon_${REPO_HASH}.pid"
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

if [[ ! -f "$CONFIG" ]]; then
    echo "Falta el archivo de configuración"
    exit 1
fi

if [[ ! -s "$CONFIG" ]]; then
    echo "El archivo de configuración está vacío"
    exit 1
fi

#PIDFILE unico para este repo
REPO_HASH=$(echo -n "$(realpath "$REPO")" | md5sum | cut -d' ' -f1)
PIDFILE="/tmp/daemon/daemon_${REPO_HASH}.pid"

start "$REPO" "$CONFIG"

