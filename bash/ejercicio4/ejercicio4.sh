#!/bin/bash

#tail -f /tmp/daemon.log
#Para visualizar el pid del deamon ejecutar en terminal: cat /tmp/daemon/daemon.pid

LOG="/tmp/daemon.log"
PIDFILE="/tmp/daemon/daemon.pid"


#Funcion ayuda
ayuda(){
    cat help.txt
    exit 0
}


#Ejecucion del deamon

daemon() {
    while true; do
        echo "Hello World"
        sleep 1
    done
}

#Funcion que inicia el deamon
start(){
    local repo="$1"
    #Con este if me aseguro que no se inicie dos veces el deamon
    if [[ -f "$PIDFILE" ]]; then
        echo "El deamon ya está corriendo."
        exit 1
    fi
    mkdir -p "$(dirname "$PIDFILE")"
    daemon > "$LOG" 2>&1 &
    PID=$!

    echo $PID > "$PIDFILE"
    echo "Pid del daemon: $PID"
    echo "Usando config: $CONFIG"

}


#Funcion que detiene el deamon
stop() {
    if [[ -f "$PIDFILE" ]]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID" && rm "$PIDFILE"
            echo "Daemon detenido (PID $PID)."
        else
            echo "No hay proceso con PID $PID, limpiando PIDFILE..."
            rm "$PIDFILE"
        fi
    else
        echo "El daemon no está corriendo."
    fi
}



#Ingreso de parametros
ACTION=""
CONFIG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--configuracion) CONFIG="$2"; shift 2 ;;
        -k|--kill) ACTION="stop"; shift ;;
        -h|--help) ayuda ;;
        *) echo "Uso: $0 [-c config] [-k] [-h]"; exit 1 ;;
    esac
done

if [[ "$ACTION" == "stop" ]]; then
    stop
else
    [[ -z "$CONFIG" ]] && { echo "Faltan parámetros obligatorios"; exit 1; }
    start "$CONFIG"
fi
