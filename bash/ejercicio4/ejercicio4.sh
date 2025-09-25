#!/bin/bash

#Para visualizar el pid del deamon ejecutar en terminal: cat /tmp/daemon/daemon.pid
# para visualizar el demon: tail -f /tmp/daemon.log

LOG="/tmp/daemon.log"
PIDFILE="/tmp/daemon/daemon.pid"



#Ejecucion del deamon
daemon() {
    while true; do
        echo "Hello World"
        sleep 1
    done
}

#Funcion que inicia el deamon
start(){
    #Con este if me aseguro que no se inicie dos veces el deamon
    if [[ -f "$PIDFILE" ]]; then
        echo "El deamon ya está corriendo."
        exit 1
    fi
    mkdir -p "$(dirname "$PIDFILE")"
    daemon > "$LOG" 2>&1 &
    PID=$!

    echo $PID > "$PIDFILE"
    echo "Pid del deamon: $PID" > "$PIDFILE"

}


#Funcion que detiene el deamon
stop(){
    if [[ -f "$PIDFILE" ]]; then
        kill $(cat "$PIDFILE") && rm "$PIDFILE"
        echo "Deamon detenido."
    else
        echo "El deamon no esta corriendo."
    fi
}



#Ingreso de parametros
case "$1" in
  -k|--kill)
    stop
    ;;
  "" )
    start
    ;;
  *)
    echo "Uso: $0 [-k|--kill]"
    exit 1
    ;;
esac
