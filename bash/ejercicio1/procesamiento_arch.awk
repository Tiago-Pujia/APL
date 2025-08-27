#!/usr/bin/awk -f

BEGIN {
    FS="|"
}

NR > 1 {
    # Se crean los arrays asociativos:
    #   suma_tiempo[(fecha, canal)]  -> suma de tiempos
    #   suma_nota[(fecha, canal)]    -> suma de notas
    #   cuenta[(fecha, canal)]       -> cantidad de registros
    #
    # Para cada registro:
    #   1. Extraer fecha, canal, tiempo y nota
    #   2. Acumular tiempo y nota por (fecha, canal)
    #   3. Contar cantidad de registros por (fecha, canal)
    
    # Variables:
    fecha = $2
    canal = $3
    tiempo = $4
    nota = $5

    # Extraemos fecha (sin hora)
    split(fecha, f, " ") # Separo fecha y hora
    fecha = f[1] # Me quedo con la fecha

    # Acumulo en arrays asociativos
    key = fecha "|" canal # Simulamos matriz con clave compuesta

    suma_tiempo[key] += tiempo
    suma_nota[key]   += nota
    cuenta[key]++
}

END {
    # Variables
    sep_dia = ""

    # Abrimos el JSON raíz
    printf "{"

    # Recorremos todas las claves acumuladas (día|canal)
    for (key in suma_tiempo) {
        # Separamos la clave en día y canal
        split(key, partes, "|")
        dia   = partes[1]
        canal = partes[2]

        # Calculamos los promedios de tiempo y nota
        tiempo_prom = suma_tiempo[key] / cuenta[key]
        nota_prom   = suma_nota[key] / cuenta[key]

        # Si es la primera vez que encontramos este día
        if (!(dia in usado_dia)) {
            # Si ya había un día anterior, cerramos su objeto JSON y agregamos coma
            if (sep_dia != "") {
                printf "}"   # Cierra el bloque JSON del día anterior
                printf ","   # Agrega coma para separar días
            }

            # Iniciamos un nuevo bloque JSON para este día
            printf "\"%s\":{", dia

            # Marcamos que el día ya fue procesado
            usado_dia[dia] = 1

            # Inicializamos el separador de canales para este día
            sep_canal[dia]=""

            # Activamos el separador de días para los siguientes días
            sep_dia=","
        }

        # Si ya agregamos un canal previo para este día, ponemos coma antes
        if (sep_canal[dia] != "") {
            printf ","
        }

        # Imprimimos el objeto JSON para este canal con sus promedios
        printf "\"%s\":{\"tiempo_respuesta_promedio\":%.2f,\"nota_satisfaccion_promedio\":%.2f}", canal, tiempo_prom, nota_prom

        # Activamos separador de canales para el próximo canal de este día
        sep_canal[dia] = ","
    }

    # Cerramos el último día y el JSON raíz
    printf "}}"
}


